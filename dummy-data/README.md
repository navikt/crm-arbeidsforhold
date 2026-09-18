# How to use dummy data with SFDX

## Exporting with record types

Always add `RecordType.DeveloperName` to your SOQL query when exporting, if you want to keep the record type intact. A plugin is fixing the record type ID before it is imported to the new scratch org, so you won't have to do a single thing.

## Exporting data from an org

For exporting with lookups, the easiest method is to export the parent and use relationship queries. (e.g., `SELECT Name, RecordType.DeveloperName, (SELECT LastName FROM Contacts) FROM Account`). This command will export your query:

```java
sfdx force:data:tree:export --query "SELECT [fields] FROM [sObject]" --outputdir dummy-data/[name] --plan
```

Use a name for the feature this data is suitable for, OR the name of the object.

Sometimes, you'll need to export from the child with numerous parents (many lookups).

- For the child records
    - `sfdx force:data:tree:export --query "SELECT [fields] FROM [child sObject]" --outputdir dummy-data/[name] --plan`
- For the parents
    - `sfdx force:data:tree:export --query "SELECT [fields] FROM [parent sObject 1]" --outputdir dummy-data/[name]` (remove --plan)
    - `sfdx force:data:tree:export --query "SELECT [fields] FROM [parent sObject 2]" --outputdir dummy-data/[name]` (remove --plan)
    - `sfdx force:data:tree:export --query "SELECT [fields] FROM [parent sObject 3]" --outputdir dummy-data/[name]` (remove --plan)

You'll then **_rename_** `dummy-data/[name]/[Child sObject]s-plan.json` to **ONLY be plan.json** (in the same folder). Then edit the file, and make sure each json file containing data is present in the plan. The plan.json file is the plan for what is imported.

```json
[
    {
        "sobject": "[Parent sObject]",
        "saveRefs": true,
        "resolveRefs": false,
        "files": ["[Parent sObject]s.json"]
    },
    {
        "sobject": "[Child sObject]",
        "saveRefs": false,
        "resolveRefs": true,
        "files": ["[Child sObject]s.json"]
    }
]
```

Because the json file containing data for the parent contains a `referenceId`, `saveRefs` is set to true for the parent above and `resolveRefs` is true for the child, you can have lookup relationships without actual IDs.

That means you'll have to edit `[Child sObject]s.json` (the data for the child records) to include the lookup by having `"[Parent sObject]": "@[Parent sObject]RefX"` (example below). Because `resolveRefs` is set to true on the child sObject, the SFDX import function automatically creates the lookup.

Example `myFeature-plan.json`:

```json
[
    {
        "sobject": "Account",
        "saveRefs": true,
        "resolveRefs": false,
        "files": ["myFeature-Accounts.json"]
    },
    {
        "sobject": "Case",
        "saveRefs": false,
        "resolveRefs": true,
        "files": ["myFeature-Cases.json"]
    }
]
```

Example `myFeature-Accounts.json`:

```json
{
    "records": [
        {
            "attributes": {
                "type": "Account",
                "referenceId": "AccountRef1"
            },
            "BillingState": "Wyoming",
            "ShippingState": "Wyoming",
            "BillingCity": "Cheyenne",
            "ShippingCity": "Cheyenne",
            "Name": "Yadel"
        }
    ]
}
```

Example `myFeature-Cases.json`:

```json
{
    "records": [
        {
            "attributes": {
                "type": "Case",
                "referenceId": "CaseRef1"
            },
            "Account": "@AccountRef1",
            "Name": "My first case"
        }
    ]
}
```

## File and folder structure

**ALWAYS** have dummy-data self-contained in its own folder, both for readability and avoiding overwriting existing data. If you want ALL scratch orgs to have your dummy data, add the data as `dummy-data/[name]/`, which contains ONE `plan.json` file and one or more `[sObjects].json` files, which are also referenced in the plan.sjon.

The init scripts for scratch org creation automatically find these `plan.sjon` files and imports them for you. If you don't want auto importing, have the `plan.sjon` file renamed to anything else, and it won't be imported.

## Importing dummy data

All data is automatically imported using the init scripts for macOS or Windows, as long as they follow the folder structures defined above. See `./scripts/mac/createScratchOrg.command` and `./scripts/windows/createScratchOrg.sh`.

## Test users (`User.json`)

`User.json` is **not** part of `Plan.json` (Record Ids such as `ProfileId` are org-specific, so a `ProfileId` exported from one org would not exist in a freshly created scratch org). Instead, `bin/create-scratch-org.sh` imports it as its own step whenever the `data` post step runs (`--post-steps data`, `--post-steps all`, or the default):

1. Resolves the `Standard User` profile Id dynamically for the target org (no hardcoded Id involved).
2. Imports only the users from `User.json` that don't already exist in the target org (matched by `Username`), so the step is safe to re-run.
3. Assigns the correct permission sets to each user via `sf org assign permset --on-behalf-of`, skipping any assignment that already exists.

`User.json` contains four test users, split by role:

| User                  | Username                     | Role          | Permission sets assigned                                                 |
| --------------------- | ---------------------------- | ------------- | ------------------------------------------------------------------------ |
| Per Saksbehandler 1   | `persaksbehandler1@nav.no`   | Saksbehandler | `AAREG_Arbeidsforhold_Saksbehandling`                                    |
| Hanna Saksbehandler 2 | `hannasaksbehandler2@nav.no` | Saksbehandler | `AAREG_Arbeidsforhold_Saksbehandling`                                    |
| Kari Brukerstøtte 1   | `karibrukerstotte1@nav.no`   | Brukerstøtte  | `AAREG_Arbeidsforhold_Support`, `AAREG_Arbeidsforhold_Support_Read_Only` |
| Ola Brukerstøtte 2    | `olabrukerstotte2@nav.no`    | Brukerstøtte  | `AAREG_Arbeidsforhold_Support`, `AAREG_Arbeidsforhold_Support_Read_Only` |

All four users share the `Standard User` profile; access is granted through permission sets, not the profile. The usernames, profile name and permission set names are all overridable via environment variables — see `./bin/create-scratch-org.sh --help` (`DUMMY_USER_FILE`, `DUMMY_USER_PROFILE_NAME`, `DUMMY_SAKSBEHANDLER_PERMSET`, `DUMMY_SAKSBEHANDLER_USERNAMES`, `DUMMY_SUPPORT_PERMSETS`, `DUMMY_SUPPORT_USERNAMES`).

To run just this step against an already-existing org, without recreating the org or reinstalling packages:

```bash
./bin/create-scratch-org.sh --alias <alias> --post-steps-only --post-steps data
```

`--post-steps-only` is a shortcut for `--skip-org --skip-packages` that runs only the requested post steps (`deploy`, `permsets`, `data`, `community`).
