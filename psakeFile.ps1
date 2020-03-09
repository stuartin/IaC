task default -depends Test

task Test {
    Invoke-Pester "$PSScriptRoot\tests"
}

task Setup -Depends Test {
    Write-Output "Setting Azure CLI defaults..."
    Write-Output "AZURE LOCATION: $ENV:AZURE_LOCATION"
    Write-Output "AZURE LOCATION: $ENV:AZURE_ACR_NAME"

    $defaults = @(
        "location=$ENV:AZURE_LOCATION", 
        "acr=$ENV:AZURE_ACR_NAME"
    )

    az configure --defaults @defaults
    az configure --list-defaults
}

task Deploy -Depends Test, Setup {
    Write-Output "Creating Resource Group..."
    $params = @(
        "--name", "$ENV:AZURE_RG_NAME", 
        "--tags", "test2"
    )
    az group create @params

    #az appservice plan create --name $(appserviceplan)  --resource-group $(resourceGroupName) --sku FREE
    #az webapp create --name $(apiapp) --resource-group $(resourceGroupName) --plan $(appserviceplan) 
    #az webapp identity assign -g $(resourceGroupName)  -n $(apiapp)
    #az keyvault create --location "$(location)" --name $(keyvault) --resource-group $(resourceGroupName)
    
    
    #az keyvault set-policy --name  $(keyvault) --object-id %spID% --secret-permissions get  --key-permissions get
    
}
