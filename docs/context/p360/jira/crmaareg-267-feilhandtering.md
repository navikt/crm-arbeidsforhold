---
jira: CRMAAREG-267
tittel: Feilhåndtering, idempotens og retry
type: Epic
status: Backlog
prioritet: Medium
opprettet: 2026-03-23
kilde: Jira — CRMAAREG (CSV-eksport + XML)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-267
speilkopi: ja
---

# CRMAAREG-267 — Feilhåndtering, idempotens og retry

**Type:** Epic · **Status:** Backlog · **Prioritet:** Medium
**Epicnamn i Jira:** `SF/P360 - Feilhåndtering, idempotens og retry`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-267)

## Formål

Gjere integrasjonen robust ved tekniske feil, duplikat og delvis fullførte flytar.

## Kvifor denne epicen finst

Integrasjonar lever ikkje i eit fint univers. Dei lever i nettverksfeil, timeoutar og små digitale samanbrot.

---

## CRMAAREG-268 · R1 — Etablere idempotens for oppretting av sak og journalpost

**Status:** Backlog · **Prioritet:** B - Viktig · **Estimat:** M
**Etikettar:** `idempotency` `resilience` `technical`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-268)

### Arbeidstype

**Type:** Technical

### Brukarbehov og verdi

**Som** utviklar
**vil eg** unngå dobbeltoppretting
**slik at** retry ikkje skaper duplikat

### Akseptansekriterier

- Idempotensstrategi er definert for case
- Idempotensstrategi er definert for journalpost
- Duplicate scenario blir handtert kontrollert
- Strategien er dokumentert

### Relatert kontekst

`Overordnet rammeverk` listar som antaking at «integrasjonen må støtte nytt forsøk uten å lage duplikate arkivoppføringer», og som ope spørsmål «hva er presis strategi for idempotens og deduplisering».

Heng tett saman med X1 (CRMAAREG-255), som definerer external ID-formatet idempotensen truleg byggjer på.

---

## CRMAAREG-274 · R2 — Etablere retry-strategi og manuell oppfølging

**Status:** Backlog · **Prioritet:** Medium · **Estimat:** M
**Etikettar:** `operations` `resilience` `retry` `support`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-274)

### Arbeidstype

**Type:** Operations

### Brukarbehov og verdi

**Som** driftsperson
**vil eg** vite kva som skal retryast og kva som skal stoppast
**slik at** feil ikkje blir usynlege

### Akseptansekriterier

- Retrybar og ikkje-retrybar feil er definerte
- Operasjonell handtering av feila meldingar er dokumentert
- Manuell re-køyring er beskriven
- Runbook er oppdatert

> **Avhengigheit:** Første kriterium overlappar direkte med F5 (CRMAAREG-121). Korleis retrybarheit blir uttrykt i exception-modellen må avklarast før begge kan implementerast. Sjå GitHub-sak #993.

> **Merk:** «Hvordan håndteres feil operasjonelt: brukerstyrt nytt forsøk, automatisk nytt forsøk, eller kombinasjon?» står som **ope spørsmål** i `Overordnet rammeverk`.
