import os
import json


def lambda_handler(event, context):
    enable_photo_challenge = (
        os.getenv("ENABLE_PHOTO_CHALLENGE", "true").lower() == "true"
    )

    response_body = {
        "_links": {
            "self": {"href": f"{os.getenv('HOST')}api"},
            "list": {"href": f"{os.getenv('HOST')}api/list"},
            "likes": {"href": f"{os.getenv('HOST')}likes"},
            "request": {"href": f"{os.getenv('HOST')}api/request"},
        },
        "maxPhotosPerRequest": int(os.getenv("MAX_PHOTOS_PER_REQUEST", 0)),
        "enablePhotoChallenge": enable_photo_challenge,
        "enablePhotoUpload": os.getenv("ENABLE_PHOTO_UPLOAD", "true").lower() == "true",
        "enableLikes": os.getenv("ENABLE_LIKES", "true").lower() == "true",
        "theme": {
            "title": os.getenv("THEME_TITLE", "Photo App"),
            "favicon": os.getenv("THEME_FAVICON", f"{os.getenv('HOST')}favicon.ico"),
            "logo": os.getenv("THEME_LOGO", f"{os.getenv('HOST')}logo.svg"),
            "headerText": os.getenv("THEME_HEADER", "Welcome to the Photo App"),
            "subHeaderText": os.getenv("THEME_SUBHEADER", "Welcome to the Photo App"),
            "description": os.getenv("THEME_DESCRIPTION", ""),
        },
    }

    if os.getenv("STUDIO_CLIENT_ID"):
        response_body["_links"]["tags"] = {"href": f"{os.environ['HOST']}api/list?view=tags"}
        response_body["studio"] = {
            "clientId": os.environ["STUDIO_CLIENT_ID"],
            "issuer": os.environ["STUDIO_ISSUER"],
            "loginUrl": os.environ["STUDIO_LOGIN_URL"],
            "editTagsUrl": f"{os.environ['HOST']}api/studio/tags",
        }

        if os.getenv("STUDIO_UPLOAD_ENABLED", "true").lower() == "true":
            response_body["studio"]["uploadUrl"] = f"{os.environ['HOST']}api/studio/upload"

    if enable_photo_challenge:
        response_body["_links"]["challenge"] = {"href": f"{os.getenv('CHALLENGEURL')}"}

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/hal+json",
        },
        "body": json.dumps(response_body, indent=2),
    }
