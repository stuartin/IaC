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
  Write-Output "Building WebApp based on image..."
  $validAcrName = ($ENV:AZURE_ACR_NAME -replace "[^a-zA-Z0-9]", "").ToLower()
  $params = @(
    "--name", "$validAcrName",   
    "--registry-rg", "$ENV:AZURE_RG_NAME", 
    "--registery-name", "$ENV:AZURE_ACR_NAME",
    "--docker-custom-image-name", "$ENV:AZURE_ACR_IMAGE_NAME",
    "$ENV:GITHUB_URI"
  )
  $command = [ScriptBlock]::Create("
      az webapp container up @params
  ")
  exec $command
  

}



