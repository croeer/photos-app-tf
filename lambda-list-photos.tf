module "lambda_list_photos" {
  source = "/Users/croeer/dev/aws-terraform/aws-lambda-tf"

  function_name = "photos-list-photos-lambda"
  zipfile_name  = "/Users/croeer/dev/photos-app/lambda/list_photos.zip"
  handler_name  = "list_photos.lambda_handler"
  runtime       = "python3.12"
  environment_variables = {
    TZ = "Europe/Berlin"
  }
}
