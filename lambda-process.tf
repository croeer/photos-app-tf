module "lambda_process" {
  source = "/Users/croeer/dev/aws-terraform/aws-lambda-tf"

  function_name = "photos-process-lambda"
  zipfile_name  = "/Users/croeer/dev/photos-app/lambda/process_photos.zip"
  handler_name  = "process_photos.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ                = "Europe/Berlin",
    PHOTO_BUCKET_NAME = aws_s3_bucket.photos_store_bucket.bucket
  }
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name = "lambda_sqs_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attach" {
  role       = module.lambda_process.iam_role_name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

resource "aws_lambda_event_source_mapping" "sqs_event" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = module.lambda_process.lambda_function_name
  batch_size       = 10
  enabled          = true
}

resource "aws_iam_role_policy" "lambda_process_s3_policy" {
  name = "lambda_process_s3_policy"
  role = module.lambda_process.iam_role_name
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
          "${aws_s3_bucket.photos_upload_bucket.arn}/*",
          "${aws_s3_bucket.photos_store_bucket.arn}",
          "${aws_s3_bucket.photos_store_bucket.arn}/*"
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy" "lambda_process_photos_dynamodb_policy" {
  name = "lambda_list_photos_dynamodb_policy"
  role = module.lambda_process.iam_role_name
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
