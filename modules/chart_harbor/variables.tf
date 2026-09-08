variable "namespace" {
  type = string
}

variable "image_registry" {
  type = string
}

variable "image_registry_auth_secret" {
  type = string
}

variable "chart_harbor_repository" {
  type = string
}

variable "chart_harbor_name" {
  type = string
}

variable "chart_harbor_tag" {
  type = string
}

variable "chart_harbor_release" {
  type = string
}

variable "harbor_image_repository_prefix" {
  type = string
}

variable "harbor_image_tag" {
  type = string
}

variable "chart_redis_repository" {
  type = string
}

variable "chart_redis_name" {
  type = string
}

variable "chart_redis_tag" {
  type = string
}

variable "chart_redis_release" {
  type = string
}

variable "redis_image_repository" {
  type = string
}

variable "redis_image_tag" {
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

variable "cluster_domain" {
  type = string
}

variable "pvc_storage_class" {
  type = string
}

variable "pvc_redis" {
  type = string
}

variable "pvc_postgresql" {
  type = string
}

variable "pvc_registry" {
  type = string
}

variable "pvc_jobservice" {
  type = string
}

variable "persistence_size" {
  type = string
}

variable "postgresql_image_repository" {
  type = string
}

variable "postgresql_image_tag" {
  type = string
}

variable "generic_shell_image_repository" {
  type = string
}

variable "generic_shell_image_tag" {
  type = string
}
