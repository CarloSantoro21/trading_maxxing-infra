# Prueba sin credenciales (provider simulado). Verifica nombres de prod y que Access use el
# proveedor One-time PIN que crea envs/dev. Correr con:
#   terraform init -backend=false && terraform test
#
# Nota: Terraform no puede simular el atributo `result` (lista anidada) del data source de
# identity providers, así que aquí se pasa onetimepin_idp_id explícito; la búsqueda real se
# prueba con `terraform plan` contra la cuenta.
mock_provider "cloudflare" {}

override_data {
  target = data.cloudflare_zero_trust_access_identity_providers.all
  values = {}
}

variables {
  cloudflare_account_id = "0123456789abcdef0123456789abcdef"
  access_team_name      = "trading-maxxing"
  access_allowed_emails = ["persona1@example.com"]
  onetimepin_idp_id     = "otp-de-dev"
}

run "nombres_y_otp_compartido" {
  command = apply

  assert {
    condition     = module.d1.database_name == "tm-prod"
    error_message = "La D1 de prod debe llamarse tm-prod."
  }

  assert {
    condition     = output.pages_project_name == "tm-web"
    error_message = "El proyecto de Pages de prod debe llamarse tm-web."
  }

  assert {
    condition     = output.worker_name == "tm-api"
    error_message = "El Worker de prod debe llamarse tm-api."
  }

  assert {
    condition     = module.access.onetimepin_idp_id == "otp-de-dev"
    error_message = "prod debe reutilizar el proveedor One-time PIN de dev."
  }

  assert {
    condition     = output.access_api_aud == null
    error_message = "Sin workers_dev_subdomain no debe crearse la app de Access de la API."
  }

  assert {
    condition     = output.pages_url == "https://tm-web.pages.dev"
    error_message = "URL de Pages incorrecta."
  }
}

run "api_protegida_con_subdominio" {
  command = apply

  variables {
    workers_dev_subdomain = "ejemplo"
  }

  assert {
    condition     = output.access_api_aud != null
    error_message = "Con workers_dev_subdomain debe crearse la app de Access de la API."
  }
}
