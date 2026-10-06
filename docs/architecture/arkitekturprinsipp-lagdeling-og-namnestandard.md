---
tittel: Arkitekturprinsipp, lagdeling og namnestandard (SF)
kilde: Confluence — Arkitekturprinsipp, lagdeling og namnestandard (SF) (PDF-eksport)
hentet: 2026-09-08
speilkopi: ja
normativ: ja
---

# Arkitekturprinsipp, lagdeling og namnestandard (SF)

## Formål

Denne sida definerer felles arkitekturprinsipp, lagdeling og namnestandard for Aa-registeret Salesforce-pakken.

Målet er å sikre at kode og metadata blir strukturert på ein måte som er konsistent, testbar, forståeleg og mogleg å vidareutvikle over tid.

Dette gjeld både for generell funksjonalitet i Aa-registeret og for integrasjonar som Public 360, Altinn og Maskinporten.

## Kvifor denne sida finst

Aa-registeret Salesforce-pakken skal kunne utviklast av fleire personar over tid utan at løysinga blir tett kopla, vanskeleg å teste eller vanskeleg å forstå.

Felles prinsipp skal bidra til:

- konsekvent utvikling på tvers av teammedlemmer
- tydelege tekniske grenser
- testbar og vedlikehaldbar kode
- låg risiko for klassenamnkollisjonar i Apex sitt flate namespace
- betre støtte for stub, fake og mock i test og utvikling
- ryddig skilje mellom Salesforce-domene og eksterne integrasjonskontraktar
- sentral logging, sporbarheit og kontrollert feilhandtering
- betre grunnlag for å skilje funksjonalitet ut i eigne unlocked packages seinare

## Normative referansar

Denne dokumentasjonen byggjer på Team Platforce sin dokumenterte namnestandard, som alle team i Nav som byggjer på Salesforce skal forhalde seg til.

Primære referansar:

- Platforce Docs
- Naming Conventions
- Casing Styles
- Apex Classes
- Apex Test Classes

Øvrige referansar som skal reknast som styrande for vidare arbeid:

- Annotations
- Apex Constants
- Apex Methods
- Apex Test Methods
- Apex Variables
- Approval Processes
- Approval Process Steps
- Custom Fields
- Custom Objects
- Flows
- Flow Elements

## Språk

All metadata og kode skal namngivast på engelsk.

Brukarvendte etikettar kan oversetjast til norsk via Salesforce sin oversettingsmekanisme.

| Type          | Eksempel                                           |
| ------------- | -------------------------------------------------- |
| Apex class    | `AAREG_ApplicationDomainService`                   |
| Felt/API-namn | Engelsk                                            |
| Label         | Kan vere norsk                                     |
| Dokumentasjon | Norsk, nynorsk eller bokmål, avhengig av målgruppe |

## Casing

Apex-klasser skal bruke PascalCase.

Variablar, metodar, konstantar og testmetodar skal følgje Team Platforce sine namnestandardar og blir ikkje redefinerte her.

Prefiks blir skilde frå klassenamnet med eitt underscore, i tråd med Platforce sin klassekonvensjon.

### Klassemønster

Platforce-standard for Apex classes er:

```text
<Namespace>_<Class Name><Optional Suffix>
```

For Aa-registeret brukar vi korte og tydelege prefiks der det er behov for å skilje ansvar eller redusere risiko for kollisjonar.

Eksempel:

```text
AAREG_ApplicationDomainService
P360_ArchiveAdapter
```

### Testklassar

Platforce-standard for Apex test classes er:

```text
<Class Being Tested>Test
```

Det betyr:

- ingen underscore før `Test`
- testklassar skal byggjast direkte på produksjonsklassen sitt namn

Eksempel:

```text
AAREG_ApplicationDomainServiceTest
P360_ArchiveAdapterTest
```

### Apex-klassenamn

Apex-klassenamn skal vere maks 40 teikn.

Dette er ein hard Salesforce-grense og må vurderast når vi namngir klassar, særleg for integrasjonar der prefiks, capability og suffix fort kan gi lange namn.

## Designprinsipp

### 1. Salesforce-domene og eksterne kontraktar skal vere skilde

Salesforce-domene skal uttrykkast med interne omgrep som høyrer til Aa-registeret og Salesforce-løysinga.

Eksterne kontraktar skal uttrykkast som eigne request-/response-DTO-ar eller transportobjekt knytt til den aktuelle integrasjonen.

Regel:

- Domain service skal ikkje kjenne til eksterne DTO-ar.
- Entry points skal ikkje bygge eksterne requestar direkte.
- Adapter og client skal ikkje jobbe direkte med SObject eller Salesforce-domene.
- Mapping skal vere den eksplisitte brua mellom intern modell og ekstern kontrakt.

### 2. Use case skal styrast av orchestrator

Orchestrator eig flyten for ein konkret operasjon.

Han koordinerer:

- domenedata
- mapping
- adapterkall
- logging
- feilflyt
- resultat tilbake til kallande lag

Orchestrator skal ikkje vere ei dumping-sone for feltreglar, transportlogikk eller tilfeldige hjelpefunksjonar.

### 3. Mapping skal vere rein og testbar

Omformarar, eller mapperar, skal berre omforme data.

Dei skal ikkje:

- gjere SOQL
- gjere DML
- gjere callouts
- skjule use case-logikk
- hente konfigurasjon direkte dersom dette bør gå via eiga teneste

Mapperar skal vere enkle å teste isolert.

### 4. Adapter er ekstern grense, ikkje transportlag

Adapter skal gi ei forretningsnær integrasjonsflate mot eit eksternt system.

Client-laget tek seg av sjølve transporten.

Dette gjer at use case-kode kan snakke med ein stabil intern kontrakt utan å kjenne til endpoint, headers, HTTP-statuskodar eller serialisering.

### 5. Logging og exceptions er del av grunnmuren

Logging, correlation ID, feilklassifisering og exceptions skal vere ein integrert del av arkitekturen, ikkje noko vi legg på til slutt.

Alle viktige integrasjonsflytar skal kunne sporast frå start til slutt.

### 6. Strukturen skal støtte framtidig pakking

Strukturen skal gjere det mogleg å skilje funksjonalitet ut i eigne unlocked packages seinare.

Målet er ikkje nødvendigvis å dele alt opp i eigne pakkar no, men å unngå ei struktur som gjer det vanskeleg seinare.

Dette betyr at kode bør organiserast etter ansvar og eigarskap, ikkje berre etter kva som var raskast å lage i første sprint.

## Lagdeling og ansvar

### Entry point

Typiske eksempel:

- Trigger handler
- Invocable Apex
- Queueable
- Platform event subscriber
- LWC Apex controller

Ansvar:

- ta imot inngang til use case
- opprette eller vidareføre teknisk kontekst
- delegere til orchestrator

Skal ikkje:

- bygge eksterne DTO-ar
- utføre HTTP-kall
- implementere mapping
- leggje transportdetaljar i use case-flyten

### Orchestration

Ansvar:

- styre use case frå start til slutt
- setje opp logg- og correlation-kontekst
- kalle domain service for interne data
- kalle mapper for kontraktsomforming
- kalle adapter for ekstern operasjon
- handtere resultat og feilklassifisering

Skal ikkje:

- implementere transportlogikk
- vere ei dumping-sone for feltreglar og mapping

### Domain service

Ansvar:

- hente og validere Salesforce-data
- uttrykkje interne reglar og semantikk
- produsere internt datagrunnlag for use case

Skal ikkje:

- kjenne til eksterne request-/response-DTO-ar
- gjere callouts
- kjenne til headers, endpoint eller transportformat

### Omformar / Mapper

Ansvar:

- transformere frå intern modell til ekstern kontrakt
- transformere frå ekstern respons til internt resultatobjekt

Skal ikkje:

- gjere SOQL
- gjere DML
- gjere callouts
- skjule use case-logikk

### Adapter

Ansvar:

- eksponere eksterne operasjonar på forretningsnivå
- skjule transportdetaljar bak eit stabilt grensesnitt
- bruke client internt
- vere enkel å stubbe eller mocke

Skal ikkje:

- kjenne Salesforce entry points
- slå opp domenedata direkte
- blande domeneansvar og transportansvar

### Client

Ansvar:

- byggje og sende HTTP-kall
- handtere headers, auth-attributt, statuskodar og timeout
- serialisere request
- deserialisere respons
- utføre låg-nivå transportlogging

Skal ikkje:

- kjenne use case eller forretningsmeining
- vite kva interne Aa-registeret-omgrep betyr
- innehalde domenevalidering

### Oversikt over lag og avhengigheiter

| Lag            | Tillatne avhengigheiter                             | Skal ikkje kjenne til                    |
| -------------- | --------------------------------------------------- | ---------------------------------------- |
| Entry point    | Orchestrator                                        | Eksterne DTO-ar, RPC, transportdetaljar  |
| Orchestrator   | Domain service, mapper, adapter, result             | Låg-nivå HTTP-implementasjon             |
| Domain service | Salesforce-domene, selectors/repositories ved behov | Eksterne DTO-ar, RPC, transport          |
| Mapper         | Inputmodell + outputmodell                          | SOQL, DML, callouts                      |
| Adapter        | Client, eksterne DTO-ar, mapper ved behov           | Salesforce entry points og domenehenting |
| Client         | Http, Named Credential, serialisering               | Use case-logikk og Salesforce-domene     |

## Namnestandard

### Prefix-regel

For å redusere risiko for kollisjonar i Apex sitt flate namespace brukar vi prefiks med underscore som skiljeteikn.

Regel:

- generelle og gjenbrukbare integrasjonsklassar får ikkje domene-prefiks
- Aa-registeret-spesifikke klassar får prefiks `AAREG_`
- integrasjonsspesifikke klassar får eige integrasjonsprefiks, til dømes `P360_`
- andre integrasjonar kan få eigne prefiks dersom det er behov

### Kva gjer vi når ein klasse rører fleire område?

Når ein klasse både er knytt til Aa-registeret og eit eksternt system, vel vi prefiks etter primært eigarskap.

Hovudregel:

- orchestratorar, domain services og mapperar som er forankra i Aa-registeret-use case får `AAREG_`
- adapterar, clientar, DTO-ar og exceptions som er forankra i ekstern kontrakt får integrasjonsprefiks

Dette gjer at namna fortel kvar klassen høyrer heime, ikkje berre kva han tilfeldigvis snakkar med.

### Interfaces

Interface-markøren `I` blir liggjande i sjølve klassenamnet, men systemprefikset kjem først for å unngå kollisjonar og for å sortere naturleg i repoet.

Mønster:

```text
<Prefix>_I<Capability>
<Prefix>_I<Capability>Adapter
<Prefix>_I<Client>
```

Eksempel:

```text
P360_IArchiveAdapter
P360_IRpcClient
```

### Commands og resultat

Bruk `Command` for input til eit use case og `Result` for internt resultat frå eit use case.

Mønster:

```text
AAREG_<UseCase>Command
AAREG_<UseCase>Result
```

Eksempel:

```text
AAREG_ArchiveApplicationCommand
AAREG_ArchiveApplicationResult
```

### DTO-ar

Bruk `Dto` berre for tekniske kontraktsobjekt som kryssar systemgrenser.

Mønster:

```text
<Prefix>_<Operation><Request|Response>Dto
```

Eksempel:

```text
P360_ArchiveRequestDto
P360_ArchiveResponseDto
```

### Omformarar / Mapperar

Mønster:

```text
AAREG_<Source>To<Target>Mapper
<Prefix>_<Operation>ResultMapper
```

Eksempel:

```text
AAREG_ArchiveApplicationMapper
P360_ArchiveResultMapper
```

### Exceptions

Det skal vere eitt tydeleg exception-hierarki for integrasjonar.

Generelle exceptions:

```text
IntegrationException
ConfigurationException
TransportException
MappingException
```

Integrasjonsspesifikke exceptions kan utvide eller spesialisere desse:

```text
P360_IntegrationException
P360_ConfigException
P360_TransportException
P360_ContractException
P360_MappingException
```

## Common / delt integrasjonsgrunnlag

Felles integrasjonsgrunnlag bør på sikt flyttast ut av Aa-registeret-spesifikk kode dersom det er relevant for fleire team eller integrasjonar.

| Klasse                   | Type      | Ansvar                                    |
| ------------------------ | --------- | ----------------------------------------- |
| `CorrelationContext`     | Klasse    | Held correlation ID og relaterte sporfelt |
| `IntegrationLogContext`  | Klasse    | Held loggkontekst for integrasjonsflyt    |
| `IntegrationException`   | Exception | Felles basisfeil for integrasjonar        |
| `ConfigurationException` | Exception | Felles konfigurasjonsfeil                 |
| `TransportException`     | Exception | Felles transportfeil                      |
| `MappingException`       | Exception | Felles mappingfeil                        |

## Overordna repostruktur

Denne strukturen viser prinsippet for korleis integrasjonskode bør organiserast.

```text
force-app/
  integration/
    common/
      classes/

    <integration-name>/
      classes/
        orchestration/
        domain/
        adapter/
        client/
        mapper/
        contract/
          dto/
        exception/

      lwc/
      objects/
      customMetadata/
      permissionsets/
      namedCredentials/
      externalCredentials/
      flows/

  tests/
    classes/
      integration/
        common/
        <integration-name>/
```

## Forhold til unlocked packages

Strukturen skal gjere det enklare å flytte funksjonalitet ut i eigne unlocked packages seinare.

Dette kan til dømes vere aktuelt for:

- felles integrasjonsgrunnlag
- integrasjonsspesifikke modular
- teststøtte og fake adapterar
- metadata og konfigurasjon knytt til bestemte integrasjonar
- felles logging- og feilhandteringsmønster

Målet er ikkje å splitte alt i eigne pakkar no. Målet er å ha ei struktur som ikkje stengjer døra for det seinare.

God pakking startar ikkje med `sfdx-project.json`. Ho startar med ryddige grenser i koden.

## Integrasjonsspesifikke designnotat

Detaljar for konkrete integrasjonar skal dokumenterast på eigne sider under den aktuelle integrasjonen.

Eksempel:

- Lagdelt struktur og namnestandard for AAReg P360-integrasjonen
- Altinn-integrasjonen for Aa-registeret
- Maskinporten

## Kva som ikkje skal dokumenterast her

Denne sida skal ikkje innehalde detaljert dokumentasjon for éin spesifikk integrasjon.

Følgjande skal dokumenterast på integrasjonsspesifikke sider:

- P360-spesifikke DTO-ar
- P360 RPC API-detaljar
- Altinn API-detaljar
- Maskinporten tokenflyt
- konkrete endpoint
- konkrete scopes
- mapping mellom Salesforce og eksternt system
- konkrete retry-reglar for ein bestemt integrasjon
- driftsrutinar for ein bestemt integrasjon

## Relaterte sider

- Arkitektur og design
- Salesforce Integrasjoner
- Public 360
- Altinn
- Maskinporten
- Team Platforce naming conventions
