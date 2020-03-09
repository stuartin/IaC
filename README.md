# IaC

# Requirements

## Service Principal

- Open AAD (Azure Active Directory)
- Select Application Registrations > New Registration

  Name | Value
  --- | ---
  Name | Azure Pipelines App
  Account Type | This org only (single tenant)

- Click register, and wait until the application has been created
- Select Certificates and Secrets for the app
- Click New client secret
- Provide a description and an expiry date
- Copy the secret that is created

## Pipeline Variables

 Name | Type | Description
 --- | --- | ---
 AZURE_SP_USERNAME | string | The application id from the Service Principal
 AZURE_SP_PASSWORD | secure_string | The secret from the Service Principal
