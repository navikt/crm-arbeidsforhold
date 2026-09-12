---
jira: CRMAAREG-236
tittel: Filhandtering og vedleggsflyt
type: Epic
status: Backlog
prioritet: Medium
opprettet: 2026-03-19
kilde: Jira — CRMAAREG (CSV-eksport + XML)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-236
hentet: 2026-09-13
speilkopi: ja
---

# CRMAAREG-236 — Filhandtering og vedleggsflyt

**Type:** Epic · **Status:** Backlog · **Prioritet:** Medium
**Epicnamn i Jira:** `SF/P360 - Filhandtering og vedleggsflyt`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-236)

## Formål

Handtere filoverføring og vedlegg skilt frå journalpostmetadata.

## Kvifor denne epicen finst

Metadata og filer er ikkje same problem. Å late som dei er det gir berre svidd arkitektur.

---

## CRMAAREG-237 · FLS1 — Avklare filstrategi for MVP

**Status:** Backlog · **Prioritet:** B - Viktig · **Estimat:** M
**Etikettar:** `architecture` `file` `technical`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-237)

### Arbeidstype

**Type:** Technical

### Brukarbehov og verdi

**Som** løysingsarkitekt
**vil eg** ha avklart korleis filer skal sendast
**slik at** vi kan implementere rett flyt først

### Akseptansekriterier

- MVP-strategi er vald: filer i same kall eller eiga flyt
- Kjelda for fil i Salesforce er dokumentert
- Maks filstorleik og støtta format er dokumenterte
- Krav til PDF/PDF-A er dokumenterte som eksternt ansvar

> **Merk:** «Store filer og mange vedlegg kan kollidere med plattformgrenser og tidsfrister» står som **risiko** i `Overordnet rammeverk`.

---

## CRMAAREG-242 · FLS2 — Leggje til filer på dokument i P360

**Status:** Backlog · **Prioritet:** B - Viktig · **Estimat:** L
**Etikettar:** `attachment` `file` `functional` `upload`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-242)

### Arbeidstype

**Type:** Functional

### Brukarbehov og verdi

**Som** saksbehandlar
**vil eg** at filene frå Salesforce blir knytte til rett dokument i P360
**slik at** journalposten blir komplett

### Akseptansekriterier

- Filer kan knytast til eksisterande P360-dokument
- Filtype og storleik blir validerte før sending
- Respons/kvittering blir lagra der det er relevant
- Feil ved filoverføring blir logga og handterte

### Avhengigheiter

Føreset at FLS1 har valt strategi, og at J2 har oppretta dokumentet filene skal knytast til.

---

## CRMAAREG-250 · FLS3 — Handtere store filer og seinare avansert filflyt

**Status:** Backlog · **Prioritet:** C - Mindre viktig · **Estimat:** S
**Etikettar:** `file` `future` `large-file` `technical`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-250)

### Arbeidstype

**Type:** Technical

### Brukarbehov og verdi

**Som** utviklar
**vil eg** ha plan og backlog for store filer
**slik at** MVP ikkje låser oss til ein dårleg modell

### Akseptansekriterier

- Trigger for «stor fil»-spor er definert
- Seinar fase for `UploadStream` eller tilsvarande er dokumentert
- Grense mot MVP er dokumentert
- Operasjonell risiko ved store filer er beskriven

### P360-operasjonar

`UploadStream` — ikkje dokumentert i noka speilkopi. Sjå GitHub-sak #995.

> **Speilingsmerknad:** «Seinar fase» er skrive slik i kjelda. Truleg meint «Seinare fase».
