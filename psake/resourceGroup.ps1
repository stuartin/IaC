include "$PSScriptRoot\shared\sharedPsakeFile.ps1"

task default -depends Test

task Deploy -Depends Test, Setup {
    Write-Output "Creating Resource Group..."
    $params = @(
        "--name", "$ENV:AZURE_RG_NAME", 
        "--tags", "version=$ENV:ENV_VERSION", "app=$ENV:APP_NAME", "env=$ENV:ENV_TAG"
    )
    az group create @params    
}
