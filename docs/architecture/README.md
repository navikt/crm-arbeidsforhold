---
tittel: Arkitektur og design (SF)
kilde: Confluence — Arkitektur og design (SF) (PDF-eksport)
hentet: 2026-09-08
speilkopi: delvis
---

# Arkitektur og design (SF)

Denne siden samler arkitektur- og designbeslutninger for Salesforce-løsningen til Aa-registeret.

Formålet er å gi utviklere, arkitekter og forvaltere ett sted å finne tekniske føringer, strukturelle valg og begrunnelser for hvordan løsningen er bygget.

Her dokumenterer vi beslutninger som påvirker flere deler av løsningen, for eksempel repositorystruktur, lagdeling, avhengigheter, integrasjonsmønstre, tekniske grenser og overordnede designprinsipper.

## Hva hører hjemme her?

- Overordnet arkitektur for Aa-registeret Salesforce-pakken
- Repositorystruktur og mappestruktur
- Lagdeling og ansvarsdeling
- Designprinsipper som gjelder på tvers av funksjonsområder
- ADR-er som påvirker flere deler av løsningen
- Tekniske valg som bør være stabile over tid

## Hva hører ikke hjemme her?

- Detaljert dokumentasjon for én spesifikk integrasjon
- Operasjonelle runbooks
- Enkeltstående feilbeskrivelser
- Midlertidige notater fra utviklingsarbeid
- Funksjonell brukerdokumentasjon

Detaljer for konkrete integrasjoner ligger under `Salesforce / Integrasjoner`.

## Hvor er fasit?

Vi deler kilden etter dokumenttype:

| Dokumenttype                                | Fasit      | Plassering                         |
| ------------------------------------------- | ---------- | ---------------------------------- |
| ADR-er                                      | Repoet     | `docs/adr/`                        |
| Tekniske føringer, lagdeling, navnestandard | Repoet     | `docs/architecture/`               |
| Integrasjonsspesifikk teknisk dokumentasjon | Repoet     | `docs/integrations/<integrasjon>/` |
| Feature-spesifikasjoner                     | Repoet     | `.github/specs/`                   |
| Arbeidsoppgaver                             | Repoet     | GitHub Issues                      |
| Forvaltnings- og prosessdokumentasjon       | Confluence | Confluence                         |
| Funksjonell brukerdokumentasjon             | Confluence | Confluence                         |
| Operasjonelle runbooks                      | Confluence | Confluence                         |

Dokumenter som er merket `speilkopi: ja` i frontmatter er kopiert fra Confluence og skal ikke redigeres her uten at kilden oppdateres. Dokumenter uten den merkingen eies av repoet.

## Dokumenter i dette området

| Dokument                                                                                           | Innhold                                                            | Status    |
| -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ | --------- |
| [Arkitekturprinsipp, lagdeling og namnestandard](arkitekturprinsipp-lagdeling-og-namnestandard.md) | Normativ side for lagdeling, designprinsipp og navnestandard       | Speilkopi |
| [Repositorystruktur](repositorystruktur.md)                                                        | `domain/`, `integration/`, `surfaces/`, `tests/` under `force-app` | UTKAST    |

Integrasjonsspesifikk dokumentasjon ligger under [docs/integrations/](../integrations/README.md).
Domenedokumentasjon ligger under [docs/domain/](../domain/README.md), brukerflater under [docs/surfaces/](../surfaces/README.md) og utviklingsstandarder i [docs/utviklingsstandarder.md](../utviklingsstandarder.md).

## ADR-er i dette repoet

Full oversikt og navngivingsregler: [docs/adr/README.md](../adr/README.md).

| ADR                                                                      | Tittel                                                                                             | Status           | Dato       |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- | ---------------- | ---------- |
| [ADR-0001](../adr/0001-arkitekturprinsipp-lagdeling-og-namnestandard.md) | Etablere felles arkitekturprinsipp, lagdeling og namnestandard for Aa-registeret Salesforce-pakken | UNDER BEHANDLING | 2026-04-26 |
