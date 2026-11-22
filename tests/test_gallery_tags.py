import json
import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.parse import parse_qsl, urlsplit

import boto3
from moto import mock_aws

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lambda-src"))
with patch.dict(os.environ, {"AWS_DEFAULT_REGION": "eu-central-1", "AWS_EC2_METADATA_DISABLED": "true"}):
    import list_photos


@mock_aws
class GalleryTagTests(unittest.TestCase):
    def setUp(self):
        env = patch.dict(os.environ, {"PHOTO_TABLE_NAME": "photos", "PHOTOS_PER_BATCH": "1",
                                      "HOST": "https://gallery/", "PHOTO_BUCKET_PUBLIC_READ_URL": "https://media{path}"})
        env.start()
        self.addCleanup(env.stop)
        self.db = boto3.client("dynamodb", region_name="eu-central-1")
        client = patch.object(list_photos, "dynamodb", self.db)
        client.start()
        self.addCleanup(client.stop)
        self.db.create_table(
            TableName="photos", BillingMode="PAY_PER_REQUEST",
            AttributeDefinitions=[{"AttributeName": name, "AttributeType": "S"} for name in ("PK", "SK", "GSI1PK", "GSI1SK")],
            KeySchema=[{"AttributeName": "PK", "KeyType": "HASH"}, {"AttributeName": "SK", "KeyType": "RANGE"}],
            GlobalSecondaryIndexes=[{"IndexName": "GSI1", "Projection": {"ProjectionType": "ALL"}, "KeySchema": [
                {"AttributeName": "GSI1PK", "KeyType": "HASH"}, {"AttributeName": "GSI1SK", "KeyType": "RANGE"}]}],
        )

    def insert(self, name, time, tags=()):
        item = {"PK": {"S": "image#" + name}, "SK": {"S": "METADATA"},
                "GSI1PK": {"S": "list"}, "GSI1SK": {"S": time}}
        for key in ("thumbnail", "web", "original"):
            item[key] = {"S": "s3://media/" + name}
        if tags:
            item["tags"] = {"SS": list(tags)}
        self.db.put_item(TableName="photos", Item=item)

    def edit(self, tags, previous, staff=True):
        event = {"routeKey": "POST /api/studio/tags", "body": json.dumps({
            "id": "image#cup", "previousTags": previous, "tags": tags})}
        if staff:
            event["requestContext"] = {"authorizer": {"jwt": {"claims": {"token_use": "access"}}}}
        return list_photos.set_tags(event, None)

    def pages(self, **query):
        for _ in range(20):
            response = list_photos.lambda_handler({"queryStringParameters": query}, None)
            self.assertEqual(response["statusCode"], 200)
            page = json.loads(response["body"])
            yield page
            if "next" not in page["_links"]:
                return
            query = dict(parse_qsl(urlsplit(page["_links"]["next"]["href"]).query))
        self.fail("Pagination did not terminate")

    def test_sparse_intersection_continues_past_empty_pages_and_tied_timestamps(self):
        for i in range(5):
            self.insert(str(i), "100", ["blau", "schale"])
        for i in range(4):
            self.insert("other" + str(i), "200", ["blau"])
        pages = list(self.pages(tags=json.dumps([" Blau ", "schale"])))
        self.assertEqual(pages[0]["photos"], [])
        ids = [p["id"] for page in pages for p in page["photos"]]
        self.assertCountEqual(ids, ["image#" + str(i) for i in range(5)])

    def test_staff_edits_catalog_search_and_legacy_photos(self):
        self.insert("cup", "100")
        self.assertEqual(next(self.pages())["photos"][0]["tags"], [])
        self.assertEqual(self.edit([" Blau ", "blau", "Türkis"], [], staff=False)["statusCode"], 403)
        self.assertEqual(self.edit([" Blau ", "blau", "Türkis"], [])["statusCode"], 200)
        self.assertEqual(next(self.pages(view="tags"))["tags"], {"blau": 1, "türkis": 1})
        self.assertEqual(next(self.pages(tags='["türkis"]'))["photos"][0]["tags"], ["blau", "türkis"])
        self.assertEqual(self.edit(["rot"], [])["statusCode"], 409)
        self.assertEqual(self.edit([], ["blau", "türkis"])["statusCode"], 200)
        self.assertEqual(next(self.pages(view="tags"))["tags"], {})
        self.assertEqual(next(self.pages(tags='["blau"]'))["photos"], [])

    def test_reprocessing_preserves_staff_tags_and_gallery_order(self):
        from process_photos import save_metadata_to_dynamodb

        keys = {"thumbnail_key": "thumb", "web_key": "web", "original_key": "original"}
        with patch.dict(os.environ, {"PHOTO_BUCKET_NAME": "media", "AWS_DEFAULT_REGION": "eu-central-1"}):
            save_metadata_to_dynamodb("cup", keys)
            time = self.db.get_item(TableName="photos", Key={"PK": {"S": "image#cup"}, "SK": {"S": "METADATA"}})["Item"]["GSI1SK"]
            self.assertEqual(self.edit(["blau"], [])["statusCode"], 200)
            save_metadata_to_dynamodb("cup", keys)
        item = self.db.get_item(TableName="photos", Key={"PK": {"S": "image#cup"}, "SK": {"S": "METADATA"}})["Item"]
        self.assertEqual(item["tags"], {"SS": ["blau"]})
        self.assertEqual(item["GSI1SK"], time)

    def test_missing_image_is_not_created_and_bad_query_is_rejected(self):
        self.assertEqual(self.edit(["rot"], [])["statusCode"], 404)
        for query in [{"tags": '"x"'}, {"cursor": "no-cursor"}]:
            self.assertEqual(list_photos.lambda_handler({"queryStringParameters": query}, None)["statusCode"], 400)
