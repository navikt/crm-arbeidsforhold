---
tittel: Utviklingsstandarder (SF)
kilde: Confluence — Utviklingsstandarder (SF) (PDF-eksport)
hentet: 2026-09-08
speilkopi: ja
---

# Utviklingsstandarder (SF)

Denne siden samler utviklingsstandarder for Aa-registeret Salesforce-løsningen.

Formålet er å gjøre det lettere å utvikle konsistent, testbart og vedlikeholdbart på tvers av teammedlemmer og funksjonsområder.

Standardene her skal være praktiske og konkrete. De skal hjelpe utviklere å ta gode valg i hverdagen, ikke være pyntedokumentasjon som ingen bruker.

## Hva hører hjemme her?

- Namnestandard for Apex, LWC, metadata og testklasser
- Teststruktur og testprinsipper
- README-struktur
- Retningslinjer for package og deploy
- Regler for plassering av kode og metadata
- Bruk av fakes, mocks og builders
- Dokumentasjonsstandarder

## Hva hører ikke hjemme her?

- Arkitekturbegrunnelser som bør være ADR
- P360-spesifikke mappingregler
- Driftshåndbøker
- Saksbehandlerdokumentasjon

## Merknad om overlapp i dette repoet

Repoet har allerede maskinlesbare utviklingsstandarder som dekker mye av det denne siden lister opp:

| Område                                    | Hvor det ligger i repoet                                                                                                |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Apex-standarder                           | [.github/instructions/salesforce-apex.instructions.md](../.github/instructions/salesforce-apex.instructions.md)         |
| LWC-standarder                            | [.github/instructions/salesforce-lwc.instructions.md](../.github/instructions/salesforce-lwc.instructions.md)           |
| Metadata-standarder                       | [.github/instructions/salesforce-metadata.instructions.md](../.github/instructions/salesforce-metadata.instructions.md) |
| Teststruktur og testprinsipper            | [.github/instructions/salesforce-testing.instructions.md](../.github/instructions/salesforce-testing.instructions.md)   |
| Navngiving, Apex-regler, Well-Architected | [force-app/main/default/AGENTS.md](../force-app/main/default/AGENTS.md)                                                 |
| Kildegrenser og lokal validering          | [AGENTS.md](../AGENTS.md)                                                                                               |

Instruksjonsfilene er fasit for agenter og styrer daglig utvikling. Denne siden er speilet fra Confluence og beskriver hva slags standarder som skal finnes, ikke standardene selv.

**Åpent spørsmål:** skal instruksjonsfilene være fasit, med Confluence som beskrivelse — eller motsatt? Se `docs/architecture/README.md` for kildeoppdelingen.
