module "lambda_list_photos" {
  source = "/Users/croeer/dev/aws-terraform/aws-lambda-tf"

  function_name = "photos-list-photos-lambda"
  zipfile_name  = "/Users/croeer/dev/photos-app/lambda/list_photos.zip"
  handler_name  = "list_photos.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ                           = "Europe/Berlin",
    PHOTO_TABLE_NAME             = local.photos_table_name,
    PHOTO_BUCKET_PUBLIC_READ_URL = "https://${aws_cloudfront_distribution.cf_photos_store.domain_name}{path}",
    PHOTOS_PER_BATCH             = 6
    HOST                         = "${module.request-api.api_gw_invoke_url}"
  }
}


resource "aws_iam_role_policy" "lambda_list_photos_s3_policy" {
  name = "lambda_list_photos_s3_policy"
  role = module.lambda_list_photos.iam_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.photos_store_bucket.arn}",
          "${aws_s3_bucket.photos_store_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_list_photos_dynamodb_policy" {
  name = "lambda_list_photos_policy"
  role = module.lambda_list_photos.iam_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/photos-table/*"
      }
    ]
  })
}
