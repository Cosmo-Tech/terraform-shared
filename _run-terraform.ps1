

# Script to run terraform modules
# Usage :
# - ./script.ps1


# Stop script if missing dependency
$required_command = 'terraform'
foreach ($command in $required_command) {
    if (!(Get-Command -errorAction SilentlyContinue -Name $command)) {
        echo "error: required command not found in the PATH: $command"
        exit
    }
}


# Get value of a variable declared in a given file from this pattern: variable = "value"
# Usage: get_var_value <file> <variable>
function get_var_value {
    param($File, $Variable)

    $value = (cat $File | select-string $Variable | select-string '=' | select-string -Pattern '#.*' -NotMatch | select -first 1)
    $value -replace '.*=.*\"(.*)\".*','$1'
}
$cloud_provider = (get_var_value 'terraform.tfvars' 'cloud_provider')
$cluster_region = (get_var_value 'terraform.tfvars' 'cluster_region')
$cluster_name = (get_var_value 'terraform.tfvars' 'cluster_name')
$state_file_name = "tfstate-shared-$cluster_name"

# Generate state_storage_name for Azure backend
# Azure storage account names must be 3-24 chars, lowercase alphanumeric only
$azure_subscription_id = (get_var_value 'terraform.tfvars' 'azure_subscription_id')
$sub_hash = ([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($azure_subscription_id)) | ForEach-Object { $_.ToString("x2") }) -join ''
$sub_hash = $sub_hash.Substring(0, 9)
$state_storage_name = "csmstates$sub_hash"


# Clear old data
rm -Recurse -Confirm:$false .terraform*
rm -Recurse -Confirm:$false terraform.tfstate*


# Automatically detect all the $TEMPLATE variables from a given a file,
# and replace them with the value that the same variable has in the current script.
# Usage: prepare_target_file <source file> <target file>
function prepare_target_file {
    param ([string]$source_file, [string]$target_file)

    if (Test-Path $target_file) { Remove-Item $target_file -Force}
    Copy-Item $source_file $target_file -Force

    $content = Get-Content $target_file -Raw
    $needed_variables = [regex]::Matches($content, 'TEMPLATE_([a-zA-Z_]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    foreach ($var in $needed_variables) {
        # Declare the TEMPLATE_variable
        $value = (Get-Variable -Name $var -ErrorAction SilentlyContinue).Value

        # Replace TEMPLATE with the actual value
        $content = $content -replace [regex]::Escape("`$TEMPLATE_$var"), $value
    }
    $content | Set-Content $target_file
}
$target_file = 'target.tf'


# The trick here is to write configuration in a dynamic file created at the begin of the
# execution, containing the config that the concerned provider is waiting for Terraform backend.
# Then, Terraform will automatically detects it from its .tf extension.
switch ([string]$cloud_provider) {
    "azure" {
        prepare_target_file "targets/$cloud_provider.target.tf" $target_file
    }

    "aws" {
        prepare_target_file "targets/$cloud_provider.target.tf" $target_file
    }

    "gcp" {
        prepare_target_file "targets/$cloud_provider.target.tf" $target_file
    }

    "kob" {
        $state_url = "$(get_var_value terraform.tfvars state_host)/$state_file_name"

        if (([string]::IsNullOrEmpty($TF_HTTP_USERNAME)) -or ([string]::IsNullOrEmpty($TF_HTTP_PASSWORD))) {
            echo "error: empty TF_HTTP_USERNAME or TF_HTTP_PASSWORD (required for backend authentication)"
            echo '  $TF_HTTP_USERNAME = ""'
            echo '  $TF_HTTP_PASSWORD = ""'
            exit
        } else {
            echo "found TF_HTTP_USERNAME & TF_HTTP_PASSWORD"
        }

        $env:TF_CLI_ARGS += ';-lock=false'

        prepare_target_file "targets/$cloud_provider.target.tf" $target_file
    }

    default {
        Write-Host "error: unknown or empty cloud_provider from terraform.tfvars" -ForegroundColor Red
        exit
    }
}


# Deploy
terraform fmt $target_file
terraform init -lock=false -upgrade -reconfigure
terraform plan -lock=false -out .terraform.plan
# terraform apply -lock=false .terraform.plan


echo ''
exit 0
