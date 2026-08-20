# This file allows to fix defaults values, and also allow to override them from terraform.tfvars, CLI arguments or TF_VAR env variables.


# Registry
variable "image_registry" { default = "cgr.dev" }
variable "image_registry_auth_secret" { default = "registry-auth-cgrdev" }


# cert-manager
variable "certmanager_chart_name" { default = "cert-manager" }
variable "certmanager_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "certmanager_chart_tag" { default = "1.5.14" }


# Traefik
variable "traefik_chart_name" { default = "traefik" }
variable "traefik_chart_repository" { default = "oci://cgr.dev/cosmotech/charts" }
variable "traefik_chart_tag" { default = "39.0.9" }
variable "traefik_image_repository" { default = "cosmotech/traefik" }
variable "traefik_image_tag" { default = "3.7.1" }


# CloudNative-PG
variable "cnpg_chart_repository" { default = "oci://cgr.dev/cosmotech/charts" }
variable "cnpg_chart_name" { default = "cloudnative-pg" }
variable "cnpg_chart_tag" { default = "0.29.0-fips" }
variable "cnpg_image_repository" { default = "cosmotech/cloudnative-pg-fips" }
variable "cnpg_image_tag" { default = "latest" }


# Harbor
variable "harbor_chart_name" { default = "harbor" }
variable "harbor_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "harbor_chart_tag" { default = "27.0.3" }

variable "harbor_postgresql_chart_name" { default = "postgresql" }
variable "harbor_postgresql_chart_repository" { default = "cosmotech/postgres-cloudnative-pg-fips" }
variable "harbor_postgresql_chart_tag" { default = "17.1.0" }
variable "harbor_postgresql_image_tag" { default = "18" }

variable "harbor_redis_chart_name" { default = "redis" }
variable "harbor_redis_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "harbor_redis_chart_tag" { default = "25.3.8" }


# Keycloak
variable "keycloak_chart_name" { default = "keycloak" }
variable "keycloak_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "keycloak_chart_tag" { default = "25.3.2" }

variable "keycloak_postgresql_chart_name" { default = "postgresql" }
variable "keycloak_postgresql_chart_repository" { default = "cosmotech/postgres-cloudnative-pg-fips" }
variable "keycloak_postgresql_chart_tag" { default = "17.1.0" }
variable "keycloak_postgresql_image_tag" { default = "18" }


# kube-prometheus-stack
variable "prometheusstack_chart_name" { default = "kube-prometheus-stack" }
variable "prometheusstack_chart_repository" { default = "oci://cgr.dev/cosmotech/charts" }
variable "prometheusstack_chart_tag" { default = "85.1.0" }


# Superset
variable "superset_chart_name" { default = "superset" }
variable "superset_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "superset_chart_tag" { default = "5.0.0" }
variable "superset_postgresql_image_tag" { default = "18" }


# Workload Scheduler (autostop/autostart)
variable "workloadscheduler_enable_creation" { default = true } # Setting to false will prevent from Kubernetes objects creation 
variable "workloadscheduler_timezone" { default = "Europe/Paris" }
variable "workloadscheduler_cron_stop" { default = "0 21 * * 1-5" }  # Stop monday-friday at 21:00
variable "workloadscheduler_cron_start" { default = "0 07 * * 1-5" } # Start monday-friday at 07:00


# Global
variable "postgresql_image_repository" { default = "cosmotech/postgres-cloudnative-pg-fips" }
