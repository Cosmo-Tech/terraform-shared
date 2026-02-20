# Terraform module: `chart_superset`

This module installs **Apache Superset** on a Kubernetes cluster using the **Helm** provider, and provisions the Kubernetes objects Superset needs to start (notably secrets and a config map).

It is designed to be consumed from a “cluster bootstrap” Terraform stack (like the root of this repository), once your Kubernetes cluster is reachable by Terraform.

---

## What this module does

When applied, the module will:

- Generate random credentials/keys used by Superset and its dependencies
- Create Kubernetes `Secret` objects for:
    - Superset admin/secret key material
    - Redis authentication
    - PostgreSQL authentication
    - A “guest token” secret used for embedded/dashboard access scenarios
    - A “Superset secret key” secret used for signing the session cookie (Flask App Builder configuration)
- Create a Kubernetes `ConfigMap` containing a `superset_config.py` (templated for your cluster domain)
- Deploy the Superset Helm chart (from the repository/chart/version you provide), using a templated `values.yaml`

---

## Requirements

- A working Kubernetes cluster
- Terraform providers configured in the calling stack:
    - `hashicorp/helm`
    - `hashicorp/kubernetes`
    - `hashicorp/random`
---

## Inputs

| Name | Type | Required | Description                                                                            |
|------|------|----------|----------------------------------------------------------------------------------------|
| `namespace` | `string` | yes | Kubernetes namespace where Superset will be installed.                                 |
| `superset_cluster_domain` | `string` | yes | DNS name used to build Superset URLs/ingress hostnames (passed into chart templating). |
| `cluster_domain` | `string` | yes | DNS name used to build frame-ancestors authorized URLs (passed into chart templating). |
| `helm_repo` | `string` | yes | Helm repository URL (e.g. `https://charts.bitnami.com/bitnami`).                       |
| `helm_chart` | `string` | yes | Helm chart name (e.g. `superset`).                                                     |
| `helm_chart_version` | `string` | yes | Helm chart version to install.                                                         |

---

## Outputs

This module does not declare explicit Terraform outputs.

If you need the generated credentials, consider adding outputs in your own fork (be cautious: outputting secrets may expose them in state/CI logs).

---

## Usage

Please refer to the "How to" section in the root README.

## Oauth providers configuration

A list of oauth providers can be defined in a dedicated config map name `superset-oauth-providers`.
The `superset-oauth-providers` configmap should have a data entry named `oauth-providers` containing a JSON array with all desired oauth providers.
Please refer to Superset documentation for more information about oauth providers configuration.
https://superset.apache.org/docs/configuration/configuring-superset/#custom-oauth2-configuration

Example:
```json
[
  {
    "name": "oauth_provider1",
    "icon": "fa-key",
    "token_key": "access_token",
    "remote_app": {
      "client_id": "<oauth_provider1_client_id>",
      "client_secret": "<oauth_provider1_client_secret>",
      "client_kwargs": {"scope": "openid profile email"},
      "server_metadata_url": "https://<oauth_provider1_url>/.well-known/openid-configuration"
    }
  },
  {
    "name": "oauth_provider2",
    "icon": "fa-key",
    "token_key": "access_token",
    "remote_app": {
      "client_id": "<oauth_provider2_client_id>",
      "client_secret": "<oauth_provider2_client_secret>",
      "client_kwargs": {"scope": "openid profile email"},
      "server_metadata_url": "https://<oauth_provider2_url>/.well-known/openid-configuration"
    }
  }
]
```

### Notes:

If you want to add a new oauth provider, you need to:
- Add the new provider in the `superset-oauth-providers` configmap
- Restart the `superset-web` pod