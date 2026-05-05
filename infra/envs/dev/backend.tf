terraform {
  backend "gcs" {
    # bucket is supplied at init time via -backend-config, e.g.:
    #   terraform init -backend-config="bucket=fintech-tfstate-xxxx"
    prefix = "envs/dev"
  }
}
