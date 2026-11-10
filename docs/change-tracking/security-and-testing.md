# Security, privacy, and testing strategy

## Security requirements

- Respect with sharing and execution context.
- Do not expose authentication metadata, credentials, or secrets in activity logs.
- Keep the activity object access-controlled and limited to needed support/review roles.
- Redact or omit sensitive values before storing them in summary fields.
- Keep personal-data capture strictly limited to what is necessary for support and traceability.

## Privacy guidance

The AAREG activity log should focus on business intent and workflow traceability, not on unrestricted personal detail. Only fields that are needed for support and review should be stored.

## Testing strategy

### Unit tests

- activity records are created for expected business events,
- correlation IDs are propagated correctly,
- no activity is logged for unrelated or unsupported actions,
- sensitive values are omitted or masked,
- the helper inserts one record per relevant business action.

### Integration tests

- create a realistic application lifecycle flow,
- verify that activity records are created in the correct sequence,
- confirm that async jobs retain the same correlation context,
- validate that technical integration failures remain separate from business activity entries.

### Negative tests

- no org-wide capture without application context,
- no false positives from unrelated object updates,
- no duplicate entries when a business action is retried unintentionally.

## Approval gate

This solution should be treated as a small, scoped business activity design and should not be implemented until reviewed and approved by the relevant stakeholders.

## Recommended final decision

The best fit for this codebase is a simple AAREG custom-object activity log, backed by a shared helper and kept separate from technical logging. This gives us traceability without adding a generic org-wide audit layer or over-engineered event infrastructure.
