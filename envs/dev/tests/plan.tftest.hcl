# Prueba sin credenciales: el provider de Cloudflare se simula (mock_provider), así que
# solo verifica nombres, wiring entre módulos y validaciones. Correr con:
#   terraform init -backend=false && terraform test
mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_identity_provider" {
    defaults = { id = "otp-dev-mock" }
  }
}

variables {
  cloudflare_account_id = "0123456789abcdef0123456789abcdef"
  access_team_name      = "trading-maxxing"
  access_allowed_emails = ["persona1@example.com", "persona2@example.com"]
  workers_dev_subdomain = "ejemplo"
}

run "nombres_y_wiring" {
  command = apply

  assert {
    condition     = module.d1.database_name == "tm-dev"
    error_message = "La D1 de dev debe llamarse tm-dev."
  }

  assert {
    condition     = output.pages_project_name == "tm-web-dev"
    error_message = "El proyecto de Pages de dev debe llamarse tm-web-dev."
  }

  assert {
    condition     = output.worker_name == "tm-api-dev"
    error_message = "El Worker de dev debe llamarse tm-api-dev."
  }

  assert {
    condition     = output.access_team_domain == "trading-maxxing.cloudflareaccess.com"
    error_message = "El team domain no se arma bien."
  }

  assert {
    condition     = module.access.onetimepin_idp_id == "otp-dev-mock"
    error_message = "dev debe crear y usar su propio proveedor One-time PIN."
  }

  assert {
    condition     = output.pages_url == "https://tm-web-dev.pages.dev"
    error_message = "URL de Pages incorrecta."
  }
}

run "allowlist_vacia_falla" {
  command = plan

  variables {
    access_allowed_emails = []
  }

  expect_failures = [var.access_allowed_emails]
}

run "subdominio_vacio_no_crea_app_api" {
  command = apply

  # En CI la variable de GitHub vacía llega como "" (no como null).
  variables {
    workers_dev_subdomain = ""
  }

  assert {
    condition     = output.access_api_aud == null
    error_message = "Con subdominio vacío no debe crearse la app de Access de la API."
  }
}
