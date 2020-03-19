<#
  .DESCRIPTION
    Create a new Kubernetes Cluster Service (AKS) from an Azure Container Registry (ACR) image

  .PARAMETER AZURE_RG_NAME
    [string]ENV:AZURE_RG_NAME - The name of the resource group

  .PARAMETER AZURE_ACR_NAME
    [string]ENV:AZURE_ACR_NAME - The name of the Azure Container Registry (ACR)

  .PARAMETER AZURE_ACR_IMAGE_NAME
    [string]ENV:AZURE_ACR_IMAGE_NAME - The name:tag to give the new image in ACR (app:latest)

  .PARAMETER AZURE_AKS_SP_USERNAME
    [string]ENV:AZURE_AKS_SP_USERNAME - The username (clientId) for the AKS SP
  
  .PARAMETER AZURE_AKS_SP_PASSWORD
    [SecureString]ENV:AZURE_AKS_SP_PASSWORD - The password (secret) for the AKS SP

  .NOTES
    Author: https://github.com/stuartin
#>
include "$PSScriptRoot\shared\sharedPsakeFile.ps1"

$acrName = ($ENV:AZURE_ACR_NAME -replace "[^a-zA-Z0-9]", "").ToLower()
$aksName = ("$($ENV:ENV_PREFIX)-aks" -replace "[^a-zA-Z0-9-]", "").ToLower()
$acrImagePath = "$acrName.azurecr.io/$ENV:AZURE_ACR_IMAGE_NAME"

task default -depends Test

task Deploy -Depends Test, Setup {
  Write-Output "Assign AKS SP permission to ACR..."
  $json = exec {
    az ad sp list --output json
  }
  $assignee = ($json | ConvertFrom-Json) | Where-Object {$_.appId -eq $ENV:AZURE_AKS_SP_USERNAME}

  $acrId = exec {
    az acr show `
        --name $acrName `
        --resource-group $ENV:AZURE_RG_NAME `
        --query "id" `
        --output tsv
  }

  exec {
    az role assignment create `
    --assignee-object-id $assignee.objectId `
    --role 'Contributor' `
    --scope $acrId
  }

  Write-Output "Creating Azure Kubernetes Service (AKS)..."
  # az cli throws warnings to stderr can't use exec
  $ErrorActionPreference = 'SilentlyContinue'
  az aks create `
    --name $aksName `
    --resource-group $ENV:AZURE_RG_NAME `
    --generate-ssh-keys `
    --enable-addons monitoring `
    --attach-acr $acrName `
    --service-principal $ENV:AZURE_AKS_SP_USERNAME `
    --client-secret $ENV:AZURE_AKS_SP_PASSWORD `
    --verbose
  $ErrorActionPreference = 'Stop'

  Write-Output "Fetching AKS credentials..."
  exec {
    az aks get-credentials `
      --name $aksName `
      --resource-group $ENV:AZURE_RG_NAME
  }
  
  Write-Output "Using .\services\aks\app.yml to generate AKS app template..."
  ((Get-Content -path "$PSScriptRoot\services\aks\app.yml" -Raw) -replace '@@acrImagePath@@',$acrImagePath) | Set-Content -Path "$PSScriptRoot\services\aks\app.yml"

  Write-Output "Running AKS deployment..."
  exec {
    kubectl apply -f "$PSScriptRoot\services\aks\app.yml"
  }

  Write-Output "Pod Status:"
  exec {
    kubectl get pods
  }
  
}