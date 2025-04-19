import os
import json


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/hal+json",
        },
        "body": json.dumps(
            {
                "_links": {
                    "self": {"href": f"{os.getenv('HOST')}api"},
                    "list": {"href": f"{os.getenv('HOST')}api/list"},
                    "likes": {"href": f"{os.getenv('HOST')}likes"},
                    "request": {"href": f"{os.getenv('HOST')}api/request"},
                    "challenge": {"href": f"{os.getenv('CHALLENGEURL')}"},
                },
                "maxPhotosPerRequest": int(os.getenv("MAX_PHOTOS_PER_REQUEST", 0)),
                "enablePhotoChallenge": os.getenv(
                    "ENABLE_PHOTO_CHALLENGE", "true"
                ).lower()
                == "true",
                "enablePhotoUpload": os.getenv("ENABLE_PHOTO_UPLOAD", "true").lower()
                == "true",
                "enableLikes": os.getenv("ENABLE_LIKES", "true").lower() == "true",
            },
            indent=2,
        ),
    }
