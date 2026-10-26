# [PUSH] Deploy to Dev

|               |                              |
| ------------- | ---------------------------- |
| **Initiator** | Manual                       |
| **Type**      | Source Deploy                |

# Intro

This workflow runs only through `workflow_dispatch` with `main` selected in
GitHub. Dispatches on other branches skip the deployment job before checkout or
authentication. It does not run automatically on `main` or `dev`.

It authenticates the existing Dev Hub and dev sandbox, then reuses
`bin/create-scratch-org.sh --no-config --alias dev --update-packages --skip-version-check`
to install missing or outdated manifest dependencies. This mode neither creates
nor deletes an org and does not run scratch-org post-steps. The installation key
is supplied through `PACKAGE_INSTALL_KEY`, not through step outputs.

Finally, `sf project deploy start` deploys `force-app` to `dev` with
`RunLocalTests` and waits up to 60 minutes. A failed dependency update or deployment
fails the job. Direct source deployments from this workflow are serialized.
No org operation is performed by the local workflow regression tests.

## Secrets

- Environment secrets
    - `secrets.CRM_PROD_SFDX_URL`
    - `secrets.DEV_SFDX_URL`
    - `secrets.CRM_PACKAGE_KEY`
        - Needed to install dependant packages

The Dev Hub authentication is for dependency resolution, not a production deployment.
See the [workflow overview](../../../docs/operations/workflows.md) for
external ownership, approval limitations and remaining shared-workflow issues.