variable "namespace" {
  type = string
}

variable "harbor_postgres_user" {
  description = "PostgreSQL username for harbor"
  type        = string
  default     = ""
}

variable "harbor_postgres_password" {
  description = "Optional PostgreSQL user password; generated if empty"
  type        = string
  default     = ""
}

variable "harbor_postgres_admin_password" {
  description = "Optional PostgreSQL admin password; generated if empty"
  type        = string
  default     = ""
}

variable "harbor_admin_password" {
  type    = string
  default = ""
}

variable "harbor_helm_repo" {
  type = string
}

variable "harbor_helm_chart" {
  type = string
}

variable "harbor_helm_chart_version" {
  type = string
}

variable "postgres_helm_repo" {
  type = string
}

variable "postgres_helm_chart" {
  type = string
}

variable "postgres_helm_chart_version" {
  type = string
}

variable "redis_helm_repo" {
  type = string
}

variable "redis_helm_chart" {
  type = string
}

variable "redis_helm_chart_version" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "pvc_storage_class" {
  type = string
}

variable "size_redis" {
  type = string
}

variable "pvc_redis" {
  type = string
}

variable "size_postgresql" {
  type = string
}

variable "pvc_postgresql" {
  type = string
}

variable "size_registry" {
  type = string
}

variable "pvc_registry" {
  type = string
}

variable "size_jobservice" {
  type = string
}

variable "pvc_jobservice" {
  type = string
}

variable "size_chartmuseum" {
  type = string
}

variable "pvc_chartmuseum" {
  type = string
}

variable "size_trivy" {
  type = string
}

variable "pvc_trivy" {
  type = string
}
