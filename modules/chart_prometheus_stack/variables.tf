variable "namespace" {
  description = "Namespace for deploying the Helm release"
  type        = string
}
variable "helm_repo_url" {
  description = "Helm repository URL for Prometheus chart"
  type        = string
}

variable "helm_chart_name" {
  description = "Helm chart name"
  type        = string
}

variable "helm_chart_version" {
  description = "Helm chart version"
  type        = string
}

variable "helm_release_name" {
  description = "Helm release name for Prometheus"
  type        = string
}


variable "cluster_domain" {
  description = "API DNS name"
  type        = string
}

variable "redis_admin_password" {
  description = "Redis admin password (leave empty to auto-generate)"
  type        = string
  default     = ""
}

variable "prometheus_admin_password" {
  description = "Prometheus admin password (leave empty to auto-generate)"
  type        = string
  default     = ""
}

variable "pvc_storage_class" {
  description = "Storage class name for Prometheus PVC"
  type        = string
}

variable "size_prometheus" {
  type = string
}

variable "pvc_prometheus" {
  type = string
}

variable "size_grafana" {
  type = string
}

variable "pvc_grafana" {
  type = string
}