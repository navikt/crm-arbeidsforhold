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
    - Basic `sfdx force:package:version:promote`
- Install Package in Preprod (`install-package-preprod`)
    - Basic `sfdx force:package:install`
- Push new version number to master (`push-new-version-number-to-master`)
    - Uses [navikt/github-action-sfdx-version-updater](https://github.com/navikt/github-action-sfdx-version-updater) (GitHub Actions plugin) to update the version number in `sfdx-project.json` (e.g., 1.7.0 => 1.8.0)
    - Creates a pull request from `auto/package-version-update` for the version number update.
    - After a manually dispatched promotion run on `main` completes, the local `promotion-auto-merge.yml` workflow enables squash auto-merge only for open, non-draft, same-repository PRs to `main` whose entire diff changes only the main package's `versionNumber`. It executes trusted base code, never PR code.
    - It runs after failed promotion runs too: the shared workflow's one-shot merge attempt can fail while waiting for review. It does not retry promotion or any Salesforce operation.
    - Auto-merge requires the repository's **Allow auto-merge** setting. Required reviews and status checks remain enforced; no admin bypass is used by the local workflow.
    - Pure version updates skip Salesforce scratch-org validation but retain the LWC and formatting checks. Dependency, metadata, API-version, and other configuration changes still require Salesforce validation.
    - The shared promotion workflow still makes its existing one-shot merge attempt using the token described below; that external implementation is not changed here.
    - GitHub may require a user with write access to approve PR workflow runs created by `GITHUB_TOKEN` before required checks can run. See [GitHub's workflow triggering documentation](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow).
    - The shared workflow's PAT-based merge attempt must be reviewed separately: the local workflow cannot prevent that attempt or guarantee that the token cannot bypass branch protection.
- Create GitHub Release (`create-release`)
    - Contains the version number, package ID, code coverage, changelog, author and basic description of changes

## Secrets

- Environment secrets
    - `secrets.CRM_PROD_SFDX_URL`
    - `secrets.CRM_PREPROD_SFDX_URL`
    - `secrets.CRM_PACKAGE_KEY`
        - Needed to install dependant packages
    - `secrets.CRM_DEPLOYMENT_PAT`
        - Used by the shared promotion workflow's existing one-shot merge attempt.
        - The local auto-merge workflow uses `GITHUB_TOKEN` instead and does not request an admin bypass.
        - [Create a PAT](https://docs.github.com/en/enterprise/2.17/user/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) with "REPO" access to get a working secret
