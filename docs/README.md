# Dokumentasjon for Arbeidsforhold og Aa-registeret

Start i [handboka](architecture/aaregisteret-handbok.md) for å forstå
produktet, brukarvegane og korleis delane heng saman. Bruk kartet nedanfor
når du har eit konkret spørsmål.

## Finn fram etter behov

| Eg vil                                   | Start her                                                                                                                                              |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Forstå produktet og arkitekturen         | [Handboka](architecture/aaregisteret-handbok.md), [heile løysinga](architecture/hele-loysinga.md), [domene](domain/README.md)                          |
| Sjå kva kvar Flow gjer                   | [Flow-katalog](architecture/aareg-flow-katalog.md) og [Flow-diagram](architecture/aareg-flow-diagrammer.md)                                            |
| Forstå P360 og dei opne kontraktane      | [P360](integrations/p360/README.md) og [datamodell](architecture/p360-data-model-og-arkiveringsjob.md)                                                 |
| Forstå Altinn og tilgang                 | [Altinn](integrations/altinn/README.md) og [tilgangskjeda](integrations/altinn/tilgangskjede-og-scenario.md)                                           |
| Finne andre integrasjonar                | [Integrasjonar](integrations/README.md)                                                                                                                |
| Kartleggje avhengnader                   | [Pakkar](architecture/pakkeavhengigheiter.md) og [kallstader](architecture/aaregisteret-pakkekallsite-matrise.md)                                      |
| Planleggje testar og syntetiske data     | [Scenario-testplan](testing/aaregisteret-scenario-testplan.md) og [testdatastrategi](testing/aaregisteret-testdata-strategi.md)                        |
| Finne interne og eksterne flater         | [Brukarflater](surfaces/README.md) og [Admin-app: plan og status](surfaces/aareg-admin-app.md)                                                         |
| Setje opp utviklingsmiljø                | [Utviklarguide](kom-i-gang.md), [skriptguide](../bin/README.md) og [kommandoreferanse](../bin/COMMANDS.md)                                             |
| Finne drift og leveranse                 | [Metadataopprydding](operations/salesforce-metadata-cleanup-runbook.md), [workflowar](operations/workflows.md) og [støtteskript](../scripts/README.md) |
| Lese tekniske val og forslag             | [ADR-register](adr/README.md) og [forbetringsforslag](architecture/forbetringsforslag-og-malmodell.md)                                                 |
| Finne eldre analysar og testresultat     | [Dokumentasjonsarkivet](archive/README.md)                                                                                                             |
| Finne standardar og dokumentasjonsansvar | [Utviklingsstandardar](utviklingsstandarder.md) og [arbeidsflyt](arbeidsflyt-og-dokumentasjon.md)                                                      |

## Diagramregister

Diagram finst både direkte i Markdown og som eigne Mermaid-kjelder. Start med
[produktbiletet](architecture/aaregisteret-handbok.md#det-store-biletet),
[grupperte Flow-diagram](architecture/aareg-flow-diagrammer.md) eller
[P360-flyten](integrations/p360/kodegjennomgang.md#ein-søknad-på-p360test).

| Område          | Sjølvstendige diagramkjelder                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Generell flyt   | [E-postflyt](AAREG_emailFlow.mmd), [kodebaseflyt](AAREG_codebaseFlowchart.mmd)                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| Data            | [Application-modell](AAREGerDiagramApplication.mmd), [ny Application-modell](AAREGerDiagramApplicationNew.mmd)                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| Pakkar          | [Pakkeoversikt](architecture/pakkeoversikt.mmd), [avhengigheitskjerne](architecture/pakkeavhengigheiter-kjerne.mmd), [preflight](architecture/pakkeversjon-preflight.mmd)                                                                                                                                                                                                                                                                                                                                                                            |
| P360            | [Komponentar](architecture/p360-component-diagram.mmd), [klassar](architecture/p360-class-diagram.mmd), [arkivsekvens](architecture/p360-archive-sequence.mmd), [datamodell](architecture/p360-data-model-relationships.mmd), [arkitekturgrenser](integrations/p360/diagrams/p360-current-architecture.mmd), [frigiving](integrations/p360/diagrams/p360-decision-release-sequence.mmd), [jobboppretting](integrations/p360/diagrams/p360-idempotent-job-creation-sequence.mmd), [jobbstatus](integrations/p360/diagrams/p360-archive-job-state.mmd) |
| Arbeidskontekst | [P360 Jira-avhengnader](context/p360/diagrams/p360-jira-dependencies.mmd), [Altinn-scenario](integrations/altinn/diagrams/consumer-scenarios.mmd)                                                                                                                                                                                                                                                                                                                                                                                                    |

## Kva er kjelde, forslag og evidens?

- Kode og metadata viser kva som finst i den **undersøkte greina**. Dei beviser
  ikkje kva som er installert eller aktivt i eit org.
- Ein lokal test eller mock beviser berre det den konkrete testen kontrollerer.
  Ekstern arkivering eller sending krev separat mottaksevidens.
- Orgobservasjonar og testloggar gjeld den registrerte datoen, versjonen og
  handlinga. Eldre rapportar ligg i [arkivet](archive/README.md).
- ADR-ar viser arkitekturval og tilhøyrande beslutningsstatus. Planar og
  forslag er ikkje det same som levert eller godkjend funksjonalitet.
- Dokument merkte `speilkopi: ja` er kopierte frå Confluence og skal ikkje
  endrast her utan at kjelda blir oppdatert. Jira-/Confluence-spegel er
  kontekst; Issues viser arbeidsoppgåver og opne avklaringar.

Oppbevar aldri secrets, credentials eller persondata i dokumentasjonen.
[Repo-README](../README.md) er inngang til oppsett og bidrag.

## Bygg nettsida lokalt

Frå reporota, med Python 3.11:

```shell
python3 -m venv .venv-docs
.venv-docs/bin/python -m pip install --require-hashes --only-binary=:all: -r requirements-docs.txt
.venv-docs/bin/python -m unittest discover -s docs-site/tests
.venv-docs/bin/python docs-site/build_docs.py
.venv-docs/bin/python docs-site/check_site.py site
```

Bygget ligg i `site/`. Mermaid blir lasta ned under bygging, kontrollert mot
ein fast hash og servert lokalt saman med lisensen. GitHub Pages blir først
oppdatert når deploy frå `main` er godkjend og fullført.
