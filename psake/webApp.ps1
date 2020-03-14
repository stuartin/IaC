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

$acrName = ($ENV:AZURE_ACR_NAME -replace "[^a-zA-Z0-9]", "").ToLower()
$webAppName = ("$($ENV:ENV_PREFIX)-webapp" -replace "[^a-zA-Z0-9-]", "").ToLower()
$appServicePlanName = ("$($ENV:ENV_PREFIX)-webapp-plan" -replace "[^a-zA-Z0-9-]", "").ToLower()
$acrImagePath = "$acrName.azurecr.io/$ENV:AZURE_ACR_IMAGE_NAME"
[System.Uri]$webAppUrl = "https://$webAppName.azurewebsites.net/"

task default -depends Test

task Deploy -Depends Test, Setup {
  Write-Output "Getting ACR settings..."  
  $command = [ScriptBlock]::Create("
    az acr credential show --name $acrName --output json
  ")
  $json = exec $command

  $acrUsername = ($json | ConvertFrom-Json).username
  $acrPassword = ($json | ConvertFrom-Json).passwords[0].value

  Write-Output "Creating app service plan..."
  $params = @(
    "--name", "$appServicePlanName",   
    "--resource-group", "$ENV:AZURE_RG_NAME",
    "--sku", "F1",
    "--is-linux"
  )
  $command = [ScriptBlock]::Create("
    az appservice plan create @params
  ")
  exec $command

  Write-Output "Building WebApp connected to ACR..."
  $params = @(
    "--name", "$webAppName",
    "--plan", "$appServicePlanName",
    "--resource-group", "$ENV:AZURE_RG_NAME", 
    "--deployment-container-image-name", "$acrImagePath"
    "--docker-registry-server-user", "$acrUsername",
    "--docker-registry-server-password", "$acrPassword"
  )
  $command = [ScriptBlock]::Create("
    az webapp create @params
  ")
  exec $command

  Write-Output "Configuring web app to use ACR image..."
  $params = @(
    "--name", "$webAppName",
    "--resource-group", "$ENV:AZURE_RG_NAME", 
    "--docker-custom-image-name", "$acrImagePath"
  )
  $command = [ScriptBlock]::Create("
    az webapp config container set @params
  ")
  exec $command

  Write-Output "Waiting for webapp to load..."
  $pollEverySeconds = 5
  $pollTimeoutSeconds = 600 # 10 Minutes
  $waitTime = 0
  $siteResponse = Invoke-WebRequest -Uri $webAppUrl.Host -UseBasicParsing -DisableKeepAlive -Method Head -ErrorAction SilentlyContinue
  while ( -not ($siteResponse) -and $siteResponse.StatusCode -ne 200 -and $WaitTime -lt $PollTimeoutSeconds) {
      Start-Sleep -Seconds $PollEverySeconds
      $WaitTime += $PollEverySeconds
      $siteResponse = Invoke-WebRequest -Uri $webAppUrl.Host -UseBasicParsing -DisableKeepAlive -Method Head -ErrorAction SilentlyContinue
  }
  
  Write-Output "Up!"

}
