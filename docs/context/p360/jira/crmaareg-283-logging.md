---
jira: CRMAAREG-283
tittel: Logging, overvaking og drift
type: Epic
status: Backlog
prioritet: Medium
opprettet: 2026-03-23
kilde: Jira — CRMAAREG (CSV-eksport + XML)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-283
speilkopi: ja
---

# CRMAAREG-283 — Logging, overvaking og drift

**Type:** Epic · **Status:** Backlog · **Prioritet:** Medium
**Epicnamn i Jira:** `SF/P360 - Logging, overvaking og drift`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-283)

## Formål

Gjere integrasjonen observerbar, sporbar og handterbar i drift.

## Kvifor denne epicen finst

Utan observabilitet blir kvar feil ei lita privat detektivforteljing.

---

## CRMAAREG-284 · O1 — Instrumentere alle hovudflytar med strukturert logging

**Status:** Backlog · **Prioritet:** B - Viktig · **Estimat:** M
**Etikettar:** `logging` `observability` `operations`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-284)

### Arbeidstype

**Type:** Operations

### Brukarbehov og verdi

**Som** driftsperson
**vil eg** ha konsistente loggar
**slik at** eg kan sjå kvar ei flyt starta, feila og slutta

### Akseptansekriterier

- Case create loggar start/slutt/feil
- Journalpost create loggar start/slutt/feil
- Filflyt loggar start/slutt/feil
- Correlation ID går gjennom heile flyta
- Sensitive felt er maskerte

### Relatert kontekst

`Overordnet rammeverk` gir føringar for logging: ingen dokumentinnhald i logger, kun nødvendig metadata for feilsøking, korrelasjons-ID skal alltid loggast.

Byggjer på F6 (CRMAAREG-129), som lagar sjølve logging-helperen.

> **Raud sone.** Maskering av sensitive felt gjeld persondata. Krev menneskeleg gjennomgang.

---

## CRMAAREG-290 · O2 — Etablere overvaking, alarmar og runbook

**Status:** Backlog · **Prioritet:** B - Viktig · **Estimat:** M
**Etikettar:** `monitoring` `operations` `runbook`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-290)

### Arbeidstype

**Type:** Operations

### Brukarbehov og verdi

**Som** driftsperson
**vil eg** ha alarmar og handbok
**slik at** feil blir oppdaga og løyste raskt

### Akseptansekriterier

- Kritiske alarmar er definerte
- Operasjonell runbook finst
- Støtteansvar er dokumentert
- Feilsøkingssteg er dokumenterte

> **Merk:** Runbook blir også nemnd i R2 (CRMAAREG-274) og D2 (CRMAAREG-315). Kven som eig runbooken er ikkje avklart.
