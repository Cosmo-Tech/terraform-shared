variable "namespace" {
  type = string
}

variable "image_registry" {
  type = string
}

variable "image_registry_auth_secret" {
  type = string
}


# -- Harbor itself
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
# -- Harbor itself


# -- Harbor PostgreSQL
variable "chart_postgresql_repository" {
  type = string
}

variable "chart_postgresql_name" {
  type = string
}

variable "chart_postgresql_tag" {
  type = string
}

variable "chart_postgresql_release" {
  type = string
}
# -- Harbor PostgreSQL


# -- Harbor Redis
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
# -- Harbor Redis


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
