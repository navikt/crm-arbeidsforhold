---
jira: CRMAAREG-83
tittel: Teknisk grunnmur og integrasjonskontraktar
type: Epic
status: Under arbeid
prioritet: A - Kritisk
opprettet: 2026-03-16
kilde: Jira — CRMAAREG (CSV-eksport + XML)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-83
hentet: 2026-09-13
speilkopi: ja
---

# CRMAAREG-83 — Teknisk grunnmur og integrasjonskontraktar

**Type:** Epic · **Status:** Under arbeid · **Prioritet:** A - Kritisk
**Epicnamn i Jira:** `SF/P360 - Teknisk grunnmur og integrasjonskontraktar`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-83)

## Formål

Etablere stabile tekniske kontraktar, service-skal og datamodellar slik at fleire utviklarar kan jobbe parallelt tidleg.

## Kvifor denne Epicen finst

Utan dette får de tett kopla kode, uklar ansvarsdelding og blokkeringar mellom utviklarar.

---

## CRMAAREG-84 · F1 — Etablere integrasjonskontraktar og namnestandard

**Status:** Ferdig · **Prioritet:** A - Kritisk · **Estimat:** S
**Etikettar:** `architecture` `contract` `foundation`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-84)

### Arbeidstype

**Type:** Foundation

### Brukarbehov og verdi

**Som** løysingsarkitekt
**vil eg** definere felles tekniske kontraktar og namnestandard
**slik at** teamet kan utvikle konsistent og parallelt

### Beskrivelse

Definere ansvar for service-lag, mapperar, DTO-ar, exceptions, logging og adapterar.

### Akseptansekriterier

- Namnestandard for interfaces, services, DTO-ar, mapperar og exceptions er dokumentert
- Ansvar mellom orchestration, domain service, RPC client, mapper og adapter er definert
- Skilje mellom Salesforce-domene og P360-kontrakt er dokumentert

### Risiko og avklaringar

Må låsast tidleg for å unngå rework

### Opnar for parallelt arbeid

Ja, blokkerande enabler

### Avhengigheiter

Blokkerer: CRMAAREG-89 (F2), CRMAAREG-101 (F3), CRMAAREG-121 (F5), CRMAAREG-143 (K1), CRMAAREG-255 (X1), CRMAAREG-310 (D1)

### Sub-taskar

CRMAAREG-85, CRMAAREG-86, CRMAAREG-87, CRMAAREG-88 — ikkje eksporterte.

### Leveransekommentar (2026-04-24)

Dokumentet «Lagdelt struktur og namnestandard for AAReg ↔ P360-integrasjonen» er utarbeidd og publisert på Confluence:
`https://confluence.adeo.no/spaces/TAF/pages/800083154/`

Dette dekkjer acceptance criteria:

- Namnestandard for interfaces, services, DTO-ar, mapperar og exceptions er definert
- Lagdeling og ansvar mellom orchestrator, domain service, mapper, adapter og RPC client er tydeleg beskrive
- Klårt skilje mellom Salesforce-domene og P360-kontrakt er etablert
- Repostruktur og planlagde klassar/interfaces er dokumenterte

Dokumentet etablerer også grunnlag for vidare arbeid i F2–F7 (DTO-ar, exceptions, logging, testbarheit), slik at utvikling kan skje parallelt og konsistent.

F1 blir vurdert som levert. Eventuelle justeringar blir teke som endringar i design, ikkje som manglande leveranse på F1.

> **Speilkopi i repoet:** [docs/integrations/p360/lagdelt-struktur-og-namnestandard.md](../../../integrations/p360/lagdelt-struktur-og-namnestandard.md)

---

## CRMAAREG-89 · F2 — Opprette domeneinterfaces og service skeletons

**Status:** Ferdig · **Prioritet:** A - Kritisk · **Estimat:** M
**Etikettar:** `apex` `foundation` `scaffold` `service`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-89)

### Arbeidstype

**Type:** Foundation

### Brukarbehov og verdi

**Som** utviklar
**vil eg** ha stabile service-signaturar
**slik at** eg kan kode mot kontrakten før full implementasjon er ferdig

### Beskrivelse

Opprette interfaces og concrete skeletons for archive adapter, RPC client, AAReg domain/orchestrator.

External ID skal støttast på kontraktsnivå (metodesignaturar), men full strategi og implementasjon ligg i X1 (CRMAAREG-255) og X3 (CRMAAREG-266). DTO-ar for external ID blir etablert i F3 (CRMAAREG-101).

### Akseptansekriterier

- Interfaces finst for sentrale tenester
- Concrete skeleton classes finst
- Metodesignaturar er dokumenterte og «ferdig nok»
- Stubbar returnerer kontrollert respons eller kastar definert exception

### Risiko og avklaringar

Må halde domenenamn skilde frå P360 service-namn

### Avhengigheiter

Avheng av: CRMAAREG-84 (F1). Refererer til CRMAAREG-101 (F3), CRMAAREG-255 (X1), CRMAAREG-266 (X3).

---

## CRMAAREG-101 · F3 — Opprette request/response DTO-ar og interne Apex data classes

**Status:** Under arbeid · **Prioritet:** A - Kritisk · **Estimat:** M
**Etikettar:** `apex` `contract` `dto` `foundation`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-101)

### Arbeidstype

**Type:** Foundation

### Brukarbehov og verdi

**Som** utviklar
**vil eg** ha tydelege datakontraktar
**slik at** serialisering, mapping og testing kan skje isolert

### Beskrivelse

Lage interne Salesforce context classes og P360 request/response DTO-ar.

### Akseptansekriterier

- DTO-ar finst for case, document og file
- Interne context classes finst for Salesforce-data
- Serialisering/deserialisering kan testast
- Obligatoriske og valfrie felt er dokumenterte

### Risiko og avklaringar

P360 payload kan krevje små justeringar seinare

### Avhengigheiter

Avheng av: CRMAAREG-84 (F1)

---

## CRMAAREG-115 · F4 — Opprette omformar (mapper) skeletons

**Status:** Backlog · **Prioritet:** A - Kritisk · **Estimat:** S/M
**Etikettar:** `apex` `foundation` `mapping`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-115)

### Arbeidstype

**Type:** Foundation

### Brukarbehov og verdi

**Som** utviklar
**vil eg** ha omformarar (mapperar) som eig all transformasjon
**slik at** service-laget slepp å bli ein søppelbøtte av logikk

### Beskrivelse

Lage omformar (mapper) skeletons for case, journalpost og file.

### Akseptansekriterier

- Omformar (mapper) skeletons finst
- Input/output-signaturar er fastlagde
- TODO-punkt for avklaringar er tydeleg markerte
- Omformarane (mapperane) kan kallast frå service-laget

### Risiko og avklaringar

Feltmapping må avklarast med fag og P360-reglar

---

## CRMAAREG-121 · F5 — Etablere exception hierarchy og feilmodell

**Status:** Under arbeid · **Prioritet:** A - Kritisk · **Estimat:** S
**Etikettar:** `error-handling` `exception` `foundation`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-121)

### Arbeidstype

**Type:** Foundation

### Brukarbehov og verdi

**Som** utviklar og driftsperson
**vil eg** ha standard feilmodell
**slik at** feilhåndtering og logging blir konsistent

### Akseptansekriterier

- Eigne exceptions finst for auth, validering, timeout, integrasjonsfeil, manglande mapping og retrybar feil
- Feilklassar støttar korrelasjons-ID
- Retrybar og ikkje-retrybar feil kan skiljast
- Feilmodell er dokumentert

### Avhengigheiter

Avheng av: CRMAAREG-84 (F1)

> **Avvik:** Denne lista stemmer ikkje med exception-hierarkiet i ADR-0001. Sjå GitHub-sak #993.

---

## CRMAAREG-129 · F6 — Etablere logging helper og correlation ID-støtte

**Status:** Under arbeid · **Prioritet:** A - Kritisk · **Estimat:** M
**Etikettar:** `correlation-id` `foundation` `logging` `observability`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-129)

### Arbeidstype

**Type:** Foundation

### Brukarbehov og verdi

**Som** utviklar og driftsperson
**vil eg** ha strukturert logging og korrelasjons-ID
**slik at** vi kan spore ei flyt frå Salesforce til P360

### Akseptansekriterier

- Det finst helper for strukturert logging
- Korrelasjons-ID kan opprettast og vidareførast
- Sensitiv informasjon blir ikkje logga
- Logging-format er dokumentert

---

## CRMAAREG-135 · F7 — Opprette mock/fake services og basis test classes

**Status:** Under arbeid · **Prioritet:** A - Kritisk · **Estimat:** M
**Etikettar:** `foundation` `mock` `test`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-135)

### Arbeidstype

**Type:** Foundation

### Brukarbehov og verdi

**Som** utviklar
**vil eg** ha fake implementasjonar og test-builders
**slik at** eg kan jobbe utan ekte P360-avhengigheit

### Akseptansekriterier

- Fake services finst for sentrale interfaces
- Basis test class finst
- Test data builders finst
- Eksempeltest viser korleis fake implementations blir brukt
