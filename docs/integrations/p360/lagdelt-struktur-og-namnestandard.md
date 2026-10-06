---
tittel: Lagdelt struktur og namnestandard for AAReg ↔ P360-integrasjonen
kilde: Confluence — Lagdelt struktur og namnestandard for AAReg ↔ P360-integrasjonen (PDF-eksport)
kilde-url: https://confluence.adeo.no/spaces/TAF/pages/800083154/
hentet: 2026-09-08
speilkopi: ja
jira: CRMAAREG-84
---

# Lagdelt struktur og namnestandard for AAReg ↔ P360-integrasjonen

## Formål

Dette designnotatet dokumenterer dei P360-spesifikke vala for lagdeling, klasseinndeling og namngiving i Aa-registeret sin integrasjon mot Public 360.

Dokumentet byggjer på dei generelle arkitekturprinsippa for Aa-registeret Salesforce-pakken:

- [Arkitekturprinsipp, lagdeling og namnestandard](../../architecture/arkitekturprinsipp-lagdeling-og-namnestandard.md)
- [Arkitektur og design](../../architecture/README.md)
- Team Platforce naming conventions

Denne sida skal derfor ikkje definere alle generelle Salesforce-prinsipp på nytt, men vise korleis dei er brukt konkret for P360-integrasjonen.

## Kva denne sida dekkjer

- P360-spesifikke prefiks og namnemønster
- klasseinndeling for Aa-registeret P360-integrasjonen
- ansvar mellom P360 adapter, RPC client, DTO-ar, mapperar og exceptions
- korleis P360-kontraktar skal haldast skilde frå Salesforce-domene
- P360-spesifikk repostruktur
- oversikt over planlagde klassar

## Viktig avgrensing

Generelle prinsipp for lagdeling, testbarheit, naming, exceptions og repositorystruktur blir dokumenterte på overordna Salesforce-nivå.

Denne sida skal berre dokumentere det som er spesifikt for Public 360-integrasjonen.

## Designprinsipp for P360-integrasjonen

### 1. Salesforce-domene og P360-kontrakt skal vere skilde

Salesforce-domene skal uttrykkast med interne Aa-registeret-omgrep og Salesforce-data som høyrer use caset til.

P360-kontrakt skal uttrykkast som eksterne request-/response-DTO-ar og transportobjekt som høyrer til integrasjonen mot Public 360.

Regel:

- Domain service skal ikkje kjenne til P360 DTO-ar.
- Entry points skal ikkje bygge P360 requestar direkte.
- Adapter og RPC client skal ikkje jobbe direkte med SObject eller Salesforce-domene.
- Mapping skal vere den eksplisitte brua mellom intern modell og P360-kontrakt.

### 2. P360-operasjonar skal gå via adapter

P360-adapteren skal gi ei forretningsnær integrasjonsflate mot Public 360.

Orchestrator skal ikkje vite korleis P360-kall blir transportert, kva headers som trengst, eller korleis RPC-formatet ser ut.

### 3. RPC client skal eige transporten

RPC client skal eige:

- HTTP-kall
- endpoint
- headers
- timeout
- serialisering
- deserialisering
- låg-nivå transportfeil

RPC client skal ikkje kjenne Aa-registeret sitt domene eller use case-logikk.

### 4. Mapperar skal eige kontraktsomforming

Mapperar skal omforme mellom:

- intern Aa-registeret-modell
- P360 request-DTO
- P360 response-DTO
- internt resultatobjekt

Mapperar skal ikkje gjere SOQL, DML eller callouts.

## Namnestandard

### Prefix-regel for P360-integrasjonen

| Prefiks       | Bruk                                                           |
| ------------- | -------------------------------------------------------------- |
| `AAREG_`      | Aa-registeret-spesifikke klassar og use case-nær logikk        |
| `P360_`       | Public 360-spesifikke adapterar, clients, DTO-ar og exceptions |
| Ingen prefiks | Generelle, gjenbrukbare integrasjonsklassar                    |

### Kva gjer vi når ein klasse rører begge sider?

Når ein klasse både er knytt til Aa-registeret og Public 360, vel vi prefiks etter primært eigarskap.

| Klasseområde                        | Prefiks  | Grunngjeving                               |
| ----------------------------------- | -------- | ------------------------------------------ |
| Orchestratorar                      | `AAREG_` | Use caset er forankra i Aa-registeret      |
| Domain services                     | `AAREG_` | Handterer Salesforce-/Aa-registeret-domene |
| Mapperar frå Aa-registeret til P360 | `AAREG_` | Startar i Aa-registeret-use case           |
| P360 adapterar                      | `P360_`  | Høyrer til P360-integrasjonsflata          |
| P360 RPC client                     | `P360_`  | Høyrer til P360-transport                  |
| P360 DTO-ar                         | `P360_`  | Representerer P360-kontrakt                |
| P360 exceptions                     | `P360_`  | Representerer P360-spesifikke feil         |

### Interfaces

Interface-markøren `I` blir liggjande i sjølve klassenamnet, men systemprefikset kjem først for å unngå kollisjonar og for å sortere naturleg i repoet.

Mønster:

```text
P360_I<Capability>Adapter
P360_I<RpcClient>
```

Eksempel:

```text
P360_IArchiveAdapter
P360_IRpcClient
```

### Orchestrators

Mønster:

```text
AAREG_<UseCase>Orchestrator
```

Eksempel:

```text
AAREG_ArchiveApplicationOrchestrator
```

Ansvar:

- styre arkiveringsflyt frå Aa-registeret til P360
- kalle domain service
- kalle mapper
- kalle P360 adapter
- handtere resultat
- handtere feilklassifisering
- vidareføre correlation ID

### Commands og resultat

Bruk `Command` for input til use case og `Result` for internt resultat frå use case.

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

### Domain services

Mønster:

```text
AAREG_<DomainArea>DomainService
```

Eksempel:

```text
AAREG_ApplicationDomainService
AAREG_AgreementDomainService
```

Ansvar:

- hente Application-relaterte data
- hente Agreement-relaterte data
- validere internt datagrunnlag
- produsere modell som mapper kan bruke

Skal ikkje:

- kjenne til P360 DTO-ar
- gjere callouts
- kjenne til P360 endpoint, headers eller RPC-format

### DTO-ar

Bruk `Dto` berre for tekniske kontraktsobjekt som kryssar systemgrensa mot Public 360.

Mønster:

```text
P360_<Operation><Request|Response>Dto
```

Eksempel:

```text
P360_ArchiveRequestDto
P360_ArchiveResponseDto
P360_DocumentDto
P360_MetadataDto
```

### Omformarar/Mapperar

Mønster:

```text
AAREG_<Source>To<Target>Mapper
P360_<Operation>ResultMapper
```

Eksempel:

```text
AAREG_ArchiveApplicationMapper
AAREG_AgreementArchiveRequestMapper
P360_ArchiveResultMapper
```

Ansvar:

- mappe intern applikasjonsmodell til P360 request
- mappe Agreement-relaterte data til P360 request
- mappe P360-respons til internt resultatobjekt

Skal ikkje:

- gjere SOQL
- gjere DML
- gjere callouts
- skjule use case-logikk

### Adapter

Mønster:

```text
P360_<Capability>Adapter
P360_I<Capability>Adapter
```

Eksempel:

```text
P360_IArchiveAdapter
P360_ArchiveAdapter
P360_StubArchiveAdapter
P360_AdapterFactory
```

Ansvar:

- eksponere P360-operasjonar på forretningsnivå
- bruke RPC client internt
- skjule transportdetaljar
- vere enkel å stubbe eller mocke
- returnere kontrollert respons eller kaste definert exception

### RPC client

Mønster:

```text
P360_IRpcClient
P360_RpcClient
P360_RpcRequest
P360_RpcResponse
```

Ansvar:

- byggje og sende HTTP/RPC-kall
- handtere headers, auth-attributt, statuskodar og timeout
- serialisere request
- deserialisere respons
- utføre låg-nivå transportlogging

Skal ikkje:

- kjenne use case eller forretningsmeining
- vite kva Application, Agreement eller Aa-registeret betyr
- gjere domenemapping

### Exceptions

P360-integrasjonen skal ha eit tydeleg exception-hierarki.

| Klasse                      | Ansvar                                     |
| --------------------------- | ------------------------------------------ |
| `P360_IntegrationException` | Basisfeil for P360-spesifikk integrasjon   |
| `P360_ContractException`    | Feil i kontrakt eller responsformat        |
| `P360_TransportException`   | Feil i transport eller HTTP-kall           |
| `P360_ConfigException`      | Feil i P360-konfigurasjon eller oppsett    |
| `P360_MappingException`     | Feil i mapping mot eller frå P360-kontrakt |

Feilklassar skal støtte correlation ID der det er relevant.

## Klasseoversikt

### Aa-registeret orchestration

| Klasse                                 | Type         | Ansvar                                                             |
| -------------------------------------- | ------------ | ------------------------------------------------------------------ |
| `AAREG_ArchiveApplicationOrchestrator` | Orchestrator | Styrer use case for arkivering frå Aa-registeret-kontekst til P360 |
| `AAREG_ArchiveApplicationCommand`      | Command      | Input til arkiverings-use-case                                     |
| `AAREG_ArchiveApplicationResult`       | Result       | Internt resultat frå arkiverings-use-case                          |

### Aa-registeret domain

| Klasse                           | Type           | Ansvar                                         |
| -------------------------------- | -------------- | ---------------------------------------------- |
| `AAREG_ApplicationDomainService` | Domain service | Hentar og validerer Application-relaterte data |
| `AAREG_AgreementDomainService`   | Domain service | Hentar og validerer Agreement-relaterte data   |

### P360 adapter

| Klasse                    | Type         | Ansvar                                        |
| ------------------------- | ------------ | --------------------------------------------- |
| `P360_IArchiveAdapter`    | Interface    | Kontrakt for arkiveringsadapter mot P360      |
| `P360_ArchiveAdapter`     | Adapter      | Reell adapterimplementasjon mot P360          |
| `P360_StubArchiveAdapter` | Stub adapter | Stub for lokal utvikling og testnære scenario |
| `P360_AdapterFactory`     | Factory      | Vel og opprettar rett adapterimplementasjon   |

### P360 transport client

| Klasse             | Type            | Ansvar                                         |
| ------------------ | --------------- | ---------------------------------------------- |
| `P360_IRpcClient`  | Interface       | Kontrakt for låg-nivå transportclient mot P360 |
| `P360_RpcClient`   | Client          | Utfører HTTP/RPC-kall mot P360                 |
| `P360_RpcRequest`  | DTO / transport | Teknisk request-innpakking mot transportlaget  |
| `P360_RpcResponse` | DTO / transport | Teknisk respons-innpakking frå transportlaget  |

### Mapper

| Klasse                                | Type   | Ansvar                                                       |
| ------------------------------------- | ------ | ------------------------------------------------------------ |
| `AAREG_ArchiveApplicationMapper`      | Mapper | Mapper intern applikasjonsmodell til P360-arkiveringsrequest |
| `AAREG_AgreementArchiveRequestMapper` | Mapper | Mapper Agreement-relatert modell til P360-request            |
| `P360_ArchiveResultMapper`            | Mapper | Mapper P360-respons til internt resultatobjekt               |

### P360 contract / DTO

| Klasse                    | Type | Ansvar                                           |
| ------------------------- | ---- | ------------------------------------------------ |
| `P360_ArchiveRequestDto`  | DTO  | Ekstern requestkontrakt for arkiveringsoperasjon |
| `P360_ArchiveResponseDto` | DTO  | Ekstern responskontrakt for arkiveringsoperasjon |
| `P360_DocumentDto`        | DTO  | Dokumentdel av P360-kontrakt                     |
| `P360_MetadataDto`        | DTO  | Metadatadel av P360-kontrakt                     |

### P360 exception

| Klasse                      | Type      | Ansvar                                     |
| --------------------------- | --------- | ------------------------------------------ |
| `P360_IntegrationException` | Exception | Basisfeil for P360-spesifikk integrasjon   |
| `P360_ContractException`    | Exception | Feil i kontrakt eller responsformat        |
| `P360_TransportException`   | Exception | Feil i transport eller HTTP-kall           |
| `P360_ConfigException`      | Exception | Feil i P360-konfigurasjon eller oppsett    |
| `P360_MappingException`     | Exception | Feil i mapping mot eller frå P360-kontrakt |

## Oversikt over lag og avhengigheiter

| Lag            | Tillatne avhengigheiter                             | Skal ikkje kjenne til                    |
| -------------- | --------------------------------------------------- | ---------------------------------------- |
| Entry point    | Orchestrator                                        | RPC, P360 DTO-ar, transportdetaljar      |
| Orchestrator   | Domain service, mapper, adapter, result             | Låg-nivå HTTP-implementasjon             |
| Domain service | Salesforce-domene, selectors/repositories ved behov | P360 DTO-ar, RPC, transport              |
| Mapper         | Inputmodell + outputmodell                          | SOQL, DML, callouts                      |
| Adapter        | RPC client, P360 DTO-ar, mapper ved behov           | Salesforce entry points og domenehenting |
| RPC client     | Http, Named Credential, serialisering               | Use case-logikk og Salesforce-domene     |

## Repostruktur for P360-integrasjonen

P360-integrasjonen skal liggje samla under `force-app/integration/p360/`.

Målet er at integrasjonen skal vere lett å finne, lett å forstå og mogleg å flytte ut i eigen unlocked package seinare dersom det blir riktig.

```text
force-app/
  integration/
    common/
      classes/
        CorrelationContext.cls
        IntegrationLogContext.cls
        IntegrationException.cls
        ConfigurationException.cls
        TransportException.cls
        MappingException.cls

    p360/
      classes/
        orchestration/
          AAREG_ArchiveApplicationOrchestrator.cls
          AAREG_ArchiveApplicationCommand.cls
          AAREG_ArchiveApplicationResult.cls

        domain/
          AAREG_ApplicationDomainService.cls
          AAREG_AgreementDomainService.cls

        adapter/
          P360_IArchiveAdapter.cls
          P360_ArchiveAdapter.cls
          P360_StubArchiveAdapter.cls
          P360_AdapterFactory.cls

        client/
          P360_IRpcClient.cls
          P360_RpcClient.cls
          P360_RpcRequest.cls
          P360_RpcResponse.cls

        mapper/
          AAREG_ArchiveApplicationMapper.cls
          AAREG_AgreementArchiveRequestMapper.cls
          P360_ArchiveResultMapper.cls

        contract/
          dto/
            P360_ArchiveRequestDto.cls
            P360_ArchiveResponseDto.cls
            P360_DocumentDto.cls
            P360_MetadataDto.cls

        exception/
          P360_IntegrationException.cls
          P360_ContractException.cls
          P360_TransportException.cls
          P360_ConfigException.cls
          P360_MappingException.cls

      lwc/
        aaregArchiveToP360Action/
        aaregP360ArchiveStatus/

      objects/
        Application__c/
          fields/
            P360_Case_Id__c.field-meta.xml
            P360_Case_Number__c.field-meta.xml
            P360_Archive_Status__c.field-meta.xml
            P360_Last_Error__c.field-meta.xml
            P360_Last_Sync_At__c.field-meta.xml

        Agreement__c/
          fields/
            P360_Document_Id__c.field-meta.xml
            P360_Document_Number__c.field-meta.xml
            P360_Archive_Status__c.field-meta.xml

      customMetadata/
        P360_Code_Table_Value.<record>.md-meta.xml
        P360_Endpoint_Config.<record>.md-meta.xml

      permissionsets/
        AAREG_P360_Archive_User.permissionset-meta.xml
        AAREG_P360_Integration_Admin.permissionset-meta.xml
        AAREG_P360_Read_Status.permissionset-meta.xml

      namedCredentials/
        P360_SIF_RPC.namedCredential-meta.xml

      externalCredentials/
        P360_Entra_ID.externalCredential-meta.xml

      flows/
        AAREG_Archive_To_P360.flow-meta.xml
        AAREG_Retry_P360_Archive.flow-meta.xml

  tests/
    classes/
      integration/
        common/
        p360/
          AAREG_ArchiveApplicationOrchestratorTest.cls
          AAREG_ArchiveApplicationMapperTest.cls
          P360_ArchiveAdapterTest.cls
          P360_RpcClientTest.cls
          P360_ArchiveResultMapperTest.cls
```

## Kvifor P360-strukturen ligg under integrasjon

P360 er ein ekstern integrasjon og skal derfor ikkje blandast inn i generell Aa-registeret-domene- eller brukarflatekode.

Ved å leggje P360-kode under `integration/p360` blir det tydeleg:

- kva som er integrasjonsspesifikt
- kva som kan stubbe eller mockast
- kvar P360-kontraktar bur
- kvar transportlaget bur
- kva som eventuelt kan skiljast ut i eigen unlocked package seinare

## Salesforce metadata som høyrer til P360-integrasjonen

P360-integrasjonen består ikkje berre av Apex-klassar. Ho omfattar også metadata som gjer integrasjonen køyrbar, konfigurerbar, sikker og synleg for brukarane.

| Metadataområde         | Bruk i P360-integrasjonen                                                                             |
| ---------------------- | ----------------------------------------------------------------------------------------------------- |
| `classes/`             | Apex-kode for orchestration, domain service, mapperar, adapterar, RPC client, DTO-ar og exceptions    |
| `lwc/`                 | P360-spesifikke brukarflatekomponentar, til dømes arkiveringsknapp, statusvising eller retry-handling |
| `objects/`             | Felt for P360-identifikatorar, arkivstatus, feildetaljar og synkroniseringstidspunkt                  |
| `customMetadata/`      | Kodeverk, endpoint-konfigurasjon, mappingverdiar og miljøstyrt konfigurasjon                          |
| `permissionsets/`      | Tilgang til arkiveringsfunksjonar, statusfelt, konfigurasjon og administrasjon                        |
| `namedCredentials/`    | Konfigurasjon for kall mot P360/SIF RPC-endepunkt                                                     |
| `externalCredentials/` | OAuth-/Entra ID-basert autentisering mot P360                                                         |
| `flows/`               | Eventuelle Flow-baserte inngangar til arkivering, retry eller statusoppdatering                       |

Desse metadataområda skal dokumenterast som del av P360-integrasjonen når dei er spesifikke for arkivering mot Public 360.

## Prinsipp for plassering av metadata

Metadata som berre finst for å støtte P360-integrasjonen skal liggje under `force-app/integration/p360/`.

Dette gjeld både Apex-kode og Salesforce metadata som LWC, objektfelt, Custom Metadata, Permission Sets, Named Credentials, External Credentials og Flows.

Poenget er at integrasjonen skal kunne forståast, testast, pakkast og eventuelt flyttast som ein samla modul.

Felles integrasjonsgrunnlag som kan brukast på tvers av fleire integrasjonar skal liggje under `force-app/integration/common/`.

Metadata som er generell for heile Aa-registeret-pakken, og ikkje berre P360-integrasjonen, skal ikkje liggje under `integration/p360/`.

## Forhold til unlocked packages

Denne strukturen gjer det enklare å flytte funksjonalitet ut i eigne unlocked packages seinare.

Særleg gjeld dette:

- felles integrasjonsgrunnlag
- P360-spesifikk integrasjonskode
- teststøtte og fake adapterar
- metadata og konfigurasjon knytt til integrasjonen

Målet er ikkje å splitte alt i eigne pakkar no, men å unngå ei struktur som gjer det vanskeleg seinare.

## Relaterte sider

- [Arkitekturprinsipp, lagdeling og namnestandard](../../architecture/arkitekturprinsipp-lagdeling-og-namnestandard.md)
- [Arkitektur og design](../../architecture/README.md)
- [Public 360](README.md)
- [Overordnet rammeverk](overordnet-rammeverk.md)
- SIF RPC API
- Mapping mot Public 360
- External ID-strategi
- Feilhåndtering, retry og idempotens

## Merknader ved speiling

- Kjelda skriv `CorrelationContext.cl` i repostruktur-treet. Dette er tolka som ein skrivefeil for `CorrelationContext.cls` og retta her. Verifiser mot Confluence.
