# Ambiente prod: lo que despliega la rama main del monorepo.
locals {
  env           = "prod"
  d1_name       = "tm-prod"
  pages_name    = "tm-web"
  worker_name   = "tm-api"
  api_hostname  = try(length(var.workers_dev_subdomain), 0) == 0 ? null : "${local.worker_name}.${var.workers_dev_subdomain}.workers.dev"
  # El subdominio real lo devuelve la API de Cloudflare: si <pages_name>.pages.dev
  # ya existe en otra cuenta, Pages le agrega un sufijo (p. ej. tm-web-9xy.pages.dev).
  web_hostname  = module.pages.subdomain
  pages_env_var = { APP_ENV = local.env }

  # El proveedor One-time PIN lo crea envs/dev (solo puede haber uno por cuenta).
  # Si se pasa onetimepin_idp_id se usa ese; si no, se busca en la cuenta.
  otp_idp_id = coalesce(var.onetimepin_idp_id, one([
    for idp in data.cloudflare_zero_trust_access_identity_providers.all.result : idp.id if idp.type == "onetimepin"
  ]))
}

data "cloudflare_zero_trust_access_identity_providers" "all" {
  account_id = var.cloudflare_account_id
}

module "d1" {
  source = "../../modules/d1"

  account_id            = var.cloudflare_account_id
  name                  = local.d1_name
  primary_location_hint = var.d1_location_hint
}

module "worker" {
  source = "../../modules/worker_settings"

  account_id = var.cloudflare_account_id
  name       = local.worker_name
}

module "pages" {
  source = "../../modules/pages"

  account_id        = var.cloudflare_account_id
  name              = local.pages_name
  production_branch = "main"
  api_worker_name   = module.worker.name
  env_vars          = local.pages_env_var
}

module "access" {
  source = "../../modules/access"

  account_id     = var.cloudflare_account_id
  env            = local.env
  team_name      = var.access_team_name
  web_hostname   = local.web_hostname
  api_hostname   = local.api_hostname
  allowed_emails = var.access_allowed_emails

  create_onetimepin_idp = false
  onetimepin_idp_id     = local.otp_idp_id

  depends_on = [module.pages, module.worker]
}
