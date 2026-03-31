# Create requirements on Azure to run a DNS01 challenge
# -> app registration with a secret
# -> store the secret in Kubernetes

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.8.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.62.0"
    }
  }
}

provider "azurerm" {
  features {}
}


locals {
  main_name              = "${var.main_name}-dns-challenge"
  dns_challenge_provider = "azure"
}

# Create app registration
resource "azuread_application_registration" "dns_challenge" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  display_name     = local.main_name
  sign_in_audience = "AzureADMyOrg"
}

# Create a secret on the app registration
resource "azuread_application_password" "dns_challenge" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  application_id = azuread_application_registration.dns_challenge[0].id
  display_name   = local.main_name
}

# Create service principal of the app registration
resource "azuread_service_principal" "dns_challenge" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  client_id = azuread_application_registration.dns_challenge[0].client_id
}

# Add permission to the service principal
resource "azurerm_role_assignment" "dns_contributor" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  scope                = data.azurerm_dns_zone.zone.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azuread_service_principal.dns_challenge[0].object_id
}

# Gather needed informations to store in Kubernetes secret
data "azuread_client_config" "current" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0
}

data "azurerm_subscription" "current" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0
}

data "azurerm_dns_zone" "zone" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  name = var.domain_zone
}

# 2. CLUSTERISSUER
# DNS-01 challenge: https://cert-manager.io/docs/configuration/acme/dns01
resource "kubernetes_secret" "dns_challenge_azuredns" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  metadata {
    name      = "dns-challenge"
    namespace = "cert-manager"
  }

  data = {
    client-id       = azuread_application_registration.dns_challenge[0].client_id
    client-secret   = azuread_application_password.dns_challenge[0].value
    domain-zone     = var.domain_zone
    domain-zone-rg  = data.azurerm_dns_zone.zone.resource_group_name
    subscription-id = data.azurerm_subscription.current.subscription_id
    tenant-id       = data.azuread_client_config.current.tenant_id
  }

  type = "Opaque"
}

data "template_file" "clusterissuer_prod_dns01_azuredns" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  template = file("${path.module}/clusterissuer.dns01.azuredns.yaml")
  vars = {
    certificate_email   = var.certificate_email
    client_id           = kubernetes_secret.dns_challenge[0].data["client-id"]
    subscription_id     = kubernetes_secret.dns_challenge[0].data["subscription-id"]
    tenant_id           = kubernetes_secret.dns_challenge[0].data["tenant-id"]
    domain_zone         = kubernetes_secret.dns_challenge[0].data["domain-zone"]
    resource_group_name = kubernetes_secret.dns_challenge[0].data["domain-zone-rg"]
  }
}

resource "kubectl_manifest" "letsencrypt_prod_dns01_azuredns" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  yaml_body = data.template_file.clusterissuer_prod_dns01_azuredns[0].rendered

  depends_on = [
    helm_release.cert_manager
  ]
}


# 3-2. CERTIFICATE
resource "kubectl_manifest" "certificate" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  yaml_body = data.template_file.certificate.rendered

  depends_on = [kubectl_manifest.letsencrypt_prod_http01[0]]
}
