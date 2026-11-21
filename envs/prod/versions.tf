terraform {
  required_version = ">= 1.6"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }

  # Estado remoto en HCP Terraform (plan gratuito). La organización sale de la variable de
  # entorno TF_CLOUD_ORGANIZATION y el token de TF_TOKEN_app_terraform_io (o terraform login).
  # El workspace debe estar en modo de ejecución "Local": HCP solo guarda el estado y el plan
  # corre en GitHub Actions o en tu máquina con CLOUDFLARE_API_TOKEN.
  # Alternativa con R2 como backend S3: ver README.md, sección "Backend alterno en R2".
  cloud {
    workspaces {
      name = "trading-maxxing-prod"
    }
  }
}

# El token se lee de la variable de entorno CLOUDFLARE_API_TOKEN; nunca va en el repo.
provider "cloudflare" {}
