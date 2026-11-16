# Implementation plan

## Phase 1: Mapping and clarification

### Goals for phase 1

- clarify which user groups need separate paths,
- define which functions should be hidden or visible for each group,
- clarify how representation context should be handled for employers, partners, and private individuals.

### Areas affected in phase 1

- [force-app/externalAccess/lwc/aareg_home/aareg_home.js](../force-app/externalAccess/lwc/aareg_home/aareg_home.js)
- [force-app/externalAccess/classes/AAREG_HomeController.cls](../force-app/externalAccess/classes/AAREG_HomeController.cls)
- [force-app/dialog/classes/AAREG_MyThreadsController.cls](../force-app/dialog/classes/AAREG_MyThreadsController.cls)

### Tests

- verify existing behavior for company representatives,
- document expected behavior for each new user group per field.

## Phase 2: ACR and email model for representative relationships

### Goals for phase 2

- use ACR as the only valid source for the relationship between a person and an organization,
- define which roles should be interpreted as employer, partner, and self,
- determine how email is stored and retrieved in Salesforce without relying on UI state alone.

### Areas affected in phase 2

- `AccountContactRelation`
- person/contact model in Salesforce,
- email field or a small AAREG-specific email table,
- Apex helper for resolving relevant contact and email based on the selected context.

### Tests for phase 2

- verify correct ACR matching for employer, partner, and self,
- verify that expired or inactive ACR records are ignored,
- verify that relevant email is retrieved without using `LastUsedOrganization__c` as the only source.

## Phase 3: Shared entry page and context selection

### Goals for phase 3

- build a small new entry page that handles user-group selection,
- preserve the current `aareg_home` flow for company representatives,
- add logic for organization number when relevant for employers and partners,
- support private individuals without organization selection,
- ensure the client cannot grant access on its own.

### Areas affected in phase 3

- LWC components for the home page and navigation,
- any Apex methods for input validation and context validation,
- potential updates to `AAREG_HomeController`.

### Dependencies for phase 3

- must be in place before the new navigation flow for other groups can be tested.

## Phase 4: Access model and server validation

### Goals for phase 4

- define clear authorization per user group,
- ensure that UI hiding is not the only access check,
- handle URL parameters as context only, not as access control.

### Areas affected in phase 4

- `AAREG_HomeController.checkAndShareIfAuthorized()`
- any new Apex helper classes for rights modeling
- any use of custom permissions or other existing permissions

### Tests for phase 4

- positive/negative access tests based on validated parameters,
- tests for invalid URL values,
- tests for missing organization number.

## Phase 5: Messages and person-based access

### Goals for phase 5

- distinguish between organization-based messages and person-based messages,
- keep the current organization-based message flow unchanged for company representatives,
- extend support for employers, partners, and private individuals via person-based context and selected organization number when relevant.

### Areas affected in phase 5

- [force-app/dialog/classes/AAREG_MyThreadsController.cls](../force-app/dialog/classes/AAREG_MyThreadsController.cls)
- relevant LWC components for displaying my messages

### Dependencies for phase 5

- must handle all user groups before moving to production.

## Phase 6: Function visibility and navigation rules

### Goals for phase 6

- hide irrelevant functions for employers, partners, and private individuals,
- display relevant menus and buttons based on actual access.

### Areas affected in phase 6

- LWC components for navigation and dashboards
- controlled logic in Apex for the function list

### Tests for phase 6

- verify that only relevant functions are shown per role,
- verify that the existing company representative flow is not changed.

## Phase 7: Verification and regression testing

### Goals for phase 7

- verify that the existing company representative flow is unchanged,
- verify role/context-based rules,
- verify server-side access in Apex.

### Test approach for phase 7

- existing Apex tests for AAREG modules are updated or extended,
- relevant LWC tests are reviewed where existing tests exist,
- additional security tests for access and message logic.

## Phase 8: Approval and transition

- document open questions,
- confirm user-group setup,
- confirm that server validation is in place before release.
