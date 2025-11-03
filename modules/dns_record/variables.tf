variable "project_id" {
  description = "GCP project ID where the DNS zone exists."
  type        = string
}

variable "managed_zone" {
  description = "DNS managed zone name in GCP."
  type        = string
}

variable "records" {
  description = <<EOT
List of DNS records to create. Each record should be a map with:
- name: the FQDN (e.g., _acme-challenge.example.com.)
- type: record type (A, CNAME, TXT, etc.)
- ttl: optional, defaults to 300
- rrdatas: list of values
EOT
  type = list(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    rrdatas = list(string)
  }))
}
