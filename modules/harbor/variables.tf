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
  type    = string
  default = ""
}
variable "harbor_helm_chart" {
  type    = string
  default = ""
}
variable "harbor_helm_chart_version" {
  type    = string
  default = ""
}
variable "postgres_helm_repo" {
  type    = string
  default = ""
}
variable "postgres_helm_chart" {
  type    = string
  default = ""
}
variable "postgres_helm_chart_version" {
  type    = string
  default = ""
}
variable "redis_helm_repo" {
  type    = string
  default = ""
}
variable "redis_helm_chart" {
  type    = string
  default = ""
}
variable "redis_helm_chart_version" {
  type    = string
  default = ""
}