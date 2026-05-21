variable "helm_chart_version" { type = string }
variable "helm_chart" { type = string }
variable "helm_repo" { type = string }
variable "lb_annotations" {}
variable "namespace" { type = string }
variable "platform_lb_ip" { type = string }