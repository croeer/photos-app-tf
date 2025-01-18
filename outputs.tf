output "bootstrap_lambda_function_url" {
  description = "The URL of the bootstrap Lambda function"
  value       = module.lambda_bootstrap.function_url
}
