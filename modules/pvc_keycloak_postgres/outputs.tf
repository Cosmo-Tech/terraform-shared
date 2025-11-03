output "postgres_keycloak_pvc_name" {
  value       = try(kubernetes_persistent_volume_claim.postgres_keycloak[0].metadata[0].name, null)
  description = "PVC name for Keycloak PostgreSQL"
}
