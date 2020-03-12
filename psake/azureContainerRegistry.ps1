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
    exec az group create @params

    Write-Output "Creating Azure Container Registry..."
    $validAcrName = $ENV:AZURE_ACR_NAME -replace "[^a-zA-Z0-9]", ""
    $params = @(
        "--resource-group", "$ENV:AZURE_RG_NAME", 
        "--name", "$validAcrName",
        "--sku", "Basic"
    )
    exec az acr create @params

    Write-Output "Logging into ACR..."
    exec az acr login --name $validAcrName

    Write-Output "Building and deploying new image..."
    $params = @(
        "--registry",
        "--acrName", "$validAcrName", 
        "$ENV:GITHUB_URI",
        "--image", "$ENV:AZURE_ACR_IMAGE_NAME"
    )
    exec az acr build create @params

}
