module "lambda_resize" {
  source = "/Users/croeer/dev/aws-terraform/aws-lambda-tf"

  function_name = "photos-resize-lambda"
  zipfile_name  = "/Users/croeer/dev/photos-app/lambda/list_photos.zip"
  handler_name  = "list_photos.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ = "Europe/Berlin"
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
  role       = module.lambda_resize.iam_role_name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

resource "aws_lambda_event_source_mapping" "sqs_event" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = module.lambda_resize.lambda_function_name
  batch_size       = 10
  enabled          = true
}
