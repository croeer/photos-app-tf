data "archive_file" "lambda_random_challenge_zip" {
  type        = "zip"
  output_path = "lambda-src/random_challenge.zip"
  source_file = "lambda-src/random_challenge.py"
}

module "lambda_randomchallenge_label" {
  source     = "cloudposse/label/null"
  version    = "0.25"
  context    = module.this.context
  name       = "randomchallenge"
  attributes = ["lambda"]
}

module "lambda_random_challenge" {
  source = "git::https://github.com/croeer/aws-lambda-tf.git?ref=v1.1.0"

  function_name = module.lambda_randomchallenge_label.id
  tags          = module.lambda_randomchallenge_label.tags
  zipfile_name  = data.archive_file.lambda_random_challenge_zip.output_path
  handler_name  = "random_challenge.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ = "Europe/Berlin",
  }
  create_function_url = true

}


# resource "aws_iam_role_policy" "lambda_random_challenge_s3_policy" {
#   name = "lambda_random_challenge_s3_policy"
#   role = module.lambda_random_challenge.iam_role_name
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:GetObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           "${aws_s3_bucket.photos_store_bucket.arn}",
#           "${aws_s3_bucket.photos_store_bucket.arn}/*"
#         ]
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "lambda_random_challenge_dynamodb_policy" {
#   name = "lambda_list_photos_policy"
#   role = module.lambda_list_photos.iam_role_name
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "dynamodb:Scan",
#           "dynamodb:Query",
#           "dynamodb:GetItem"
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/photos-table/*"
#       }
#     ]
#   })
# }
