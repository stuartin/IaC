# IaC

Proof of concept.

Use Azure CLI and Azure DevOps to deploy Infrastructure as Code (IaC) in an idempotent and consistent manner.

# Overview

All tests and deployment are handled using the `.\deploy.ps1` file. This will _BootStrap_ the Azure Pipelines vmimage with the required PowerShell Modules defined in requirements.psd1 (using [psdepend](https://github.com/RamblingCookieMonster/PSDepend)) and run whatever [psake](https://github.com/psake/psake) task you need.

The `.\psakeFile.ps1` ensures that any dependent tasks are run first before deployment - such as [pester](https://github.com/pester/Pester) tests and logging into the Azure Subscription.

# Getting Started

The base project will create a new **Resource Group** using a **Service Principal**, extend the `Deploy` Task in the `.\psakeFile.ps1` to extend this workflow.
1. Ensure that a **Service Principal** is created with access to your Azure Subscription.
1. Create a new repo in github (manually), duplicate this one and remove temp folder
    ```PowerShell
    git clone --bare https://github.com/stuartin/IaC.git
    cd IaC.git
    git push --mirror https://github.com/exampleuser/new-repository.git
    cd..
    Remove-Item IaC.git --Recurse --Force
    ```
1. Clone your new github repo and open vscode
    ```PowerShell
    git clone https://github.com/exampleuser/new-repository.git
    cd <new_repository>
    code .
    ```
1. Update `azure-pipelines-dev.yml` and `azure-pipelines-prod.yml` with the below variables based on your app
    ```PowerShell
    APP_NAME: <your_app_name>
    ENV_TAG: <prod / dev>
    ENV_VERSION: <v0.0.1>
    ```
1. Save and commit to Github
    ```PowerShell
    git add *
    git commit -m "set app name and version"
    git push
    ```
1. Repeat the last two steps in the **dev** branch

1. Create a new [Azure DevOps](https://dev.azure.com/) project
1. Create a new **Pipeline** for dev - specify your GitHub repo, use the `azure-pipelines-dev.yml` file in the **dev** branch.
1. Add the **Mandatory Pipeline Variables** and click save/run
1. Rename the pipeline to **IaC - dev** (Pipelines > More Actions > Rename)
1. Create a new **Pipeline** for prod - specify your GitHub repo, use the `azure-pipelines-prod.yml` file. 
1. Add the **Mandatory Pipeline Variables** and click save/run
1. Rename the pipeline to **IaC - prod** (Pipelines > More Actions > Rename)

**IaC - dev** 
> Pipeline will trigger whenever a new commit is added to the **dev** branch.

**IaC - prod**
> Pipeline will trigger whenever a new tag is added to **master** and that tag is referenced inside the `azure-pipelines-prod.yml` file.

# Gitflow

There is a `dev` branch and `master`.
Each branch has a seperate pipeline. Only releases in `master` will be deployed to prod.

# Requirements

## Service Principal

- Open AAD (Azure Active Directory)
- Select **Application Registrations** > **New Registration**

  Name | Value
  --- | ---
  Name | IaC
  Account Type | This org only (single tenant)

- Click **register**, and wait until the application has been created

### Create new secret

- Select **Certificates and Secrets** for the app
- Click **New client secret**
- Provide a description and an expiry date
- **Copy** the secret that is created (this will be your only chance)

### Give Service Principal access to subscription

 - Open **Subscriptions** > **Your subscription**
 - Select **Access Control (IAM)**
 - Select **Role Assignments** > **Add** > **Add Role Assignment**
 - Select **Contributor** and **search** for the newly created Service Principal (IaC)
 - Click **Save**

## Mandatory Pipeline Variables

 Name | Type | Description
 --- | --- | ---
 azure.sp.username | string | The application id from the Service Principal
 azure.sp.password | secret | The secret from the Service Principal
 azure.sp.tenantid | string | The tenant id for where the Service Principal exists

 # Managing Versions/Releases

 To keep track of Infrastructure versions, it is imperative to deploy each resource using a **ENV_PREFIX**, this includes the app name, environment and version that is being deployed. 
 Production releases should always enforce the Infrastructure Version within the `.\azure-pipelines.yml` file.

 ## Production

Production deployments are handled using github releases/tags.

 1. Ensure that all tests and code are working as required.
 1. Update the `.\azure-pipelines-prod.yml` file with with the current release version to publish and any new variables required from `dev`
    ```yaml
    variables:
      APP_NAME: IaC
      ENV_TAG: prod
      ENV_VERSION: v0.0.2
      ENV_PREFIX: $(APP_NAME)_$(ENV_TAG)_$(ENV_VERSION)

    trigger:
      tags:
        include:
        - v0.0.2
    ```
1. Commit or submit a PR to your master branch.
1. Create a new tag/release in your repo that matches the version in the `.\azure-pipelines-prod.yml` file - (_e.g. v0.0.2_)
1. The production environment will be deployed at the specified version

## Development

The dev pipeline will always run when a new commit is detected in the **dev** branch.

## Rollback

If you need to roll back **prod** to a previous release, run the prod release pipeline manually and specify the previous release tag.

1. Select **Pipelines** > **prod** > **Run Pipeline**
1. Enter **master** for the branch and the **release tag** for the commit
1. Click **Run**

