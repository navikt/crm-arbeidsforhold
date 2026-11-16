# Current technical implementation

## 1. Home page and organization selection

The home page for the external user experience is implemented in the LWC [force-app/externalAccess/lwc/aareg_home/aareg_home.js](../force-app/externalAccess/lwc/aareg_home/aareg_home.js) and the server controller [force-app/externalAccess/classes/AAREG_HomeController.cls](../force-app/externalAccess/classes/AAREG_HomeController.cls).

The current model uses Altinn organizations and the user’s last-used organization number. This is a solid model for company representatives, but it is not the correct policy for the new user groups:

- `LastUsedOrganization__c` should only be used for company representatives,
- employers, partners, and private individuals use person-based context in addition to an optional selected organization number,
- private individuals do not need an organization number,
- the other groups should have one active organization context per flow and not multiple simultaneous active organization selections.

- `AAREG_HomeController.getOrganizationsWithRoles()` fetches organizations for the logged-in user.
- `AAREG_HomeController.getLastUsersLastUsedOrganization()` reads `User.LastUsedOrganization__c`.
- `AAREG_HomeController.updateLastUsedOrganization()` updates the selected organization number.
- `AAREG_HomeController.checkAndShareIfAuthorized()` verifies whether the user has access to the selected organization and shares relevant agreements with the user.

This means that the current user flow is strongly tied to organization selection as context. The `aareg_home` LWC also handles sorting, display of available organizations, and security checks before the user gains access to organization-based features.

## 2. Current access model

The home page does more than display information. It also performs server-side authorization:

- `checkAndShareIfAuthorized` calls `AAREG_CommunityUtils.getUserRights()` for access control.
- If the user has permission for the Altinn role `nav_arbeidsforhold_aa-registeret-sok-tilgang` or `nav_arbeidsforhold_aa-registeret-brukerstotte`, the access status is set on the server.
- This is not just hiding UI elements; it is actual authorization in Apex.

This is important to keep in mind when supporting new user groups. The same pattern should be reused for new user types, even if the rights roles granting access vary.

## 3. My applications and my agreements

The current application logic for the external application flow is in the following files:

- [force-app/externalApplication/classes/AAREG_ApplicationController.cls](../force-app/externalApplication/classes/AAREG_ApplicationController.cls)
- [force-app/externalApplication/classes/AAREG_MyApplicationsController.cls](../force-app/externalApplication/classes/AAREG_MyApplicationsController.cls)
- [force-app/externalAgreement/classes/AAREG_MyAgreementsController.cls](../force-app/externalAgreement/classes/AAREG_MyAgreementsController.cls)

`AAREG_ApplicationController` handles:

- creation and saving of applications,
- draft storage,
- updating `Access_Request__c`,
- updating `RelatedContact__c`,
- upserting basic codes,
- document linking and submission.

`AAREG_MyApplicationsController.getUsersApplications()` fetches applications for the most recently selected organization. This means the current model is organization-centered and not person-centered for these functions.

`AAREG_MyAgreementsController` is similarly focused on the organization or selected context and includes operations such as updating, deleting, and retrieving agreement contact information.

## 4. Support and messages

The support flow and message handling are currently implemented in the dialog module:

- [force-app/dialog/classes/AAREG_contactSupportController.cls](../force-app/dialog/classes/AAREG_contactSupportController.cls)
- [force-app/dialog/classes/AAREG_MyThreadsController.cls](../force-app/dialog/classes/AAREG_MyThreadsController.cls)

`AAREG_MyThreadsController.getUsersThreads()` retrieves threads based on `User.LastUsedOrganization__c` and then finds the associated account via the organization number.

This is important: the current messaging model is typically organization-centered for company representatives. It therefore does not cover the current requirements for personal messages for employers, partners, or private individuals without further extension.

## 5. Direct entry via URL and state parameters

There is already use of `CurrentPageReference` and `state` parameters in the LWC for the application flow:

- [force-app/externalApplication/lwc/aareg_application/aareg_application.js](../force-app/externalApplication/lwc/aareg_application/aareg_application.js)

This component reads `this.currentPageReference.state` and uses fields such as:

- `c__applicationType`
- `c__isDraft`
- `c__status`

This provides a pattern for direct URL entry, but the current use is focused on the application flow and not on broader user-group selection. The first version of a shared entry page therefore needs to be built without making large changes to the same navigation model while still respecting existing `state`-based navigation patterns.

## 6. What must be understood in the analysis

The current solution has a clear pattern:

- organization selection is the context for much of the business functionality,
- user group and representation are not clearly separated into a context model,
- messages and applications are partly organization-focused,
- server logic performs actual access control, while UIs only show or hide elements in addition.

This is a good foundation for the extension, but it requires a conscious model to separate business context from personal context and actual entitlement.
