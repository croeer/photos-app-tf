module "api_gw_label" {
  source     = "cloudposse/label/null"
  version    = "0.25"
  context    = module.this.context
  name       = var.api_name
  attributes = ["api"]
}


resource "aws_apigatewayv2_api" "http_api" {
  name          = module.api_gw_label.id
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
  }
}

resource "aws_apigatewayv2_integration" "get_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda_list_photos.lambda_function_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "post_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda_upload.lambda_function_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "like_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda_like_photos.lambda_function_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_get_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.get_lambda_integration.id}"
  # authorization_type = "JWT"
  # authorizer_id = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

resource "aws_apigatewayv2_route" "like_get_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /likes/{userId}"
  target    = "integrations/${aws_apigatewayv2_integration.like_integration.id}"
  # authorization_type = "JWT" 
  # authorizer_id = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

resource "aws_apigatewayv2_route" "like_post_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /likes/{userId}/{imageId}"
  target    = "integrations/${aws_apigatewayv2_integration.like_integration.id}"
  # authorization_type = "JWT"
  # authorizer_id = aws_apigatewayv2_authorizer.jwt_authorizer.id
}


resource "aws_apigatewayv2_route" "default_post_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.post_lambda_integration.id}"
  # authorization_type = "JWT"
  # authorizer_id = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

output "api_url" {
  value = aws_apigatewayv2_stage.default_stage.invoke_url
}

resource "aws_lambda_permission" "get_lambda_permission" {
  statement_id  = "Allow${var.api_name}ApiGateway-${module.lambda_list_photos.lambda_function_name}"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_list_photos.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*/{proxy+}"
}

resource "aws_lambda_permission" "post_lambda_permission" {
  statement_id  = "Allow${var.api_name}ApiGateway-${module.lambda_upload.lambda_function_name}"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_upload.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*/{proxy+}"
}

resource "aws_lambda_permission" "like_lambda_permission" {
  statement_id  = "Allow${var.api_name}ApiGateway-${module.lambda_like_photos.lambda_function_name}"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_like_photos.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*/likes/*"
}
