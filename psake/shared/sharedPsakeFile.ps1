#task default -depends Test

task Test {
    Invoke-Pester "..\tests"
}

task Setup {
    Write-Output "Logging into Azure environment..."
    $params = @(
        "--service-principal"
        "--username", "$ENV:AZURE_SP_USERNAME",
        "--password", "$ENV:AZURE_SP_PASSWORD",
        "--tenant", "$ENV:AZURE_SP_TENANTID"
    )
    az login @params
    
    Write-Output "Setting Azure CLI defaults..."
    $defaults = @(
        "location=$ENV:AZURE_LOCATION"
    )
    az configure --defaults @defaults
    az configure --list-defaults

    
}