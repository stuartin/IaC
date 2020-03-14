<#
  .DESCRIPTION
    Build a docker file from a public git uri and deploys to Azure Container Registry (ACR)

  .PARAMETER AZURE_RG_NAME
    [string]ENV:AZURE_RG_NAME - The name of the resource group

  .PARAMETER AZURE_ACR_NAME
    [string]ENV:AZURE_ACR_NAME - The name of the Azure Container Registry (ACR)

  .PARAMETER AZURE_ACR_IMAGE_NAME
    [string]ENV:AZURE_ACR_IMAGE_NAME - The name:tag to give the new image in ACR (app:latest)

  .PARAMETER GITHUB_URI
    [string]ENV:GITHUB_URI - The uri to the public repo containg a Dockerfile (https://github.com/user/repo.git#master:Subfolder)
  
  .NOTES
    Author: https://github.com/stuartin
#>
include "$PSScriptRoot\shared\sharedPsakeFile.ps1"

$acrName = ($ENV:AZURE_ACR_NAME -replace "[^a-zA-Z0-9]", "").ToLower()

task default -depends Test

task Build -Depends Test, Setup {
    Write-Output "Creating Resource Group..."
    exec {
      az group create `
      --name $ENV:AZURE_RG_NAME `
      --location "australiasoutheast"
    }

    Write-Output "Creating Azure Container Registry..."
    exec {
        az acr create `
        --resource-group $ENV:AZURE_RG_NAME `
        --name $acrName `
        --sku "Basic" `
        --admin-enabled "true"
    }

    Write-Output "Building and deploying new image..."
    # az acr build throws WARNING messages to STDERR output stream (https://github.com/Azure/acr/issues/162)
    # causing exec (psake) to report a failure, unable to use exec to test for success
    # must execute the command outside of exec.
    #
    # or set azure-pipelines.yml with the below config:
    # failOnStderr: true'
    #
    # below does not work
    # $command = [ScriptBlock]::Create("
    #     az acr build @params 2> $null
    # ")   
    # exec $command 

    # the below will redirect STDERR (Error Stream) to $null, command
    # could fail but would report success
    $ErrorActionPreference = 'SilentlyContinue'
    az acr build `
      --registry $acrName `
      --image $ENV:AZURE_ACR_IMAGE_NAME `
      $ENV:GITHUB_URI `
      2> $null
    $ErrorActionPreference = 'Stop'
}
