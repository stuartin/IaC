<#
  .DESCRIPTION
    Build a docker file from a public git uri and deploys to Azure Container Registry (ACR)

  .PARAMETER AZURE_RG_NAME
    [string]ENV:AZURE_RG_NAME - The name of the resource group

  .PARAMETER AZURE_ACR_NAME
    [string]ENV:AZURE_ACR_NAME - The name of the Azure Resource Container (ACR)

  .PARAMETER AZURE_ACR_IMAGE_NAME
    [string]ENV:AZURE_ACR_IMAGE_NAME - The name:tag to give the new image in ACR (app:latest)

  .PARAMETER GITHUB_URI
    [string]ENV:GITHUB_URI - The uri to the public repo (https://github.com/user/repo.git#master:Subfolder)
  
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
    $validAcrName = ($ENV:AZURE_ACR_NAME -replace "[^a-zA-Z0-9]", "").ToLower()
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
        "--registry", "$validAcrName", 
        "--image", "$ENV:AZURE_ACR_IMAGE_NAME",
        "$ENV:GITHUB_URI"
    )

    # acr build throws warning messages to STDERR output stream
    # causing exec to report a failure, unable to use exec to test for success.
    # Just execute the command outside of exec.
    #
    # not likely to be changed: https://github.com/Azure/acr/issues/162
    #
    $ErrorActionPreference = 'SilentlyContinue'
    $command = [ScriptBlock]::Create("
        az acr build @params
    ")   
    exec $command 

    # shows job creation output
    # az acr build @params n>&1

    
    #az acr build @params
    $ErrorActionPreference = 'Stop'
}
