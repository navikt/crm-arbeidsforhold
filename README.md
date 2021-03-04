Template repository for CRM packages. Necessary steps after using template:

1. Add secrets (see [description](https://github.com/navikt/crm-workflows-base))
    - PROD_SFDX_URL `[REQUIRED]` (contact #crm-platform-team on Slack)
    - PREPROD_SFDX_URL `[REQUIRED]` (contact #crm-platform-team on Slack)
    - INTEGRATION_SANDBOX_SFDX_URL `[REQUIRED]` (contact #crm-platform-team on Slack)
    - PACKAGE_KEY `[REQUIRED]`
    - DEPLOYMENT_PAT `[REQUIRED]` ([documentation](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token), give repo access)
    - UAT_SFDX_URL `[OPTIONAL]`
    - DEV_SFDX_URL `[OPTIONAL]`
    - DEPLOY_TO_DEV_AFTER_PACKAGE_CREATION `[OPTIONAL]`
    - DEPLOY_TO_UAT_AFTER_PACKAGE_CREATION `[OPTIONAL]`
2. Create an init release in GitHub (not pre-release)
    - Important! Release creation will fail if an init release has not been made!
3. Create file `.sfdx/sfdx-config.json` (to create package)
    - Add `{"defaultdevhubusername": "[your_devhub_user]","defaultusername": "" }` to it and change the DevHub username
4. Create a package in SFDX
    - `sfdx force:package:create -n YourPackageName -t Unlocked -r force-app`
    - If you receive an error, contact #crm-platform-team on Slack to create the package
5. Create an test metadata file in `force-app` folder to initiate init package creation (can be just a CustomLabel file)
6. Push changes made to `force-app` and `sfdx-project.json` (remember to fetch Package ID if #crm-platform-team creates the package)

# crm-shared-template

[![Build](https://github.com/navikt/XXXXXXXXXXXXX/workflows/%5BPUSH%5D%20Create%20Package/badge.svg)](https://github.com/navikt/XXXXXXXXXXXXX/actions?query=workflow%3Acreate)
[![GitHub version](https://badgen.net/github/release/navikt/XXXXXXXXXXXXX/stable)](https://github.com/navikt/XXXXXXXXXXXXX)
[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/navikt/XXXXXXXXXXXXX/blob/master/LICENSE)

## Dependencies

This package is dependant on the following packages

-   [XXXXXXXXXXXXX](https://github.com/navikt/XXXXXXXXXXXXX)
-   [XXXXXXXXXXXXX](https://github.com/navikt/XXXXXXXXXXXXX)

## Installation

1. Install [npm](https://nodejs.org/en/download/)
1. Install [Salesforce DX CLI](https://developer.salesforce.com/tools/sfdxcli)
    - Alternative: `npm install sfdx-cli --global`
1. Clone this repository ([GitHub Desktop](https://desktop.github.com) is recommended for non-developers)
1. Run `npm install` from the project root folder
1. Install [SSDX](https://github.com/navikt/ssdx)
    - **Non-developers may stop after this step**
1. Install [VS Code](https://code.visualstudio.com) (recommended)
    - Install [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
    - **Install recommended plugins!** A notification should appear when opening VS Code. It will prompt you to install recommended plugins.
1. Install [AdoptOpenJDK](https://adoptopenjdk.net) (only version 8 or 11)
1. Open VS Code settings and search for `salesforcedx-vscode-apex`
1. Under `Java Home`, add the following:
    - macOS: `/Library/Java/JavaVirtualMachines/adoptopenjdk-[VERSION_NUMBER].jdk/Contents/Home`
    - Windows: `C:\\Program Files\\AdoptOpenJDK\\jdk-[VERSION_NUMBER]-hotspot`

## Other

Questions? Ask on #crm-platform-team on Slack.
