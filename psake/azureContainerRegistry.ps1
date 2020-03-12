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
        "--location", "australiasoutheast"
    )
    $command = [ScriptBlock]::Create("
      az group create @params
    ")
    exec $command

    Write-Output "Creating Azure Container Registry..."
    $validAcrName = $ENV:AZURE_ACR_NAME -replace "[^a-zA-Z0-9]", ""
    $params = @(
        "--resource-group", "$ENV:AZURE_RG_NAME", 
        "--name", "$validAcrName",
        "--sku", "Basic"
    )
    $command = [ScriptBlock]::Create("
      az acr create @params
    ")
    exec $command

    Write-Output "Logging into ACR..."
    $command = [ScriptBlock]::Create("
      az acr login --name $validAcrName
    ")   
    exec $command 

    Write-Output "Building and deploying new image..."
    $params = @(
        "--registry",
        "--acrName", "$validAcrName", 
        "$ENV:GITHUB_URI",
        "--image", "$ENV:AZURE_ACR_IMAGE_NAME"
    )
    $command = [ScriptBlock]::Create("
      az acr build create @params
    ")   
    exec $command 
    

}
