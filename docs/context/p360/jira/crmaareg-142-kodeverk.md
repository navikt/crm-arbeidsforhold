---
jira: CRMAAREG-142
tittel: Kodeverk, metadata-adapter og dependency injection
type: Epic
status: Under arbeid
prioritet: Medium
opprettet: 2026-03-17
kilde: Jira — CRMAAREG (CSV-eksport + XML)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-142
hentet: 2026-09-13
speilkopi: ja
---

# CRMAAREG-142 — Kodeverk, metadata-adapter og dependency injection

**Type:** Epic · **Status:** Under arbeid · **Prioritet:** Medium
**Epicnamn i Jira:** `SF/P360 - Kodeverk, metadata-adapter og dependency injection`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-142)

## Formål

Skjule kodeverk-oppslag bak adapter, med Salesforce Custom Metadata som MVP-løysing.

## Kvifor denne epicen finst

De får ikkje bruke direkte P360-oppslag no. Då må løysinga framleis vere rein nok til å byte adapter seinare utan kirurgi med motorsag.

---

## CRMAAREG-143 · K1 — Etablere Custom Metadata-modell for P360-kodeverk

**Status:** Backlog · **Prioritet:** A - Kritisk · **Estimat:** S
**Etikettar:** `codetable` `configuration` `metadata`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-143)

### Arbeidstype

**Type:** Foundation

### Brukarbehov og verdi

**Som** utviklar
**vil eg** ha kodeverk lagra i Custom Metadata
**slik at** Salesforce kan slå opp verdiar utan direkte P360-kall

### Akseptansekriterier

- Custom Metadata Type er definert
- Felt for Salesforce-nøkkel, P360-kode, recno og visingslabel finst
- Språk og aktiv/inaktiv status kan støttast
- Metadata-modellen er dokumentert

### Avhengigheiter

Avheng av: CRMAAREG-84 (F1)

> **Merk:** Feltet `recno` er ikkje forklart i noka speilkopi frå Confluence. Sjå GitHub-sak #995.

---

## CRMAAREG-155 · K2 — Implementere metadata-basert code table service

**Status:** Backlog · **Prioritet:** A - Kritisk · **Estimat:** M
**Etikettar:** `adapter` `codetable` `foundation` `metadata`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-155)

### Arbeidstype

**Type:** Foundation

### Brukarbehov og verdi

**Som** utviklar
**vil eg** ha eit `IP360CodeTableService` som les frå Custom Metadata
**slik at** omformarane (mapperane) slepp å vite kor kodeverket kjem frå

### Akseptansekriterier

- `IP360CodeTableService` finst
- `P360CodeTableMetadataService` implementerer interfacet
- Service kan hente document categories, document statuses og case statuses
- Service kan hente «required mapping» for ein Salesforce-nøkkel
- Manglande mapping kastar definert exception

> **Avvik:** Klassenamna følgjer ikkje namnestandarden. Skal truleg vere `P360_ICodeTableService` og `P360_CodeTableMetadataService`. Sjå GitHub-sak #994.

---

## CRMAAREG-163 · K3 — Etablere dependency injection / service locator for adapterar

**Status:** Under arbeid · **Prioritet:** A - Kritisk · **Estimat:** S
**Etikettar:** `adapter` `di` `foundation` `service-locator`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-163)

### Arbeidstype

**Type:** Foundation

### Brukarbehov og verdi

**Som** utviklar
**vil eg** kunne bytte adapter-implementasjon
**slik at** vi seinare kan bruke P360-oppslag utan å skrive om domenelogikk

### Akseptansekriterier

- Service locator eller enkel DI-mekanisme finst
- Standard for kodeverk er metadata-adapter
- Test kan injecte fake/mock adapter
- Omformarar (mapperar) brukar interfacet, ikkje metadata direkte

> **Merk:** Confluence-dokumentasjonen nemner `P360_AdapterFactory` for same formål. Forholdet mellom DI/service locator i K3 og factory-mønsteret i designnotatet er ikkje avklart.

---

## CRMAAREG-169 · K4 — Laste initiale kodeverk-verdiar i Salesforce

**Status:** Backlog · **Prioritet:** A - Kritisk · **Estimat:** M
**Etikettar:** `codetable` `metadata` `seed-data`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-169)

### Arbeidstype

**Type:** Technical

### Brukarbehov og verdi

**Som** teamet
**vil eg** ha første sett med gyldige kodeverk i metadata
**slik at** utvikling og test kan starte mot ekte verdiar

### Akseptansekriterier

- Case status har initiale verdiar
- Document status har initiale verdiar
- Document category har initiale verdiar
- Verdiane er kvalitetssikra og dokumenterte

---

## CRMAAREG-175 · K5 — Planleggje RPC-basert code table adapter for seinare fase

**Status:** Backlog · **Prioritet:** C - Mindre viktig · **Estimat:** S
**Etikettar:** `adapter` `codetable` `future` `rpc`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-175)

### Arbeidstype

**Type:** Technical

### Brukarbehov og verdi

**Som** utviklar
**vil eg** ha plan for seinare P360-oppslag
**slik at** metadata-løysinga ikkje blir permanent teknisk gjeld

### Akseptansekriterier

- Design for framtidig `P360CodeTableRpcService` er dokumentert
- Avhengigheiter mot `SupportService`/`GetCodeTableRows` er dokumenterte
- Byttepunkt via DI er verifisert
- Story er flytta til fase 2+

> **Avvik:** `P360CodeTableRpcService` følgjer ikkje namnestandarden. Skal truleg vere `P360_CodeTableRpcService`. Sjå GitHub-sak #994.
