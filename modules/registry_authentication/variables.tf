
variable "registry" {
  type = string
}

variable "namespace" {
  type = string
}

variable "secret" {
  type = string
}

variable "username" {
  type      = string
  sensitive = true
}

variable "password" {
  type      = string
  sensitive = true
}
