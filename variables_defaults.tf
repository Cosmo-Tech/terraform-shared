## This file allows to fix defaults values, and also allow to override them from terraform.tfvars, CLI arguments or TF_VAR env variables.


## cert-manager
variable "cert_manager_deploy" { default = true }
variable "cert_manager_chart_name" { default = "cert-manager" }
variable "cert_manager_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "cert_manager_chart_tag" { default = "1.5.14" }
variable "cert_manager_image_tag" { default = "1.21.1" }


## Traefik
variable "traefik_deploy" { default = true }
variable "traefik_chart_name" { default = "traefik" }
variable "traefik_chart_repository" { default = "oci://cgr.dev/cosmotech/charts" }
variable "traefik_chart_tag" { default = "39.0.9" }
variable "traefik_image_tag" { default = "3.7.1" }


## CloudNative-PG ("cnpg", = PostgreSQL)
variable "cnpg_deploy" { default = true }
variable "cnpg_chart_repository" { default = "oci://cgr.dev/cosmotech/charts" }
variable "cnpg_chart_name" { default = "cloudnative-pg" }
variable "cnpg_chart_tag" { default = "0.29.0-fips" }
variable "cnpg_image_tag" { default = "1.30.0" }


## Harbor
variable "harbor_deploy" { default = true }
variable "harbor_chart_name" { default = "harbor" }
variable "harbor_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "harbor_chart_tag" { default = "27.0.3" }
variable "harbor_image_tag" { default = "2.15.2" }

variable "harbor_redis_chart_name" { default = "redis" }
variable "harbor_redis_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "harbor_redis_chart_tag" { default = "25.3.8" }
variable "harbor_redis_image_tag" { default = "8.8.2" }


## Keycloak
variable "keycloak_deploy" { default = true }
variable "keycloak_chart_name" { default = "keycloak" }
variable "keycloak_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "keycloak_chart_tag" { default = "25.3.2" }
variable "keycloak_image_repository" { default = "proxy-chainguard/cosmotech/keycloak" }
variable "keycloak_image_tag" { default = "26.7.3" }


## kube-prometheus-stack
variable "prometheusstack_deploy" { default = true }
variable "prometheusstack_chart_name" { default = "kube-prometheus-stack" }
variable "prometheusstack_chart_repository" { default = "oci://cgr.dev/cosmotech/charts" }
variable "prometheusstack_chart_tag" { default = "85.1.0" }


## Superset
variable "superset_deploy" { default = true }
variable "superset_chart_name" { default = "superset" }
variable "superset_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "superset_chart_tag" { default = "5.0.0" }
variable "superset_image_tag" { default = "6.1.0" }
variable "superset_redis_image_tag" { default = "8.8.2" }


## Workload Scheduler (autostop/autostart)
variable "workload_scheduler_deploy" { default = true }
variable "workload_scheduler_timezone" { default = "Europe/Paris" }
variable "workload_scheduler_cron_stop" { default = "0 21 * * 1-5" }  # Stop monday-friday at 21:00
variable "workload_scheduler_cron_start" { default = "0 07 * * 1-5" } # Start monday-friday at 07:00


## Global
variable "image_registry" { default = "registry.cosmotech.com" }
variable "image_registry_auth_secret" { default = "registry-auth-cosmotech" }
variable "image_repository_prefix" { default = "proxy-chainguard/cosmotech" }

variable "postgresql_image_name" { default = "postgres-cloudnative-pg-fips" }
variable "postgresql_image_tag" { default = "18" }

variable "generic_shell_image_name" { default = "os-shell-iamguarded" }
variable "generic_shell_image_tag" { default = "latest" }

locals {
  module_storage_onprem_tag = "main"
  module_storage_azure_tag  = "main"
  module_storage_aws_tag    = "main"
  module_storage_gcp_tag    = "main"
}
