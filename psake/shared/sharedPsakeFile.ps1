task Test {
    Invoke-Pester "..\tests"
}

task Setup {
    Write-Output "Setting Azure CLI defaults..."

    which az
    whereis az

    # update .config file
    $configFile = "$AZURE_CONFIG_DIR/config"
    $pattern = '\[core]'
    $replace = "[core]`r`noutput=table"

    (Get-Content -Path $configFile -Raw) -replace $pattern,$replace | Set-Content -Path $configFile

    # set cli defaults
    $defaults = @(
        "location=$ENV:AZURE_LOCATION"
    )
    az configure --defaults @defaults
    az configure --list-defaults
    
    Write-Output "Logging into Azure environment..."
    $params = @(
        "--service-principal"
        "--username", "$ENV:AZURE_SP_USERNAME",
        "--password", "$ENV:AZURE_SP_PASSWORD",
        "--tenant", "$ENV:AZURE_SP_TENANTID"
    )
    az login @params
    
}