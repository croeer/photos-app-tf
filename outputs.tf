output "bootstrap_lambda_function_url" {
  description = "The URL of the bootstrap Lambda function"
  value       = module.lambda_bootstrap.function_url
}

output "random_challenge_lambda_function_url" {
  description = "The URL of the random challenge Lambda function"
  value       = module.lambda_random_challenge.function_url
}
output "api_gw_invoke_url" {
  description = "The invoke URL of the API Gateway"
  value       = aws_apigatewayv2_stage.default_stage.invoke_url
}

output "s3_bucket_name" {
  description = "The name of the client S3 bucket"
  value       = module.client_bucketlabel.id
}
