variable "namespace" {
  type = string
}

# variable "image_registry" {
#   type = string
# }

# variable "image_registry_auth_secret" {
#   type = string
# }

variable "chart_repository" {
  type = string
}

variable "chart_name" {
  type = string
}

variable "chart_tag" {
  type = string
}

variable "chart_release" {
  type = string
}

# variable "helm_chart_version" { type = string }
# variable "helm_chart" { type = string }
# variable "helm_repo" { type = string }

variable "platform_lb_ip" {
  type = string
}

variable "lb_annotations" {}
