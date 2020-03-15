FormatTaskName {
    param($taskName)
    write-host "Executing Task: $taskName" -ForegroundColor blue
 }

task Test {
    Invoke-Pester "..\tests"
}

task Setup {
    Write-Output "Setting Azure CLI defaults..."

    # update .config file
    $configFile = "$HOME/.azure/config"
    $pattern = '\[core]'
    $replace = "[core]`r`noutput=table"

    if (-not (Test-Path -Path $configFile)) {
        New-Item -Type File -Path $configFile -Value $replace -Force | Out-Null
    } else {
        (Get-Content -Path $configFile -Raw) -replace $pattern,$replace | Set-Content -Path $configFile
    }  

    # set cli defaults
    az configure --defaults  "location=$ENV:AZURE_LOCATION"
    az configure --list-defaults
    
    Write-Output "Logging into Azure environment..."
    exec { 
      az login `
        --service-principal `
        --username $ENV:AZURE_SP_USERNAME `
        --password $ENV:AZURE_SP_PASSWORD `
        --tenant $ENV:AZURE_SP_TENANTID
    }
}

task AddServicePrincipal {
    param($name, $role, $scope)

    Write-Output "Creating new service principal..."
    Write-Output "Name: $name"
    Write-Output "Role: $role"
    Write-Output "Scope: $scope"

    $json = exec { 
      az ad sp create-for-rbac `
        --scopes $scope `
        --role $role `
        --name $name `
        --output json
    }

    $Script:spUser = $json.appId
    $Script:spPassword = $json.password
    
}