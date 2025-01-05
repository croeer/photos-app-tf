module "lambda_list_photos" {
  source = "/Users/croeer/dev/aws-terraform/aws-lambda-tf"

  function_name = "photos-list-photos-lambda"
  zipfile_name  = "/Users/croeer/dev/photos-app/lambda/list_photos.zip"
  handler_name  = "list_photos.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ = "Europe/Berlin",
    PHOTOS_TABLE = "photos-table"
  }
}

resource "aws_iam_role_policy" "lambda_list_photos_policy" {
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
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/photos-table"
      }
    ]
  })
}
