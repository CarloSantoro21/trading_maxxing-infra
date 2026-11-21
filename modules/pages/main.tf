# Proyecto de Cloudflare Pages para apps/web (Next.js con `output: "export"`).
#
# El proyecto es de "subida directa" (sin integración con Git): el pipeline del monorepo
# compila el sitio y lo sube con `wrangler pages deploy apps/web/out --project-name <nombre>`.
# Por eso `build_config` es solo informativo (documenta cómo se compila) y no dispara builds.
#
# `deployment_configs` conecta el proyecto con el Worker de la API mediante un service
# binding llamado "API": las Pages Functions (o el proxy de /api) llaman a la API sin salir
# a internet y sin pasar por Access.
resource "cloudflare_pages_project" "this" {
  account_id        = var.account_id
  name              = var.name
  production_branch = var.production_branch

  build_config = {
    build_caching   = true
    build_command   = var.build_command
    destination_dir = var.destination_dir
    root_dir        = var.root_dir
  }

  deployment_configs = {
    production = {
      compatibility_date = var.compatibility_date
      services = {
        (var.api_binding_name) = {
          service = var.api_worker_name
        }
      }
      env_vars = local.env_vars
    }

    preview = {
      compatibility_date = var.compatibility_date
      services = {
        (var.api_binding_name) = {
          service = var.api_worker_name
        }
      }
      env_vars = local.env_vars
    }
  }
}

locals {
  env_vars = {
    for k, v in var.env_vars : k => {
      type  = "plain_text"
      value = v
    }
  }
}
