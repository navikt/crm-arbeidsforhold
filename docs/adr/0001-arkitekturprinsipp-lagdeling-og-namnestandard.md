---
adr: 0001
tittel: Etablere felles arkitekturprinsipp, lagdeling og namnestandard for Aa-registeret Salesforce-pakken
status: UNDER BEHANDLING
dato: 2026-04-26
kilde: Confluence — ADR-0001 (PDF-eksport)
hentet: 2026-09-08
speilkopi: ja
---

# ADR-0001: Etablere felles arkitekturprinsipp, lagdeling og namnestandard for Aa-registeret Salesforce-pakken

**Status:** UNDER BEHANDLING
**Dato:** 2026-04-26

## Kontekst

Aa-registeret Salesforce-pakken skal vidareutviklast som ei Salesforce-løysing med både generell domenefunksjonalitet og fleire integrasjonar mot eksterne system.

Dette omfattar mellom anna:

- generell Aa-registeret-funksjonalitet i Salesforce
- integrasjon mot Public 360
- integrasjon mot Altinn
- bruk av Maskinporten for autentisering mot Altinn
- framtidige integrasjonar og tekniske kapabilitetar

Pakken skal kunne utviklast av fleire personar over tid. Då treng vi felles arkitekturprinsipp, tydeleg lagdeling og ein namnestandard som gjer løysinga lettare å forstå, teste, vidareutvikle og eventuelt dele opp i eigne unlocked packages seinare.

Utan felles struktur aukar risikoen for:

- tett kopling mellom brukarflate, domene, integrasjon og transport
- at eksterne API-kontraktar lek inn i Salesforce-domene
- at Flow, LWC, triggerar eller queueables får for mykje ansvar
- at mapping blir spreidd i serviceklassar, orchestratorar eller transportlag
- at HTTP-kall, endpoint, headers og tokenlogikk blir spreidd i kodebasen
- at testane blir tunge, ustabile eller avhengige av eksterne system
- at klassenamn blir uklare eller kolliderer i Apex sitt flate namespace
- at det blir vanskeleg å skilje funksjonalitet ut i eigne unlocked packages seinare

Vi treng derfor ei overordna arkitekturavgjerd som gjeld Aa-registeret Salesforce-pakken som heilskap, ikkje berre éin integrasjon.

Detaljar for kvar integrasjon skal dokumenterast i eigne integrasjonsspesifikke designnotat.

## Beslutning

Vi skal etablere og følgje felles arkitekturprinsipp, lagdeling og namnestandard for Aa-registeret Salesforce-pakken.

Avgjerda gjeld for:

- generell Aa-registeret-funksjonalitet
- Public 360-integrasjonen
- Altinn-integrasjonen
- Maskinporten-relatert token- og autentiseringslogikk
- framtidige integrasjonar og tekniske modular i pakken

Den normative sida for denne avgjerda er:

- Arkitekturprinsipp, lagdeling og namnestandard

Integrasjonsspesifikke sider skal berre dokumentere korleis dei felles prinsippa blir brukt konkret for den aktuelle integrasjonen.

## Valde arkitekturprinsipp

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

Orchestrator skal koordinere:

- domenedata
- mapping
- adapterkall
- logging
- feilflyt
- resultat tilbake til kallande lag

Orchestrator skal ikkje vere ei dumping-sone for feltreglar, transportlogikk eller tilfeldige hjelpefunksjonar.

### 3. Mapping skal vere rein og testbar

Mapperar, eller omformarar, skal berre omforme data.

Mapperar skal ikkje:

- gjere SOQL
- gjere DML
- gjere callouts
- skjule use case-logikk
- hente konfigurasjon direkte dersom dette bør gå via eiga teneste

Mapperar skal vere enkle å teste isolert.

### 4. Adapter er ekstern grense, ikkje transportlag

Adapter skal gi ei forretningsnær integrasjonsflate mot eit eksternt system.

Client-laget tek seg av sjølve transporten.

Dette gjer at use case-kode kan snakke med ein stabil intern kontrakt utan å kjenne til endpoint, headers, HTTP-statuskodar, tokenformat eller serialisering.

### 5. Logging og exceptions er del av grunnmuren

Logging, correlation ID, feilklassifisering og exceptions skal vere ein integrert del av arkitekturen.

Dette skal ikkje leggjast på til slutt.

Alle viktige integrasjonsflytar skal kunne sporast frå start til slutt.

### 6. Strukturen skal støtte framtidig pakking

Strukturen skal gjere det mogleg å skilje funksjonalitet ut i eigne unlocked packages seinare.

Målet er ikkje nødvendigvis å dele alt opp i eigne pakkar no, men å unngå ei struktur som gjer det vanskeleg seinare.

Kode skal derfor organiserast etter ansvar og eigarskap, ikkje berre etter kva som er raskast å lage i første sprint.

## Vald lagdeling

### Entry point

Entry points er tekniske inngangar til use case.

Typiske eksempel:

- Trigger handler
- Invocable Apex
- Queueable
- Platform event subscriber
- LWC Apex controller

Entry point skal:

- ta imot inngang til use case
- opprette eller vidareføre teknisk kontekst
- delegere til orchestrator

Entry point skal ikkje:

- bygge eksterne DTO-ar
- utføre HTTP-kall
- implementere mapping
- leggje transportdetaljar i use case-flyten

### Orchestration

Orchestration-laget styrer use case frå start til slutt.

Orchestrator skal:

- setje opp logg- og correlation-kontekst
- kalle domain service for interne data
- kalle mapper for kontraktsomforming
- kalle adapter for ekstern operasjon
- handtere resultat og feilklassifisering

Orchestrator skal ikkje:

- implementere transportlogikk
- innehalde låg-nivå HTTP-logikk
- vere ei dumping-sone for feltreglar og mapping

### Domain service

Domain service handterer Salesforce-/Aa-registeret-domene.

Domain service skal:

- hente og validere Salesforce-data
- uttrykkje interne reglar og semantikk
- produsere internt datagrunnlag for use case

Domain service skal ikkje:

- kjenne til eksterne request-/response-DTO-ar
- gjere callouts
- kjenne til headers, endpoint eller transportformat

### Mapper / omformar

Mapperar er den eksplisitte brua mellom intern modell og ekstern kontrakt.

Mapperar skal:

- transformere frå intern modell til ekstern kontrakt
- transformere frå ekstern respons til internt resultatobjekt
- vere enkle å teste isolert

Mapperar skal ikkje:

- gjere SOQL
- gjere DML
- gjere callouts
- skjule use case-logikk

### Adapter

Adapteren er den forretningsnære grensa mot eit eksternt system.

Adapteren skal:

- eksponere eksterne operasjonar på forretningsnivå
- skjule transportdetaljar bak eit stabilt grensesnitt
- bruke client internt
- vere enkel å stubbe eller mocke

Adapteren skal ikkje:

- kjenne Salesforce entry points
- slå opp domenedata direkte
- blande domeneansvar og transportansvar

### Client

Client-laget eig transporten mot eksterne system.

Client skal:

- byggje og sende HTTP-kall
- handtere headers, auth-attributt, statuskodar og timeout
- serialisere request
- deserialisere respons
- utføre låg-nivå transportlogging

Client skal ikkje:

- kjenne use case eller forretningsmeining
- vite kva interne Aa-registeret-omgrep betyr
- innehalde domenevalidering

## Namnestandard

Vi skal følgje Team Platforce sin namnestandard for Salesforce.

- All metadata og kode skal namngivast på engelsk.
- Brukarvendte etikettar kan oversetjast til norsk via Salesforce sin oversettingsmekanisme.
- Apex-klasser skal bruke PascalCase.
- Prefiks blir skilde frå klassenamnet med eitt underscore.

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

Apex testklassar skal følgje mønsteret:

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

Dette må vurderast når vi namngir klassar, særleg for integrasjonar der prefiks, capability og suffix fort kan gi lange namn.

### Prefix-regel

For å redusere risiko for kollisjonar i Apex sitt flate namespace brukar vi prefiks med underscore som skiljeteikn.

| Prefiks             | Bruk                                                             |
| ------------------- | ---------------------------------------------------------------- |
| ingen prefiks       | Generelle og gjenbrukbare integrasjonsklassar                    |
| `AAREG_`            | Aa-registeret-spesifikke klassar og use case-nær logikk          |
| integrasjonsprefiks | Integrasjonsspesifikke adapterar, clientar, DTO-ar og exceptions |

Eksempel på integrasjonsprefiks:

| Prefiks                            | Bruk                                                     |
| ---------------------------------- | -------------------------------------------------------- |
| `P360_`                            | Public 360-spesifikk integrasjonskode                    |
| eventuelt framtidig Altinn-prefiks | Altinn-spesifikk integrasjonskode dersom behovet oppstår |

### Kva gjer vi når ein klasse rører fleire område?

Når ein klasse både er knytt til Aa-registeret og eit eksternt system, vel vi prefiks etter primært eigarskap.

| Klasseområde                                      | Prefiks             |
| ------------------------------------------------- | ------------------- |
| Orchestratorar for Aa-registeret-use case         | `AAREG_`            |
| Domain services for Aa-registeret-domene          | `AAREG_`            |
| Mapperar som er forankra i Aa-registeret-use case | `AAREG_`            |
| Adapterar for ekstern kontrakt                    | integrasjonsprefiks |
| Clientar for ekstern transport                    | integrasjonsprefiks |
| DTO-ar for ekstern kontrakt                       | integrasjonsprefiks |
| Exceptions for ekstern integrasjon                | integrasjonsprefiks |

Dette gjer at namna fortel kvar klassen høyrer heime, ikkje berre kva han tilfeldigvis snakkar med.

## Generelle klassemønster

### Interfaces

Interface-markøren `I` blir liggjande i sjølve klassenamnet, men systemprefikset kjem først.

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

### Mapperar

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

## Dokumentasjonskonsekvens

Denne ADR-en gjeld overordna arkitektur for Aa-registeret Salesforce-pakken.

Felles prinsipp skal dokumenterast på overordna Salesforce-nivå:

- Arkitektur og design
- Arkitekturprinsipp, lagdeling og namnestandard

Integrasjonsspesifikke detaljar skal dokumenterast under den aktuelle integrasjonen. Eksempel:

- Public 360
- Altinn
- Maskinporten

Dette betyr at følgjande ikkje skal dupliserast i fleire integrasjonsdokument:

- generelle lagdelingsprinsipp
- generell namnestandard
- generelle testklassereglar
- generelle prinsipp for entry point, orchestrator, domain service, mapper, adapter og client
- generelle prinsipp for skilje mellom Salesforce-domene og eksterne kontraktar

Integrasjonsspesifikke sider skal berre beskrive det som er spesielt for den aktuelle integrasjonen, til dømes:

- konkrete DTO-ar
- konkrete API-ar
- konkrete endpoint
- konkrete scopes
- konkrete mapperar
- konkrete retry-reglar
- konkrete driftsrutinar

## Konsekvensar

### Positive konsekvensar

Denne avgjerda gir:

- tydelegare struktur på tvers av Aa-registeret Salesforce-pakken
- betre skilje mellom Salesforce-domene og eksterne integrasjonskontraktar
- betre testbarheit
- mindre risiko for tett kopla kode
- enklare parallell utvikling
- enklare bruk av stub, fake og mock
- tydelegare eigarskap per klasse
- betre struktur for logging og feilhandtering
- betre grunnlag for seinare refaktorering
- betre grunnlag for seinare flytting til eigne unlocked packages

### Negative konsekvensar

Denne avgjerda gir også nokre kostnader:

- fleire klassar enn ei flat og enkel løysing
- meir struktur som utviklarar må forstå
- behov for disiplin i kvar logikk blir plassert
- risiko for overstrukturering dersom vi lagar lag utan reelt ansvar
- noko meir arbeid tidleg i prosjektet

Dette blir akseptert fordi Aa-registeret Salesforce-pakken skal vidareutviklast over tid, ha fleire integrasjonar og kunne forvaltast av fleire utviklarar.

## Alternativ som blei vurdert

### Alternativ 1: Flat struktur med færre klassar

Vi kunne lagt mykje logikk i få serviceklassar.

Dette blei avvist fordi det ville gitt høg risiko for tett kopling mellom Salesforce-domene, integrasjonskontraktar, mapping og transportlogikk.

Det ville også gjort testing, feilsøking og parallell utvikling vanskelegare.

### Alternativ 2: La entry points handtere integrasjonsdetaljar direkte

Vi kunne late Flow, LWC, triggerar eller queueables bygge eksterne requestar direkte.

Dette blei avvist fordi eksterne kontraktar då ville lekke inn i brukarflate og prosesslogikk. Endringar i eksterne API-ar ville då kunne påverke store delar av Salesforce-løysinga.

### Alternativ 3: Lage eigne arkitekturprinsipp per integrasjon

Vi kunne laga eigne arkitekturprinsipp for Public 360, Altinn og framtidige integrasjonar.

Dette blei avvist fordi det ville gitt dobbeltvedlikehald og risiko for ulike mønster i same Salesforce-pakke.

Vi vel i staden éin felles arkitekturstandard for Aa-registeret, og eigne integrasjonsspesifikke designnotat for konkrete val.

### Alternativ 4: Byggje eit generisk integrasjonsrammeverk først

Vi kunne starta med å byggje eit generisk rammeverk for alle framtidige integrasjonar.

Dette blei avvist som første steg fordi det ville auke omfanget og risikoen.

Vi vel heller ein struktur som er generell nok til å kunne gjenbrukast, men konkret nok til å levere reelle integrasjonar.

### Alternativ 5: Splitte i eigne unlocked packages no

Vi kunne etablert eigne unlocked packages for felles integrasjonsgrunnlag og kvar integrasjon med ein gong.

Dette blir ikkje gjort som del av denne avgjerda.

Strukturen skal likevel gjere det mogleg å flytte funksjonalitet ut i eigne unlocked packages seinare utan stor omskriving.

## Føringar for implementasjon

- Nye klassar skal plasserast i riktig lag.
- Entry points skal delegere til orchestrator.
- Domain services skal ikkje kjenne til eksterne DTO-ar.
- HTTP-kall skal berre skje frå client-/transportlag.
- Adapter skal skjule transportdetaljar for use case-kode.
- Mapperar skal vere reine og testbare.
- Exceptions skal vere klassifiserte og kunne støtte correlation ID.
- Logging skal ikkje innehalde sensitive data, token eller dokumentinnhald.
- Testar skal kunne bruke stub/fake utan ekte ekstern avhengigheit.
- Namn skal haldast innanfor Salesforce si grense på maks 40 teikn for Apex-klassenamn.
- Integrasjonsspesifikke detaljar skal dokumenterast på eigne sider under aktuell integrasjon.

## Relaterte sider

- Arkitektur og design
- Arkitekturprinsipp, lagdeling og namnestandard
- Salesforce Integrasjoner
- Public 360
- Altinn
- Maskinporten
- Lagdelt struktur og namnestandard for AAReg P360-integrasjonen
