output "name" {
  description = "Nombre del Worker."
  value       = cloudflare_worker.this.name
}

output "id" {
  description = "ID del Worker en Cloudflare."
  value       = cloudflare_worker.this.id
}
