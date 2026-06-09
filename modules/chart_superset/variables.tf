variable "namespace" {
  type = string
}

variable "image_registry" {
  type = string
}

variable "image_registry_auth_secret" {
  type = string
}

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

variable "cluster_domain" {
  type = string
}

variable "superset_cluster_domain" {
  type = string
}

variable "superset_connect_timeout" {
  type    = string
  default = "30s"
}

variable "superset_query_timeout" {
  type    = string
  default = "60s"
}

variable "superset_buffer_size" {
  type    = string
  default = "16K"
}

variable "superset_max_file_size" {
  type    = string
  default = "5m"
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

variable "postgresql_image_repository" {
  type = string
}

variable "postgresql_image_tag" {
  type = string
}
