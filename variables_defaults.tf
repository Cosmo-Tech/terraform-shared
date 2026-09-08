## This file allows to fix defaults values, and also allow to override them from terraform.tfvars, CLI arguments or TF_VAR env variables.


## Registry
variable "image_registry" { default = "registry.cosmotech.com" }
variable "image_registry_auth_secret" { default = "registry-auth-cosmotech" }


## Generic shell (used to run init containers, scripts etc...)
variable "generic_shell_image_repository" { default = "cgr-proxy/cosmotech/os-shell-iamguarded" }
variable "generic_shell_image_tag" { default = "latest" }


## cert-manager
variable "certmanager_chart_name" { default = "cert-manager" }
variable "certmanager_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "certmanager_chart_tag" { default = "1.5.14" }
variable "certmanager_image_repository_prefix" { default = "cgr-proxy/cosmotech/cert-manager" }
variable "certmanager_image_tag" { default = "1.21.1" }


## Traefik
variable "traefik_chart_name" { default = "traefik" }
variable "traefik_chart_repository" { default = "oci://cgr.dev/cosmotech/charts" }
variable "traefik_chart_tag" { default = "39.0.9" }
variable "traefik_image_repository" { default = "cgr-proxy/cosmotech/traefik" }
variable "traefik_image_tag" { default = "3.7.1" }


## CloudNative-PG ("cnpg", = PostgreSQL)
variable "cnpg_chart_repository" { default = "oci://cgr.dev/cosmotech/charts" }
variable "cnpg_chart_name" { default = "cloudnative-pg" }
variable "cnpg_chart_tag" { default = "0.29.0-fips" }
variable "cnpg_image_repository" { default = "cgr-proxy/cosmotech/cloudnative-pg-fips" }
variable "cnpg_image_tag" { default = "1.30.0" }


## Harbor
variable "harbor_chart_name" { default = "harbor" }
variable "harbor_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "harbor_chart_tag" { default = "27.0.3" }
variable "harbor_image_repository_prefix" { default = "cgr-proxy/cosmotech/harbor" }
variable "harbor_image_tag" { default = "2.15.2" }

variable "harbor_postgresql_image_tag" { default = "18" }

variable "harbor_redis_chart_name" { default = "redis" }
variable "harbor_redis_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "harbor_redis_chart_tag" { default = "25.3.8" }
variable "harbor_redis_image_repository" { default = "cgr-proxy/cosmotech/redis" }
variable "harbor_redis_image_tag" { default = "8.8.2" }


## Keycloak
variable "keycloak_chart_name" { default = "keycloak" }
variable "keycloak_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "keycloak_chart_tag" { default = "25.3.2" }
variable "keycloak_image_repository" { default = "cgr-proxy/cosmotech/keycloak" }
variable "keycloak_image_tag" { default = "26.7.3" }

variable "keycloak_postgresql_image_tag" { default = "18" }


## kube-prometheus-stack
variable "prometheusstack_chart_name" { default = "kube-prometheus-stack" }
variable "prometheusstack_chart_repository" { default = "oci://cgr.dev/cosmotech/charts" }
variable "prometheusstack_chart_tag" { default = "85.1.0" }


## Superset
variable "superset_chart_name" { default = "superset" }
variable "superset_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "superset_chart_tag" { default = "5.0.0" }

variable "superset_postgresql_image_tag" { default = "18" }


## Workload Scheduler (autostop/autostart)
variable "workloadscheduler_enable_creation" { default = true } # Setting to false will prevent from Kubernetes objects creation 
variable "workloadscheduler_timezone" { default = "Europe/Paris" }
variable "workloadscheduler_cron_stop" { default = "0 21 * * 1-5" }  # Stop monday-friday at 21:00
variable "workloadscheduler_cron_start" { default = "0 07 * * 1-5" } # Start monday-friday at 07:00


## Global
variable "postgresql_image_repository" { default = "cgr-proxy/cosmotech/postgres-cloudnative-pg-fips" }
locals {
  module_storage_onprem_tag = "main"
  module_storage_azure_tag  = "main"
  module_storage_aws_tag    = "main"
  module_storage_gcp_tag    = "main"
}
