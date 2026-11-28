---
tittel: Integrasjoner (SF)
kilde: Repoet — crm-arbeidsforhold
oppdatert: 2026-11-28
speilkopi: nei
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
- [Altinn](altinn/README.md)
- Brreg

## Viktig prinsipp

Integrasjoner skal ikke eie Aa-registeret sitt domene.

Integrasjoner skal oversette mellom interne modeller og eksterne kontrakter på en kontrollert og testbar måte.

## Eierskap til denne siden

Siden er repo-eid fra 2026-11-28, ikke en speilkopi fra Confluence.
Den ble opprinnelig hentet fra Confluence-siden «Integrasjoner (SF)» 2026-09-08.
Confluence må lenke hit og beskrive kildeansvaret. Inntil oppfølgingen i
[#1289](https://github.com/navikt/crm-arbeidsforhold/issues/1289) er utført,
kan Confluence ha en eldre beskrivelse.
