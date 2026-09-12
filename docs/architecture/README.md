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

| Dokumenttype                                | Fasit      | Plassering                                             |
| ------------------------------------------- | ---------- | ------------------------------------------------------ |
| ADR-er                                      | Repoet     | `docs/adr/`                                            |
| Tekniske føringer, lagdeling, navnestandard | Repoet     | `docs/architecture/`                                   |
| Integrasjonsspesifikk teknisk dokumentasjon | Repoet     | `docs/integrations/<integrasjon>/`                     |
| Operative utviklingsstandarder              | Repoet     | `.github/instructions/`, `AGENTS.md`, relevante skills |
| Feature-spesifikasjoner                     | Repoet     | `.github/specs/`                                       |
| Arbeidsoppgaver                             | Repoet     | GitHub Issues                                          |
| Forvaltnings- og prosessdokumentasjon       | Confluence | Confluence                                             |
| Funksjonell brukerdokumentasjon             | Confluence | Confluence                                             |
| Operasjonelle runbooks                      | Confluence | Confluence                                             |

Dokumenter som er merket `speilkopi: ja` i frontmatter er kopiert fra Confluence og skal ikke redigeres her uten at kilden oppdateres. Dokumenter uten den merkingen eies av repoet.

## Utviklingsstandarder

Maskinlesbare instruksjonsfiler, `AGENTS.md` og relevante skills er fasit for agentadferd og operativ utvikling. `docs/utviklingsstandarder.md` er en speilkopi som beskriver standardområdene og peker til den operative fasiten; den skal ikke konkurrere med eller overstyre instruksjonsfilene.

README-struktur og dokumentasjonsstandarder håndheves gjennom repository-instruksjonene og etablerte dokumentmaler. Det opprettes ikke en separat, parallell standardtekst i speilkopien uten at Confluence-kilden oppdateres samtidig.

## Dokumenter i dette området

| Dokument                                                                                           | Innhold                                                            | Status              |
| -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ | ------------------- |
| [Arkitekturprinsipp, lagdeling og namnestandard](arkitekturprinsipp-lagdeling-og-namnestandard.md) | Normativ side for lagdeling, designprinsipp og navnestandard       | Speilkopi           |
| [Repositorystruktur](repositorystruktur.md)                                                        | `domain/`, `integration/`, `surfaces/`, `tests/` under `force-app` | UTKAST              |
| [P360 datamodell og asynkron arkiveringsjobb](p360-data-model-og-arkiveringsjob.md)                | `Access_Request__c`-hierarki og P360-jobbmodell                    | Delvis implementert |

Integrasjonsspesifikk dokumentasjon ligger under [docs/integrations/](../integrations/README.md).
Domenedokumentasjon ligger under [docs/domain/](../domain/README.md), brukerflater under [docs/surfaces/](../surfaces/README.md) og utviklingsstandarder i [docs/utviklingsstandarder.md](../utviklingsstandarder.md).

## ADR-er i dette repoet

Full oversikt og navngivingsregler: [docs/adr/README.md](../adr/README.md).

| ADR                                                                      | Tittel                                                                                             | Status           | Dato       |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- | ---------------- | ---------- |
| [ADR-0001](../adr/0001-arkitekturprinsipp-lagdeling-og-namnestandard.md) | Etablere felles arkitekturprinsipp, lagdeling og namnestandard for Aa-registeret Salesforce-pakken | UNDER BEHANDLING | 2026-04-26 |
| [ADR-0002](../adr/0002-accountcontactrelation-for-personkontoer.md)      | AccountContactRelation objekt brukes for kontakter tilknyttet Personkontoer                        | Foreslått        | 2026-08-26 |
| [ADR-0003](../adr/0003-e-post-for-personkonto-via-aareg-og-krr.md)       | Håndtering av e-postadresse for personkonto via AAREG og KRR                                       | Foreslått        | 2026-08-27 |
| [ADR-0004](../adr/0004-p360-composition-root-og-kontraktsgrense.md)      | P360 composition root og kontraktsgrense                                                           | Foreslått        | 2026-09-10 |
