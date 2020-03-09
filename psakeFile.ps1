task default -depends Test

task Test {
    Write-Output "------- WRITE TESTS TO EXECUTE AND UPDATE TEST TASK -------"
    Invoke-Pester "$PSScriptRoot\tests"
}

task Setup -Depends Test {
    # setup azure cli
    $defaults = @(
        "--location", "$ENV:AZURE_LOCATION", # default geo location
        "--acr", "$ENV:AZURE_ACR_NAME" # default acr (azure container registry) name
    )

    #az configure --defaults @defaults
}

task Deploy -Depends Test, Setup {

    # deploy resource group
    $params = @(
        "--name", "test", 
        "--tags", "test2"
    )
    #az group create @params
    #az appservice plan create --name $(appserviceplan)  --resource-group $(resourceGroupName) --sku FREE
    #az webapp create --name $(apiapp) --resource-group $(resourceGroupName) --plan $(appserviceplan) 
    #az webapp identity assign -g $(resourceGroupName)  -n $(apiapp)
    #az keyvault create --location "$(location)" --name $(keyvault) --resource-group $(resourceGroupName)
    
    
    #az keyvault set-policy --name  $(keyvault) --object-id %spID% --secret-permissions get  --key-permissions get
    
}
