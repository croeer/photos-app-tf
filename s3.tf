module "photos_upload_bucketlabel" {
  source     = "cloudposse/label/null"
  version    = "0.25"
  context    = module.this.context
  name       = "${var.app_name}-upload"
  attributes = ["s3", var.aws_account_id]
}

resource "aws_s3_bucket" "photos_upload_bucket" {
  bucket        = module.photos_upload_bucketlabel.id
  force_destroy = true
}

module "photos_store_bucketlabel" {
  source     = "cloudposse/label/null"
  version    = "0.25"
  context    = module.this.context
  name       = "${var.app_name}-store"
  attributes = ["s3", var.aws_account_id]
}

resource "aws_s3_bucket" "photos_store_bucket" {
  bucket        = module.photos_store_bucketlabel.id
  force_destroy = true
}

data "aws_iam_policy_document" "queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.photos_upload_bucket.arn]
    }
  }
}

module "photos_sqs_label" {
  source     = "cloudposse/label/null"
  version    = "0.25"
  context    = module.this.context
  name       = var.app_name
  attributes = ["sqs"]
}


resource "aws_sqs_queue" "queue" {
  name = module.photos_sqs_label.id
}

# Attach the policy to the SQS queue
resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = data.aws_iam_policy_document.queue.json
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.photos_upload_bucket.id

  depends_on = [aws_sqs_queue.queue, aws_sqs_queue_policy.queue_policy, aws_s3_bucket.photos_upload_bucket] // Add this line

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


resource "aws_s3_bucket_policy" "photos_store_bucket_cf_policy" {
  bucket = aws_s3_bucket.photos_store_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "PolicyForCloudFrontPrivateContent-${aws_s3_bucket.photos_store_bucket.bucket}"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal-${aws_s3_bucket.photos_store_bucket.bucket}"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.photos_store_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cf_photos_store.arn
          }
        }
      }
    ]
  })
}
