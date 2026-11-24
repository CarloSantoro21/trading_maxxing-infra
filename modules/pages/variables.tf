variable "account_id" {
  description = "ID de la cuenta de Cloudflare."
  type        = string
}

variable "name" {
  description = "Nombre del proyecto de Pages (tm-web-dev, tm-web). Define el dominio <name>.pages.dev."
  type        = string
}

variable "production_branch" {
  description = "Rama que cuenta como producción del proyecto (develop para dev, main para prod)."
  type        = string
}

variable "api_worker_name" {
  description = "Nombre del Worker de la API al que apunta el service binding (tm-api-dev, tm-api)."
  type        = string
}

variable "api_binding_name" {
  description = "Nombre del service binding dentro de Pages (env.API)."
  type        = string
  default     = "API"
}

variable "compatibility_date" {
  description = "compatibility_date de las Pages Functions."
  type        = string
  default     = "2026-11-01"
}

variable "build_command" {
  description = "Comando de build documentado en el proyecto (el pipeline compila por su cuenta)."
  type        = string
  default     = "pnpm install --frozen-lockfile && pnpm build"
}

variable "root_dir" {
  description = "Carpeta del monorepo donde vive el frontend."
  type        = string
  default     = "apps/web"
}

variable "destination_dir" {
  description = "Carpeta de salida del export estático de Next.js, relativa a root_dir."
  type        = string
  default     = "out"
}

variable "env_vars" {
  description = "Variables de entorno en texto plano para las Pages Functions (nada secreto aquí)."
  type        = map(string)
  default     = {}
}
