variable "namespace" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "superset_cluster_domain" {
  type = string
}

variable "helm_repo" {
  type = string
}

variable "helm_chart" {
  type = string
}

variable "helm_chart_version" {
  type = string
}

variable "superset_connect_timeout" {
  type = string
  default = "30s"
}

variable "superset_query_timeout" {
  type = string
  default = "60s"
}

variable "superset_buffer_size" {
  type = string
  default = "16K"
}

variable "superset_max_file_size" {
  type = string
  default = "5m"
}

