# Lokal implementasjonsstatus mot Jira

Oppdatert 2026-11-04 frå lokal kode, dokumentasjon og direkte Jira-kontroll.

Dette dokumentet er repo-eigd teknisk evidens og ikkje ei speilkopi av Jira. Den historiske statustabellen nedanfor byggjer på CSV-eksporten frå 2026-09-13; nyare Jira-statusar er kontrollert direkte og dokumenterte i dei tilhøyrande gjennomgangane. Kode- og testomtalar skil mellom tidlegare verifisering og testar som ikkje er køyrde i den aktuelle gjennomgangen.

## CRMAAREG-143 / K1 — kontrollert 2026-11-04

Jira-historia og deloppgåvene 144–154 står no som **Ferdig**, med løysing **Utført**. Repoet inneheld 13 Custom Metadata-postfiler for standardprofilen. Endelege domenespesifikke feltmappingar står framleis att etter [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016). Typebeskrivinga er retta slik at ho skil mellom standardpostane som finst og uavklarte mappingar. Ingen Salesforce-org er kontakta i denne oppdateringa.

## CRMAAREG-155 / K2 — kontrollert 2026-11-04

Jira-historia og deloppgåvene 156–162 står no som **Ferdig**, med løysing **Utført**. `P360_ICodeTableService` og `P360_CodeTableMetadataService` gjer generiske oppslag på aktiv metadata etter tabellnamn og Salesforce-nøkkel, med cache per transaksjon og `P360_MissingCodeTableMappingException` når ei mapping manglar. Testklassen dekkjer både treff på `DefaultValueSet` og manglande mapping; tidlegare scratch-verifisering er oppsummert i statusrada nedanfor. Metadata har `CaseStatus` og `DocumentCategory`, men inga eiga `DocumentStatus`-rad; `JournalStatus`-verdien blir brukt for det obligatoriske P360 `CreateDocument.Status`-feltet. Konkrete domenemappingar og kodeverdiar skal avklarast i [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016), ikkje gjettast inn i tenesta. Ingen Salesforce-org er kontakta i denne oppdateringa.

## CRMAAREG-163 / K3 — kontrollert 2026-11-04

Jira-parenten står framleis i **Under arbeid**. GitHub [#996](https://github.com/navikt/crm-arbeidsforhold/issues/996) er lukka med avgjerda om `P360_AdapterFactory` som composition root og constructor injection, utan service locator. Eksisterande Jira-kommentarar dokumenterer at `P360ServiceLocator` ikkje skal byggjast. `P360_AdapterFactory` og eksempelfake-testen finst; deloppgåvene 165 og 168 står **Ferdig**, medan 164, 166 og 167 står i **Backlog**. Case- og dokumentmapperane som finst brukar `P360_ICodeTableService`, men Jira-deloppgåvene 166/167 viser framleis til dei fråverande klassane `P360CaseMapper` og `P360JournalpostMapper`. K3 kan ikkje ryddast som ferdig før desse deloppgåvene er flytta/avgrensa eller akseptansekriteria er oppdaterte. #994 er framleis open for namneavviket i K2. Ingen Salesforce-org er kontakta i denne oppdateringa.

## CRMAAREG-169 / K4 — kontrollert 2026-11-04

Jira-parenten er **Under arbeid**; deloppgåvene 170–172 er **Ferdig** / **Utført**, og 173–174 står i **Backlog**. Metadata har `CaseStatus` / `Default` = `B` (Under behandling), `JournalStatus` / `Default` = `J` (Journalført), og `DocumentCategory` / `Outgoing` = `Dokument ut`. `JournalStatus` er verdien mapperane sender i det obligatoriske P360 `CreateDocument.Status`-feltet; tabellen heiter ikkje `DocumentStatus`. Metadata-README-en seier at standardverdiane kjem frå P360-avklaringa og er godkjende, men identifiserer ikkje presis kjelde og eigar per verdi. Han skisserer omsyn ved endringar, men ikkje ein full godkjennings- og endringsprosess. Difor står opphav/eigarskap og prosess (173–174) att, og K4 er ikkje ferdig. GitHub [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016) er framleis open for full Salesforce-til-SIF-mapping. Ingen Salesforce-org er kontakta i denne oppdateringa.

## CRMAAREG-181 / S1 — kontrollert 2026-11-04

Jira-parenten står i **Backlog**; deloppgåve 186 er **Under arbeid**, medan 182–185 og 187 står i **Backlog**. `P360_Integration_Setting__c` er ein Hierarchy Custom Setting for miljøstyrt Named Credential-namn og mock-transport, ikkje ei faktisk Credential- eller endpoint-konfigurasjon. `P360_AuthenticationException` finst, men `P360_RpcClient.send()` er framleis ein stub som kastar `P360_TransportException`; autentisering, auth-feilhandtering og transportlogging er ikkje implementerte i RPC-klienten. GitHub [#1017](https://github.com/navikt/crm-arbeidsforhold/issues/1017) står open for eksterne endpoint-, header- og auth-avklaringar. Ingen Salesforce-org er kontakta i denne oppdateringa.

## CRMAAREG-105: filgrunnlag — gjennomgang 2026-11-02

Jira stod i **Backlog** ved lesing av saka. Statusen er behalden; detaljane nedanfor gjeld lokal `main` ved `1e46e002`, ikkje ein ny org-verifikasjon. Resten av historietabellen nedanfor er frå den eldre gjennomgangen.

### Grunnlag og eksisterande leveranse

- [F3-historia](jira/crmaareg-83-teknisk-grunnmur.md#crmaareg-101--f3--opprette-requestresponse-dto-ar-og-interne-apex-data-classes) krev interne Salesforce-dataklassar og separate P360-DTO-ar. Ho krev ikkje filtransport som del av dataklassane.
- [CreateDocument-specen](../../../.github/specs/p360-create-document-dtos.md) og lukka [#1010](https://github.com/navikt/crm-arbeidsforhold/issues/1010) dekkjer SIF-filkontrakten, ikkje Salesforce-filmodellen eller transport.
- [Mapper-input](../../../force-app/integration/p360/classes/mapper/AAREG_ApplicationFileToP360FileMapper.cls) har `title`, `format` og `base64Data`. Søknads- og vedtaksdokumentmapperane brukar dette filgrunnlaget. Ei eiga klasse kalla `SalesforceDocumentFile` er ikkje funnen.
- [Mapper-testen](../../../force-app/tests/classes/integration/p360/mapper/AAREG_FileMapperTest.cls) dekkjer feltmapping og avvising av manglande innhald. [DTO-testen](../../../force-app/tests/classes/integration/p360/contract/P360_FileParameterDtoTest.cls) dekkjer JSON round-trip. Den eldre F4-rada dokumenterer allereie levert mock-mapping og tidlegare scratch-testar; dette er ikkje nytt restarbeid.
- [Datamodellen](../../architecture/p360-data-model-og-arkiveringsjob.md) skil persisterte P360-filreferansar og vedleggsjobbar frå sjølve filinnhaldet. `P360_File_Id__c` er ikkje ei intern filmodell.

### Det vi må sjå på

1. Avgjere om mapper-inputen oppfyller CRMAAREG-105 sitt behov for ei intern dataklasse, eller om use caset krev ein separat modell med Salesforce-filidentitet og meir metadata. Dei undersøkte dokumenta fastset ikkje dette for deloppgåva.
2. Dokumentere obligatoriske og valfrie felt, slik F3 krev, og knyte relevante testar til det avklarte scope-et.
3. Ikkje opprette ein ny klasse berre for å matche det gamle Jira-namnet. Avklare ansvar og gjenbruk først.

Filkjelde, storleiksgrenser, inline versus upload, cleanup og delvis-feil-handtering høyrer til [filhandteringshistoriene](jira/crmaareg-236-filhandtering.md) og [#1018](https://github.com/navikt/crm-arbeidsforhold/issues/1018). Desse punkta skal ikkje åleine hindre ferdigstilling av ei avgrensa dataklasseoppgåve. [Completion roadmap](../../../.github/specs/p360-completion-roadmap.md) og [teknisk oversikt](../../integrations/p360/teknisk-oversikt.md) skil også levert mock-grunnlag frå uferdig live-flyt.

**Validering:** Kode, metadata, spec, dokumentasjon og GitHub-saker er lesne. Ingen Apex-testar er køyrde og ingen org er kontakta i denne gjennomgangen.

## CRMAAREG-110: UpdateDocument-DTO-ar — gjennomgang 2026-11-02

Jira stod i **Backlog** ved lesing av saka; statusen er behalden. [GitHub #1174](https://github.com/navikt/crm-arbeidsforhold/issues/1174) følgjer opp implementasjonen.

- Ingen `UpdateDocument`-klassar, Apex-metadata eller testar er funne under `force-app/` i lokal `main` ved `1e46e002`.
- [SIF-kontraktdokumentet](../../integrations/p360/sif-api-kontrakter.md#updatedocument) skildrar identifikasjon, oppdateringssemantikk og støtta feltområde. Kontraktuttrekket er levert i [#1008](https://github.com/navikt/crm-arbeidsforhold/issues/1008); vi skal ikkje opne dette arbeidet på nytt.
- [CreateDocument-specen](../../../.github/specs/p360-create-document-dtos.md) og [#1010](https://github.com/navikt/crm-arbeidsforhold/issues/1010) avgrensar uttrykkeleg mot UpdateDocument. Lukkinga dekkjer ikkje denne deloppgåva.
- Før kode må feltutval, obligatoriske/valfrie felt og resultatkontrakt konkretiserast i ei avgrensa spec mot SIF-kjelda. Request-/response-DTO-ar og JSON-testar for identitet, valde felt, `null`, tom streng og resultat-/feilfelt står att.
- Mapping, Salesforce-oppdateringskontekst (CRMAAREG-104), RPC, auth og filtransport er eigne ansvar. DTO-oppgåva skal ikkje krevje at heile oppdateringsflyten er ferdig.

**Validering:** Kode-/metadata-søk, eksisterande spec, kontraktdokumentasjon og GitHub-saker er kontrollerte. Ingen nye Apex-testar er køyrde og ingen org er kontakta.

## CRMAAREG-112: felles external-ID-klasse — gjennomgang 2026-11-03

Jira stod i **Backlog** ved lesing av saka; statusen er behalden.

- Ei eiga `P360ExternalId`-klasse eller tilsvarande namngitt external-ID-klasse med metadata er ikkje funnen i lokal `main` ved `1e46e002`.
- Identiteten er allereie representert som felt i mellom anna [CreateCase](../../../force-app/integration/p360/classes/contract/dto/P360_CreateCaseRequestDto.cls), [UpdateCase](../../../force-app/integration/p360/classes/contract/dto/P360_UpdateCaseRequestDto.cls) og [CreateDocument](../../../force-app/integration/p360/classes/contract/dto/P360_CreateDocumentRequestDto.cls): `externalId` og `externalSystem`. Dette er ikkje i seg sjølv ei avgjerd om ein felles verdiklasse.
- [Idempotens-specen](../../../.github/specs/p360-idempotency-keys.md) gjeld interne jobbnøklar og avgrensar uttrykkeleg mot ekstern ID-mapping, P360-duplikatsemantikk og recovery.
- [External-ID-historia](jira/crmaareg-254-external-id.md) og opne [#1015](https://github.com/navikt/crm-arbeidsforhold/issues/1015) følgjer opp format, type/system, eigarskap, lagring og ekstern recovery. Interne jobbnøklar gir ikkje dokumenterte garantiar om P360 si handtering av identitet eller duplikat.

**Oppfølging:** Avgjere om eksisterande DTO-felt er tilstrekkelege for dei godkjende use casa, eller om ein felles verdiklasse har eit konkret ansvar som manglar. Dokumentere avgjerda og eventuelle felt/testkrav før implementering. Ikkje leggje til ein klasse berre for å matche Jira-namnet, og ikkje krevje full retry-/recovery-implementasjon for å avslutte ei avgrensa dataklasseoppgåve.

**Validering:** Kode-/metadata-søk, spec, dokumentasjon og #1015 er kontrollerte. Ingen nye Apex-testar er køyrde og ingen org er kontakta.

## CRMAAREG-115: mapper-grunnlag — gjennomgang 2026-11-03

Jira vart først endra frå **Backlog** til **Under arbeid** etter godkjenning. Kommentaren om at mapper-laget ikkje var implementert vart retta. Deloppgåvene CRMAAREG-116–120 stod i Backlog ved starten av gjennomgangen; kvar oppdatering er dokumentert nedanfor.

- [Case-mapperen](../../../force-app/integration/p360/classes/mapper/AAREG_ApplicationToP360CaseMapper.cls) har typa input og `mapToCreateCase`, med injisert kodeverksteneste.
- [Søknadsdokument-mapperen](../../../force-app/integration/p360/classes/mapper/AAREG_ApplicationToP360DocumentMapper.cls) og [vedtaksdokument-mapperen](../../../force-app/integration/p360/classes/mapper/AAREG_DecisionToP360DocumentMapper.cls) har input-/output-grenser mot CreateDocument.
- [Filmapperen](../../../force-app/integration/p360/classes/mapper/AAREG_ApplicationFileToP360FileMapper.cls) omformar førehandslasta tittel, format og base64-innhald utan upload eller callout. Dokumentmapperane brukar filmapperen.
- [Mapper-testane](../../../force-app/tests/classes/integration/p360/mapper/) finst for case, søknadsdokument, vedtaksdokument og filer. Den eldre F4-rada dokumenterer tidlegare scratch-evidens; ingen nye testresultat er etablerte her.

**Avslutning:** Etter gjennomgang av CRMAAREG-116–120 og ny godkjenning er også F4 sett til **Ferdig**, med løysing **Utført**. Alle fem deloppgåvene er ferdige i Jira. Mapper-grunnlag og offentlege input-/output-signaturar finst, avklaringar er dokumenterte, og mapperane kan kallast frå service-laget gjennom dei offentlege metodane utan transportlogikk. Dette oppfyller skeleton-scope; faktisk kopling til endeleg flyt er ikkje det same som kallbarheit. Full feltmapping og endeleg flytkopling står framleis att, jf. [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016), [#1095](https://github.com/navikt/crm-arbeidsforhold/issues/1095) og [teknisk oversikt](../../integrations/p360/teknisk-oversikt.md).

**Validering:** Kode, testfiler, F4-krav og eksisterande dokumentasjon er lesne. Jira-status og lagra kommentar er kontrollerte i nettlesaren. Ingen nye Apex-testar er køyrde og ingen org er kontakta.

### CRMAAREG-116: case-mapper

Etter godkjenning er deloppgåva sett til **Ferdig**, med løysing **Utført**, for skeleton-scope. Status og kort kommentar med GitHub-lenkje er kontrollerte i Jira.

[Case-mapperen](../../../force-app/integration/p360/classes/mapper/AAREG_ApplicationToP360CaseMapper.cls) har offentleg `Input`, injisert `P360_ICodeTableService` og `mapToCreateCase(Input)` som returnerer `P360_CreateCaseRequestDto`. Apex-metadata finst. [Den fokuserte testen](../../../force-app/tests/classes/integration/p360/mapper/AAREG_ApplicationToP360CaseMapperTest.cls) dekkjer input og kodeverksverdiar under minimum-access-brukar med kodeverkstilgang.

[Mapper-README](../../../force-app/integration/p360/classes/mapper/README.md) og [gjennomgangen](../../integrations/p360/steg-for-steg-gjennomgang.md) dokumenterer det domeneeigde namnet og grensa mot full feltmapping og live transport. Det er ikkje nødvendig å opprette ein separat `P360CaseMapper` berre for å matche det gamle Jira-namnet. Ferdigstillinga gjeld skeleton-oppgåva, ikkje endeleg produksjonsmapping eller faktisk kopling frå service-/orkestratorflyten. Ingen nye Apex-testar er køyrde.

### CRMAAREG-117: dokumentmapperar

Etter godkjenning er deloppgåva sett til **Ferdig**, med løysing **Utført**, for skeleton-scope. Status og kort kommentar med GitHub-lenkje er kontrollerte i Jira.

[Søknadsdokument-mapperen](../../../force-app/integration/p360/classes/mapper/AAREG_ApplicationToP360DocumentMapper.cls) og [vedtaksdokument-mapperen](../../../force-app/integration/p360/classes/mapper/AAREG_DecisionToP360DocumentMapper.cls) har offentlege inputtypar, injisert kodeverksteneste og `mapToCreateDocument(Input)` med `P360_CreateDocumentRequestDto` som resultat. [Søknadstesten](../../../force-app/tests/classes/integration/p360/mapper/AAREG_CreateDocumentMapperTest.cls) og [vedtakstesten](../../../force-app/tests/classes/integration/p360/mapper/AAREG_DecisionDocumentMapperTest.cls) dekkjer identitet, dokumentmetadata, kodeverksverdiar og mock-filinnhald.

[Mapper-README](../../../force-app/integration/p360/classes/mapper/README.md) dokumenterer ansvarsdeling og domeneeigde namn. Ein separat `P360JournalpostMapper` skal ikkje opprettast berre for å matche Jira-namnet. Søknadsmappinga lèt dokumentkategori stå open, og testane dokumenterer ikkje ein komplett live-request. Full feltmapping, endeleg flytkopling og filtransport er ikkje ferdigstilte gjennom denne skeleton-oppgåva. Ingen nye Apex-testar er køyrde og ingen org er kontakta.

### CRMAAREG-118: filmapper

Etter godkjenning er deloppgåva sett til **Ferdig**, med løysing **Utført**, for skeleton-scope. Status og kort kommentar med GitHub-lenkje er kontrollerte i Jira.

[Filmapperen](../../../force-app/integration/p360/classes/mapper/AAREG_ApplicationFileToP360FileMapper.cls) har offentleg `Input` og `mapToFile(Input)` som returnerer `P360_FileParameterDto`. Tittel, format og base64-innhald blir overførte, og manglande input gir kontrollert `P360_ContractException`. Apex-metadata finst. [Testane](../../../force-app/tests/classes/integration/p360/mapper/AAREG_FileMapperTest.cls) dekkjer feltmapping og avvising av manglande filinnhald.

Dokumentmapperane brukar filmapperen, og [mapper-README](../../../force-app/integration/p360/classes/mapper/README.md) dokumenterer ansvarsgrensa. Ein separat `P360FileMapper` skal ikkje opprettast berre for å matche Jira-namnet. Filhenting frå Salesforce, storleiksgrenser, endeleg filstrategi og opplasting høyrer til vidare filarbeid, mellom anna [#1018](https://github.com/navikt/crm-arbeidsforhold/issues/1018). Ingen nye Apex-testar er køyrde og ingen org er kontakta.

### CRMAAREG-119: dokumenterte mapping-avklaringar

Etter godkjenning er deloppgåva sett til **Ferdig**, med løysing **Utført**. Status og kort kommentar med klikkbare lenkjer til vidare arbeid er kontrollerte i Jira.

[Mapper-README](../../../force-app/integration/p360/classes/mapper/README.md) dokumenterer grensa mot full Salesforce-feltmapping, open dokumentkategori for søknadsdokument og uavklart filstrategi. [Teknisk oversikt](../../integrations/p360/teknisk-oversikt.md#kontraktgrensa-mot-sif) og [completion roadmap](../../../.github/specs/p360-completion-roadmap.md#2-resolve-contract-and-ownership-decisions) samlar dei eksterne avgjerdene og skil desse frå levert mock-grunnlag.

[#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016) følgjer opp Salesforce-/SIF-felt, kodeverdiar, obligatoriske og kondisjonelle felt, identitet og dataminimering. [#1018](https://github.com/navikt/crm-arbeidsforhold/issues/1018) følgjer opp filrepresentasjon, metadata, storleiksgrenser, upload og delvis-feil-handtering. Begge sakene er opne. Ferdigstillinga gjeld dokumentasjon av spørsmåla, ikkje at avgjerdene er tekne eller produksjonsmappinga er ferdig. Ingen nye Apex-testar er køyrde og ingen org er kontakta.

### CRMAAREG-120: mapper-testgrunnlag

Etter godkjenning er deloppgåva sett til **Ferdig**, med løysing **Utført**, for test-skeleton-scope. Status og kort kommentar med klikkbar GitHub-lenkje til testmappa er kontrollerte i Jira.

[Case-testen](../../../force-app/tests/classes/integration/p360/mapper/AAREG_ApplicationToP360CaseMapperTest.cls), [søknadsdokument-testen](../../../force-app/tests/classes/integration/p360/mapper/AAREG_CreateDocumentMapperTest.cls), [vedtaksdokument-testen](../../../force-app/tests/classes/integration/p360/mapper/AAREG_DecisionDocumentMapperTest.cls) og [filtesten](../../../force-app/tests/classes/integration/p360/mapper/AAREG_FileMapperTest.cls) har tilhøyrande Apex-metadata. Dei inneheld fem testmetodar med konkrete assertions for input, identitet, kodeverksverdiar og filinnhald. Filtesten dekkjer også kontrollert avvising av manglande base64-innhald; søknadsdokument-testen stadfestar at dokumentkategori ikkje blir gjetta.

Dette oppfyller oppgåva om testgrunnlag, ikkje full feildekning, komplett Salesforce-feltmapping eller live-integrasjon. Dei tre case-/dokumenttestane brukar minimum-access-brukar med kodeverkstilgang; filtesten brukar ikkje `runAs`. Ingen testkode er endra i statusgjennomgangen. Tidlegare scratch-evidens står i den historiske F4-rada nedanfor; ingen nye Apex-testar er køyrde og ingen org er kontakta.

Eksporten frå 2026-09-13 viser 3 ferdige, 13 under arbeid og 18 backlog-historier. På epicnivå er 7 under arbeid og 4 i backlog.

### CRMAAREG-121 / F5: status 2026-11-03

F5 står framleis **Under arbeid**, sjølv om deloppgåvene CRMAAREG-122–128 no er **Ferdig / Utført** i Jira. Validering blir handtert av eksisterande `P360_ContractException`, manglande kodeverk-mapping har eigen exception, og bruksmønsteret er dokumentert. Foreldreoppgåva blir ståande open medan exception-lista og namna blir harmoniserte mellom Jira og ADR-0001; [#993](https://github.com/navikt/crm-arbeidsforhold/issues/993) er oppdatert med avgjerdene, men står open, og [#976](https://github.com/navikt/crm-arbeidsforhold/issues/976) er ikkje oppdatert med ei endeleg avklart liste. F5-kommentaren i Jira er oppdatert til å skilje dei lukka deloppgåvene frå dette attståande arbeidet.

### CRMAAREG-124: bruke `P360_ContractException` for input- og kontraktvalidering

Etter godkjenning er deloppgåva sett til **Ferdig**, med løysing **Utført**. Løysinga er avgrensa til å bruke eksisterande `P360_ContractException` for input-/kontraktvalidering i staden for å lage ein ny `P360ValidationException`-klasse. Dette er konsistent med [P360_IntegrationException](../../../force-app/integration/p360/classes/exception/P360_IntegrationException.cls), [P360_ContractException](../../../force-app/integration/p360/classes/exception/P360_ContractException.cls) og [exception-README](../../../force-app/integration/p360/classes/exception/README.md).

Det er fortsatt open oppfølgjing i [#993](https://github.com/navikt/crm-arbeidsforhold/issues/993) og F5/Jira for å harmonisere dokumentasjon, namngiving og øvrig koordinering. Den konkrete avgjerda om validering er likevel løyst: vi skal ikkje introdusere ei ny valideringsklasse utan tydelig eigentleg behov.

### CRMAAREG-127: manglande kodeverk-mapping

Etter godkjenning er deloppgåva sett til **Ferdig**, med løysing **Utført**. [P360_MissingCodeTableMappingException](../../../force-app/integration/p360/classes/exception/P360_MissingCodeTableMappingException.cls) finst som subtype av `P360_MappingException`; metadata-tenesta kastar ho når aktiv mapping manglar. [Testen](../../../force-app/tests/classes/integration/p360/codetable/P360_CodeTableMetadataServiceTest.cls) stadfestar at feilen blir kasta og at meldinga inneheld tabell og nøkkel. [Kodeverks-README](../../../force-app/integration/p360/classes/codetable/README.md) dokumenterer same åtferd.

Jira-kommentaren lenkjer direkte til klassen og testen. Namne- og dokumentasjonsharmonisering står framleis att i F5 og [#993](https://github.com/navikt/crm-arbeidsforhold/issues/993); denne deloppgåva innebar ikkje å endre Jira-tittelen eller exception-hierarkiet.

### CRMAAREG-128: dokumentere bruksmønster

Etter godkjenning er dokumentasjonsdeloppgåva sett til **Ferdig**, med løysing **Utført**. [Exception-README](../../../force-app/integration/p360/classes/exception/README.md) forklarer val av exception-type, retrybarheit og correlation ID. Den detaljerte [steg-for-steg-guiden](../../integrations/p360/steg-for-steg-gjennomgang.md#bruk-av-exceptions) dokumenterer worker-klassifisering, retry/bakoff og avgrensinga for correlation ID: worker-loggen brukar ID frå jobbrada og les ikkje `error.correlationId`; ende-til-ende-propagering står att.

Jira-status og kort kommentar med lenkjer til begge dokumenta vart kontrollerte etter reload. Ingen nye Apex-testar er køyrde og ingen org er kontakta; endringa er dokumentasjon.

## Status per Jira-historie

| Jira              | Jira-status 2026-09-13 | Lokal teknisk status                                 | Evidens                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Restarbeid                                                                                                   |
| ----------------- | ---------------------- | ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| CRMAAREG-89 / F2  | Ferdig                 | Fullført med mock-kompatibel intern orchestratorflyt | Interfaces, adapter, RPC-klient, `AAREG_ArchiveApplicationOrchestrator` med validering og mock-basert request/response-kopling, samt schema-safe typed Application-/Agreement-domain contexts. Verifisert mot scratch org: orchestrator-test 3/3 og domain-testar 4/4 grøne                                                                                                                                                                                                                                                                                                                                      | Full Salesforce-feltmapping og ekte P360-transport ligg i seinare historier                                  |
| CRMAAREG-101 / F3 | Under arbeid           | Delvis                                               | DTO-ar med serialiseringstestar, `AAREG_ApplicationArchiveContext` og `AAREG_AgreementArchiveContext` som typed, org-safe domain contexts for verifiserte `Application__c.Id`/`Agreement__c.Id`; P360-referansefelt som ikkje finst i target-org er ikkje spørrte                                                                                                                                                                                                                                                                                                                                                | Context-klassar for fleire use cases, UpdateDocument og full komposisjon manglar                             |
| CRMAAREG-115 / F4 | Under arbeid           | CreateCase + dokument- og file-parameter mock-slices | `AAREG_ApplicationToP360CaseMapper`, `AAREG_ApplicationToP360DocumentMapper`, `AAREG_DecisionToP360DocumentMapper` og `AAREG_ApplicationFileToP360FileMapper` brukar godkjende `Default`-kodeverk og kontraktverdiane du har gitt. Begge CreateDocument-mapperane integrerer mock-file payloads i `request.files`; ingen upload-endpoint blir vald. Verifisert mot scratch org: søknadsdokument/vedtaksdokument 2/2 og file-mapper 2/2 grøne                                                                                                                                                                     | ContentVersion-henting, storleiksvalidering, filopplasting og live transport er ikkje implementert enno      |
| CRMAAREG-121 / F5 | Under arbeid           | Delvis                                               | Base-, contract-, transport-, auth-, timeout-, retryable-, mapping- og config-exceptions med hierarkitest; `isRetryable`-klassifisering lagt til `P360_IntegrationException` (standard `false`, sett via `withRetryable(Boolean)`), `P360_RetryableException` set han alltid til `true`. Namneavgjerd (2026-09-13): behald `P360_`-prefiks med understrek for alle P360-klassar (`P360_IntegrationException`), i tråd med ADR-0001 og eksisterande kode. Jira-teksten (`P360IntegrationException` utan understrek) er ikkje retta i Jira enno. Verifisert mot scratch org `crm-arbeidsforhold`: 7/7 testar grøne | Retting av klassenamn i sjølve Jira-oppgåva (CRMAAREG-122 osv.) attstår som ei ekstern, menneskeleg handling |

| CRMAAREG-129 / F6 | Under arbeid | Delvis | `CorrelationContext` og `IntegrationLogContext` med testar; `IntegrationLogRedactor` fjernar sensitive feltverdiar (token, secret, authorization, cookie, fnr, ssn) før logging; `P360_IntegrationException.withCorrelationId` fører correlation-ID gjennom eit catch-grense; `IntegrationLogger` (CRMAAREG-131-namnet) byggjer eit redigert loggpayload og persisterer det som `Application_Log__c` via den etablerte `LoggerUtility`/`Application_Event__e`-pipelinen (`Category__c` = systemnamn, `Application_Domain__c` = eksisterande `AAREG`-verdi). Verifisert mot scratch org `crm-arbeidsforhold`: deploy `0AfQI00000jKxV30AK` (2/2), `0AfQI00000jKxmn0AC` (4/4) og `0AfQI00000jKyB40AK` (4/4, inkl. faktisk `Application_Log__c`-persistens og redaksjon), alle testar grøne | Transportpropagering over HTTP gjenstår, avhengig av #1017 (RPC-miljø/endepunkt/auth); ingen P360-spesifikk `Application_Domain`-verdi finst, så `AAREG` blir brukt |
| CRMAAREG-135 / F7 | Under arbeid | Delvis | `P360_TestDataFactory`, builders, stub adapter og RPC-testdobbel | Dei Jira-namngitte fake-servicene og base test class finst ikkje |
| CRMAAREG-143 / K1 | Backlog | Fullført med standarddata, ikkje-sensitive verdiar | Custom Metadata Type `P360_Code_Table_Value__mdt` med felt `Table_Name__c`, `Salesforce_Key__c`, `Language_Code__c`, `P360_Code__c`, `P360_Recno__c`, `Transport_Value__c`, `Display_Label__c`, `Active__c`, `Sort_Order__c`; 13 standardrecordar er lagde inn med `Salesforce_Key__c = Default` frå tidlegare P360-avklaring. Permission Set `P360_Code_Table_Access` gir lesetilgang og inngår i `P360_Integration_User`. Verifisert mot scratch org `crm-arbeidsforhold`: deploy `0AfQI00000jLALp0AO` (13/13), treff- og manglande-mapping-testar 2/2 grøne | Konkrete Salesforce-feltmappingar utover standardprofilen krev framleis fagleg avklaring (#1016) |
| CRMAAREG-155 / K2 | Backlog | Delvis | `P360_CodeTableRowDto`, `P360_ICodeTableService`, `P360_CodeTableMetadataService` (SOQL-oppslag mot `P360_Code_Table_Value__mdt` med enkel per-transaksjon-cache), `P360_MissingCodeTableMappingException`. `P360_MappingException` gjort `virtual` for å støtte dette. Verifisert mot scratch org `crm-arbeidsforhold`: treff på `DefaultValueSet` og manglande mapping 2/2 grøne | Mapping-service for konkrete Salesforce-felt og fleire profiler må byggjast når domenemappinga er ferdig (#1016) |
| CRMAAREG-163 / K3 | Backlog | Løyst via eksisterande arkitekturavgjerd | Mønsterkonflikten `P360ServiceLocator` vs. `P360_AdapterFactory` (delvis #996) er alt avgjort: kommentaren på #1017 stadfestar «`P360_AdapterFactory` er composition root. Constructor injection blir brukt; ingen service locator.» `P360ServiceLocator` skal difor **ikkje** byggjast. `@TestVisible`-injeksjonshookar (CRMAAREG-165) er overflødige sidan constructor injection alt gir same testbarheit. Eksempeltest med fake adapter (CRMAAREG-168) finst alt: `P360_AdapterFactoryTest` brukar `P360_TestRpcClient` injisert via konstruktør | `P360CaseMapper`/`P360JournalpostMapper` (CRMAAREG-166/167) finst ikkje enno — dei er del av F4, sjølv blokkert av namnekonflikten i #994 |
| CRMAAREG-268 / R1 | Under arbeid | Delvis, intern Salesforce-slice fullført | Fire deterministiske nøkkelformat, unik metadata og idempotent `ApplicationDocument`-jobb | Ekstern P360 duplicate/recovery og andre jobbtypar |
| CRMAAREG-274 / R2 | Under arbeid | Worker-skjelett fullført mot stub | `P360_ArchiveJobClaimService` (claimer Pending/forfalte Failed-jobbar med lease, inkrementerer forsøksteljar) og `P360_ArchiveJobWorker` (Queueable, klassifiserer utfall via `isRetryable` + MVP-backoff `1m, 5m, 15m, 1t, 6t`, maks 5 forsøk). Permission Set `P360_Archive_Job_Processing` utvida med felt for status/lease/feilkontekst. Scratch/sandkasse kan bruke eksplisitt `P360_Integration_Setting__c.Use_Mock_Transport__c = true` for `P360_StubArchiveAdapter`; standard er ekte transport. Verifisert mot scratch org `crm-arbeidsforhold`: 8/8 nye testar grøne, ingen regresjon | Ekte P360-kall er framleis kontrollert blokkert (kastar `P360_ContractException`) til `#1017`/`#1016` er avklart; ingen scheduler/cron koplar workeren til klare jobbar enno |
| CRMAAREG-255 / X1 | Backlog | Salesforce-feltlagring alt på plass | Text-felt for eksterne P360-ID-ar finst alt, eigd i tråd med `#1016`-modellen: `Access_Request__c.P360_Case_Id__c`/`P360_Case_Number__c` (sak), `Application__c`/`Application_Decision__c`/`Agreement__c` sine `P360_Document_Id__c`/`P360_Document_Number__c`/`P360_File_Id__c` (dokument/fil). Ingen transformasjon av ID-en — han lagrast slik P360 returnerer han | Sjølve formatdefinisjonen (CRMAAREG-256–258) og namngjevingsdokumentasjonen (CRMAAREG-260) er ikkje skrive ned som eige punkt, men følgjer implisitt av felta som alt finst |
| CRMAAREG-296 / T1 | Under arbeid | Delvis, omfattande | P360-testsuite med alle P360-testklassar; DTO-, grense-, release-, metadata-, idempotens- og jobbtestar | Mapper- og komplette produksjonsflytar manglar |
| CRMAAREG-310 / D1 | Ferdig | Fullført for gjeldande D1-scope | ADR-ar, teknisk oversikt og 13 lenka komponent-, klasse-, sekvens-, status- og relasjonsdiagram | Dokumenta må vidareførast når worker og transport blir implementerte |

## Verifiserte leveransar

### Frigiving og låsing

- MyTriggers-registrering for `Application_Decision__c` før insert og update.
- Custom permission `P360_Archive_Release`.
- Einvegs frigivingssignal og låsing av ordinære felt.
- Release-guarden er non-bypassable, og release-settet gir ikkje ekstra objekt-CRUD.
- Dry-run `0AfRR00000g2QhN0AU`: 11/11 komponentar og 5/5 fokuserte testar.
- Desse siste release-hardening-endringane er ikkje dokumenterte som permanent deploya i dette dokumentet.

### Idempotens og jobboppretting

- `P360_IdempotencyKey` for fire arkivhendingar.
- `P360_ArchiveJobService` for idempotent `ApplicationDocument`-jobb.
- `P360_Archive_Job_Processing` med avgrensa tilgang.
- Deploy `0AfRR00000g2PtN0AU`: 27/27 komponentar og 4/4 testar.
- Test run `707RR00001XtOIQ`: 4/4 testar, 84 prosent service-dekning og 100 prosent key-dekning.

### Samla teststatus

- P360-testsuiten inneheld 44/44 P360-testklassar i gjeldande arbeidskopi.
- Heile 44-klassarsuiten er ikkje dokumentert som køyrd samla etter dei siste endringane.
- Dei verifiserte ID-ane over gjeld dei oppførte fokuserte slicene, ikkje ein full ende-til-ende P360-test.

## Vidare statusforvaltning

- Jira er autoritativ kjelde for arbeidsstatus, ansvar og prioritering.
- Repoet er autoritativ kjelde for teknisk evidens, arkitektur og testresultat.
- `docs/context/p360/jira-*` er spegel-/kontekstfiler og skal oppdaterast frå ein ny Jira-eksport, ikkje gjennom manuell parallell statusføring.
- Ekstern P360-deduplisering og recovery må framleis avklarast før den delen av CRMAAREG-268 kan reknast som ferdig.
- Worker, retry og manuell oppfølging må implementerast før CRMAAREG-274 kan reknast som teknisk ferdig.
