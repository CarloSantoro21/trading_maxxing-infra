# Base de datos D1 (SQLite serverless) de un ambiente.
# El esquema y las migraciones NO viven aquí: las aplica `wrangler d1 migrations apply`
# desde el pipeline del monorepo. Terraform solo crea la base vacía.
resource "cloudflare_d1_database" "this" {
  account_id            = var.account_id
  name                  = var.name
  primary_location_hint = var.primary_location_hint
}
