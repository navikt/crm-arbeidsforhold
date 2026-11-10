# Data model and logging design

## AAREG activity log object

The activity log is the authoritative record of business actions performed by crm-arbeidsforhold. It should contain only meaningful actions and not every low-level system event.

### Recommended fields

- Application__c
- RelatedRecordId__c
- RelatedObjectApiName__c
- ActivityType__c
- ActivitySummary__c
- CorrelationId__c
- SourceClass__c
- SourceMethod__c
- UserId__c
- PayloadJson__c
- CreatedDate

## Technical log

The technical log should continue to capture:

- integration failures,
- callout exceptions,
- retry behavior,
- API diagnostics,
- correlation identifiers for operational troubleshooting.

This remains separate from the AAREG activity object.

## Logging policy

- Log a business activity only when the app intentionally performs a meaningful action.
- Keep payloads small and sanitized.
- Avoid storing tokens, secrets, or full PII payloads.
- Include correlation identifiers when the action spans multiple service layers or async work.
- Prefer a concise summary over a full record snapshot.

## Recommended behavior

When a business workflow changes an application, agreement, decision, inquiry, or related record, the service layer should insert one activity record with a clear type and summary. This keeps the implementation simple and avoids scattering logging logic across every controller.
