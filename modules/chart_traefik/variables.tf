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

variable "traefik_image_repository" {
  type = string
}

variable "traefik_image_tag" {
  type = string
}

variable "platform_lb_ip" {
  type = string
}

variable "lb_annotations" {}
