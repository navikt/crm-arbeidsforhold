---
jira: CRMAAREG-215
tittel: Journalpost som document metadata-flyt
type: Epic
status: Backlog
prioritet: Medium
opprettet: 2026-03-19
kilde: Jira — CRMAAREG (CSV-eksport + XML)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-215
speilkopi: ja
---

# CRMAAREG-215 — Journalpost som document metadata-flyt

**Type:** Epic · **Status:** Backlog · **Prioritet:** Medium
**Epicnamn i Jira:** `SF/P360 - Journalpost som document metadata-flyt`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-215)

## Formål

Implementere journalpost som Salesforce-domene mot P360 `DocumentService`.

## Kvifor denne epicen finst

Det de kallar journalpost i domene, må teknisk mappe til dokumentmetadata i P360.

---

## CRMAAREG-216 · J1 — Avklare forretningsreglar for journalpost

**Status:** Backlog · **Prioritet:** B - Viktig · **Estimat:** M
**Etikettar:** `functional` `journalpost` `mapping`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-216)

### Arbeidstype

**Type:** Functional

### Brukarbehov og verdi

**Som** løysingsarkitekt
**vil eg** ha klare reglar for journalpost-metadata
**slik at** mapper og service-lag kan byggjast rett

### Akseptansekriterier

- Skiljet mellom journalpostmetadata og fil er dokumentert
- Obligatoriske felt er identifiserte
- Reglar for innkomande, utgåande og eventuelt notat er dokumenterte
- Reglar for sender/mottakar er dokumenterte

---

## CRMAAREG-221 · J2 — Opprette journalpost i Salesforce-domene via P360 DocumentService

**Status:** Backlog · **Prioritet:** Medium · **Estimat:** L
**Etikettar:** `create` `documentservice` `functional` `journalpost`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-221)

### Arbeidstype

**Type:** Functional

### Brukarbehov og verdi

**Som** saksbehandlar
**vil eg** at Salesforce kan opprette journalpost i P360
**slik at** dokumentmetadata blir journalført korrekt

### Akseptansekriterier

- Journalpost mappar til `CreateDocument`
- Knyting til sak skjer via ekstern saks-ID eller annan avklart strategi
- Ekstern document ID og document number blir lagra tilbake i Salesforce
- Valideringsfeil stoppar før kall
- Feil blir logga med correlation ID

### Relaterte felt

Confluence-designnotatet listar desse felta på `Agreement__c`:
`P360_Document_Id__c`, `P360_Document_Number__c`, `P360_Archive_Status__c`

### P360-operasjonar

`DocumentService` / `CreateDocument` — ikkje dokumentert i noka speilkopi. Sjå GitHub-sak #995.

---

## CRMAAREG-229 · J3 — Oppdatere journalpostmetadata i P360

**Status:** Backlog · **Prioritet:** B - Viktig · **Estimat:** M
**Etikettar:** `documentservice` `functional` `journalpost` `update`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-229)

### Arbeidstype

**Type:** Functional

### Brukarbehov og verdi

**Som** saksbehandlar
**vil eg** at relevante metadata kan oppdaterast
**slik at** journalposten i P360 held seg korrekt

### Akseptansekriterier

- Berre oppdaterbare felt blir sende
- Oppdatering krev kjent document number eller annan avklart nøkkel
- Ingen oppdatering skjer ved ingen reell endring
- Feil blir klassifiserte riktig

> **Merk:** «Hvilke livssyklusregler låser oppføringer i P360» står som **ope spørsmål** i `Overordnet rammeverk`. Det påverkar kva som faktisk er oppdaterbart her.
