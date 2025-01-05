resource "aws_s3_bucket" "photos_upload_bucket" {
  bucket = var.photos_upload_bucket_name
}

resource "aws_s3_bucket" "photos_store_bucket" {
  bucket = var.photos_store_bucket_name
}

data "aws_iam_policy_document" "queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:*:*:photos-app-s3-sqs"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.photos_upload_bucket.arn]
    }
  }
}

resource "aws_sqs_queue" "queue" {
  name   = "photos-app-s3-sqs"
  policy = data.aws_iam_policy_document.queue.json
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.photos_upload_bucket.id

  queue {
    queue_arn = aws_sqs_queue.queue.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_cors_configuration" "photos_upload_bucket_cors" {
  bucket = aws_s3_bucket.photos_upload_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
