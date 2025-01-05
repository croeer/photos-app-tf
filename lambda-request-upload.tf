module "lambda_upload" {
  source = "/Users/croeer/dev/aws-terraform/aws-lambda-tf"

  function_name = "photos-upload-lambda"
  zipfile_name  = "/Users/croeer/dev/photos-app/lambda/request_photo_upload.zip"
  handler_name  = "request_photo_upload.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ                     = "Europe/Berlin",
    MAX_PHOTOS_PER_REQUEST = "10",
    UPLOAD_BUCKET_NAME     = aws_s3_bucket.photos_upload_bucket.bucket
  }
}

resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda_s3_policy"
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
