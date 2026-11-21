# Cómo contribuir

## Ramas

```
feature/<issue>-<descripcion>  ──PR──▶  develop  ──PR──▶  main
```

- `main`: lo que está aplicado en **prod**. Solo recibe PRs desde `develop`.
- `develop`: lo que está aplicado en **dev**. Recibe PRs desde `feature/*`.
- `feature/*` (o `fix/*`): una rama por issue, creada desde `develop`.

Nadie hace push directo a `develop` ni a `main`; todo entra por PR con el CI en verde.

## Flujo

1. `git fetch origin && git checkout -b feature/<issue>-<algo> origin/develop`
2. Cambia el Terraform y corre localmente:
   ```bash
   terraform fmt -recursive
   cd envs/dev && terraform init -backend=false && terraform validate && terraform test
   ```
3. Abre el PR contra `develop`. El workflow corre `fmt`, `validate`, `test`, `tflint` y, si hay
   secrets, publica el `terraform plan` de dev y prod como comentario. Revisa el plan antes de
   aprobar.
4. Al mergear a `develop`, aplica dev con *Actions > Terraform > Run workflow* (`dev`, `apply`).
5. Para prod: PR `develop` → `main`, merge, y *Run workflow* (`prod`, `apply`) desde `main`.
   El environment `prod` pide aprobación.

## Convenciones

- Commits en español con [Conventional Commits](https://www.conventionalcommits.org/es/):
  `feat(access): ...`, `fix(pages): ...`, `docs: ...`, `ci: ...`.
- Nada de secretos en el repo: `*.tfvars` está en `.gitignore`; usa `terraform.tfvars.example`.
- Los nombres de recursos (`tm-dev`, `tm-web`, `tm-api`, ...) son contrato con el monorepo:
  si cambias uno, cámbialo también en su `wrangler.toml` y en el pipeline.
