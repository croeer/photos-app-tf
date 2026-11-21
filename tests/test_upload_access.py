import json
import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lambda-src"))
with patch.dict(os.environ, {
    "AWS_DEFAULT_REGION": "eu-central-1",
    "AWS_ACCESS_KEY_ID": "test",
    "AWS_SECRET_ACCESS_KEY": "test",
}):
    import request_photo_upload


class UploadEndpointTests(unittest.TestCase):
    def test_signed_form_posts_directly_to_bucket_region(self):
        form = request_photo_upload.create_presigned_post("studio-test", "bowl.jpg", 300)
        self.assertEqual(form["url"], "https://studio-test.s3.eu-central-1.amazonaws.com/")
        self.assertEqual(form["fields"]["x-amz-algorithm"], "AWS4-HMAC-SHA256")
        self.assertIn("/eu-central-1/s3/aws4_request", form["fields"]["x-amz-credential"])


class UploadAccessTests(unittest.TestCase):
    def setUp(self):
        env = patch.dict(os.environ, {
            "ENABLE_PHOTO_UPLOAD": "true",
            "STAFF_UPLOADS_ONLY": "true",
            "MAX_PHOTOS_PER_REQUEST": "5",
            "UPLOAD_BUCKET_NAME": "studio-test",
        })
        env.start()
        self.addCleanup(env.stop)
        signer = patch.object(request_photo_upload, "create_presigned_post", return_value={"fields": {}, "url": "test"})
        self.sign = signer.start()
        self.addCleanup(signer.stop)
        self.event = {
            "routeKey": "POST /api/studio/upload",
            "body": json.dumps({"photos": json.dumps(["bowl.jpg"])}),
        }

    def status(self):
        return request_photo_upload.lambda_handler(self.event, None)["statusCode"]

    def set_claims(self, token_use):
        self.event["requestContext"] = {"authorizer": {"jwt": {"claims": {"token_use": token_use}}}}

    def test_anonymous_request_cannot_sign(self):
        self.assertEqual(self.status(), 403)
        self.sign.assert_not_called()

    def test_id_token_cannot_sign(self):
        self.set_claims("id")
        self.assertEqual(self.status(), 403)
        self.sign.assert_not_called()

    def test_old_route_cannot_sign_in_staff_mode(self):
        self.event["routeKey"] = "POST /{proxy+}"
        self.set_claims("access")
        self.assertEqual(self.status(), 403)
        self.sign.assert_not_called()

    def test_authorized_studio_request_can_sign(self):
        self.set_claims("access")
        self.assertEqual(self.status(), 200)
        self.sign.assert_called_once()

    def test_event_mode_can_sign_for_guests(self):
        os.environ["STAFF_UPLOADS_ONLY"] = "false"
        self.event["routeKey"] = "POST /{proxy+}"
        self.assertEqual(self.status(), 200)
        self.sign.assert_called_once()

    def test_disabled_uploads_cannot_sign_for_staff(self):
        os.environ["ENABLE_PHOTO_UPLOAD"] = "false"
        self.set_claims("access")
        self.assertEqual(self.status(), 403)
        self.sign.assert_not_called()
