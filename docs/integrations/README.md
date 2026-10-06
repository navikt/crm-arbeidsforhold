---
tittel: Integrasjoner (SF)
kilde: Confluence — Integrasjoner (SF) (PDF-eksport)
hentet: 2026-09-08
speilkopi: ja
---

# Integrasjoner (SF)

Denne siden samler dokumentasjon for system-til-system-integrasjoner i Aa-registeret Salesforce-løsningen.

Integrasjoner er tekniske koblinger mellom Salesforce og andre systemer. Dette gjelder uavhengig av om systemet er internt eller eksternt for NAV.

## Hva hører hjemme her?

- Integrasjonsarkitektur
- Adaptere
- Klienter
- DTO-er og kontrakter
- Autentisering og teknisk konfigurasjon
- Mapping mot eksterne systemer
- Feilhåndtering
- Retry og idempotens
- Logging og correlation ID
- Teststrategi for integrasjoner

## Felles integrasjonsgrunnlag

Felles byggesteiner som correlation context, felles loggkontekst og generelle exceptions dokumenteres under `Common integrasjonsgrunnlag`.

## Konkrete integrasjoner

Konkrete integrasjoner dokumenteres på egne undersider, for eksempel:

- [P360](p360/README.md)
- Altinn
- Brreg

## Viktig prinsipp

Integrasjoner skal ikke eie Aa-registeret sitt domene.

Integrasjoner skal oversette mellom interne modeller og eksterne kontrakter på en kontrollert og testbar måte.
