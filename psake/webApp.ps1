<#
  .DESCRIPTION
    Create a new WebApp from an Azure Container Registry (ACR) image

  .PARAMETER AZURE_RG_NAME
    [string]ENV:AZURE_RG_NAME - The name of the resource group

  .PARAMETER AZURE_ACR_NAME
    [string]ENV:AZURE_ACR_NAME - The name of the Azure Resource Container (ACR)

  .PARAMETER AZURE_ACR_IMAGE_NAME
    [string]ENV:AZURE_ACR_IMAGE_NAME - The name:tag to give the new image in ACR (app:latest)

  .PARAMETER AZURE_WEBAPP_NAME
    [string]ENV:AZURE_WEBAPP_NAME - The name of the webapp to deploy

  .NOTES
    Author: https://github.com/stuartin
#>

include "$PSScriptRoot\shared\sharedPsakeFile.ps1"

task default -depends Test

task Deploy -Depends Test, Setup {
  Write-Output "Logging into ACR..."
  $validAcrName = ($ENV:AZURE_ACR_NAME -replace "[^a-zA-Z0-9]", "").ToLower()
  $command = [ScriptBlock]::Create("
      az acr login --name $validAcrName
  ")   
  exec $command 

  Write-Output "Creating app service plan..."
  $params = @(
    "--name", "$($ENV:ENV_PREFIX)_webapp_plan",   
    "--resource-group", "$ENV:AZURE_RG_NAME"
  )
  $command = [ScriptBlock]::Create("
    az appservice plan create @params
  ")
  exec $command


  Write-Output "Building WebApp..."
  $params = @(
    "--name", "$validAcrName",
    "--plan", "$($ENV:ENV_PREFIX)_webapp_plan",
    "--resource-group", "$ENV:AZURE_RG_NAME", 
    "--deployment-container-image-name", "$validAcrName.azurecr.io/$ENV:AZURE_ACR_IMAGE_NAME"
  )
  $command = [ScriptBlock]::Create("
    az webapp create @params
  ")
  exec $command
  

}



