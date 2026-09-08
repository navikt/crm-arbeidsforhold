---
jira: CRMAAREG-194
tittel: Sakssynk mellom Salesforce og P360
type: Epic
status: Backlog
prioritet: Medium
opprettet: 2026-03-18
kilde: Jira — CRMAAREG (CSV-eksport + XML)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-194
speilkopi: ja
---

# CRMAAREG-194 — Sakssynk mellom Salesforce og P360

**Type:** Epic · **Status:** Backlog · **Prioritet:** Medium
**Epicnamn i Jira:** `SF/P360 - Sakssynk mellom Salesforce og P360`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-194)

## Formål

_Ingen beskriving registrert i Jira._

> Dette er den einaste epicen utan formål og grunngjeving. Dei ti andre har begge deler. Sjå GitHub-sak #995.

---

## CRMAAREG-195 · C1 — Avklare forretningsreglar for sak

**Status:** Backlog · **Prioritet:** A - Kritisk · **Estimat:** M
**Etikettar:** `business-rules` `case` `functional` `mapping`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-195)

### Arbeidstype

**Type:** Functional

### Brukarbehov og verdi

**Som** produktansvarleg
**vil eg** ha klare reglar for når sak skal opprettast og oppdaterast
**slik at** Salesforce og P360 oppfører seg likt

### Akseptansekriterier

- Reglar for oppretting er dokumenterte
- Reglar for oppdatering er dokumenterte
- Obligatoriske felt er identifiserte
- Eigarskap til felt og autoritativ kjelde er dokumentert

> **Merk:** «Uklare mappingregler (hva blir sak vs journalpost vs dokument)» står som **risiko** i `Overordnet rammeverk`. Denne storien er der den risikoen skal lukkast.

---

## CRMAAREG-200 · C2 — Opprette P360-sak frå Salesforce

**Status:** Backlog · **Prioritet:** B - Viktig · **Estimat:** L
**Etikettar:** `P360` `case` `create` `functional`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-200)

### Arbeidstype

**Type:** Functional

### Brukarbehov og verdi

**Som** saksbehandlar
**vil eg** at Salesforce kan opprette P360-sak
**slik at** arkivprosessen kan starte utan manuell dobbeltføring

### Akseptansekriterier

- P360-sak blir oppretta når triggerreglar er oppfylte
- Salesforce lagrar ekstern saks-ID, case number og status
- Valideringsfeil stoppar før kallout
- Teknisk feil blir logga med correlation ID
- Duplikat blir hindra eller oppdaga

### Relaterte felt

Confluence-designnotatet listar desse felta på `Application__c`:
`P360_Case_Id__c`, `P360_Case_Number__c`, `P360_Archive_Status__c`, `P360_Last_Error__c`, `P360_Last_Sync_At__c`

### Avhengigheiter

Ikkje registrert i Jira, men avheng truleg av F2–F7, S1, X1 og K2. Sjå [jira-oversikt.md](../jira-oversikt.md).

---

## CRMAAREG-208 · C3 — Oppdatere P360-sak ved relevante endringar

**Status:** Backlog · **Prioritet:** B - Viktig · **Estimat:** M
**Etikettar:** `case` `functional` `sync` `update`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-208)

### Arbeidstype

**Type:** Functional

### Brukarbehov og verdi

**Som** saksbehandlar
**vil eg** at relevante endringar i Salesforce kan oppdatere P360-sak
**slik at** data held seg konsistente

### Akseptansekriterier

- Berre godkjende felt triggar oppdatering
- Ingen oppdatering skjer ved ingen reell endring
- Manglande ekstern ID blir handtert kontrollert
- Feil blir kategoriserte som retrybar eller ikkje

> **Merk:** Siste kriterium føreset at retrybarheit er avklart. Sjå GitHub-sak #993.
