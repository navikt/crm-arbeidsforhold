---
tittel: P360 GitHub issue-triage og handlingsstatus
kilde: repo-state, kodemodell og dokumentert arkitektur
hentet: 2026-09-08
status: anbefalt
---

# P360 GitHub issue-triage og handlingsstatus

## Mål

Dette dokumentet skiller mellom:

- faktiske implementation blockers for P360-integrasjonen
- repo- og dokumentasjonsarbeid som allerede er løst eller kun er administrativt
- saker som bør bli stående i backlogen fordi de påvirker fremtidig implementasjon

## Kategorisering

### 1) Aktivt implementasjonsarbeid som bør beholdes åpent

Disse punktene er reelle blocker for koden vi faktisk skal implementere:

- `A2` / `976`: etablere felles exception-hierarki for integrasjoner
- `A3` / `977`: avklare navnekonvensjonsbrudd i Apex-klasser
- `A4` / `978`: rydde legacy testmetodenavn
- `A5` / `979`: vurdere Sev2 CRUD/FLS-funn etter PMD-suppress
- `A6` / `980`: rydde motstridende eksempler i `AGENTS.md`
- `D1` / `993`: avklare exception-hierarki i forhold til ADR-0001
- `D2` / `994`: rette klassenavn som bryter navnestandard
- `D3` / `995`: kontraktsdokumentasjon for P360-operasjoner
- `E1` / `996`: avklare forholdet mellom DI/service locator og `P360_AdapterFactory`
- `E2` / `997`: avklare eierforhold til runbook
- `E3` / `998`: registrere manglende avhengigheter i Jira og rydde `CRMAAREG-194`

Dette er de issue-funnene som fortsatt har reell verdi for den videre implementasjonen.

### 2) Dokumentasjons-/cleanup-arbeid som er løst eller skal holdes på lav prioritet

Dette er hovedsakelig arbeid som allerede er håndtert i repoet eller som representerer overflødig speilingsarbeid:

- `B1` / `981`: speile Confluence-arkitekturprinsipp til docs
- `B2` / `982`: speile lagdelt struktur og namnestandard
- `B3` / `983`: speile P360 API- og kontraktsdokumentasjon
- `B4` / `984`: legge inn Confluence URL i frontmatter
- `C1` / `988`: normalisere ADR-nummerering og statusvokabular
- `C2` / `989`: avklare utviklingsstandarder
- `C3` / `990`: policy for personnavn og miljø-URL-er i offentlig repo
- `C4` / `991`: oppdatere `CONTEXT.md` og `AGENTS.md` med ny docs-struktur
- `C5` / `992`: verifisere speiling fra PDF
- `A7` / `986`: flytte Altinn-testbrukerlegitimasjon ut av repoet
- `A8` / `987`: oppdatere rot-README

Dette er ikke de samme som den faktiske P360-implementasjonsblokkeringen. De kan holdes som backlog, flyttes til dokumentasjonsarbeid eller lukkes som løst når repoet er driftsklart.

### 3) Dokumentert som “ikke valgt i denne runden”

Noen issue-funn er relevante for prosjekthåndtering, men ikke for den konkrete implementasjonsfase vi er i nå:

- `A1` / `975`: migreringsstrategi for ADR-strukturen
- `A2` / `976` og `A3` / `977` er mer håndterings-/kvalitetsarbeid, men målrettet mot samme kodebase
- `D1` / `993` og `D2` / `994` er del av formell kodekvalitet og designkonformitet, ikke selve transportimplementasjon

Disse kan ligge i backlogen frem til vi har valgt et konkret utviklingsspor.

## Anbefalt driftstatus

### Behold åpent

Det bør være et tydelig fokus på disse emnene:

1. exception hierarchy og feilmodell
2. kontrakt og DTO-definisjon for P360
3. auth/header-konfigurasjon og SIF RPC-protokoll
4. første faktisk fungerende adapter/transport-implementasjon
5. repo-quality cleanup som peker direkte på implementasjonsfremdrift

### Lukk som løst eller stale når repoet er klart

Hvis vi vurderer dokumentasjonsspeiling og repo-cleanup som ferdig, kan disse lukkes:

- `A7`, `A8`, `B1`, `B2`, `B3`, `B4`, `C1`, `C2`, `C3`, `C4`, `C5`

### Behold i backlogen uten å bruke dem som nåværende blocker

- `A1`, `A2`, `A3`, `A4`, `A5`, `A6`, `E1`, `E2`, `E3`

## Konklusjon

Den faktiske blokka for videre P360-arbeid er ikke “repoet er tomt” eller “vi mangler designarkitektur”. Den faktiske blokka er at vi fortsatt mangler en tydelig og formelt avklart kontrakt, auth og feilmodell mellom Salesforce og Public 360.

Derfor bør vi bruke repoet som den autoritative kilden og holde de tekniske P360-issue-funnene åpne, mens de rent dokumentasjons- og speilingsoppgavene enten lukkes eller flyttes til et lavprioritert backlog-lag.
