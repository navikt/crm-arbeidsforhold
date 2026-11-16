# ACR and email handling for the support extension

## 1. Context

To identify the correct email address for a person representing an employer, partner, or themselves, we must use AccountContactRelation (ACR) as the bridge between the person and the organization. ACR is the reliable source showing that a person is actually connected to a specific account and in which role that person acts.

This is necessary because the current solution is heavily based on `User.LastUsedOrganization__c` and the selected organization number. This is not enough for person-based representation relationships, because the same person can have several relevant roles and several related accounts.

## 2. Problem statement

We need to solve three things at the same time:

1. find the correct person connected to the selected organization or their own user relationship,
2. find the correct email address for that person,
3. store the email address in Salesforce in a way that is searchable, validatable, and robust against changes in KRR/Altinn.

## 3. Requirements for the solution

### 3.1 ACR as the source of representation relationship

- `AccountContactRelation` is the master of the relationship between a person and an organization.
- The relationship should only be active when `IsActive = true`.
- The role on the relationship must distinguish between:
    - employer,
    - partner,
    - own person / self,
    - possibly other relevant representation types.
- The relationship may need time restrictions via `StartDate` and `EndDate` if this is required for historical accuracy or real changes in access.

### 3.2 Identifying the correct contact

For each logged-in user, the system should be able to resolve:

- which person account or contact is relevant for the user,
- which account or organization the person represents,
- whether the person should be treated as “self”, “employer”, or “partner”.

It should not be possible to treat `User.LastUsedOrganization__c` alone as valid representation context for these user groups. `LastUsedOrganization__c` can still be used as a fallback for existing organization-based users, but not as the only source for new representation patterns.

In practice this means:

- company representatives use the current organization model,
- employers and partners use person-based context and one selected organization number,
- private individuals use person-based context without an organization number,
- we do not support multiple simultaneous organization selections in the same flow for these new groups.

### 3.3 Email as data in Salesforce

We need a storage pattern that allows email to be used in:

- contact information,
- notifications / communication,
- support flow and messages,
- history and searchability,
- later transfer to KRR or other data sources.

There are already several places in the repo where email is stored on transactional objects such as `Application__c.Email__c`, `RelatedContact__c.Email__c`, and `Inquiry__c.Email__c`. This is useful, but it is not enough as the master for representation context. We therefore need a normalized, explicit data source for contact email in the person/context model.

## 4. Proposed design

### 4.1 Use ACR as the relationship model

We recommend building a small, concrete context module around ACR:

- `AccountContactRelation` is used to find all active relationships for the current person.
- `Roles` or an AAREG-specific field model is used to classify the relationship.
- A small Apex service, for example `AAREG_ContactContextService`, is responsible for connecting:
    - user,
    - related contact,
    - account,
    - role,
    - relevant email address.

This keeps the solution small and limited to AAREG without introducing a large generic audit/access system.

### 4.2 Email in Salesforce

We recommend using one of two models depending on which source is actually authoritative:

#### Variant A: Use Contact.Email / PersonEmail as the primary field

This is the simplest model if Salesforce is the authoritative source for the current person. Advantages:

- small code change,
- simple access control,
- good searchability,
- uses standard Salesforce fields.

Requirements for this:

- the field must be updated as part of the AAREG/KRR synchronization,
- it must be clear which sources can overwrite the email,
- the field must never be used without validation.

#### Variant B: A small AAREG table for email snapshot

If KRR/AAREG has specific requirements for history, multiple email addresses, or source tracking, we should use a small custom object, for example:

- `AAREG_PersonEmail__c`

This object should contain:

- `ContactId` or `PersonAccountId`
- `Email__c`
- `Source__c` (KRR, AAREG, Manual, Import)
- `IsPrimary__c`
- `ValidFrom__c`
- `ValidTo__c`
- `LastValidated__c`

This is a good choice when we need to store several addresses or maintain history without overloading standard `Contact.Email`.

### 4.3 Recommendation

For this solution we recommend a small and practical model:

- ACR is the source of truth for representation relationships.
- Email is stored in Salesforce in a normalized field or small custom object.
- A utility/service fetches the relevant email based on the ACR and selected context.
- We avoid a large generic “email framework”; we only use what is actually needed for AAREG.

## 5. Changes required in the AAREG solution

### 5.1 Apex and service layer

A new small Apex service must be created with responsibility for:

- finding active ACR records for a person,
- deciding which account is relevant,
- classifying the relationship as employer / partner / self,
- returning the relevant email address.

Examples of methods:

- `resolvePersonContext(User currentUser)`
- `resolveAccountContactRelations(Id personContactId)`
- `resolveRelevantEmail(Id contactId, Id accountId)`
- `resolveApplicableContactsForSupport(Id accountId)`

### 5.2 Updating existing lookups and flows

The following areas must be updated so they use ACR context instead of only `LastUsedOrganization__c`:

- support/message display,
- user group/representation logic,
- email links in the support/inquiry flow,
- personalization of email addresses for relevant contacts.

This should not be done as a large refactor of the entire app. The correct change is to place context resolution in one small service and use it where the current organization logic is too narrow.

### 5.3 Test coverage

For each new function we need a small but clear test coverage:

- person with ACR to an employer gets the correct email,
- person with ACR to a partner gets the correct email,
- person without active ACR gets no result or a correct error/blank,
- old / expired ACR records are ignored,
- historical email addresses are handled correctly,
- only the active relationship is used in support and message flows.

## 6. Adoption rules

- ACR is the source of truth for representation relationships.
- `LastUsedOrganization__c` remains the context for existing organization-based operations, but not the only mechanism for person relationships.
- Email data must be validated before use in outbound communication.
- Email in Salesforce must be traceable back to source and date.
- No function should use direct URL/UI state as the basis for access.

## 7. Acceptance criteria

The solution is approved when:

1. the system can identify the correct person and account for employer, partner, and self via ACR,
2. the system can fetch the correct email address for the current relationship,
3. the email is stored in Salesforce in a stable and searchable format,
4. the use of `LastUsedOrganization__c` is no longer the only signal for person-based representation,
5. relevant support and message flows are verifiable with tests.
