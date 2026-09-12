---
jira: CRMAAREG-309
tittel: Arkitektur, dokumentasjon og overlevering
type: Epic
status: Under arbeid
prioritet: Medium
opprettet: 2026-03-23
kilde: Jira — CRMAAREG (CSV-eksport + XML)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-309
hentet: 2026-09-13
speilkopi: ja
---

# CRMAAREG-309 — Arkitektur, dokumentasjon og overlevering

**Type:** Epic · **Status:** Under arbeid · **Prioritet:** Medium
**Epicnamn i Jira:** `SF/P360 - Arkitektur, dokumentasjon og overlevering`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-309)

## Formål

Dokumentere løysing, drift og vidare forvaltning.

## Kvifor denne epicen finst

Ei løysing som berre éin person forstår er ikkje ferdig. Ho er gissel.

---

## CRMAAREG-310 · D1 — Dokumentere arkitektur, sekvensar og tekniske val

**Status:** Ferdig · **Prioritet:** B - Viktig · **Estimat:** M
**Etikettar:** `adr` `architecture` `documentation`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-310)

### Arbeidstype

**Type:** Documentation

### Brukarbehov og verdi

**Som** utviklar og forvaltar
**vil eg** forstå løysinga og kvifor ho er bygd slik
**slik at** vidareutvikling og vedlikehald blir mogleg

### Akseptansekriterier

- Arkitekturdiagram finst
- Sekvensdiagram finst for case, journalpost og file
- Adaptermønsteret for metadata er dokumentert
- ADR-ar for sentrale val finst

### Avhengigheiter

Avheng av: CRMAAREG-84 (F1)

### Status i repoet

Fullført for gjeldande D1-scope:

| Akseptkriterium                            | Status                                                                                                                                                                                         |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Arkitekturdiagram                          | Ferdig — komponent-, no-status- og relasjonsdiagram er lenka frå [diagramregisteret](../../../README.md#diagramregister)                                                                       |
| Sekvensdiagram for case, journalpost, file | Ferdig for dokumentert kontraktgrense og gjeldande interne flytar; diagramma skal vidareførast når ende-til-ende transport blir implementert                                                   |
| Adaptermønsteret for metadata dokumentert  | Ferdig for gjeldande composition-root- og adapterval i [di-og-adapterval.md](../../../integrations/p360/di-og-adapterval.md)                                                                   |
| ADR-ar for sentrale val                    | Ferdig for gjeldande scope gjennom [ADR-0001](../../../adr/0001-arkitekturprinsipp-lagdeling-og-namnestandard.md) og [ADR-0004](../../../adr/0004-p360-composition-root-og-kontraktsgrense.md) |

---

## CRMAAREG-315 · D2 — Dokumentere drift, støtte og overlevering

**Status:** Under arbeid · **Prioritet:** B - Viktig · **Estimat:** M
**Etikettar:** `documentation` `handover` `operations`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-315)

### Arbeidstype

**Type:** Documentation

### Brukarbehov og verdi

**Som** driftsperson og forvaltar
**vil eg** ha praktisk dokumentasjon
**slik at** teamet kan handtere løysinga utan personavhengigheit

### Akseptansekriterier

- Driftsguide finst
- Feilsøkingsguide finst
- Re-køyringsprosess er dokumentert
- Kjent teknisk gjeld og fase 2-punkt er dokumenterte

### Merknad om teknisk gjeld

Siste kriterium overlappar med arbeidet som allereie er gjort i GitHub. Fase 2-punkt er alt identifiserte i K5 (CRMAAREG-175), X3 (CRMAAREG-266) og FLS3 (CRMAAREG-250), som alle er merkte «flytta til fase 2+».

Kjent teknisk gjeld i repoet er sporet i GitHub-sakene #975–#995.
