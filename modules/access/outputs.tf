output "team_domain" {
  description = "Team domain de Zero Trust (para validar JWT: https://<team_domain>/cdn-cgi/access/certs)."
  value       = "${var.team_name}.cloudflareaccess.com"
}

output "onetimepin_idp_id" {
  description = "ID del proveedor One-time PIN usado por las aplicaciones."
  value       = local.otp_idp_id
}

output "web_aud" {
  description = "AUD (Application Audience tag) de la app del dashboard."
  value       = cloudflare_zero_trust_access_application.web.aud
}

output "api_aud" {
  description = "AUD de la app de la API en workers.dev (null si no se creó)."
  value       = local.create_api_app ? cloudflare_zero_trust_access_application.api[0].aud : null
}

output "service_token_client_id" {
  description = "Client ID del token de servicio del motor (header CF-Access-Client-Id)."
  value       = cloudflare_zero_trust_access_service_token.motor.client_id
  sensitive   = true
}

output "service_token_client_secret" {
  description = "Client Secret del token de servicio del motor (header CF-Access-Client-Secret). Solo se ve al crearlo."
  value       = cloudflare_zero_trust_access_service_token.motor.client_secret
  sensitive   = true
}
