---
jira: CRMAAREG-254
tittel: External ID-strategi og oppslag
type: Epic
status: Backlog
prioritet: Medium
opprettet: 2026-03-19
kilde: Jira — CRMAAREG (CSV-eksport + XML)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-254
speilkopi: ja
---

# CRMAAREG-254 — External ID-strategi og oppslag

**Type:** Epic · **Status:** Backlog · **Prioritet:** Medium
**Epicnamn i Jira:** `SF/P360 - External ID-strategi og oppslag`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-254)

## Formål

Sikre robust kopling mellom Salesforce og P360 via eksterne ID-ar.

## Kvifor denne epicen finst

Eksterne ID-ar er limet i integrasjonen. Utan ein klar strategi blir oppslag, retry og recovery eit sirkus.

---

## CRMAAREG-255 · X1 — Etablere external ID strategy for case, journalpost og file

**Status:** Backlog · **Prioritet:** B - Viktig · **Estimat:** M
**Etikettar:** `external-id` `idempotency` `technical`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-255)

### Arbeidstype

**Type:** Technical

### Brukarbehov og verdi

**Som** løysingsarkitekt
**vil eg** ha ein standard for external IDs
**slik at** oppslag og gjenfinning blir robuste

### Akseptansekriterier

- Format for external ID er definert
- Type/system-verdi er definert per entitet
- Unikheit og idempotensforhold er dokumenterte
- Felt i Salesforce for lagring av eksterne ID-ar er definerte

### Avhengigheiter

Avheng av: CRMAAREG-84 (F1). Blokkerer i praksis F2 (CRMAAREG-89), som treng metodesignaturar med external ID.

> **Merk:** «Hva er presis strategi for idempotens og deduplisering» står som **ope spørsmål** i `Overordnet rammeverk`. Denne storien og R1 (CRMAAREG-268) skal lukke det.

---

## CRMAAREG-261 · X2 — Implementere lookup i Salesforce basert på lagra eksterne ID-ar

**Status:** Backlog · **Prioritet:** B - Viktig · **Estimat:** M
**Etikettar:** `external-id` `lookup` `mvp` `technical`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-261)

### Arbeidstype

**Type:** Technical

### Brukarbehov og verdi

**Som** utviklar
**vil eg** kunne slå opp integrasjonstilstand lokalt i Salesforce
**slik at** vi ikkje er avhengige av P360-oppslag i MVP

### Akseptansekriterier

- Salesforce kan finne tidlegare oppretta entitetar via lagra eksterne ID-ar
- Løysinga støttar retry og gjenopptaking
- Manglande ID-ar blir handterte kontrollert
- Statusmodell for lokal lookup er dokumentert

---

## CRMAAREG-266 · X3 — Planleggje P360 external ID recovery-oppslag for seinare fase

**Status:** Backlog · **Prioritet:** C - Mindre viktig · **Estimat:** S
**Etikettar:** `external-id` `future` `recovery` `technical`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-266)

### Arbeidstype

**Type:** Technical

### Brukarbehov og verdi

**Som** utviklar
**vil eg** ha klar plan for seinare recovery mot P360
**slik at** vi kan styrkje robustheita når tilgang kjem

### Akseptansekriterier

- Design for bruk av `GetEntitiesExternalIds` er dokumentert
- Avhengigheiter mot miljøkonfig er dokumenterte
- Ingen domenekode må endrast når adapter kjem
- Story er flytta til fase 2+

### P360-operasjonar

`GetEntitiesExternalIds` — ikkje dokumentert i noka speilkopi. Sjå GitHub-sak #995.
