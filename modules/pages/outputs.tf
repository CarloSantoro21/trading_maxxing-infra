output "project_name" {
  description = "Nombre del proyecto; se usa en `wrangler pages deploy --project-name`."
  value       = cloudflare_pages_project.this.name
}

output "subdomain" {
  description = "Dominio *.pages.dev del proyecto (p. ej. tm-web-dev.pages.dev)."
  value       = cloudflare_pages_project.this.subdomain
}

output "hostname" {
  description = "Hostname de producción del proyecto, calculado a partir del nombre."
  value       = "${var.name}.pages.dev"
}
