locals {
  photos_likes_table_name = aws_dynamodb_table.photo_likes_table.name
}

data "archive_file" "lambda_like_photos_zip" {
  type        = "zip"
  output_path = "lambda-src/like_photos.zip"
  source_file = "lambda-src/like_photos.py"
}

module "lambda_like_photos" {
  source = "git::https://github.com/croeer/aws-lambda-tf.git?ref=v1.0.0"

  function_name = "photos-like-photos-lambda"
  zipfile_name  = data.archive_file.lambda_like_photos_zip.output_path
  handler_name  = "like_photos.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ                     = "Europe/Berlin",
    PHOTO_LIKES_TABLE_NAME = local.photos_likes_table_name,
    PHOTO_TABLE_NAME       = local.photos_table_name,
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
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.photos_table_name}",
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.photo_likes_table_name}"
        ]
      }
    ]
  })
}
