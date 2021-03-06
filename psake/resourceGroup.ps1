<#
  .DESCRIPTION
    Create a new resource group

  .PARAMETER AZURE_RG_NAME
    [string]ENV:AZURE_RG_NAME - The name of the resource group
  
  .NOTES
    Author: https://github.com/stuartin
#>
include "$PSScriptRoot\shared\sharedPsakeFile.ps1"

task default -depends Test

task Build -Depends Test, Setup {
    Write-Output "Creating Resource Group..."
    exec {
      az group create `
        --name $ENV:AZURE_RG_NAME `
        --tags version=$ENV:ENV_VERSION,app=$ENV:APP_NAME,env=$ENV:ENV_TAG
    }
}
