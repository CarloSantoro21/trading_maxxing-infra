# Ambiente dev: lo que despliega la rama develop del monorepo.
locals {
  env           = "dev"
  d1_name       = "tm-dev"
  pages_name    = "tm-web-dev"
  worker_name   = "tm-api-dev"
  api_hostname  = try(length(var.workers_dev_subdomain), 0) == 0 ? null : "${local.worker_name}.${var.workers_dev_subdomain}.workers.dev"
  web_hostname  = "${local.pages_name}.pages.dev"
  pages_env_var = { APP_ENV = local.env }
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
  production_branch = "develop"
  # Referencia al módulo (no al string) para que el Worker exista antes del binding.
  api_worker_name = module.worker.name
  env_vars        = local.pages_env_var
}

module "access" {
  source = "../../modules/access"

  account_id     = var.cloudflare_account_id
  env            = local.env
  team_name      = var.access_team_name
  web_hostname   = local.web_hostname
  api_hostname   = local.api_hostname
  allowed_emails = var.access_allowed_emails

  # dev es dueño del proveedor One-time PIN de la cuenta; prod lo reutiliza.
  create_onetimepin_idp = true

  depends_on = [module.pages, module.worker]
}
