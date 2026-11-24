# Configuración de tflint (la usa .github/workflows/terraform.yml).
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
