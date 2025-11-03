output "grafana_pvc_name" {
  value       = try(kubernetes_persistent_volume_claim.grafana[0].metadata[0].name, null)
  description = "Grafana PVC name"
}

output "loki_pvc_name" {
  value       = try(kubernetes_persistent_volume_claim.loki[0].metadata[0].name, null)
  description = "Loki PVC name"
}
