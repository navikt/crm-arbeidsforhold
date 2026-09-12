---
jira: CRMAAREG-295
tittel: Test, kvalitet og verifikasjon
type: Epic
status: Under arbeid
prioritet: Medium
opprettet: 2026-03-23
kilde: Jira — CRMAAREG (CSV-eksport + XML)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-295
hentet: 2026-09-13
speilkopi: ja
---

# CRMAAREG-295 — Test, kvalitet og verifikasjon

**Type:** Epic · **Status:** Under arbeid · **Prioritet:** Medium
**Epicnamn i Jira:** `SF/P360 - Test, kvalitet og verifikasjon`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-295)

## Formål

Sikre at løysinga er testa frå einingstest til ende-til-ende.

## Kvifor denne epicen finst

«Det funka i sandbox ein gong» er ikkje kvalitet. Det er berre eit minne.

---

## CRMAAREG-296 · T1 — Etablere einingstestar og kontraktstestar

**Status:** Under arbeid · **Prioritet:** A - Kritisk · **Estimat:** M
**Etikettar:** `contract-test` `test` `unit-test`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-296)

### Arbeidstype

**Type:** Test

### Brukarbehov og verdi

**Som** utviklar
**vil eg** ha raske og stabile testar
**slik at** vi kan refaktorere trygt

### Akseptansekriterier

- DTO-serialisering er testa
- Omformarar (mapperar) er testa
- Exceptions er testa
- Fake adapters og fake services blir brukte
- Happy path og sad path er dekte

### Relatert kontekst

Byggjer på F7 (CRMAAREG-135), som lagar fake services og test builders.

Repoet har eigen TDD-praksis i `.github/skills/tdd-salesforce/SKILL.md` og testinstruks i `.github/instructions/salesforce-testing.instructions.md`. Namnestandarden for testklassar er `<ClassBeingTested>Test`.

> **Org-avhengig:** Apex-testar kan ikkje køyrast utan autentisert Salesforce-org.

---

## CRMAAREG-303 · T2 — Etablere integrasjonstest mot miljø

**Status:** Backlog · **Prioritet:** A - Kritisk · **Estimat:** L
**Etikettar:** `e2e` `integration-test` `test`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-303)

### Arbeidstype

**Type:** Test

### Brukarbehov og verdi

**Som** teamet
**vil eg** verifisere ekte kallflyt
**slik at** vi veit at løysinga fungerer utanfor fine tankar og falske mockar

### Akseptansekriterier

- Case create kan testast mot miljø
- Journalpost create kan testast mot miljø
- Filflyt kan testast mot miljø
- Auth-feil, timeout og valideringsfeil er testa
- Resultat kan sporast med correlation ID

### Miljø

`Overordnet rammeverk` listar fire miljø: Public 360 test, Public 360 prod, Salesforce sandbox, Salesforce prod. Konkrete URL-ar ligg i Confluence.

> **Org-avhengig og krev tilgang til P360 test.** Kan ikkje køyrast lokalt.
