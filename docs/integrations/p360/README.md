---
tittel: Public 360 (SF)
kilde: Confluence — Public 360 (SF) (PDF-eksport)
hentet: 2026-09-08
speilkopi: ja
---

# Public 360 (SF)

## Formål

Denne sida samlar dokumentasjon for Salesforce-integrasjonar mot Public 360 i Nav.

Public 360 er arkiv- og journalsystemet som blir brukt for å sikre korrekt arkivering, journalføring, sporbarheit og etterleving av arkivkrav. For Aa-registeret betyr dette at saker, journalpostar, dokument og vedlegg som blir behandla i Salesforce, skal kunne arkiverast i Public 360 med korrekt metadata og tydeleg status tilbake i Salesforce.

## Kort forklart

Salesforce er arbeidsflata der saksbehandlinga skjer.

Public 360 er autoritativt arkiv- og journalsystem.

Integrasjonen mellom Salesforce og Public 360 skal sørgje for at relevant informasjon frå Salesforce blir arkivert korrekt, utan at saksbehandlarar må føre same informasjon manuelt fleire stader.

## Kva dette området inneheld

Dette området skal samle dokumentasjon om:

- overordna arkitektur for Salesforce-integrasjonar mot Public 360
- Aa-registeret sin integrasjon mot Public 360
- API-bruk og tekniske kontraktar
- mapping mellom Salesforce-domene og Public 360-kontrakt
- autentisering og tilgang
- logging, feilhåndtering og korrelasjons-ID
- miljø, konfigurasjon og drift
- avklaringar mot P360-teamet

## Viktigaste prinsipp

Integrasjonane mot Public 360 skal byggjast etter nokre faste prinsipp:

- Salesforce-domene og Public 360-kontrakt skal vere tydeleg skilde.
- Entry points som Flow, LWC, triggerar og queueables skal ikkje bygge Public 360-requestar direkte.
- Mapping mellom Salesforce og Public 360 skal liggje i eigne mapper-/omformar-klassar.
- Transportdetaljar, headers, endpoint og serialisering skal isolerast i eigne client-/adapter-lag.
- Feil skal klassifiserast slik at vi kan skilje mellom funksjonelle feil, tekniske feil, autentiseringsfeil og retrybare feil.
- Alle hovudflytar skal kunne sporast med korrelasjons-ID.
- Sensitive data og dokumentinnhald skal ikkje loggast.

## Relevante arkitektursider

Denne integrasjonsdokumentasjonen byggjer på dei generelle arkitekturprinsippa for Aa-registeret Salesforce-pakken:

- [Arkitektur og design](../../architecture/README.md)
- [Arkitekturprinsipp, lagdeling og namnestandard](../../architecture/arkitekturprinsipp-lagdeling-og-namnestandard.md)
- [Repositorystruktur](../../architecture/repositorystruktur.md)

Desse sidene ligg på overordna nivå under Salesforce, sidan dei gjeld heile Aa-registeret-pakken og ikkje berre Public 360-integrasjonen.

Public 360-dokumentasjonen skal derfor berre beskrive det som er spesifikt for integrasjonen mot Public 360, som API-bruk, mapping, external ID, idempotens, retry, logging, miljø og drift.

## Ansvar og eigarskap

| Område                                                          | Ansvar                                                                     |
| --------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Public 360 som arkiv- og journalsystem                          | Team P360                                                                  |
| Arkivstruktur, sakstypar, journalposttypar og valideringsreglar | Team P360                                                                  |
| Salesforce-integrasjon og teknisk implementasjon                | Salesforce-teamet som eig løysinga                                         |
| Plattformstandardar for Salesforce                              | Team Platforce                                                             |
| Faglege reglar for Aa-registeret                                | Team Arbeidsforhold / produkteigar                                         |
| Drift og feilsøking                                             | Løysingseigande team, med støtte frå Team Platforce og Team P360 ved behov |

## Underliggjande sider

Følgjande sider bør liggje under dette området:

- Aa-registeret Public 360
- [Overordnet rammeverk](overordnet-rammeverk.md)
- [SIF RPC-operasjonar og kontraktsstatus](sif-rpc-operasjonar.md)
- [SIF RPC kontraktsoppslag](sif-rpc-kontrakt-oppslag.md)
- [Dependency injection og adapterval](di-og-adapterval.md)
- API og SIF RPC
- Metadata og kodeverk
- External ID-strategi
- Feilhåndtering, retry og idempotens
- Logging og overvåking
- Miljø og konfigurasjon
- Runbook og drift

## Miljø

| Miljø              | Beskriving                                             |
| ------------------ | ------------------------------------------------------ |
| Public 360 test    | Brukast for utvikling, avklaringar og integrasjonstest |
| Public 360 prod    | Produksjonsmiljø for arkivering og journalføring       |
| Salesforce sandbox | Salesforce test-/utviklingsmiljø                       |
| Salesforce prod    | Produksjonsmiljø for Aa-registeret i Salesforce        |

## Avgrensing

Denne sida dokumenterer Salesforce-integrasjonar mot Public 360.

Ho skal ikkje erstatte dokumentasjon som Team P360 eig om Public 360 som system, arkivstruktur, Noark-konfigurasjon eller intern forvaltning av Public 360.

Salesforce-dokumentasjonen skal beskrive korleis Salesforce brukar Public 360 sine grensesnitt, kva ansvar Salesforce-løysinga har, og kva avklaringar som må vere på plass for trygg arkivering.

## Relaterte sider

Desse sidene ligg utanfor Public 360-området, men er relevante for å forstå heilskapen rundt Salesforce, Aa-registeret og integrasjonsarkitekturen:

- Salesforce
- [Salesforce Integrasjoner](../README.md)
- Altinn
- Aa-registeret
- [Arkitektur og design](../../architecture/README.md)
- Logging og overvåking
- Runbook og drift
