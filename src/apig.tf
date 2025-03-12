locals {
  apig_name        = local.lambda_name
  apig_root_domain = "example.com"
  apig_subdomain   = local.env == "production" ? local.resource_name_prefix : "${local.resource_name_prefix}-${local.env}"
}

#-------------------------------------#
# Data sources

data "aws_acm_certificate" "this" {
  domain      = "*.${local.apig_root_domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "this" {
  name = "${local.apig_root_domain}."
}

#-------------------------------------#
# API Gateway

# tflint-ignore: terraform_module_version
module "apig" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = local.apig_name
  protocol_type = "HTTP"

  # Custom domain
  domain_name                 = "${local.apig_subdomain}.${local.apig_root_domain}"
  domain_name_certificate_arn = data.aws_acm_certificate.this.arn

  # Access logs
  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = var.cw_logs_retention
    format = jsonencode({
      context = {
        domainName              = "$context.domainName"
        integrationErrorMessage = "$context.integrationErrorMessage"
        protocol                = "$context.protocol"
        requestId               = "$context.requestId"
        requestTime             = "$context.requestTime"
        responseLength          = "$context.responseLength"
        routeKey                = "$context.routeKey"
        stage                   = "$context.stage"
        status                  = "$context.status"
        error = {
          message      = "$context.error.message"
          responseType = "$context.error.responseType"
        }
        identity = {
          sourceIP = "$context.identity.sourceIp"
        }
        integration = {
          error             = "$context.integration.error"
          integrationStatus = "$context.integration.integrationStatus"
        }
      }
    })
  }

  # Routes and integrations
  # integrations = {
  #   "GET /search/{key}" = {
  #     lambda_arn             = module.lambda.lambda_invoke_arn
  #     payload_format_version = "2.0"
  #     timeout_milliseconds   = 12000
  #   }
  # }

  routes = {
    "GET /search/{key}" = {
      integration = {
        uri                    = module.lambda.lambda_invoke_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 12000
      }
    }
  }
}

#-------------------------------------#
# IAM Role

resource "aws_lambda_permission" "apig_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${module.apig.api_execution_arn}/${local.env}/*"
}

#-------------------------------------#
# Domain

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = module.apig.stage_domain_name
  type    = "A"
  alias {
    name                   = module.apig.domain_name_arn
    zone_id                = module.apig.domain_name_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  domain_name = module.apig.domain_name_id
  api_id      = module.apig.api_id
  stage_name  = local.env
}
