variable "email" {
  description = "Email for Let's Encrypt"
  type        = string
}
variable "project_id" {}
variable "region" { default = "europe-west6" }
variable "customer_name" {}
variable "project_name" {}
variable "project_stage" {}
variable "api_dns_name" {}
variable "cloud_provider" {}