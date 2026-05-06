variable "project_id" {
  type = string
}

variable "env" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "alert_email" {
  type        = string
  description = "Email address to receive Cloud Monitoring alert notifications."
}

variable "slack_channel_name" {
  type        = string
  default     = ""
  description = "Slack channel name (e.g. #alerts). Leave empty to skip Slack notification channel."
}

variable "slack_auth_token" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Slack bot OAuth token. Required if slack_channel_name is set."
}

# Services to build SLOs for: name => display_name.
variable "services" {
  type = map(string)
  default = {
    "account-service"      = "Account Service"
    "transaction-service"  = "Transaction Service"
    "notification-service" = "Notification Service"
    "api-gateway"          = "API Gateway"
    "frontend"             = "Frontend"
  }
}

variable "availability_slo_goal" {
  type    = number
  default = 0.999 # 99.9%
}

variable "latency_slo_goal" {
  type    = number
  default = 0.95 # 95% of requests under threshold
}

variable "latency_threshold_ms" {
  type    = number
  default = 1000
}
