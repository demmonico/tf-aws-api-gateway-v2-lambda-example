# Lambda Outputs

output "module_lambda_name" {
  value = module.lambda.lambda_name
}

output "module_lambda_arn" {
  value = module.lambda.lambda_arn
}

output "module_lambda_invoke_arn" {
  value = module.lambda.lambda_invoke_arn
}
