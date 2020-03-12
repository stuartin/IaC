include "$PSScriptRoot\shared\sharedPsakeFile.ps1"

task default -depends Test

task Deploy -Depends Test, Setup {
    Write-Output "Creating Resource Group..."
    $params = @(
        "--name", "$ENV:AZURE_RG_NAME", 
        "--tags", "version=$ENV:ENV_VERSION", "app=$ENV:APP_NAME", "env=$ENV:ENV_TAG"
    )
    az group create @params

    #az appservice plan create --name $(appserviceplan)  --resource-group $(resourceGroupName) --sku FREE
    #az webapp create --name $(apiapp) --resource-group $(resourceGroupName) --plan $(appserviceplan) 
    #az webapp identity assign -g $(resourceGroupName)  -n $(apiapp)
    #az keyvault create --location "$(location)" --name $(keyvault) --resource-group $(resourceGroupName)
    
    
    #az keyvault set-policy --name  $(keyvault) --object-id %spID% --secret-permissions get  --key-permissions get
    
}
