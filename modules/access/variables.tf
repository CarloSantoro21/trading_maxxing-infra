variable "account_id" {
  description = "ID de la cuenta de Cloudflare."
  type        = string
}

variable "env" {
  description = "Nombre del ambiente (dev, prod). Se usa en los nombres de los recursos."
  type        = string
}

variable "team_name" {
  description = "Nombre del equipo de Zero Trust; el team domain es <team_name>.cloudflareaccess.com."
  type        = string
}

variable "web_hostname" {
  description = "Hostname del dashboard en Pages (p. ej. tm-web-dev.pages.dev). También se protegen sus previews."
  type        = string
}

variable "api_hostname" {
  description = "Hostname del Worker en workers.dev (p. ej. tm-api-dev.<subdominio>.workers.dev). null o vacío = no se crea la app de la API."
  type        = string
  default     = null
}

variable "allowed_emails" {
  description = "Allowlist de correos que pueden entrar al dashboard."
  type        = list(string)

  validation {
    condition     = length(var.allowed_emails) > 0
    error_message = "La allowlist necesita al menos un correo."
  }

  validation {
    condition     = alltrue([for e in var.allowed_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])
    error_message = "Todos los elementos de allowed_emails deben ser correos válidos."
  }
}

variable "create_onetimepin_idp" {
  description = "true = este ambiente crea el proveedor One-time PIN de la cuenta. Solo un ambiente debe hacerlo."
  type        = bool
  default     = false
}

variable "onetimepin_idp_id" {
  description = "ID de un proveedor One-time PIN existente (cuando create_onetimepin_idp = false)."
  type        = string
  default     = null
}

variable "session_duration" {
  description = "Duración de la sesión de Access para personas."
  type        = string
  default     = "24h"
}

variable "service_token_duration" {
  description = "Vigencia del token de servicio del motor (8760h = 1 año)."
  type        = string
  default     = "8760h"
}
