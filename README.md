# trading_maxxing-infra

Terraform de Cloudflare para [trading_maxxing](https://github.com/CarloSantoro21/trading_maxxing)
(proyecto final de Infraestructura, ITESO). Crea, en el **plan gratuito** de Cloudflare, todo lo
que el código del monorepo necesita para correr en dos ambientes, `dev` y `prod`.

```
                         Internet
                            │
             ┌──────────────┴───────────────┐
             ▼                              ▼
   Cloudflare Access (One-time PIN, allowlist de correos)
             │                              │ (token de servicio del motor)
             ▼                              ▼
   Pages  tm-web-dev / tm-web  ──service binding "API"──▶  Worker  tm-api-dev / tm-api
   (Next.js export estático)                               (Hono + Workers Observability)
                                                                   │
                                                                   ▼
                                                           D1  tm-dev / tm-prod
                                                                   ▲
                                         HTTPS saliente, /internal/*│ con CF-Access-Client-Id/Secret
                                                                   │
                                Mac de Carlo: docker compose (agents, engine, forecast, Redis)
```

## Qué crea

| Recurso | Tipo de Terraform | dev | prod |
| --- | --- | --- | --- |
| Base de datos D1 | `cloudflare_d1_database` | `tm-dev` | `tm-prod` |
| Proyecto de Pages (apps/web) | `cloudflare_pages_project` | `tm-web-dev` (rama de producción `develop`) | `tm-web` (rama `main`) |
| Worker de la API (cascarón + Observability) | `cloudflare_worker` | `tm-api-dev` | `tm-api` |
| Proveedor One-time PIN | `cloudflare_zero_trust_access_identity_provider` | lo crea dev | reutiliza el de dev |
| Política "allow equipo" (allowlist) | `cloudflare_zero_trust_access_policy` | `tm-dev allow equipo` | `tm-prod allow equipo` |
| Política del motor (`non_identity`) | `cloudflare_zero_trust_access_policy` | `tm-dev service token motor` | `tm-prod service token motor` |
| Token de servicio del motor | `cloudflare_zero_trust_access_service_token` | `tm-motor-dev` | `tm-motor-prod` |
| App de Access del dashboard | `cloudflare_zero_trust_access_application` | `tm-web-dev.pages.dev` y `*.tm-web-dev.pages.dev` | `tm-web.pages.dev` y `*.tm-web.pages.dev` |
| App de Access de la API (opcional) | `cloudflare_zero_trust_access_application` | `tm-api-dev.<subdominio>.workers.dev` | `tm-api.<subdominio>.workers.dev` |

El proyecto de Pages declara un **service binding `API`** hacia el Worker del mismo ambiente, así
el frontend llama a la API sin salir a internet. La app de Access de la API se crea solo si defines
`workers_dev_subdomain`; deja pasar a los correos de la allowlist y al token de servicio del motor.

**Qué NO hace Terraform** (lo hace el pipeline del monorepo con `wrangler`):

- Subir el código del Worker (`wrangler deploy`) y sus secretos (`wrangler secret put`).
- Aplicar las migraciones de D1 (`wrangler d1 migrations apply`).
- Compilar y subir el sitio (`wrangler pages deploy apps/web/out --project-name ...`).

Terraform crea los recursos vacíos; `wrangler` pone el contenido. Así cada herramienta tiene un
solo dueño y no se pisan.

## Estructura

```
modules/
  d1/               base D1
  pages/            proyecto de Pages con service binding al Worker
  access/           One-time PIN, políticas, token de servicio y apps de Access
  worker_settings/  Worker vacío con Workers Observability (APM)
envs/
  dev/              raíz de Terraform de dev  (workspace HCP: trading-maxxing-dev)
  prod/             raíz de Terraform de prod (workspace HCP: trading-maxxing-prod)
    tests/          pruebas `terraform test` con provider simulado (sin credenciales)
.github/workflows/terraform.yml
```

## Costos

**$0.** Todo cabe en los planes gratuitos:

| Servicio | Límite gratuito relevante |
| --- | --- |
| Pages | 500 builds al mes, sitios y ancho de banda ilimitados |
| Workers | 100 000 peticiones al día |
| D1 | 5 GB de almacenamiento, 5 M de filas leídas al día |
| Workers Observability | incluido (logs y trazas con retención corta) |
| Zero Trust / Access | gratis hasta 50 usuarios |
| HCP Terraform | plan Free (estado remoto, hasta 500 recursos) |

Activar Zero Trust puede pedir un método de pago aunque el plan sea de $0. No hay cargos mientras no
cambies de plan.

## Requisitos

- Terraform >= 1.6 (las pruebas `terraform test` con `mock_provider` piden >= 1.7).
- Cuenta de Cloudflare con **Zero Trust activado** (plan Free) y un *team name* elegido.
- Cuenta de HCP Terraform (o R2, ver más abajo).

### Token de API de Cloudflare (permisos mínimos)

Crea un token en *My Profile > API Tokens > Create Custom Token*, limitado a **tu cuenta**:

| Ámbito | Permiso | Para qué |
| --- | --- | --- |
| Account | D1: Edit | `cloudflare_d1_database` |
| Account | Cloudflare Pages: Edit | `cloudflare_pages_project` |
| Account | Workers Scripts: Edit | `cloudflare_worker` (y Observability) |
| Account | Access: Apps and Policies: Edit | apps y políticas de Access |
| Account | Access: Service Tokens: Edit | token de servicio del motor |
| Account | Access: Organizations, Identity Providers, and Groups: Edit | proveedor One-time PIN |

No necesita permisos de zona (no usamos dominio propio; todo vive en `*.pages.dev` y `*.workers.dev`).
Ponle fecha de expiración y, si quieres, restricción de IP.

## Bootstrap (una sola vez)

1. **Zero Trust.** En el dashboard de Cloudflare entra a *Zero Trust*, elige el plan Free y un team
   name (por ejemplo `trading-maxxing`). El team domain queda como `trading-maxxing.cloudflareaccess.com`.
2. **Token de API** con los permisos de la tabla anterior.
3. **HCP Terraform.**
   - Crea (o reutiliza) una organización.
   - Crea dos workspaces de tipo *CLI-driven*: `trading-maxxing-dev` y `trading-maxxing-prod`.
   - En cada workspace, *Settings > General > Execution Mode* = **Local**. HCP solo guarda el estado;
     el plan corre en tu máquina o en GitHub Actions con `CLOUDFLARE_API_TOKEN`.
   - Crea un *team token* o *user token* (será `TF_API_TOKEN`).
4. **GitHub** (Settings de este repo):
   - Secrets: `CLOUDFLARE_API_TOKEN`, `TF_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`,
     `ACCESS_ALLOWED_EMAILS` (JSON, por ejemplo `["a@x.com","b@y.com"]`).
   - Variables: `TF_CLOUD_ORGANIZATION`, `ACCESS_TEAM_NAME`, `WORKERS_DEV_SUBDOMAIN` (opcional).
   - Environments: `dev` y `prod`; en `prod` activa **Required reviewers**. Los secrets pueden
     vivir a nivel repo o por environment.
5. **Primer apply local** (o con el workflow, ver abajo). **dev va primero**, porque crea el
   proveedor One-time PIN que prod reutiliza:

   ```bash
   export CLOUDFLARE_API_TOKEN=...          # token del paso 2
   export TF_CLOUD_ORGANIZATION=mi-org      # organización de HCP
   terraform login                          # o export TF_TOKEN_app_terraform_io=...

   cd envs/dev
   cp terraform.tfvars.example terraform.tfvars   # y llénalo
   terraform init
   terraform plan
   terraform apply

   cd ../prod
   cp terraform.tfvars.example terraform.tfvars
   terraform init && terraform apply
   ```

Si ya existía un proveedor One-time PIN en la cuenta (creado desde el dashboard), impórtalo en dev
en lugar de crear otro:
`terraform import 'module.access.cloudflare_zero_trust_access_identity_provider.otp[0]' 'accounts/<account_id>/<idp_id>'`.

### Backend alterno en R2

Si no quieres HCP Terraform, guarda el estado en un bucket de R2 (API compatible con S3; R2 también
tiene capa gratuita de 10 GB, pero activarlo pide método de pago):

1. Crea el bucket `tm-tfstate` y un token de R2 con *Object Read & Write* sobre ese bucket.
2. En `envs/<env>/versions.tf`, reemplaza el bloque `cloud { ... }` por:

   ```hcl
   backend "s3" {
     bucket                      = "tm-tfstate"
     key                         = "dev/terraform.tfstate" # prod/terraform.tfstate en prod
     region                      = "auto"
     endpoints                   = { s3 = "https://<ACCOUNT_ID>.r2.cloudflarestorage.com" }
     use_path_style              = true
     use_lockfile                = true # Terraform >= 1.10
     skip_credentials_validation = true
     skip_region_validation      = true
     skip_requesting_account_id  = true
     skip_metadata_api_check     = true
     skip_s3_checksum            = true
   }
   ```

3. Exporta `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` con las llaves del token de R2 y corre
   `terraform init -migrate-state`. En el workflow, cambia `TF_API_TOKEN` por esas dos llaves.

## CI/CD (`.github/workflows/terraform.yml`)

| Evento | Qué corre |
| --- | --- |
| PR y push a `develop`/`main` | `terraform fmt -check`, `init -backend=false`, `validate` y `terraform test` en dev y prod; `tflint` (no bloquea) |
| PR, si existen `CLOUDFLARE_API_TOKEN` y `TF_API_TOKEN` | `terraform plan` de dev y prod, publicado como comentario en el PR (se actualiza en cada push) |
| *Run workflow* manual (`workflow_dispatch`) | `plan` o `apply` del environment elegido; `prod` pide aprobación y solo se aplica desde `main` |

## Valores para el monorepo (wrangler.toml y secrets)

Después de un `apply`, lee los outputs:

```bash
cd envs/dev
terraform output                                   # valores no sensibles
terraform output -raw motor_service_token_client_id
terraform output -raw motor_service_token_client_secret
```

| Output | Dónde se usa en el monorepo |
| --- | --- |
| `d1_database_id` | `database_id` en `[[d1_databases]]` (binding `DB`) de `wrangler.toml` |
| `d1_database_name` | `database_name` en `[[d1_databases]]` |
| `worker_name` | `name` del Worker (`tm-api-dev` / `tm-api`) |
| `pages_project_name` | `wrangler pages deploy apps/web/out --project-name <valor>` |
| `pages_url` | URL del dashboard (detrás de Access) |
| `access_team_domain` | variable `ACCESS_TEAM_DOMAIN` del Worker (para validar el JWT de Access) |
| `access_web_aud` | variable `ACCESS_AUD` del Worker (AUD del dashboard) |
| `access_api_aud` | AUD de la app de la API en workers.dev (si se configuró) |
| `motor_service_token_client_id` / `_client_secret` | `.env` del motor en la Mac (`CF_ACCESS_CLIENT_ID` / `CF_ACCESS_CLIENT_SECRET`) |

El `database_id` y el AUD no son secretos (se pueden commitear en `wrangler.toml`). El client secret
del token de servicio **sí** lo es: solo va en el `.env` de la Mac o en un secret.

## Destruir

```bash
cd envs/prod && terraform destroy   # prod primero: usa el proveedor One-time PIN de dev
cd ../dev   && terraform destroy
```

`terraform destroy` borra las bases D1 **con sus datos**. Si el borrado del proyecto de Pages falla
por tener muchos deployments, bórralos antes desde el dashboard o con `wrangler pages deployment`.

## Pruebas locales sin credenciales

```bash
terraform fmt -check -recursive
cd envs/dev && terraform init -backend=false && terraform validate && terraform test
cd ../prod  && terraform init -backend=false && terraform validate && terraform test
```

`terraform test` usa un provider simulado: revisa nombres, conexiones entre módulos y validaciones
sin tocar la cuenta de Cloudflare.

Ver [CONTRIBUTING.md](CONTRIBUTING.md) para la estrategia de ramas.
