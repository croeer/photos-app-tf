module "request-api" {
  source = "/Users/croeer/dev/aws-terraform/aws-apigw-tf"

  api_name                    = "photos-api"
  get_integration_lambda_name = module.lambda_list_photos.lambda_function_name
  get_integration_lambda_arn  = module.lambda_list_photos.lambda_function_arn

  post_integration_lambda_name = module.lambda_upload.lambda_function_name
  post_integration_lambda_arn  = module.lambda_upload.lambda_function_arn

}
