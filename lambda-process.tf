locals {
  photos_table_name = aws_dynamodb_table.photo_table.name
  sqs_queue_url     = aws_sqs_queue.queue.id
}

data "archive_file" "lambda_process_photos_zip" {
  type        = "zip"
  output_path = "lambda-src/process_photos.zip"
  source_file = "lambda-src/process_photos.py"
}

module "lambda_process_label" {
  source     = "cloudposse/label/null"
  version    = "0.25"
  context    = module.this.context
  name       = "${var.app_name}-process"
  attributes = ["lambda"]
}

module "lambda_process" {
  source = "git::https://github.com/croeer/aws-lambda-tf.git?ref=v1.1.0"

  function_name = module.lambda_process_label.id
  tags          = module.lambda_process_label.tags
  zipfile_name  = data.archive_file.lambda_process_photos_zip.output_path
  handler_name  = "process_photos.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 1024
  timeout       = 10
  layers        = ["arn:aws:lambda:eu-central-1:770693421928:layer:Klayers-p312-Pillow:4"]
  environment_variables = {
    TZ                = "Europe/Berlin",
    PHOTO_BUCKET_NAME = aws_s3_bucket.photos_store_bucket.bucket,
    PHOTO_TABLE_NAME  = local.photos_table_name
    SQS_QUEUE_URL     = local.sqs_queue_url
  }
}

module "lambda_sqspolicy_label" {
  source  = "cloudposse/label/null"
  version = "0.25"
  context = module.this.context
  name    = "${var.app_name}-sqs-policy"
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name = module.lambda_sqspolicy_label.id

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
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.photos_upload_bucket.arn}",
          "${aws_s3_bucket.photos_upload_bucket.arn}/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.photos_store_bucket.arn}",
          "${aws_s3_bucket.photos_store_bucket.arn}/*"
        ]
      },
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
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${module.dynamodb_photos_label.id}"
      }
    ]
  })
}
