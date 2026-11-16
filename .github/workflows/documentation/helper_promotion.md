# [HELPER] Promotion

|               |                   |
| ------------- | ----------------- |
| **Initiator** | Manual            |
| **Type**      | Package Promotion |

# Intro

This workflows does the following:

- Promotes an unlocked package
- Creates a new GitHub Release
- Adjusts the version number on the minor
    - 1.7.0 would become 1.8.0
- Installs the package in preprod

## Input

- Package ID
    - 18 digit Unlocked Package ID (or even managed packages)
    - Can be found from the Release page on each GitHub repository
- Description field used in the GitHub Release

## Jobs

- Debug Information (`debug`)
    - Prints the input information (in case you forgot).
- Promote Package (`promote-package`)
    - Promotes the package in production after the PREPROD installation succeeds.
- Install Package in Preprod (`install-package-preprod`)
    - Basic `sfdx force:package:install`
- Install Package in UAT (`install-package-uat`)
    - Installs the package in UAT, independently of the PREPROD promotion gate.
- Create version update pull request (`push-new-version-number`)
    - Uses the pinned package version updater to update `sfdx-project.json` (e.g., 1.7.0 => 1.8.0).
    - Creates a pull request from `auto/package-version-update` for the version number update.
    - The local workflow enables squash auto-merge for that PR using `GITHUB_TOKEN`. GitHub still enforces the required reviews and status checks; the workflow does not use a PAT or request an admin bypass.
    - Pure version updates skip Salesforce scratch-org validation but retain the LWC and formatting checks. Dependency, metadata, API-version, and other configuration changes still require Salesforce validation.
    - GitHub may require a user with write access to approve PR workflow runs created by `GITHUB_TOKEN` before required checks can run. See [GitHub's workflow triggering documentation](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow).
- Create GitHub Release (`create-release`)
    - Contains the version number, package ID, code coverage, changelog, author and basic description of changes

## Secrets

- Environment secrets
    - `secrets.CRM_PROD_SFDX_URL`
    - `secrets.CRM_PREPROD_SFDX_URL`
    - `secrets.CRM_UAT_SFDX_URL`
    - `secrets.CRM_PACKAGE_KEY`
        - Needed to install dependant packages

The local [package-promotion.yml](../package-promotion.yml) owns the promotion
sequence and PR auto-merge. The caller only runs it when manually dispatched
from `main`. It continues to call the pinned shared
`deployPackage.yml` workflow for PREPROD and UAT installation and the shared
Salesforce CLI install, authentication and version-update actions. Those
external dependencies remain owned by `navikt/crm-workflows-base`.

## Version-update handoff

The promotion workflow waits for the generated version-update PR to merge. Since
that PR uses `GITHUB_TOKEN`, its merge does not trigger the `push`-based package
creation workflow. After confirming the merge and expected PR head, promotion
explicitly dispatches `push_create-package1.yml` on `main`. The wait is limited
to 350 minutes; if the PR is closed without merging or is not merged before the
timeout, the promotion job fails without dispatching package creation.

The GitHub Release action targets `github.sha`, keeping a newly created release
tag on the same commit that the promotion workflow checked out.

If a person merges the version-update PR manually, the promotion workflow skips
the explicit dispatch and relies on the normal `push` trigger. For bot merges,
it checks for an existing package-creation run for the merge commit before
dispatching, avoiding a duplicate build and SIT installation.
