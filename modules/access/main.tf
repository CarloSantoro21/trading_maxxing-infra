# Cloudflare Access (Zero Trust) de un ambiente.
#
# Qué protege:
#   1. El sitio de Pages (<proyecto>.pages.dev y sus previews *.<proyecto>.pages.dev):
#      solo entran los correos de la allowlist, con One-time PIN (código al correo).
#   2. (Opcional) El Worker de la API en workers.dev: entran los mismos correos y además
#      el token de servicio del motor que corre en la Mac (headers CF-Access-Client-Id y
#      CF-Access-Client-Secret). Así /internal/* nunca queda abierto a internet.
#
# El service binding Pages -> Worker no pasa por Access (es una llamada interna).

# --- Identity provider: One-time PIN ---------------------------------------------------
# Cloudflare solo permite UN proveedor One-time PIN por cuenta. dev y prod comparten cuenta,
# así que un ambiente lo crea (create_onetimepin_idp = true) y el otro reutiliza su ID.
resource "cloudflare_zero_trust_access_identity_provider" "otp" {
  count = var.create_onetimepin_idp ? 1 : 0

  account_id = var.account_id
  name       = "One-time PIN"
  type       = "onetimepin"
  config     = {}
}

locals {
  otp_idp_id = var.create_onetimepin_idp ? cloudflare_zero_trust_access_identity_provider.otp[0].id : var.onetimepin_idp_id

  create_api_app = var.api_hostname != null && var.api_hostname != ""
}

# --- Políticas reutilizables -----------------------------------------------------------
resource "cloudflare_zero_trust_access_policy" "allow_team" {
  account_id       = var.account_id
  name             = "tm-${var.env} allow equipo"
  decision         = "allow"
  session_duration = var.session_duration

  include = [for email in var.allowed_emails : { email = { email = email } }]

  require = [{ login_method = { id = local.otp_idp_id } }]
}

resource "cloudflare_zero_trust_access_policy" "motor_service_token" {
  account_id = var.account_id
  name       = "tm-${var.env} service token motor"
  decision   = "non_identity"

  include = [{ service_token = { token_id = cloudflare_zero_trust_access_service_token.motor.id } }]
}

# --- Token de servicio del motor (Mac) -------------------------------------------------
resource "cloudflare_zero_trust_access_service_token" "motor" {
  account_id = var.account_id
  name       = "tm-motor-${var.env}"
  duration   = var.service_token_duration
}

# --- Aplicación: dashboard en Pages ----------------------------------------------------
resource "cloudflare_zero_trust_access_application" "web" {
  account_id = var.account_id
  name       = "trading_maxxing web (${var.env})"
  type       = "self_hosted"

  destinations = [
    { type = "public", uri = var.web_hostname },
    { type = "public", uri = "*.${var.web_hostname}" },
  ]

  session_duration          = var.session_duration
  app_launcher_visible      = false
  allowed_idps              = [local.otp_idp_id]
  auto_redirect_to_identity = true

  policies = [
    { id = cloudflare_zero_trust_access_policy.allow_team.id, precedence = 1 },
  ]
}

# --- Aplicación: API en workers.dev (opcional) -----------------------------------------
resource "cloudflare_zero_trust_access_application" "api" {
  count = local.create_api_app ? 1 : 0

  account_id = var.account_id
  name       = "trading_maxxing api (${var.env})"
  type       = "self_hosted"

  destinations = [
    { type = "public", uri = var.api_hostname },
  ]

  session_duration          = var.session_duration
  app_launcher_visible      = false
  allowed_idps              = [local.otp_idp_id]
  auto_redirect_to_identity = true
  # Para el motor: sin sesión válida devuelve 401 en lugar de redirigir al login.
  service_auth_401_redirect = true

  policies = [
    { id = cloudflare_zero_trust_access_policy.motor_service_token.id, precedence = 1 },
    { id = cloudflare_zero_trust_access_policy.allow_team.id, precedence = 2 },
  ]
}
