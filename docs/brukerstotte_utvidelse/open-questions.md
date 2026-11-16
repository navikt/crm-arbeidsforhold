# Open questions and decisions to be made before implementation

## 1. Which user groups should actually be supported in the first release?

Yes, the first version should support private individuals in addition to employers and partners.

This means the first release should cover three user groups:

- employers,
- partners,
- private individuals.

This affects both the URL pattern, the access model, and how person-based context is selected and validated in the UI and server logic.

## 2. Should the user group be defined in a separate Apex context model?

It is recommended yes, but this must be decided explicitly. A simple model is better than a broad and generic access framework.

## 3. Should message display be person-based or organization-based per group?

Decision: the current message display for company representatives and for users who already have access to support should work exactly as it does today and should not be changed.

For the new representation roles covering people who represent employers, partners, and themselves, message display should be person-based as the main model. The organization is then used as context or filter, but not as the only or primary criterion for which messages should be shown.

This means that:

- the current organization-based flow is kept unchanged for existing users,
- the new person-based model is used only for the new representation roles,
- a person’s active ACR relationships to an employer or partner should be able to resolve the correct message context,
- organization selection can be used to narrow or set context, but not as the only criterion for who should see which messages,
- the person’s identity and relationship are the underlying factors for access to messages and email in the new user group.

This avoids regression in the current solution while still supporting the new representation patterns.

## 4. Is it necessary to support multiple organization selections per user?

No. `LastUsedOrganization__c` should only be used for company representatives.

For the other user groups, we should use person-based context while also supporting a selected organization number as the work context for the current task. This means that each user should only have one active organization selection in a given work flow, not several simultaneous active organization selections in the same context.

In short:

- company representatives: existing model with `LastUsedOrganization__c` as the main context,
- employers, partners, and private individuals: person-based context + one selected organization number as the work context,
- no support for multiple simultaneous active organization selections for these groups.

This is understandable and helps avoid a double context model in the same flow.

## 5. What is the desired behavior for users without an organization context?

For private individuals representing themselves, they do not need to enter an organization number and do not need to select an organization. They should be able to enter their personal context directly.

For employers and partners, it is important that they either:

- enter with an organization number, or
- must select an organization on the homepage before they can continue in the work flow.

This means these users must have a valid organization context, while private individuals do not need one.

## 6. Is there a need for new Custom Metadata or permission sets for the new user group?

This must be clarified before implementation, because some permissions may be more naturally modeled as existing roles or Custom Metadata.

## 7. Should this live in the same LWC component or several shared components?

Yes, we should limit the number of new components. I believe it is better to use the current `aareg_home` as the current organization-based entry, and then create a small new entry page for the new user groups that can choose user type and organization.

This should work as a coherent structure:

- the current `aareg_home` remains the existing organization-based page,
- the new page is used for new user groups when they need to choose user type and/or organization context,
- after the context is chosen, they can continue into the same existing functionality as the current flow,
- we avoid building an entirely new parallel app from scratch and keep the solution small and understandable.

In short: I would not create a completely new `aareg_home` from scratch that replaces the current page, but rather a small, clear new entry that points back to the current `aareg_home` flow when necessary.

## 8. Which functions are “allowed” and which are “not allowed”?

Yes, this should be documented as a matrix for each user group. Here is a current, editable matrix for use as a starting point before implementation:

| User group                           | Code / role                | Must have organization context | Must select organization                        | Person-based context     | Allowed functions                                                             | Not allowed functions                                          |
| ------------------------------------ | -------------------------- | ------------------------------ | ----------------------------------------------- | ------------------------ | ----------------------------------------------------------------------------- | -------------------------------------------------------------- |
| Company representative               | Existing organization user | Yes                            | Yes, via current flow                           | No                       | All current organization-based functions                                      | New person-based functions without organization context        |
| Employer                             | New user group             | Yes                            | Yes, either via organization number or homepage | Yes                      | Functions tied to the selected employer organization and own personal context | Multiple simultaneous organization selections in the same flow |
| Partner                              | New user group             | Yes                            | Yes, either via organization number or homepage | Yes                      | Functions tied to the selected partner organization and own personal context  | Multiple simultaneous organization selections in the same flow |
| Private individual                   | New user group             | No                             | No                                              | Yes                      | Personal tasks and personal messages without organization requirements        | Mandatory organization selection                               |
| Support user / existing support user | Existing support           | Yes/depending on current flow  | As today                                        | Depends on current model | Existing support flow without change                                          | Regression in current behavior                                 |

This is a good starting point for reducing the main decisions to a simple table. You can edit it based on what is actually allowed for each function in the final release.

## 9. What is the desired level of audit / tracking in this first step?

This project should stay small and AAREG-specific. Before implementation, it must be decided how much history is actually needed in the process without building a generic activity system.

## 10. Will this be an isolated AAREG solution or should it share logic with other areas?

It is recommended to keep this AAREG-specific in the first phase so the solution remains simple to understand, maintain, and audit.
