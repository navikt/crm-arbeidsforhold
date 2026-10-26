# [PUSH] Create Package

|               |                    |
| ------------- | ------------------ |
| **Initiator** | PR Merge           | 
| **Type**      | PAckage Creation   |

# Intro

This workflow runs on pushes to `main` that change `force-app/**`,
`sfdx-project.json` or `.forceignore`, including PR merges. It can also be started
manually. Documentation-only changes do not create packages. It does the following
through the pinned `navikt/crm-workflows-base` implementation:

- Create an unlocked package
- Create a GitHub release
- Verifies the package in SIT sandbox

## Jobs in the pinned shared workflow

- Create Package (`create-package`)
    - The following folders are deleted to avoid packaging unpackagable metadata
        - `./force-app/unpackagable`
        - `./force-app/unpackagable-with-auto-deploy`
        - `./force-app/scratch-org`
    - An unlocked package is created
- Validate install in SIT Sandbox (`validate-in-sit`)
    - The package is installed in the SIT sandbox
    - This is an integration sandbox to test that all of NAV's Salesforce packages can be installed in the same production org
- Create release (`create-release`)
    - Create a GitHub Release denoted a "Pre-release" until the package is promoted for full release
    - Requires successful package creation and SIT validation

## Secrets

- Environment secrets
    - `secrets.CRM_PROD_SFDX_URL`
    - `secrets.CRM_SIT_SFDX_URL`
    - `secrets.CRM_PACKAGE_KEY`
        - Needed to install dependant packages

## Environments

This workflow requires Dev Hub and SIT authentication. It does not deploy to
production or preprod.

The pinned workflow creates the package, validates installation in SIT and creates
a release. It does not contain the previously documented automatic dev/UAT
deployment jobs or their deployment-toggle checks.

Direct source deployment to dev is a separate, manual workflow. See the
[workflow overview](../../../docs/operations/workflows.md) for external
ownership and approval limitations. Local checks do not execute package creation,
SIT installation or release creation.