locals {
  photos_likes_table_name = aws_dynamodb_table.photo_likes_table.name
}

data "archive_file" "lambda_like_photos_zip" {
  type        = "zip"
  output_path = "lambda-src/like_photos.zip"
  source_file = "lambda-src/like_photos.py"
}

module "lambda_like_label" {
  source     = "cloudposse/label/null"
  version    = "0.25"
  context    = module.this.context
  name       = "like"
  attributes = ["lambda"]
}

module "lambda_like_photos" {
  source = "git::https://github.com/croeer/aws-lambda-tf.git?ref=v1.1.0"

  function_name = module.lambda_like_label.id
  tags          = module.lambda_like_label.tags
  zipfile_name  = data.archive_file.lambda_like_photos_zip.output_path
  handler_name  = "like_photos.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ                     = "Europe/Berlin",
    PHOTO_LIKES_TABLE_NAME = module.dynamodb_likes_label.id,
    PHOTO_TABLE_NAME       = module.dynamodb_photos_label.id,
  }
}


resource "aws_iam_role_policy" "lambda_like_photos_dynamodb_policy" {
  name = "lambda_like_photos_policy"
  role = module.lambda_like_photos.iam_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${module.dynamodb_photos_label.id}",
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${module.dynamodb_likes_label.id}"
        ]
      }
    ]
  })
}
