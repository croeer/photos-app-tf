module "studio_tags_label" {
  source     = "cloudposse/label/null"
  version    = "0.25"
  context    = module.this.context
  name       = "${var.app_name}-studio-tags"
  attributes = ["lambda"]
}

module "studio_tags" {
  count         = var.staff_uploads_only ? 1 : 0
  source        = "git::https://github.com/croeer/aws-lambda-tf.git?ref=v1.1.0"
  function_name = module.studio_tags_label.id
  tags          = module.studio_tags_label.tags
  zipfile_name  = data.archive_file.lambda_list_photos_zip.output_path
  handler_name  = "list_photos.set_tags"
  runtime       = "python3.12"
  environment_variables = {
    PHOTO_TABLE_NAME = aws_dynamodb_table.photo_table.name
  }
}

resource "aws_iam_role_policy" "studio_tags" {
  count = var.staff_uploads_only ? 1 : 0
  name  = "edit-photo-tags"
  role  = module.studio_tags[0].iam_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "dynamodb:UpdateItem"
      Resource = aws_dynamodb_table.photo_table.arn
    }]
  })
}

resource "aws_apigatewayv2_integration" "studio_tags" {
  count                  = var.staff_uploads_only ? 1 : 0
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.studio_tags[0].lambda_function_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "studio_tags" {
  count                = var.staff_uploads_only ? 1 : 0
  api_id               = aws_apigatewayv2_api.http_api.id
  route_key            = "POST /api/studio/tags"
  target               = "integrations/${aws_apigatewayv2_integration.studio_tags[0].id}"
  authorization_type   = "JWT"
  authorization_scopes = ["openid"]
  authorizer_id        = aws_apigatewayv2_authorizer.studio[0].id
}

resource "aws_lambda_permission" "studio_tags" {
  count         = var.staff_uploads_only ? 1 : 0
  statement_id  = "ApiGatewayEditPhotoTags"
  action        = "lambda:InvokeFunction"
  function_name = module.studio_tags[0].lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/POST/api/studio/tags"
}
