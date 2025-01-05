module "request-api" {
  source = "/Users/croeer/dev/aws-terraform/aws-apigw-tf"

  api_name                = "photos-api"
  integration_lambda_name = module.lambda_upload.lambda_function_name
  integration_lambda_arn  = module.lambda_upload.lambda_function_arn

}
