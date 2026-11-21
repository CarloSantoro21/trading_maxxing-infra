variable "account_id" {
  description = "ID de la cuenta de Cloudflare."
  type        = string
}

variable "name" {
  description = "Nombre de la base D1 (tm-dev, tm-prod)."
  type        = string
}

variable "primary_location_hint" {
  description = "Región preferida para la réplica primaria (wnam, enam, weur, eeur, apac, oc). null deja que Cloudflare elija."
  type        = string
  default     = null
}
