import json
import boto3
import os
from botocore.exceptions import ClientError
from decimal import Decimal

dynamodb = boto3.resource("dynamodb")
likes_table = dynamodb.Table(os.getenv("PHOTO_LIKES_TABLE_NAME"))
photos_table = dynamodb.Table(os.getenv("PHOTO_TABLE_NAME"))


def handle_get(event):
    user_id = event["pathParameters"]["userId"]

    try:
        # Query the likes table for all photos liked by this user
        response = likes_table.query(
            KeyConditionExpression="UserId = :user_id",
            ExpressionAttributeValues={":user_id": user_id},
        )

        # Extract just the photo IDs into a list
        liked_photos = [item["ImageId"] for item in response.get("Items", [])]

        return {"statusCode": 200, "body": json.dumps({"photos": liked_photos})}

    except ClientError as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}


def handle_post(event):
    print("event", event)
    user_id = event["pathParameters"]["userId"]
    image_id = event["pathParameters"]["imageId"]
    has_liked = event["queryStringParameters"]["hasLiked"].lower() == "true"

    update_likes_count = True
    try:
        # Use conditional update to prevent race conditions
        # First check if user already liked the image
        print("trying to get item for user", user_id, "and image", image_id)
        response = likes_table.get_item(Key={"UserId": user_id, "ImageId": image_id})

        if "Item" in response:
            print("item found")
            if has_liked:
                print("has liked")
                update_likes_count = False
            else:
                # Remove the like record
                print("removing like")
                likes_table.delete_item(Key={"UserId": user_id, "ImageId": image_id})
        else:
            if has_liked:
                # Add the like record
                print("adding like")
                likes_table.put_item(Item={"UserId": user_id, "ImageId": image_id})
            else:
                update_likes_count = False

        # Update likes count in photos table
        if update_likes_count:
            print("updating likes count")
            photos_table.update_item(
                Key={"PK": "image#" + image_id, "SK": "METADATA"},
                UpdateExpression="ADD likes :inc",
                ExpressionAttributeValues={":inc": -1 if not has_liked else 1},
                ReturnValues="UPDATED_NEW",
            )

        return {
            "statusCode": 200,
            "body": "ok",
        }

    except ClientError as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}


def lambda_handler(event, context):
    http_method = event["requestContext"]["http"]["method"]

    if http_method == "GET":
        return handle_get(event)
    elif http_method == "POST":
        return handle_post(event)
    else:
        return {"statusCode": 405, "body": json.dumps({"error": "Method not allowed"})}
