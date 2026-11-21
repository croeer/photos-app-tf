data "archive_file" "lambda_bootstrap_zip" {
  type        = "zip"
  output_path = "lambda-src/bootstrap.zip"
  source_file = "lambda-src/bootstrap.py"
}

module "lambda_bootstrap_label" {
  source     = "cloudposse/label/null"
  version    = "0.25"
  context    = module.this.context
  name       = "${var.app_name}-bootstrap"
  attributes = ["lambda"]
}

module "lambda_bootstrap" {
  source = "git::https://github.com/croeer/aws-lambda-tf.git?ref=v1.1.0"

  function_name = module.lambda_bootstrap_label.id
  tags          = module.lambda_bootstrap_label.tags
  zipfile_name  = data.archive_file.lambda_bootstrap_zip.output_path
  handler_name  = "bootstrap.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ                     = "Europe/Berlin",
    MAX_PHOTOS_PER_REQUEST = var.max_photos_per_request,
    HOST                   = aws_apigatewayv2_stage.default_stage.invoke_url,
    CHALLENGEURL           = module.lambda_random_challenge.function_url,
    ENABLE_PHOTO_CHALLENGE = var.enable_photochallenge,
    ENABLE_PHOTO_UPLOAD    = var.enable_photoupload && !var.staff_uploads_only
    STUDIO_CLIENT_ID       = var.staff_uploads_only ? aws_cognito_user_pool_client.studio[0].id : ""
    STUDIO_UPLOAD_ENABLED  = var.enable_photoupload
    STUDIO_ISSUER          = var.staff_uploads_only ? local.studio_issuer : ""
    STUDIO_LOGIN_URL       = var.staff_uploads_only ? local.studio_login_url : ""
    ENABLE_LIKES           = var.enable_likes
    THEME_TITLE            = var.theme_config.title
    THEME_HEADER           = var.theme_config.header
    THEME_SUBHEADER        = var.theme_config.subHeader
    THEME_DESCRIPTION      = var.theme_config.description
  }

  create_function_url = true

}
