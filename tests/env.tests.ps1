Set-StrictMode -Version latest

Describe 'BuildEnvironment' {

    Context 'Variables' {
        It "ENV:VAR's should not be null" {

            $ENV:AZURE_LOCATION | Should Not Be $Null
            $ENV:AZURE_ACR_NAME | Should Not Be $Null

        }
    }

}
