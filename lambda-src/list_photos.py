import base64
import binascii
import json
import os
import unicodedata
from collections import Counter
from urllib.parse import urlencode, urlparse

import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.client("dynamodb")


def normalize_tags(tags):
    if not isinstance(tags, list) or len(tags) > 20:
        raise ValueError("Expected up to 20 tags")
    normalized = set()
    for tag in tags:
        if not isinstance(tag, str):
            raise ValueError("Invalid tag")
        tag = " ".join(unicodedata.normalize("NFC", tag).lower().split())
        if not tag or len(tag) > 40 or "," in tag or not tag.isprintable():
            raise ValueError("Tags must be 1–40 characters without commas")
        normalized.add(tag)
    return sorted(normalized)


def reply(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def cursor_key(cursor):
    try:
        timestamp, photo_id = json.loads(base64.urlsafe_b64decode(cursor))
        if not (isinstance(timestamp, str) and timestamp.isdigit()
                and isinstance(photo_id, str) and photo_id.startswith("image#")):
            raise ValueError()
    except (ValueError, TypeError, binascii.Error) as exc:
        raise ValueError("Invalid cursor") from exc
    return {"GSI1PK": {"S": "list"}, "GSI1SK": {"S": timestamp},
            "PK": {"S": photo_id}, "SK": {"S": "METADATA"}}


def cursor_for(key):
    values = [key["GSI1SK"]["S"], key["PK"]["S"]]
    return base64.urlsafe_b64encode(json.dumps(values).encode()).decode()


def photo(record):
    def public_url(field):
        path = urlparse(record[field]["S"]).path
        return os.environ["PHOTO_BUCKET_PUBLIC_READ_URL"].replace("{path}", path)

    return {
        "id": record["PK"]["S"],
        "thumbnail": public_url("thumbnail"),
        "web": public_url("web"),
        "original": public_url("original"),
        "likes": int(record.get("likes", {"N": "0"})["N"]),
        "tags": sorted(record.get("tags", {}).get("SS", [])),
    }


def lambda_handler(event, context):
    query = event.get("queryStringParameters") or {}
    catalog = query.get("view") == "tags"
    values = {":pk": {"S": "list"}}
    params = {
        "TableName": os.environ["PHOTO_TABLE_NAME"], "IndexName": "GSI1",
        "KeyConditionExpression": "GSI1PK = :pk",
        "ExpressionAttributeValues": values, "ScanIndexForward": False,
        "Limit": int(os.environ["PHOTOS_PER_BATCH"]),
    }
    try:
        tags = normalize_tags(json.loads(query.get("tags", "[]")))
        if "cursor" in query:
            params["ExclusiveStartKey"] = cursor_key(query["cursor"])
    except (ValueError, TypeError):
        return reply(400, {"error": "Invalid tags or cursor"})

    # Continue to accept timestamp links issued before full-key pagination.
    if "next" in query:
        params["KeyConditionExpression"] += " and GSI1SK < :before"
        values[":before"] = {"S": query["next"]}

    if catalog:
        params.update(ProjectionExpression="#tags", ExpressionAttributeNames={"#tags": "tags"}, Limit=500)
    elif tags:
        terms = []
        for i, tag in enumerate(tags):
            key = f":tag{i}"
            terms.append(f"contains(#tags, {key})")
            values[key] = {"S": tag}
        params.update(FilterExpression=" AND ".join(terms), ExpressionAttributeNames={"#tags": "tags"})
        # DynamoDB applies filters after evaluating the batch. Bound each read
        # and return its cursor even when this batch has zero matches.
        params["Limit"] *= 4

    page = dynamodb.query(**params)
    host = os.environ["HOST"]
    url = f"{host}api/list"
    links = {"self": {"href": url + ("?" + urlencode(query) if query else "")},
             "request": {"href": f"{host}api/request"}, "bootstrap": {"href": f"{host}api"}}
    if page.get("LastEvaluatedKey"):
        following = {**query, "cursor": cursor_for(page["LastEvaluatedKey"])}
        links["next"] = {"href": url + "?" + urlencode(following)}

    if catalog:
        counts = Counter(tag for item in page["Items"] for tag in item.get("tags", {}).get("SS", []))
        body = {"tags": counts}
    else:
        body = {"photos": [photo(item) for item in page["Items"]]}
    result = reply(200, {"_links": links, **body})
    result["headers"]["Content-Type"] = "application/hal+json"
    return result


def set_tags(event, context):
    claims = event.get("requestContext", {}).get("authorizer", {}).get("jwt", {}).get("claims", {})
    if event.get("routeKey") != "POST /api/studio/tags" or claims.get("token_use") != "access":
        return reply(403, {"error": "Staff sign-in required"})
    try:
        body = json.loads(event.get("body") or "{}")
        photo_id = body["id"]
        if not isinstance(photo_id, str) or not photo_id.startswith("image#") or len(photo_id.encode()) > 2048:
            raise ValueError()
        tags = normalize_tags(body["tags"])
        previous = normalize_tags(body["previousTags"])
    except (ValueError, TypeError, KeyError):
        return reply(400, {"error": "Invalid photo or tags"})

    values = {}
    expected = "attribute_not_exists(#tags)"
    if previous:
        expected = "#tags = :previous"
        values[":previous"] = {"SS": previous}
    update = "REMOVE #tags"
    if tags:
        update = "SET #tags = :tags"
        values[":tags"] = {"SS": tags}

    try:
        dynamodb.update_item(
            TableName=os.environ["PHOTO_TABLE_NAME"],
            Key={"PK": {"S": photo_id}, "SK": {"S": "METADATA"}},
            UpdateExpression=update, ExpressionAttributeNames={"#tags": "tags"},
            ConditionExpression=f"attribute_exists(thumbnail) AND ({expected})",
            ReturnValuesOnConditionCheckFailure="ALL_OLD",
            **({"ExpressionAttributeValues": values} if values else {}),
        )
    except ClientError as exc:
        if exc.response["Error"]["Code"] != "ConditionalCheckFailedException":
            raise
        item = exc.response.get("Item", {})
        if "thumbnail" not in item:
            return reply(404, {"error": "Photo not found"})
        current = sorted(item.get("tags", {}).get("SS", []))
        if current != tags:
            return reply(409, {"tags": current})
    return reply(200, {"tags": tags})
