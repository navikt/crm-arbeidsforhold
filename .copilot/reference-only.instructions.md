---
applyTo: '**'
---

Desse mappene er berre for referanse og/eller pakke-eigde:

- src-temp
- platform-data-model
- custom-metadata-dao
- custom-permission-helper
- feature-toggle
- record-type-cache
- crm-platform-base
- crm-platform-reporting
- crm-platform-access-control
- crm-thread-view
- crm-shared-timeline
- crm-community-base
- crm-platform-integration
- crm-platform-email-scheduling
- crm-journal-utilities
- crm-shared-user-notification
- crm-shared-flowComponents
- crm-platform-oppgave
- crm-henvendelse-base
- crm-henvendelse

Reglar for AI/agentar:

- Ikkje opprett, endre, flytt eller slett filer i desse mappene.
- Innhaldet kan lesast for kontekst og referanse.
- Dersom ei oppgåve krev endring i desse mappene, stopp og be om eksplisitt godkjenning frå brukar før du held fram.
- Ved eksplisitt godkjenning skal endringar avgrensast til minimum nødvendig omfang.

Teknisk handheving:

- Pre-commit-policy blir handheva i .husky/pre-commit.
- Nødunntak krev eksplisitt setting av miljøvariabel ALLOW_PACKAGE_DIR_COMMIT=1.
