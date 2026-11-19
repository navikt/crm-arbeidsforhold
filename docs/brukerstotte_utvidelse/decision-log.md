# Decision log for specification consolidation

Date: 2026-11-18

## Purpose

This log summarizes the consolidation changes made after peer review feedback, so PR reviewers can quickly see what changed in the specification package.

## Applied updates

1. One authoritative target model is now explicit in `overview.md`.
2. `proposed-changes.md` now marks conflicting alternatives as replaced and strengthens direct-link/server-contract rules.
3. `implementation-plan.md` is split into:
    - clarification tracks (owner decisions first),
    - implementation phases (after gates are approved).
4. `open-questions.md` is converted to a decision register with:
    - status,
    - owner,
    - remaining implementation gates.
5. `risks-and-testing.md` now includes:
    - direct-link parity risk,
    - denied vs technical-error handling tests,
    - feature-toggle transition matrix tests,
    - explicit regression/rollback checks.

## Decisions reflected

- First release includes employer, partner, and private individual.
- Existing company representative/support behavior must not regress.
- `LastUsedOrganization__c` remains for existing company representative flow only.
- Private individual flow is person-based without organization requirement.
- Employer/partner require organization context in their flow.
- One active organization context per flow where organization is required.
- Small portal/role-page extension is preferred over parallel new app.

## Remaining gates

- Final owner decisions for metadata/permission strategy and audit scope.
- Final approved role-function/data matrix.
- Final direct-link denial/error contract.
- Final transition/rollback contract.
