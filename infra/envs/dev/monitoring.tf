module "monitoring" {
  source = "../../modules/monitoring"

  project_id   = var.project_id
  env          = var.env
  cluster_name = module.gke.cluster_name
  region       = var.region

  alert_email        = var.alert_email
  slack_channel_name = var.slack_channel_name
  slack_auth_token   = var.slack_auth_token
}
