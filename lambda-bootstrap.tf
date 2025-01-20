data "archive_file" "lambda_bootstrap_zip" {
  type        = "zip"
  output_path = "lambda-src/bootstrap.zip"
  source_file = "lambda-src/bootstrap.py"
}

module "lambda_bootstrap" {
  source = "git::https://github.com/croeer/aws-lambda-tf.git"

  function_name = "bootstrap-lambda"
  zipfile_name  = data.archive_file.lambda_bootstrap_zip.output_path
  handler_name  = "bootstrap.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ                     = "Europe/Berlin",
    MAX_PHOTOS_PER_REQUEST = var.max_photos_per_request,
    HOST                   = "${module.request-api.api_gw_invoke_url}",
    CHALLENGEURL           = module.lambda_random_challenge.function_url
  }

  create_function_url = true

}
