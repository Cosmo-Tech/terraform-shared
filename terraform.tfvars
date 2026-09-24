# ## VARIABLES EXAMPLE FOR AZURE
 cloud_provider        = "azure"
 cluster_region        = "westeurope"
 cluster_name          = "aks-dev-devops-ggon-upgrade4"
 domain_zone           = "azure.platform.cosmotech.com"
azure_subscription_id = "a24b131f-bd0b-42e8-872a-bded9b91ab74"
azure_entra_tenant_id = "e413b834-8be8-4822-a370-be619545cb49"
# azure_subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# azure_entra_tenant_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"


# ## VARIABLES EXAMPLE FOR GCP
# cloud_provider = "gcp"


# ## VARIABLES EXAMPLE FOR AWS
# cloud_provider = "aws"


# ## VARIABLES EXAMPLE FOR KOB (= On-Premise)
# cloud_provider         = "kob"
# cluster_region         = ""
# cluster_name           = "kob-dev-devops"
# domain_zone            = "onpremise.platform.cosmotech.com"
# dns_challenge_provider = "azure"
# state_host             = "https://cosmotechstates.onpremise.platform.cosmotech.com"


## COMMON VARIABLES EXAMPLE
# This email can be any email, it will just be used as the contact email for Let's encrypt
certificate_email = "platform@cosmotech.com"
