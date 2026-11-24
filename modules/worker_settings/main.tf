# "Cascarón" del Worker de la API (tm-api-dev / tm-api).
#
# Terraform crea el Worker vacío con Workers Observability (logs + trazas = el APM del
# proyecto) para que exista ANTES de que:
#   - Pages declare su service binding "API" hacia él, y
#   - Access proteja su hostname de workers.dev.
#
# El código, las variables y los secretos los sube `wrangler deploy` / `wrangler secret put`
# desde el pipeline del monorepo. Mantén `observability` igual en wrangler.toml para que
# Terraform y wrangler no se peleen.
resource "cloudflare_worker" "this" {
  account_id = var.account_id
  name       = var.name
  logpush    = false

  observability = {
    enabled            = true
    head_sampling_rate = var.head_sampling_rate
    logs = {
      enabled            = true
      head_sampling_rate = var.head_sampling_rate
      invocation_logs    = true
    }
  }

  # wrangler maneja el subdominio workers.dev (workers_dev = true) y las etiquetas.
  lifecycle {
    ignore_changes = [subdomain, tags, tail_consumers]
  }
}
