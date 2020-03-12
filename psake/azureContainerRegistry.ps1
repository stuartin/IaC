<#
  .DESCRIPTION
    Build a docker file from a public git uri and deploys to Azure Container Registry (ACR)

  .PARAMETER AZURE_RG_NAME
    [string]ENV:AZURE_RG_NAME - The name of the resource group

  .PARAMETER AZURE_ACR_NAME
    [string]ENV:AZURE_ACR_NAME - The name of the Azure Resource Container (ACR)
            Must conform to ^[a-zA-Z0-9]*$

  .PARAMETER AZURE_ACR_IMAGE_NAME
    [string]ENV:AZURE_ACR_IMAGE_NAME - The name:tag to give the new image in ACR (app:latest)

  .PARAMETER GITHUB_URI
    [string]ENV:GITHUB_URI - The uri to the (https://github.com/user/repo.git#master:Subfolder)
  
  .NOTES
    Author: https://github.com/stuartin
#>
$ErrorActionPreference = 'Stop'
include "$PSScriptRoot\shared\sharedPsakeFile.ps1"

task default -depends Test

task Deploy -Depends Test, Setup {
    Write-Output "Creating Resource Group..."
    $params = @(
        "--name", "$ENV:AZURE_RG_NAME", 
        "--tags", "version=$ENV:ENV_VERSION", "app=$ENV:APP_NAME", "env=$ENV:ENV_TAG"
    )
    az group create @params

    Write-Output "Creating Azure Container Registry..."
    $params = @(
        "--resource-group", "$ENV:AZURE_RG_NAME", 
        "--name", "$ENV:AZURE_ACR_NAME",
        "--sku", "Basic"
    )
    az acr create @params

    Write-Output "Logging into ACR..."
    az acr login --name $ENV:AZURE_ACR_NAME

    Write-Output "Building and deploying new image..."
    $params = @(
        "--registry",
        "--acrName", "$ENV:AZURE_ACR_NAME", 
        "$ENV:GITHUB_URI",
        "--image", "$ENV:AZURE_ACR_IMAGE_NAME"
    )
    az acr build create @params

}
