output "database_id" {
  description = "UUID de la base; va en `database_id` del bloque [[d1_databases]] de wrangler.toml."
  value       = cloudflare_d1_database.this.uuid
}

output "database_name" {
  description = "Nombre de la base; va en `database_name` de wrangler.toml."
  value       = cloudflare_d1_database.this.name
}
