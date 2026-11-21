variable "account_id" {
  description = "ID de la cuenta de Cloudflare."
  type        = string
}

variable "name" {
  description = "Nombre del Worker (tm-api-dev, tm-api). Debe coincidir con `name` en wrangler.toml."
  type        = string
}

variable "head_sampling_rate" {
  description = "Fracción de peticiones que se registran en Workers Observability (1 = 100 %)."
  type        = number
  default     = 1

  validation {
    condition     = var.head_sampling_rate > 0 && var.head_sampling_rate <= 1
    error_message = "head_sampling_rate debe estar entre 0 (exclusivo) y 1."
  }
}
