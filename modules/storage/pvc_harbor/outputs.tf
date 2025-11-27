output "postgres_keycloak_pvc_name" {
  value       = try(kubernetes_persistent_volume_claim.harbor[0].metadata[0].name, null)
  description = "PVC name for harbor"
}
