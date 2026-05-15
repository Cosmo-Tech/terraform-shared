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

variable "certificate_email" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "service_annotations" {
  type = string
}

variable "cloud_provider" {
  type = string
}

variable "dns_challenge_provider" {
  type = string
}
