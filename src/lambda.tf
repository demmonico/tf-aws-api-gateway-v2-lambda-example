locals {
  lambda_name = "${local.resource_name_prefix}-${local.env}"
}

#-------------------------------------#

module "lambda" {
  source = "git::https://github.com/demmonico/tf-modules-aws-lambda.git?ref=1.0.1"

  lambda_name = local.lambda_name
  dlq_enabled = false
}
