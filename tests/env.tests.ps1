Set-StrictMode -Version latest

Describe 'BuildEnvironment' {

    Context 'Variables' {
        It "ENV:VAR's should not be null" {

            $ENV:AZURE_SP_USERNAME | Should Not Be $Null
            $ENV:AZURE_SP_PASSWORD | Should Not Be $Null
            $ENV:AZURE_SP_TENANTID | Should Not Be $Null
            $ENV:AZURE_LOCATION | Should Not Be $Null
            $ENV:AZURE_RG_NAME | Should Not Be $Null
            $ENV:AZURE_AKS_SP_USERNAME | Should Not Be $Null
            $ENV:AZURE_AKS_SP_PASSWORD | Should Not Be $Null

        }
    }

}
