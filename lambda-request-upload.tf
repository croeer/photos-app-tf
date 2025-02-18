data "archive_file" "lambda_request_photo_upload_zip" {
  type        = "zip"
  output_path = "lambda-src/request_photo_upload.zip"
  source_file = "lambda-src/request_photo_upload.py"
}

module "lambda_upload_label" {
  source     = "cloudposse/label/null"
  version    = "0.25"
  context    = module.this.context
  name       = "upload"
  attributes = ["lambda"]
}

module "lambda_upload" {
  source = "git::https://github.com/croeer/aws-lambda-tf.git?ref=v1.1.0"

  function_name = module.lambda_upload_label.id
  tags          = module.lambda_upload_label.tags
  zipfile_name  = data.archive_file.lambda_request_photo_upload_zip.output_path
  handler_name  = "request_photo_upload.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ                     = "Europe/Berlin",
    MAX_PHOTOS_PER_REQUEST = var.max_photos_per_request,
    UPLOAD_BUCKET_NAME     = aws_s3_bucket.photos_upload_bucket.bucket
  }
}

resource "aws_iam_role_policy" "lambda_request_s3_policy" {
  name = "lambda_request_s3_policy"
  role = module.lambda_upload.iam_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.photos_upload_bucket.arn}",
          "${aws_s3_bucket.photos_upload_bucket.arn}/*"
        ]
      }
    ]
  })
}
