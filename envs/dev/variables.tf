variable "cloudflare_account_id" {
  description = "ID de la cuenta de Cloudflare (Dashboard > Workers & Pages > Account ID)."
  type        = string
}

variable "access_team_name" {
  description = "Nombre del equipo de Zero Trust (<team_name>.cloudflareaccess.com). Se elige al activar Zero Trust."
  type        = string
}

variable "access_allowed_emails" {
  description = "Allowlist de correos con acceso al dashboard. En CI llega como TF_VAR_access_allowed_emails='[\"a@x.com\"]'."
  type        = list(string)

  validation {
    condition     = length(var.access_allowed_emails) > 0
    error_message = "La allowlist necesita al menos un correo."
  }
}

variable "workers_dev_subdomain" {
  description = "Subdominio workers.dev de la cuenta (<subdominio>.workers.dev). null o vacío = no se protege la API con Access."
  type        = string
  default     = null
}

variable "d1_location_hint" {
  description = "Región preferida de la base D1 (wnam = oeste de Norteamérica, la más cercana a México)."
  type        = string
  default     = "wnam"
}
