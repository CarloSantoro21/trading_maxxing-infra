# Valores que el pipeline del monorepo copia a wrangler.toml / secrets de GitHub.

output "d1_database_id" {
  description = "database_id para [[d1_databases]] en wrangler.toml."
  value       = module.d1.database_id
}

output "d1_database_name" {
  description = "database_name para [[d1_databases]] en wrangler.toml."
  value       = module.d1.database_name
}

output "worker_name" {
  description = "Nombre del Worker (name en wrangler.toml / --env)."
  value       = module.worker.name
}

output "pages_project_name" {
  description = "Proyecto de Pages para `wrangler pages deploy --project-name`."
  value       = module.pages.project_name
}

output "pages_url" {
  description = "URL pública (detrás de Access) del dashboard."
  value       = "https://${module.pages.hostname}"
}

output "access_team_domain" {
  description = "Team domain de Zero Trust (ACCESS_TEAM_DOMAIN del Worker)."
  value       = module.access.team_domain
}

output "access_web_aud" {
  description = "AUD de la app de Access del dashboard (ACCESS_AUD del Worker / middleware)."
  value       = module.access.web_aud
}

output "access_api_aud" {
  description = "AUD de la app de Access de la API en workers.dev (null si no se configuró workers_dev_subdomain)."
  value       = module.access.api_aud
}

output "motor_service_token_client_id" {
  description = "CF-Access-Client-Id que usa el motor de la Mac."
  value       = module.access.service_token_client_id
  sensitive   = true
}

output "motor_service_token_client_secret" {
  description = "CF-Access-Client-Secret que usa el motor de la Mac."
  value       = module.access.service_token_client_secret
  sensitive   = true
}
