locals {
  studio_issuer    = var.staff_uploads_only ? "https://${aws_cognito_user_pool.studio[0].endpoint}" : ""
  studio_login_url = var.staff_uploads_only ? "https://${aws_cognito_user_pool_domain.studio[0].domain}.auth.${data.aws_region.current.region}.amazoncognito.com" : ""
  studio_origins   = [for domain in concat([module.client_homepage_spa.cloudfront_distribution.domain_name], var.custom_domain_names) : "https://${domain}/"]
}

resource "aws_cognito_user_pool" "studio" {
  count                    = var.staff_uploads_only ? 1 : 0
  name                     = "${module.api_gw_label.id}-studio"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}

resource "aws_cognito_user_pool_domain" "studio" {
  count        = var.staff_uploads_only ? 1 : 0
  domain       = "studio-${lower(replace(aws_cognito_user_pool.studio[0].id, "_", "-"))}"
  user_pool_id = aws_cognito_user_pool.studio[0].id
}

resource "aws_cognito_user_pool_client" "studio" {
  count                                = var.staff_uploads_only ? 1 : 0
  name                                 = "studio-upload"
  user_pool_id                         = aws_cognito_user_pool.studio[0].id
  generate_secret                      = false
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
  callback_urls                        = local.studio_origins
  logout_urls                          = local.studio_origins
}

resource "aws_apigatewayv2_authorizer" "studio" {
  count            = var.staff_uploads_only ? 1 : 0
  api_id           = aws_apigatewayv2_api.http_api.id
  name             = "studio-staff"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    issuer   = local.studio_issuer
    audience = [aws_cognito_user_pool_client.studio[0].id]
  }
}

resource "aws_apigatewayv2_route" "studio_upload" {
  count                = var.staff_uploads_only && var.enable_photoupload ? 1 : 0
  api_id               = aws_apigatewayv2_api.http_api.id
  route_key            = "POST /api/studio/upload"
  target               = "integrations/${aws_apigatewayv2_integration.post_lambda_integration.id}"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.studio[0].id
  authorization_scopes = ["openid"]
}

output "studio_user_pool_id" {
  description = "User pool where the administrator invites studio staff."
  value       = var.staff_uploads_only ? aws_cognito_user_pool.studio[0].id : null
}
