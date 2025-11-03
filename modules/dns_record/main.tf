resource "google_dns_record_set" "this" {
  for_each = { for r in var.records : r.name => r }

  name         = each.value.name
  type         = each.value.type
  ttl          = lookup(each.value, "ttl", 300)
  managed_zone = var.managed_zone
  project      = var.project_id
  rrdatas      = each.value.rrdatas
}

output "record_names" {
  description = "List of DNS record names created."
  value       = [for r in google_dns_record_set.this : r.name]
}
