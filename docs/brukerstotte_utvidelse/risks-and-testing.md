# Risks and testing strategy

## 1. Risks

### 1.1 Regression for company representatives

The biggest risk is that the existing behavior for company representatives will change when trying to expand the user groups.

This particularly applies to:

- organization selection and `LastUsedOrganization__c`,
- my applications,
- my agreements,
- my messages,
- access to support.

### 1.2 Incorrect access control

If access is based only on UI hiding, the user may gain access to data or functionality through direct calls or manipulated parameters. Therefore, Apex server logic must be the actual authorization mechanism.

### 1.3 Direct-link behavior mismatch

If direct links and portal navigation do not run the same access checks, users may see inconsistent behavior or unintended access. Direct links must always use the same server-side decision path as portal navigation.

### 1.4 Mixing user group and representation models

If the user group and selected organization number are mixed into the same variable or flow, it can lead to incorrect context and unintended access.

### 1.5 Message errors

The current message model is organization-based. There is significant risk in extending it without explicit person-based filtering for other groups.

### 1.6 Transition risk with feature toggle

If old/new entry behavior is controlled by feature toggle, risk exists around missing flag values, technical flag lookup errors, and rollout/rollback behavior. Access rules must remain enforced regardless of toggle state.

## 2. Test approach

### 2.1 Existing Apex tests

There are already test classes in several AAREG modules, for example:

- AAREG_ApplicationControllerTest
- AAREG_MyApplicationsControllerTest
- AAREG_ContactSupportControllerTest
- AAREG_MyThreadsControllerTest

These must be reviewed and extended, especially when access control or message configuration is changed.

### 2.2 New tests that should be created

- access test for employer without application access,
- access test for partner without organization-based display of applications and agreements,
- access test for private individual with only personal messages,
- negative test for invalid URL parameters,
- negative test for manipulated organization number,
- test that the existing company representative flow remains unchanged.
- direct-link tests for each role page,
- denied access returns to portal with safe message code,
- technical access-lookup failure shows dedicated safe error behavior,
- toggle matrix tests: on, off, missing value, technical error.

### 2.3 LWC test coverage

There are LWC tests in the affected areas that already use Apex wires, for example the `aareg_home` test. These should be extended for the new user-group pattern and for error handling of the selected context.

### 2.4 Verification of server-side access

It must be tested in Apex that not only UI elements are hidden, but that the server actually rejects unauthorized calls.

### 2.5 Regression and rollout checks

- verify existing support and company representative user journeys without behavior drift,
- verify the same data-level authorization in both old and new entry experiences during transition,
- verify rollback path before production-like rollout.

## 3. Recommendation

To limit regression risk, the implementation should be split into small phases and validated after each phase. This is important because the current organization-based flow is central to the solution and should not be changed without targeted regression testing.
