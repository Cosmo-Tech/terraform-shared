
variable "kws_scale_down_schedule" {
  type = string
}

variable "kws_scale_up_schedule" {
  type = string
}

variable "image_registry_auth_secret" {
  type = string
}

variable "image_repository_prefix" {
  type = string
}

variable "kws_image_tag" {
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

variable "namespace" {
  type = string
}

variable "chart_prefix_product" {
  type = string
}