# Lokal implementasjonsstatus mot Jira

Oppdatert 2026-11-05 frå lokal kode, dokumentasjon og direkte Jira-kontroll.

Den nye [status-speilinga frå 2026-11-05](jira-status-2026-11-05.md) inneheld alle 239 eksporterte P360-saker med titlar, statusar, løysingar og overordna saksnøklar. Ho erstattar dei eldre eksporttala for desse felta, ikkje tekniske vurderingar eller historiske beskrivingar. Eksporten viser 6 ferdige historier, 18 under arbeid og 10 i backlog; deloppgåvene er fordelte på 80 ferdige, 29 under arbeid og 85 i backlog. «Ferdig / Ikke relevant» må skiljast frå levert implementasjon.

Dette dokumentet er repo-eigd teknisk evidens og ikkje ei speilkopi av Jira. Den historiske statustabellen nedanfor byggjer på CSV-eksporten frå 2026-09-13; nyare Jira-statusar er kontrollert direkte og dokumenterte i dei tilhøyrande gjennomgangane. Kode- og testomtalar skil mellom tidlegare verifisering og testar som ikkje er køyrde i den aktuelle gjennomgangen.

## CRMAAREG-188 / S2 — kontrollert 2026-11-05

[S2](https://nav.atlassian.net/browse/CRMAAREG-188) er kontrollert i live Jira som **Under arbeid**. CRMAAREG-192 er **Under arbeid**, medan CRMAAREG-189–191 og CRMAAREG-193 er i **Backlog**. Ingen statusar er endra.

[P360_Integration_User](../../../force-app/integration/p360/permissionsetgroups/P360_Integration_User.permissionsetgroup-meta.xml) samlar jobbprosessering, kodeverkstilgang og RPC-klassetilgang. Frigiving har eit separat permission set. Dette er tilgangsmetadata, ikkje bevis for oppretta tenestekonto, tildeling eller faktisk miljøtilgang. [RPC-permission-settet](../../../force-app/integration/p360/permissionsets/P360_RPC_Callout_Access.permissionset-meta.xml) seier eksplisitt at External Credential Principal-tilgang må leggjast til etter at principal finst.

[IntegrationLogger](../../../force-app/integration/common/classes/IntegrationLogger.cls) avgrensar feilloggen til fire tekniske felt og tek ikkje imot payload eller exceptiontekst. [IntegrationLogRedactor](../../../force-app/integration/common/classes/IntegrationLogRedactor.cls) maskerer verdiar etter kjende nøkkelfragment; dette er ikkje generell inspeksjon av vilkårlege verdiar eller bevis for komplett maskeringspolicy. P360-workeren har éin avgrensa feillogg-kallar, ikkje full transportaudit.

**Attstår:** Avklart tenestekonto/eigarskap og minste tilgang, audit-hendingar og sporbarheit gjennom transport, godkjende maskeringskrav og teamforankra DoD. Ingen bruk av `ADContextUser` er funnen i P360-koden; fråvær i ein uimplementert transport er ikkje dokumentert godkjenning av prinsippet. Ein ny datert Jira-kommentar er lagd inn og kontrollert etter omlasting; historiske kommentarar er urørte. Ingen org er kontakta eller ny Apex-test køyrd.

## CRMAAREG-84 / F1 — kontrollert 2026-11-05

[F1](https://nav.atlassian.net/browse/CRMAAREG-84) og deloppgåvene CRMAAREG-85–88 er kontrollerte i live Jira som **Ferdig**. Leveransen gjeld dokumentert pakkestruktur, lagdeling, namnestandard og planlagde klasse-/interfaceansvar; ingen titlar eller statusar er endra.

[Designnotatet](../../integrations/p360/lagdelt-struktur-og-namnestandard.md) dokumenterer skiljet mellom Salesforce-domene og P360-kontrakt, prefiks, klasseoversikt og ansvaret til orchestrator, mapper, adapter og RPC-client. [Kodeoversikta](../../../force-app/integration/p360/classes/README.md) skildrar ansvarsmappene i dagens implementasjon. Den planlagde klasseoversikta er ikkje bevis for at alle klassar og operasjonar er implementerte.

F1 si ferdigstilling er ikkje formell ADR-godkjenning: [ADR-0001](../../adr/0001-arkitekturprinsipp-lagdeling-og-namnestandard.md) står **UNDER BEHANDLING**, og [ADR-0004](../../adr/0004-p360-composition-root-og-kontraktsgrense.md) står **Foreslått**. Forholdet mellom den faktiske P360-exceptionbasen og eit generelt hierarki er framleis ope under [#993](https://github.com/navikt/crm-arbeidsforhold/issues/993). Constructor injection/composition root er samordna separat under [#996](https://github.com/navikt/crm-arbeidsforhold/issues/996); dette avgjer ikkje alle K3-akseptansekriteria eller live transport.

Ein ny kommentar merkt «Status 05.11.2026» er lagd inn og kontrollert etter omlasting. Historiske kommentarar, ADR-statusar og spegelkopiar er urørte. Ingen produksjonskode eller metadata er endra, ingen org er kontakta og ingen ny Apex-test er køyrd.

## CRMAAREG-89 / F2 — kontrollert 2026-11-05

[F2](https://nav.atlassian.net/browse/CRMAAREG-89) og dei tolv deloppgåvene CRMAAREG-90–100 og CRMAAREG-321 er kontrollerte i live Jira som **Ferdig**. Klassenamna stemmer med eksisterande kode; ingen titlar eller statusar er endra.

[Application-tenesta](../../../force-app/integration/p360/classes/domain/AAREG_ApplicationDomainService.cls) og [Agreement-tenesta](../../../force-app/integration/p360/classes/domain/AAREG_AgreementDomainService.cls) spør etter Salesforce-posten og returnerer typa kontekst med ID. Dei kastar `P360_ContractException` ved manglande ID eller post. [Orkestratoren](../../../force-app/integration/p360/classes/orchestration/AAREG_ArchiveApplicationOrchestrator.cls) validerer command og koplar intern request/response til injisert arkivadapter, utan full domenemapping. Den reelle arkivadapteren og RPC-klienten stoppar framleis før callout.

[Den opphavlege domenespecen](../../../.github/specs/p360-domain-service-boundaries.md) har fått ei datert presisering som skil det historiske exception-scopet frå dagens gyldige ID-kontekstar. [F2-valideringsoversikta](../../../.github/specs/p360-f2-validation-status.md) er samordna med dette. Testmetoden `archiveContextStopsAtF3Boundary` har historisk namn, men assertionane kontrollerer returnert kontekst; namnet er ikkje bevis for dagens stoppgrense. Dei lukka [#1003](https://github.com/navikt/crm-arbeidsforhold/issues/1003) og [#1006](https://github.com/navikt/crm-arbeidsforhold/issues/1006) er ikkje opna på nytt.

Historisk testresultat 22/22 er bevart som historisk evidens, ikkje ny verifisering. Ingen produksjonskode eller metadata er endra, ingen org er kontakta og ingen ny Apex-test er køyrd.

## CRMAAREG-101 / F3 — namnesamordning 2026-11-05

[F3](https://nav.atlassian.net/browse/CRMAAREG-101) er kontrollert mot DTO-/testfilene og [serialiseringsspecen](../../../.github/specs/p360-dto-serialization.md). Desse titlane er retta til eksisterande Apex-namn:

| Jira                                                          | Frå                                  | Til                                                              |
| ------------------------------------------------------------- | ------------------------------------ | ---------------------------------------------------------------- |
| [CRMAAREG-106](https://nav.atlassian.net/browse/CRMAAREG-106) | `P360CreateCaseRequest/Response`     | `P360_CreateCaseRequestDto / P360_CreateCaseResponseDto`         |
| [CRMAAREG-107](https://nav.atlassian.net/browse/CRMAAREG-107) | `P360UpdateCaseRequest/Response`     | `P360_UpdateCaseRequestDto / P360_UpdateCaseResponseDto`         |
| [CRMAAREG-108](https://nav.atlassian.net/browse/CRMAAREG-108) | `P360GetCasesRequest/Response`       | `P360_GetCasesRequestDto / P360_GetCasesResponseDto`             |
| [CRMAAREG-109](https://nav.atlassian.net/browse/CRMAAREG-109) | `P360CreateDocumentRequest/Response` | `P360_CreateDocumentRequestDto / P360_CreateDocumentResponseDto` |
| [CRMAAREG-111](https://nav.atlassian.net/browse/CRMAAREG-111) | `P360GetDocumentsRequest/Response`   | `P360_GetDocumentsRequestDto / P360_GetDocumentsResponseDto`     |
| [CRMAAREG-113](https://nav.atlassian.net/browse/CRMAAREG-113) | `P360FileParameter`                  | `P360_FileParameterDto`                                          |

Alle seks titlane og uendra **Ferdig**-statusar er kontrollerte i parenten etter ny innlasting. CRMAAREG-114 er òg **Ferdig**, CRMAAREG-102–104 er **Under arbeid**, og CRMAAREG-105/110/112 er i **Backlog**. F3 held fram **Under arbeid**. Uavklarte kontekst-/filmodellnamn er ikkje automatisk erstatta med eksisterande klassar; scope må først avklarast som dokumentert i dei tidlegare gjennomgangane. [UpdateDocument-saka](https://github.com/navikt/crm-arbeidsforhold/issues/1174) er framleis open.

Ein ny kommentar merkt «Status 05.11.2026» er lagd inn og kontrollert etter omlasting; historiske kommentarar er urørte. Namnerettingane endrar ikkje DTO-felt, JSON-kontrakt eller leveransescope. Ingen kode eller metadata er endra, ingen org er kontakta og ingen ny Apex-test er køyrd.

## CRMAAREG-135 / F7 — kontrollert 2026-11-05

[F7](https://nav.atlassian.net/browse/CRMAAREG-135) står framleis **Under arbeid**. [CRMAAREG-141](https://nav.atlassian.net/browse/CRMAAREG-141) er **Ferdig** for builders; CRMAAREG-136–140 står i **Backlog**. Statusane er kontrollerte i live Jira og ikkje endra.

[P360_TestDataFactory](../../../force-app/tests/classes/integration/p360/test/P360_TestDataFactory.cls) har builders for arkivrequest/-response og RPC-request/-response, minimum-access-brukar og isolerte feature-flag-fixtures. [Factory-testen](../../../force-app/tests/classes/integration/p360/test/P360_TestDataFactoryTest.cls) kontrollerer builder-overstyringar under `System.runAs`.

[P360_StubArchiveAdapter](../../../force-app/integration/p360/classes/adapter/P360_StubArchiveAdapter.cls) gir kontrollert suksess utan callout. [P360_TestRetryableArchiveAdapter](../../../force-app/tests/classes/integration/p360/test/P360_TestRetryableArchiveAdapter.cls) kastar retrybar feil. [P360_TestRpcClient](../../../force-app/tests/classes/integration/p360/test/P360_TestRpcClient.cls) tel `send`-kall og feilar testen dersom transport blir nådd; han simulerer ikkje vellukka RPC-respons.

Ingen av `FakeP360CaseService`, `FakeP360JournalpostService`, `FakeP360FileService`, `FakeP360CodeTableService` eller `BaseIntegrationTest` er funne i Apex-koden. Eksisterande arkiv-/RPC-testdoblar skal ikkje omtalast som leveranse av desse klassane. Kodeverkstenesta har framleis berre metadata-implementasjonen; ein alternativ fake-test er eit restpunkt i [K3](https://nav.atlassian.net/browse/CRMAAREG-163). Scope for dei gamle fake-service- og basetestoppgåvene må avklarast mot dagens interfaces før dei eventuelt blir omdøypte eller avslutta. Det er ikkje innført krav om nye parallellklassar eller testarv.

Den historiske F7-kommentaren vart først feilaktig redigert. Originalteksten er gjenoppretta, og dagens vurdering er lagd inn som ein separat kommentar merkt «Status 05.11.2026», med Jira-saksreferanse til K3. Begge kommentarane er kontrollerte etter lagring og omlasting. Jira viser framleis redigeringsmerket på den gamle kommentaren; innhaldet er gjenoppretta, ikkje redigeringshistorikken. Ingen kode, metadata eller historiske spegelkopiar er endra, ingen org er kontakta og ingen ny Apex-test er køyrd.

## CRMAAREG-143 / K1 — kontrollert 2026-11-04

Jira-historia og deloppgåvene 144–154 står no som **Ferdig**, med løysing **Utført**. Repoet inneheld 13 Custom Metadata-postfiler for standardprofilen. Endelege domenespesifikke feltmappingar står framleis att etter [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016). Typebeskrivinga er retta slik at ho skil mellom standardpostane som finst og uavklarte mappingar. Ingen Salesforce-org er kontakta i denne oppdateringa.

## CRMAAREG-155 / K2 — kontrollert 2026-11-04

Jira-historia og deloppgåvene 156–162 står no som **Ferdig**, med løysing **Utført**. `P360_ICodeTableService` og `P360_CodeTableMetadataService` gjer generiske oppslag på aktiv metadata etter tabellnamn og Salesforce-nøkkel, med cache per transaksjon og `P360_MissingCodeTableMappingException` når ei mapping manglar. Testklassen dekkjer både treff på `DefaultValueSet` og manglande mapping; tidlegare scratch-verifisering er oppsummert i statusrada nedanfor. Metadata har `CaseStatus` og `DocumentCategory`, men inga eiga `DocumentStatus`-rad; `JournalStatus`-verdien blir brukt for det obligatoriske P360 `CreateDocument.Status`-feltet. Konkrete domenemappingar og kodeverdiar skal avklarast i [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016), ikkje gjettast inn i tenesta. Ingen Salesforce-org er kontakta i denne oppdateringa.

## CRMAAREG-163 / K3 — kontrollert 2026-11-04

Jira-parenten står framleis i **Under arbeid**. GitHub [#996](https://github.com/navikt/crm-arbeidsforhold/issues/996) er lukka med avgjerda om `P360_AdapterFactory` som composition root og constructor injection, utan service locator. Eksisterande Jira-kommentarar dokumenterer at `P360ServiceLocator` ikkje skal byggjast. `P360_AdapterFactory` og eksempelfake-testen finst; deloppgåvene 165 og 168 står **Ferdig**, medan 164, 166 og 167 står i **Backlog**. Case- og dokumentmapperane som finst brukar `P360_ICodeTableService`, men Jira-deloppgåvene 166/167 viser framleis til dei fråverande klassane `P360CaseMapper` og `P360JournalpostMapper`. K3 kan ikkje ryddast som ferdig før desse deloppgåvene er flytta/avgrensa eller akseptansekriteria er oppdaterte. #994 er framleis open for namneavviket i K2. Ingen Salesforce-org er kontakta i denne oppdateringa.

### K3 — oppfølging 2026-11-05

Etter uttrykkeleg godkjenning er [166](https://nav.atlassian.net/browse/CRMAAREG-166) og [167](https://nav.atlassian.net/browse/CRMAAREG-167) sette til **Ferdig / Utført** for constructor-injection-scope. Titlane er retta frå dei gamle `P360CaseMapper` / `P360JournalpostMapper` til:

- `Bruke constructor injection i AAREG_ApplicationToP360CaseMapper`
- `Bruke constructor injection i AAREG_ApplicationToP360DocumentMapper og AAREG_DecisionToP360DocumentMapper`

Alle tre mapperane tek `P360_ICodeTableService` i konstruktøren og kallar `getValue` gjennom interfacet. Dei eig ikkje direkte metadata-oppslag. Eksisterande mappertestar injiserer den konkrete `P360_CodeTableMetadataService`; dette er ikkje ein test med alternativ fake-kodeverksteneste.

[164](https://nav.atlassian.net/browse/CRMAAREG-164) er avslutta med status **Ferdig**, men løysing **Ikke relevant**, etter avgjerda i [#996](https://github.com/navikt/crm-arbeidsforhold/issues/996). Tittelen `Lage P360ServiceLocator` er bevart som historisk spor av det forkasta arbeidet. Kommentaren seier uttrykkeleg at dette ikkje er ein levert service locator. 165/168 er uendra **Ferdig**.

Parenten heiter no **K3 - Etablere constructor injection for adapterar og kodeverkstenester**. Det første akseptansekriteriet er presisert til constructor injection og `P360_AdapterFactory` som composition root for arkivadapteren, ikkje global service locator. Resten av beskrivinga er bevart. Status held fram **Under arbeid**, sjølv om alle deloppgåvene no er avslutta.

**Attstår før K3 kan lukkast:** Samordne og verifisere akseptansekriteria om metadata som standard kodeverksteneste og test med alternativ kodeverksimplementasjon. [Factory-testen](../../../force-app/tests/classes/integration/p360/adapter/P360_AdapterFactoryTest.cls) beviser injisert RPC-client og val av arkivadapter, ikkje eit fake-kodeverksbytte i mapperane. Factoryen har ikkje ei kodeverksgren. Ingen nye krav om global locator eller K5-RPC-implementasjon er innførte.

**Validering:** Kode, eksisterande testfiler, #996 og live Jira er lesne. Ny tittel, kriterium, kommentar og deloppgåvestatusar er kontrollerte etter omlasting; 164 si løysing er kontrollert på eiga side. Ingen Apex-API, produksjonskode eller metadata er endra, ingen org er kontakta og ingen ny Apex-test er køyrd.

## CRMAAREG-169 / K4 — kontrollert 2026-11-04

Jira-parenten er **Under arbeid**; deloppgåvene 170–172 er **Ferdig** / **Utført**, og 173–174 står i **Backlog**. Metadata har `CaseStatus` / `Default` = `B` (Under behandling), `JournalStatus` / `Default` = `J` (Journalført), og `DocumentCategory` / `Outgoing` = `Dokument ut`. `JournalStatus` er verdien mapperane sender i det obligatoriske P360 `CreateDocument.Status`-feltet; tabellen heiter ikkje `DocumentStatus`. Metadata-README-en seier at standardverdiane kjem frå P360-avklaringa og er godkjende, men identifiserer ikkje presis kjelde og eigar per verdi. Han skisserer omsyn ved endringar, men ikkje ein full godkjennings- og endringsprosess. Difor står opphav/eigarskap og prosess (173–174) att, og K4 er ikkje ferdig. GitHub [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016) er framleis open for full Salesforce-til-SIF-mapping. Ingen Salesforce-org er kontakta i denne oppdateringa.

## CRMAAREG-181 / S1 — kontrollert 2026-11-04

Jira-parenten står i **Backlog**; deloppgåve 186 er **Under arbeid**, medan 182–185 og 187 står i **Backlog**. `P360_Integration_Setting__c` er ein Hierarchy Custom Setting for miljøstyrt Named Credential-namn og mock-transport, ikkje ei faktisk Credential- eller endpoint-konfigurasjon. `P360_AuthenticationException` finst, men `P360_RpcClient.send()` er framleis ein stub som kastar `P360_TransportException`; autentisering, auth-feilhandtering og transportlogging er ikkje implementerte i RPC-klienten. GitHub [#1017](https://github.com/navikt/crm-arbeidsforhold/issues/1017) står open for eksterne endpoint-, header- og auth-avklaringar. Ingen Salesforce-org er kontakta i denne oppdateringa.

## CRMAAREG-195 / C1 — kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-195) og deloppgåvene 196–199 står i **Backlog**. Den eksisterande korte kommentaren om uavklarte forretningsreglar og autoritativ feltkjelde er framleis dekkjande; ingen Jira-endring er gjort.

- [SIF-kontrakten](../../integrations/p360/sif-api-kontrakter.md#case-service) dokumenterer plattformkrav for oppretting og oppdatering, men er ikkje ei godkjenning av Aa-registeret sine triggerreglar, obligatoriske domenefelt eller feltansvar.
- [Case-mapperen](../../../force-app/integration/p360/classes/mapper/AAREG_ApplicationToP360CaseMapper.cls) krev førehandslasta `title`, `externalId` og `externalSystem`, og hentar standardverdiar frå kodeverkstenesta. Han les ikkje Salesforce-forretningsfelt og avgjer ikkje når ei sak skal opprettast eller oppdaterast.
- [Completion roadmap](../../../.github/specs/p360-completion-roadmap.md#2-resolve-contract-and-ownership-decisions) og opne [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016) krev godkjent event-/objektscope, feltmapping, kondisjonelle krav, identitet og dataminimering.

**Attstår:** Avklare opprettings-/oppdateringshendingar, autoritativ kjelde per felt og obligatoriske domenefelt med produkt- og P360-eigar. Deretter kan mapper-TODO-ar avgrensast. Ikkje markere 198 ferdig berre fordi SIF-feltlista finst.

## CRMAAREG-200 / C2 — oppdatert og kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-200) er endra frå **Backlog** til **Under arbeid**. Deloppgåvene 201, 202 og 206 er også **Under arbeid**; 203–205 og 207 står framleis i **Backlog**. Statusane og ein ny, kort kommentar med klikkbar GitHub-lenkje er kontrollerte etter ny innlasting. Kommentaren presiserer at mapper-, validerings- og testgrunnlag finst, utan å påstå faktisk sakoppretting.

| Deloppgåve               | Evidens og avgrensing                                                                                                                                                                                                                                                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 201 — validering         | Mapperen avviser manglande input, tittel, ekstern ID og eksternt system. Godkjende domenereglar og komplett validering før eit faktisk CreateCase-kall står att.                                                                                                                                                                                     |
| 202 — mapping            | `mapToCreateCase(Input)` byggjer ein typa request med input og standard kodeverksverdiar. Full Salesforce-feltmapping og kopling frå arkivflyten står att.                                                                                                                                                                                           |
| 203 — RPC                | [Adapteren](../../../force-app/integration/p360/classes/adapter/P360_ArchiveAdapter.cls) og [RPC-klienten](../../../force-app/integration/p360/classes/client/P360_RpcClient.cls) stoppar med definerte exceptions før callout. [#1017](https://github.com/navikt/crm-arbeidsforhold/issues/1017) er open.                                           |
| 204 — respons og lagring | CreateCase-respons-DTO og serialiseringstestar finst, men ingen faktisk responsparsing og skriving av saks-ID/saksnummer til Salesforce er kopla inn.                                                                                                                                                                                                |
| 205 — logging            | [Worker-loggaren](../../../force-app/integration/p360/classes/job/P360_ArchiveJobWorker.cls) loggar kontrollerte jobbfeil. Dette er ikkje start-, slutt- og feillogging med correlation ID for ein CreateCase-flyt.                                                                                                                                  |
| 206 — unit-testar        | [Mapper-testen](../../../force-app/tests/classes/integration/p360/mapper/AAREG_ApplicationToP360CaseMapperTest.cls) dekkjer input og standardverdiar. [CreateCase-testen](../../../force-app/tests/classes/integration/p360/contract/P360_CreateCaseRequestDtoTest.cls) dekkjer request-/responsfelt ved JSON round-trip, ikkje full saksoppretting. |
| 207 — feiltestar         | Den fokuserte case-mappertesten dekkjer berre normal mapping. Han dokumenterer ikkje avvising av manglande input eller live CreateCase-feil. Generiske adapter-/worker-testar avsluttar ikkje dette use caset.                                                                                                                                       |

[Orkestratoren](../../../force-app/integration/p360/classes/orchestration/AAREG_ArchiveApplicationOrchestrator.cls) sender berre generisk arkividentitet og correlation ID til adapteren. Han brukar ikkje case-mapperen og persisterer ikkje resultatet. Worker-en byggjer tilsvarande ein generisk arkivrequest og oppdaterer jobbstatus; mock-suksess er ikkje evidens for oppretta P360-sak.

**Avvik frå historisk designnotat:** Den historiske Jira-spegelkopien viser saksreferansefelt på `Application__c`. I repoet ligg [P360_Case_Id__c](../../../force-app/integration/p360/objects/Access_Request__c/fields/P360_Case_Id__c.field-meta.xml) og [P360_Case_Number__c](../../../force-app/integration/p360/objects/Access_Request__c/fields/P360_Case_Number__c.field-meta.xml) på `Access_Request__c`, som vanlege Text-felt utan Unique eller External ID. Vidare lesing av [gjeldande datamodell](../../architecture/p360-data-model-og-arkiveringsjob.md#eigarskap-til-p360-referansar) stadfestar at dette er tilsikta: Access Request eig P360-saka, medan søknad og vedlegg deler saksreferansane. Den første C1–C3-gjennomgangen overdreiv derfor uvissa om eigarobjektet. Implementert responslagring, konkret ekstern identitet og godkjend feltmapping står framleis att; felta skal ikkje flyttast eller dupliserast for å følgje det eldre notatet.

## CRMAAREG-208 / C3 — kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-208) og deloppgåvene 209–214 står i **Backlog**. Eksisterande kommentar om at DTO finst, men delta, mapping, RPC og recovery manglar, er framleis dekkjande; ingen Jira-endring er gjort.

[UpdateCase-specen](../../../.github/specs/p360-update-case-dtos.md) og [DTO-testen](../../../force-app/tests/classes/integration/p360/contract/P360_UpdateCaseRequestDtoTest.cls) avgrensar leveransen til interne datafelt og JSON round-trip. Søk gjennom Apex-koden viser ingen produksjonsbruk av `P360_UpdateCaseRequestDto` utanfor DTO-klassen. Dei eksisterande P360-triggerane gjeld vedtaksfrigiving og ContentVersion-arkivjobbar, ikkje feltstyrt UpdateCase-synk.

**Attstår:** Godkjenne oppdaterbare felt og hendingar, implementere delta-sjekk, mapping og RPC-kall, og teste ingen-endring og manglande ekstern ID. SIF-reglane om identifikasjon, `null` og tom streng er dokumenterte i [kontrakten](../../integrations/p360/sif-api-kontrakter.md#updatecase), men må koplast til det godkjende use caset. Generisk retryklassifisering i worker-en oppfyller ikkje åleine C3.

**Validering for C1–C3:** Lokal kode, metadata, relevante spec-ar, testar, historisk Jira-eksport, live Jira og GitHub #1016/#1095 er lesne ved repo-revisjon `21a9bea2`. Ingen nye Apex-testar er køyrde og ingen Salesforce-org er kontakta; testfiler og tidlegare mock-resultat er ikkje ny live-verifikasjon. Jira-spegelkopiane er ikkje endra.

## CRMAAREG-216 / J1 — kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-216) og deloppgåvene 217–220 står i **Backlog**. Den eksisterande kommentaren om at dato-, sender-/mottakar- og obligatoriske journalpostreglar ikkje er godkjende som full mappingkontrakt, er framleis dekkjande. Ingen Jira-endring er gjort.

[CreateDocument-specen](../../../.github/specs/p360-create-document-dtos.md) skil dokumentmetadata frå filkontrakten. [SIF-oppslaget](../../integrations/p360/sif-api-kontrakter.md#createdocument) dokumenterer obligatorisk tittel, kategori og journalstatus, alternativ saksidentifikasjon, kategoriavhengige sender-/mottakarkrav og datoavgrensingar. Dette er teknisk kontraktgrunnlag, ikkje ferdige domenereglar for innkomande, utgåande og notat.

**Attstår:** Godkjenne kategori og obligatoriske/kondisjonelle felt per hending, kjelde for sender/mottakar og kva Salesforce-datoar som skal bli dokumentdato, journaldato og utsendingsdato. [Mapper-README](../../../force-app/integration/p360/classes/mapper/README.md) dokumenterer standardmapping og opne spørsmål, men erstattar ikkje desse avgjerdene. Deloppgåvene skal ikkje markerast ferdige berre fordi SIF-feltlista finst; [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016) er framleis open.

## CRMAAREG-221 / J2 — oppdatert og kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-221) og deloppgåvene 222, 223 og 227 er endra frå **Backlog** til **Under arbeid**. Deloppgåvene 224–226 og 228 står framleis i **Backlog**. Statusane og ein ny, kort kommentar med klikkbar GitHub-lenkje er kontrollerte etter ny innlasting. Den nye kommentaren korrigerer den eldre påstanden om at mapping og validering manglar heilt.

- **222 — validering:** [Søknadsmapperen](../../../force-app/integration/p360/classes/mapper/AAREG_ApplicationToP360DocumentMapper.cls) og [vedtaksmapperen](../../../force-app/integration/p360/classes/mapper/AAREG_DecisionToP360DocumentMapper.cls) avviser manglande input, tittel, dokumentdato, saksnummer, ekstern ID og eksternt system. Dei validerer ikkje fullstendige kategori-, kontakt- eller datoreglar.
- **223 — mapping:** Begge byggjer `P360_CreateDocumentRequestDto` med saksnummer, ekstern identitet, dokumentdato, standardmetadata og eventuelle førehandslasta filer. Søknadsmappinga lèt `category` stå tom; vedtaksmappinga brukar `Dokument ut`. Ingen av dei fyller sender/mottakar, journaldato eller utsendingsdato. Dette er ikkje komplett live-payload. Mapperane er berre kalla frå testar i den undersøkte Apex-koden, ikkje frå orkestratoren eller worker-en.
- **224–226 — transport, lagring og logging:** Adapter/RPC stoppar før callout. Respons-DTO-ar finst, men parsing av faktisk SIF-respons og lagring av dokumentreferansar er ikkje kopla inn. Worker-feillogging er ikkje komplett CreateDocument-logging med correlation ID.
- **227 — unit-testar:** [Søknadstesten](../../../force-app/tests/classes/integration/p360/mapper/AAREG_CreateDocumentMapperTest.cls) stadfestar normal mapping og medvite open kategori. [Vedtakstesten](../../../force-app/tests/classes/integration/p360/mapper/AAREG_DecisionDocumentMapperTest.cls) stadfestar utgåande standardverdiar og mock-filinnhald. [DTO-testen](../../../force-app/tests/classes/integration/p360/contract/P360_CreateDocumentRequestDtoTest.cls) dekkjer JSON round-trip, ikkje journalføring.
- **228 — feiltestar:** Dei to dokumentmappertestane dekkjer berre normal mapping. Use case-testar for ugyldig journalpost, manglande kontakt, ugyldig datorekkjefølgje og transport-/responsfeil står att etter kontraktavklaring.

**Saksnøkkel og referansar:** Mapperane brukar `caseNumber`, medan DTO-en også kan representere `caseExternalId`. Endeleg strategi må godkjennast. Dokument-ID-/nummerfelt finst på [Application__c](../../../force-app/integration/p360/objects/Application__c/fields/), [Application_Decision__c](../../../force-app/integration/p360/objects/Application_Decision__c/fields/) og [Agreement__c](../../../force-app/integration/p360/objects/Agreement__c/fields/); det historiske designnotatet omtalar berre Agreement. Eksistensen av desse Text-felta er ikkje implementert lagring eller avklart eigarskap for alle hendingar. Mapping og samansetjing av flyten står att under [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016) og [#1095](https://github.com/navikt/crm-arbeidsforhold/issues/1095).

## CRMAAREG-229 / J3 — kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-229) og deloppgåvene 230–235 står i **Backlog**. Eksisterande kommentar om at GetDocuments-DTO finst, men UpdateDocument og oppdateringsflyten manglar, er framleis dekkjande. Ingen Jira-endring er gjort.

Ingen UpdateDocument-klassar, Apex-metadata eller testar er funne under `force-app/`. [#1174](https://github.com/navikt/crm-arbeidsforhold/issues/1174) er open for den avgrensa DTO-leveransen; ho skal ikkje utvidast til heile J3. [SIF-oppslaget](../../integrations/p360/sif-api-kontrakter.md#updatedocument) dokumenterer identifikasjon og `null`-/tom-streng-semantikk. Godkjende oppdaterbare domenefelt, livssyklusavgrensingar, delta-sjekk, mapping, RPC, feilklassifisering og testar for endring/ingen-endring står framleis att.

**Validering for J1–J3:** Spec, dokumentasjon, mapperar, DTO-ar, relevante testfiler, feltmetadata, live Jira og GitHub #1016/#1174 er undersøkte. GitHub-sakene har fått avgrensa statusoppdateringar. Ingen nye Apex-testar er køyrde og ingen Salesforce-org er kontakta. Historiske Jira-/Confluence-spegelkopiar er ikkje endra.

## CRMAAREG-237 / FLS1 — oppdatert og kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-237) og deloppgåvene 238 og 241 er endra frå **Backlog** til **Under arbeid** for delvis kartlagde filkjelder og dokumentert målansvar for arkivversjonen. Deloppgåvene 239–240 står i **Backlog**: MVP-transport og storleiksgrenser er ikkje valde. Ingen deloppgåver er markerte ferdige.

- **238 — filkjelde:** [Søknadskontrolleren](../../../force-app/externalApplication/classes/AAREG_ApplicationController.cls) opprettar `ContentVersion` frå base64 og legg deretter til `ContentDocumentLink`. Han set ikkje `FirstPublishLocationId`. [P360-handleren](../../../force-app/integration/p360/classes/P360_ContentVersionArchiveHandler.cls) opprettar berre jobb når fila ved insert har `FirstPublishLocationId` på ein søknad med Access Request, og gate er på. Den eksisterande opplastingsstien er derfor ikkje dekt av denne inngangen. Dette er eit statisk påvist koplingsgap, ikkje ein ny runtime-test.
- [Vedtaks-PDF-tenesta](../../../force-app/internalApplicationDecision/classes/AAREG_ApplicationDecisionPDFFileService.cls) genererer Salesforce-PDF og lenkjer fila etter insert. [Avtalefil-tenesta](../../../force-app/internalApplicationAgreement/classes/AAREG_createContentVersionForAgreement.cls) kopierer ei søknadsfil til avtalen. Desse eksisterande funksjonane er ikkje P360-filtransport og skal ikkje endrast som del av statusgjennomgangen.
- **241 — konverteringsansvar:** [Datamodellen](../../architecture/p360-data-model-og-arkiveringsjob.md#arkiveringsreglar) skildrar målkravet om at P360 skal generere og eige arkivversjonen av vedtaksdokumentet, fortrinnsvis PDF/A, utan å gjere arkivering avhengig av Salesforce-PDF. Endeleg ekstern leveranse og ansvar må stadfestast; dette vel ikkje kjelde eller konvertering for alle søknadsvedlegg.

**Attstår:** Avgrense filkjelder og godkjende hendingar, velje inline versus opplasta referanse, og dokumentere format, storleik, heap-/payloadomsyn, metadata, cleanup og delvis-feil-handtering i [#1018](https://github.com/navikt/crm-arbeidsforhold/issues/1018). [SIF-kontrakten](../../integrations/p360/sif-api-kontrakter.md#file-service) skildrar alternativa, ikkje ei godkjend MVP-avgjerd.

## CRMAAREG-242 / FLS2 — oppdatert og kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-242) og deloppgåvene 243–244 er endra frå **Backlog** til **Under arbeid**. Deloppgåvene 245–249 står framleis i **Backlog**. Ny kort kommentar skil levert mock-grunnlag frå faktisk filoverføring.

- **243 — filvalidering:** [Filmapperen](../../../force-app/integration/p360/classes/mapper/AAREG_ApplicationFileToP360FileMapper.cls) krev input, tittel, format og base64-innhald. Han kontrollerer ikkje støtta filtypar, innhaldsformat, gyldig base64 eller filstorleik.
- **244 — payload:** Mapperen overfører førehandslasta tittel, format og base64 til `P360_FileParameterDto` og set `versionFormat = Original`. Dokumentmapperane brukar han. Dette er ikkje ContentVersion-henting, FileService-upload eller tilknyting til eit eksisterande P360-dokument.
- **245–246 — transport og kvittering:** Ingen Upload-implementasjon eller DTO-ar for Upload er funne under `force-app/`. `P360_File_Id__c` finst på dei tre dokumenteigarobjekta, men er ikkje kopla til kvittering frå faktisk filtransport. RPC-klienten er framleis ein stub.
- **247–249 — feiltestar:** [Filmappertesten](../../../force-app/tests/classes/integration/p360/mapper/AAREG_FileMapperTest.cls) dekkjer normal mapping og manglande innhald; [DTO-testen](../../../force-app/tests/classes/integration/p360/contract/P360_FileParameterDtoTest.cls) dekkjer JSON round-trip. Dette er ikkje testar for ugyldig filtype, stor fil eller timeout. [ContentVersion-testen](../../../force-app/tests/classes/integration/p360/P360_ContentVersionArchiveHandlerTest.cls) dekkjer direkte publisering og gate, ikkje seinare lenking frå søknadskontrolleren.

## CRMAAREG-250 / FLS3 — kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-250) og deloppgåvene 251–253 står i **Backlog**. Ingen Jira-endring er gjort. [SIF-oppslaget](../../integrations/p360/sif-api-kontrakter.md#large-files) omtalar `/v2/support/Uploadfile` som eit seinare alternativ, skilt frå `FileService/Upload`. Det fastset ikkje storfilgrense eller godkjent operasjon for MVP. Jira-namnet `UploadStream` skal ikkje tolkast som ein vald eller implementert RPC-operasjon.

**Validering for FLS1–FLS3:** Kode og metadata i P360-integrasjonen er samanlikna med eksisterande søknads-, vedtaks- og avtalefilproduksjon, testfiler, spec og arkitekturdokumentasjon. Live Jira og GitHub #1018 er kontrollerte. Ingen ny Apex-test eller Salesforce-org-operasjon er køyrd; ingen produksjonskode, metadata eller historiske spegelkopiar er endra.

## CRMAAREG-255 / X1 — kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-255) står i **Under arbeid**. Deloppgåve 259 er **Ferdig**; 256–258 og 260 står i **Backlog**. Eksisterande kommentar skil lagringsfelta frå endeleg external-ID-format og livsløp. Ingen status- eller kommentarendring er nødvendig.

- [Datamodellen](../../architecture/p360-data-model-og-arkiveringsjob.md#eigarskap-til-p360-referansar) fastset Access Request som eigar av saksreferansane og søknad, vedtak og avtale som eigarar av dokumentreferansane. Metadata og [metadatatesten](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobMetadataTest.cls) støttar denne plasseringa. Dette underbyggjer ferdigstillinga av 259.
- Saks-, dokument- og filreferansane er Text-felt, ikkje unike Salesforce External ID-felt. Jobben sitt [Idempotency_Key__c](../../../force-app/integration/p360/objects/P360_Archive_Job__c/fields/Idempotency_Key__c.field-meta.xml) er derimot obligatorisk, Unique og External ID. Desse representerer ulike identitetar og må ikkje blandast.
- Mapperane tek imot `externalId` og `externalSystem`, men genererer ikkje eit godkjent format per ekstern entitet. [Idempotens-specen](../../../.github/specs/p360-idempotency-keys.md) avgrensar eksplisitt dei fire interne jobbnøklane frå ekstern ID-mapping og P360-recovery.

**Attstår:** Format og type/system per sak, journalpost og fil, ekstern unikheit og livsløp, og korleis desse blir brukte ved ukjent resultat og retry. Eit testeksempel med eit systemnamn eller ein jobb-ID er ikkje slik godkjenning. [#1015](https://github.com/navikt/crm-arbeidsforhold/issues/1015) og [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016) står opne.

## CRMAAREG-261 / X2 — kontrollert og presisert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-261) og deloppgåvene 262–265 står i **Under arbeid**; ingen statusar er endra. Ein ny, kort kommentar presiserer at jobbgjenbruk finst for alle fire jobbtypane, ikkje berre ApplicationDocument slik den eldre kommentaren seier. Han skil dette frå oppslag via lagra eksterne P360-ID-ar.

- **262 — lookup:** [Jobbservicen](../../../force-app/integration/p360/classes/job/P360_ArchiveJobService.cls) finn og gjenbrukar jobbar etter intern idempotensnøkkel for ApplicationDocument, ApplicationAttachment, DecisionDocument og AgreementDocument. Han slår ikkje opp eksterne saks-, dokument- eller filreferansar. Søk gjennom Apex-koden viser ingen implementert P360-reference lookup utility; GetCases/GetDocuments-DTO-ane er berre brukte i DTO-klassar og serialiseringstestar.
- **263 — statusmodell:** [Status-metadata](../../../force-app/integration/p360/objects/P360_Archive_Job__c/fields/Status__c.field-meta.xml) definerer Pending, In Progress, Succeeded, Failed og Manual Review. Datamodellen skil teknisk jobbstatus frå autoritative P360-referansar. Dette er levert jobbgrunnlag, men ikkje eit fullført lokalt oppslag som kombinerer referanse, jobbstatus og gjenopptaking.
- **264 — manglande ID:** Jobbservicen avviser manglande Salesforce-kontekst og correlation ID. Domene-tenestene kontrollerer at søknad/avtale finst, men les ikkje P360-referansane. Dette er ikkje ferdig handtering av manglande ekstern ID ved lokal gjenopptaking.
- **265 — testar:** [Jobbservicetesten](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobServiceTest.cls) dekkjer gjenbruk av alle fire jobbtypane og manglande søknadskontekst. Worker-/claim-testar dekkjer interne jobbforløp. Dei dokumenterer ikkje ekstern ID-recovery etter vellukka P360-kall med tapt Salesforce-respons.

**Attstår:** Implementere det lokale oppslags-use-caset med eksplisitt retur-/feilåtferd, tilgang/sharing og handtering av tomme eller motstridande referansar. Testa jobbgjenbruk er ikkje ferdig X2, og lokalt oppslag skal ikkje gjerast avhengig av at eit eksternt recovery-endepunkt blir tilgjengeleg.

## CRMAAREG-266 / X3 — kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-266) og deloppgåvene 280–282 står i **Backlog**. Eksisterande kommentar om at P360-recovery krev ekstern kontrakt, er dekkjande. Ingen Jira-endring er gjort.

[Operasjonsoversikta](../../integrations/p360/sif-rpc-operasjonar.md) merkar `GetEntitiesExternalIds` som ikkje stadfesta og seinare fase: service, request, response og recovery-strategi manglar. Ingen implementasjon er funnen i Apex-koden. [GetCases-specen](../../../.github/specs/p360-get-cases-dtos.md) dekkjer datakontraktar og utelèt orkestrering og RPC-integrasjon; han stadfestar ikkje `GetEntitiesExternalIds`.

**Attstår:** Godkjenne timeout-/ukjent-resultat-scenario, oppslagsnøkkel og treffreglar, feil-/fallbackåtferd, miljøavhengigheiter og adapter-backlog under [#1015](https://github.com/navikt/crm-arbeidsforhold/issues/1015). Ikkje byggje eit gjetta endepunkt eller bruke blind create som fallback.

**Validering for X1–X3:** Live Jira, metadata, kode, relevante testfiler, spec-ar og gjeldande arkitekturdokument er samanlikna. Ingen nye Apex-testar er køyrde og ingen Salesforce-org er kontakta. Historiske spegelkopiar og produksjonskode er ikkje endra.

## CRMAAREG-268 / R1 — kontrollert og presisert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-268) står i **Under arbeid**. Deloppgåvene 269–271 og 273 står **Ferdig**, medan 272 er **Under arbeid**. Ingen statusar er endra. Ny kort kommentar presiserer skiljet mellom implementert intern jobbgjenbruk og uverifisert samtidig duplicate-race / ekstern P360-deduplisering.

[Idempotens-specen](../../../.github/specs/p360-idempotency-keys.md), [nøkkelklassen](../../../force-app/integration/p360/classes/job/P360_IdempotencyKey.cls) og [jobbservicen](../../../force-app/integration/p360/classes/job/P360_ArchiveJobService.cls) dekkjer alle fire interne jobbtypane. Metadata har unik External ID-nøkkel; servicen søkjer før insert og handterer `DUPLICATE_VALUE` ved nytt oppslag. [Servicetestane](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobServiceTest.cls) stadfestar sekvensiell gjenbruk, men inneheld ikkje ein eksplisitt samtidig race-test. Den eldre Jira-kommentaren si formulering om testa duplicate-race skal ikkje brukast som slik evidens.

**Attstår:** 269 si ferdigstilling må lesast som eksisterande intern-slice-status, ikkje ein godkjend ekstern case-nøkkel. Ingen eigen case-jobbtype eller full CreateCase-deduplisering er implementert. Ekstern case-/dokumentidentitet, duplicate-respons og trygg handtering etter ukjent P360-resultat står att under [#1015](https://github.com/navikt/crm-arbeidsforhold/issues/1015) og X1–X3.

## CRMAAREG-274 / R2 — oppdatert og kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-274) står i **Under arbeid**. Deloppgåvene 275 og 277 held fram **Under arbeid**; 276 og 278 er endra frå **Backlog** til **Under arbeid** for førebels retrypolicy og dokumentert manuell målprosess. 279 står i **Backlog** for operasjonell verifisering. Ny kort kommentar korrigerer påstanden om at worker, scheduler og backoff manglar.

- **275 — klassifisering:** [Worker-en](../../../force-app/integration/p360/classes/job/P360_ArchiveJobWorker.cls) brukar `P360_IntegrationException.isRetryable`, som standard er false og kan setjast eksplisitt. Ikkje-retrybar feil og oppbrukte forsøk går til Manual Review; retrybar feil før grensa går til Failed med neste tidspunkt. Endeleg klassifisering av HTTP-/P360-feilkodar og ukjent resultat er ikkje implementert i transportstubben. Exception-klassen sitt namn åleine gjer ikkje ein timeout trygg å retrye.
- **276 — policy:** [Claim-servicen](../../../force-app/integration/p360/classes/job/P360_ArchiveJobClaimService.cls) set ti minutts lease og aukar forsøksteljaren. Worker stoppar ved femte forsøk. Dei automatisk brukte ventetidene er derfor 1, 5, 15 og 60 minutt; den femte listeverdien på 360 minutt blir ikkje nådd i normal automatisk flyt. Det [dokumenterte](../../architecture/p360-data-model-og-arkiveringsjob.md#førebels-mvp-retrypolicy) 24-timarsvindauget er ikkje handheva. Callout-timeout på 120 sekund er målpolicy, ikkje implementert transport.
- **277 — status og køyring:** Jobbstatusane, [scheduler](../../../force-app/integration/p360/classes/job/P360_ArchiveJobScheduler.cls), claim og worker finst. Scheduler claimar opptil ti jobbar og køyrer ein queueable; dette er ikkje ei oppretta eller verifisert org-cron. Claim-queryen tek Pending og forfalte Failed, men ikkje In Progress med utløpt lease. Ho brukar ikkje `FOR UPDATE` eller tilsvarande atomisk reservasjon; implementasjonen dokumenterer dermed ikkje trygg parallell claiming eller automatisk recovery av hengande jobbar.
- **278 — manuell re-køyring:** [Datamodellen](../../architecture/p360-data-model-og-arkiveringsjob.md#manuell-frigiving) skildrar autoriserte roller, grunn/brukar/tidspunkt og Manual Review → Pending → In Progress utan direkte callout. Metadatafelta for manuell frigiving finst, men søk i Apex, Flow, trigger og JavaScript viser inga implementert handling som fyller dei og frigir jobben. Dette er dokumentert målprosess, ikkje ferdig eller operasjonelt testa re-køyring.
- **279 — operasjonell test:** [Claim-testane](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobClaimServiceTest.cls), [worker-testane](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobWorkerTest.cls) og [scheduler-testane](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobSchedulerTest.cls) dekkjer interne jobbforløp, gate, retry og terminal feil. Dei beviser ikkje parallell claiming, lease-recovery, manuell frigiving eller trygg live-retry etter tapt respons. Tidlegare mock-smoke er heller ikkje full driftsverifikasjon.

**Attstår:** Avstemme implementert og dokumentert policy, teste/implementere atomisk claim og lease-recovery, fullføre kontrollert manuell handling og få éin eigd runbook. [#997](https://github.com/navikt/crm-arbeidsforhold/issues/997) er framleis open for runbook-eigarskap; [#1015](https://github.com/navikt/crm-arbeidsforhold/issues/1015) er oppdatert med dei konkrete gapane. Desse funna er ikkje retta i kode under statusarbeidet.

**Validering for R1–R2:** Kode, metadata, spec, dokumenterte målreglar, testfiler, live Jira og GitHub er samanlikna. Jira-statusar og korte kommentarar er kontrollerte etter ny innlasting. Ingen nye Apex-testar er køyrde og ingen Salesforce-org er kontakta; samtidigheits- og recovery-gap er statiske funn, ikkje resultat frå nye runtime-testar. Historiske spegelkopiar er ikkje endra.

## CRMAAREG-284 / O1 — oppdatert og kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-284) står i **Under arbeid**. Deloppgåvene 285–287 held fram i **Backlog** for instrumentering av dei tre faktiske flytane. 288 er endra frå **Backlog** til **Under arbeid** for avgrensa logger-/worker-testgrunnlag; 289 held fram **Under arbeid** for loggstruktur. Ingen deloppgåver er markerte ferdige. Ein ny kort kommentar skil worker-feillogging frå ende-til-ende-instrumentering.

- [Worker-en](../../../force-app/integration/p360/classes/job/P360_ArchiveJobWorker.cls) har eitt kall til `IntegrationLogger.logFailure`: system `P360`, operasjon frå `Archive_Event_Type__c`, status `RetryScheduled` eller `ManualReview`, og jobbens correlation-ID. Kallet er best-effort; loggerfeil blir fanga utan å stoppe jobbklassifiseringa. Dette er ikkje start-/slutt-/feillogging per CreateCase, CreateDocument eller upload.
- [Loggeren](../../../force-app/integration/common/classes/IntegrationLogger.cls) persisterer berre `systemName`, `operationName`, `status` og `correlationId`. Labels blir syntakskontrollerte og sensitive namnefragment avviste. Correlation-ID må ha 32 heksadesimale teikn; andre verdiar blir `[REDACTED]`. Dokumentinnhald, request-/response-payload og exception-tekst er ikkje del av dette logger-API-et.
- [Logger-testen](../../../force-app/tests/classes/integration/common/IntegrationLoggerTest.cls) dekkjer dei fire felta og normalisering av ugyldig/sensitiv kontekst. [Worker-testane](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobWorkerTest.cls) dekkjer lagra teknisk feilkontekst utan exception-melding og med rett jobbtype/status. Dette er avgrensa testdekning, ikkje ny runtime-verifikasjon eller full personverngodkjenning.
- [Redactoren](../../../force-app/integration/common/classes/IntegrationLogRedactor.cls) har eigne testar for nøkkelbasert maskering, men blir ikkje kalla av denne loggeren. Han skal ikkje omtalast som ein universell eller automatisk del av P360-loggkjeda.
- Worker-requesten fyller berre `externalId` frå intern jobbnøkkel, ikkje `correlationId`. Orkestratoren kan vidareføre correlation-ID i sitt generiske request/resultat, men transportstubben implementerer ikkje gjennomgåande korrelasjon. At ein ID finst på jobben og i éin logg beviser ikkje heile kjeda.

**Attstår:** Start/slutt/feil for godkjende live-flytar, gjennomgåande opaque correlation-ID, kontroll av alle loggflater og handtering av loggfeil. [Teknisk oversikt](../../integrations/p360/teknisk-oversikt.md#logging-og-neste-kopling) er korrigert frå dei utdaterte labelnamna `ArchiveJob`/`Failed` til dei faktiske felta. [#1096](https://github.com/navikt/crm-arbeidsforhold/issues/1096) er lukka for loggergrunnlaget; O1 og [#1095](https://github.com/navikt/crm-arbeidsforhold/issues/1095) er ikkje ferdige.

## CRMAAREG-290 / O2 — kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-290) og deloppgåvene 291–294 står i **Backlog**. Eksisterande kommentar om manglande alarmkriterium, runbook, støtteansvar og operativ feilsøkingsguide er dekkjande for produksjonsberedskap; ingen Jira-endring er gjort.

[Mock-testguiden](../../integrations/p360/user-testing-guide.md) dokumenterer intern scratch-/mock-verifikasjon utan live P360-kall. Han erstattar ikkje ein operativ produksjonsrunbook. Søk i Salesforce-metadata fann ingen P360-namngjevne rapportar, dashboards, report types eller notification types; dette er ikkje kontroll av eksterne overvakingstenester eller org-konfigurasjon.

**Attstår:** Godkjenne alarmkriterium, tersklar, mottakarar og støtteansvar, lenkje til éin eigd Confluence-runbook og samordne feilsøkings-/re-køyringsinnhald mellom R2, O2 og D2. [#997](https://github.com/navikt/crm-arbeidsforhold/issues/997) er framleis open for eigarskap og kjelde; kode eller ein lokal mock-guide kan ikkje åleine lukke dette.

**Validering for O1–O2:** Kode, relevante logger-/worker-testfiler, spec, dokumentasjon, Salesforce-kjeldemetadata, GitHub og live Jira er lesne. Ingen nye Apex-testar er køyrde og ingen org er kontakta; tidlegare testresultat er historisk evidens. Berre repo-eigd dokumentasjon og tracking er oppdaterte, ikkje produksjonskode eller historiske spegelkopiar.

## CRMAAREG-296 / T1 — oppdatert og kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-296) held fram **Under arbeid**. 297–299 er flytta frå **Backlog** til **Under arbeid**; 300 er flytta til **Ferdig** for den generiske kodeverkstenesta. 301 (exceptions) og 302 (serialisering) held fram **Ferdig** innan eksisterande scope. Ny kort Jira-kommentar korrigerer eldre påstand om at mapper- og kodeverkstestar manglar.

| Deloppgåve               | Lest kodeevidens                                                                                                                                                                                                                                                                                                                      | Avgrensing                                                                                                                           |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 297 — case-mapper        | [Case-testen](../../../force-app/tests/classes/integration/p360/mapper/AAREG_ApplicationToP360CaseMapperTest.cls) kontrollerer input-identitet, defaults og arkivkode under minimum-access-brukar med kodeverkstilgang.                                                                                                               | Éin normal mapping-test; ikkje komplett negativ dekning eller godkjend endeleg feltmapping.                                          |
| 298 — journalpost-mapper | [Søknadstesten](../../../force-app/tests/classes/integration/p360/mapper/AAREG_CreateDocumentMapperTest.cls) og [vedtakstesten](../../../force-app/tests/classes/integration/p360/mapper/AAREG_DecisionDocumentMapperTest.cls) kontrollerer metadata, identitet og innebygd filmapping. Søknadskategori er medvite null.              | Normale mapperresultat, ikkje komplett dekning av ugyldige/manglande felt, kontakt-/datoreglar eller faktisk orkestrert flyt.        |
| 299 — filmapper          | [Filtesten](../../../force-app/tests/classes/integration/p360/mapper/AAREG_FileMapperTest.cls) kontrollerer bevarte felt, `Original` og kontrollert feil ved manglande base64-data.                                                                                                                                                   | Ingen test av ugyldig base64, støtta format eller storleiksgrenser; transport-timeout høyrer til transport-/integrasjonstesting.     |
| 300 — code table service | [Kodeverkstesten](../../../force-app/tests/classes/integration/p360/codetable/P360_CodeTableMetadataServiceTest.cls) dekkjer konfigurert `DefaultValueSet` og kontrollert exception for ukjend tabell/nøkkel under minimum-access-brukar med relevant permission set.                                                                 | Ferdig for generisk K2-scope; ikkje godkjenning av alle domenespesifikke kodeverdiar eller full dekning av framtidige mappingreglar. |
| 301 — exceptions         | [Hierarkitesten](../../../force-app/tests/classes/integration/p360/exception/P360_ExceptionHierarchyTest.cls) kontrollerer konkrete typar og arverelasjonar; eigne correlation-/retryable-testar finst.                                                                                                                               | Ferdig testleveranse er ikkje det same som at Jira-namn, ADR og live feilklassifisering er ferdig avklarte under F5/#993.            |
| 302 — serialisering      | [Round-trip-testen](../../../force-app/tests/classes/integration/p360/contract/P360_DtoSerializationTest.cls) og operasjonsspesifikke DTO-testar, til dømes [CreateDocument](../../../force-app/tests/classes/integration/p360/contract/P360_CreateDocumentRequestDtoTest.cls), kontrollerer felt gjennom JSON serialize/deserialize. | Intern DTO-kontrakt, ikkje verifisert SIF-envelope/wire-format, og ikkje dekning for DTO-ar som enno ikkje finst.                    |

[Orkestratortesten](../../../force-app/tests/classes/integration/p360/orchestration/AAREG_ArchiveApplicationOrchestratorTest.cls) injiserer `P360_StubArchiveAdapter` og kontrollerer manglande command/application-ID og vellukka stub-resultat. Testnamnet `validCommandIsRejectedUntilOrchestrationIsImplemented` er forelda i høve til assertionane som forventar suksess; namnet åleine skal ikkje brukast som statusbevis. Fake-/stub-grunnlag finst, men er ikkje i seg sjølv bevis for godkjend SIF-komposisjon.

**Historisk verifikasjon:** [#1092](https://github.com/navikt/crm-arbeidsforhold/issues/1092) dokumenterer post-merge-suite 90/90 (`707QI00001Idq8v`) og godkjend mock-smoke. Den seinare loggergjennomgangen har eit anna 90/90-run (`707QI00001IdqiI`), og PR #1102 dokumenterer worker 6/6 (`707QI00001IeSQt`). Dette er ulike historiske køyringar, ikkje nye resultat frå denne gjennomgangen eller bevis for at all framtidig mapping er dekt.

**Attstår i T1:** Komplettere positive og negative åtferdstestar for endeleg godkjende mapping-/valideringsreglar og støtte nye kontraktar etter kvart som dei blir implementerte. Live P360-køyring er T2-scope og er ikkje åleine ein grunn til å halde ein ferdig einingstest open.

## CRMAAREG-303 / T2 — kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-303) og 304–308 er verifiserte i **Backlog**, utan endring. Eksisterande kommentar om at integrasjonstest mot P360-testmiljø ikkje er implementert eller køyrd, er framleis dekkjande.

[Mock-scriptet](../../../scripts/p360-mock-smoke.sh), [testguiden](../../integrations/p360/user-testing-guide.md) og [#1092](https://github.com/navikt/crm-arbeidsforhold/issues/1092) dekkjer intern ApplicationDocument-/ApplicationAttachment-jobbflyt, worker-status og duplikatnøklar. Dei verifiserer ikkje CreateCase, CreateDocument eller upload mot P360, ekte auth-/timeout-/valideringsfeil, lagring av returnerte P360-referansar eller gjennomgåande korrelasjon. Generisk testdatafactory er heller ikkje eit godkjent testdatasett for det eksterne miljøet.

**Attstår:** Avtale scenario, syntetiske testdata, eksakt ikkje-produksjonsmiljø og tilgang etter kontrakt-/mappingavklaringane; implementere og køyre integrasjonstestar; kontrollere referanselagring og correlation-ID; dokumentere faktiske avvik/funn frå desse køyringane. Lokale statiske funn og mock-data blir ikkje rekna som ferdige deloppgåver for live T2.

**Validering for T1–T2:** Relevant testkode, spec/roadmap, mock-script, historisk GitHub-evidens og live Jira er lesne. Ingen nye Apex-testar eller mock-/integrasjonskøyringar er utførte og ingen org er kontakta. Ny Apex-validering krev fersk stadfesting av eksakt ikkje-produksjonsmål og handling; live T2 krev i tillegg godkjend P360-kontrakt, miljø og testdata.

## CRMAAREG-310 / D1 — kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-310) og 311–314 er verifiserte i **Ferdig**, utan statusendring. Dette gjeld dokumentert grunnmur og kontraktgrense, ikkje ferdig live-integrasjon eller godkjenning av alle arkitekturavgjerder. Ein ny kort kommentar presiserer skiljet og oppdateringsbehovet etter worker-leveransen.

- [Diagramregisteret](../../README.md#diagramregister) lenkjer komponent-, klasse-, relasjons-, kontraktgrense- og interne jobb-/frigivingsdiagram. [Teknisk oversikt](../../integrations/p360/teknisk-oversikt.md) og [roadmap](../../../.github/specs/p360-completion-roadmap.md) skil implementert grunnmur frå målarkitektur og eksterne avgjerder. Det er ikkje grunnlag for å omtale desse som verifiserte live-sekvensar for case, journalpost og upload.
- [Adapterdokumentasjonen](../../integrations/p360/di-og-adapterval.md) er oppdatert til faktisk factory-val: eksplisitt org-default mock-setting vel stub; elles blir adapter/RPC-skjelettet konstruert. Prosesseringsgate er eit separat default-off vern. Ein framtidig K5-kodeverkadapter er ikkje ein implementert factory-gren.
- [Kontraktgrensesekvensen](../../architecture/p360-archive-sequence.mmd) viste tidlegare adapter-til-client-kall og svar som om dei fanst. Han viser no kontrollert exception før RPC, i samsvar med [adapteren](../../../force-app/integration/p360/classes/adapter/P360_ArchiveAdapter.cls) og [orkestratoren](../../../force-app/integration/p360/classes/orchestration/AAREG_ArchiveApplicationOrchestrator.cls). Direkte client-kall ville òg stoppe før transport.
- [Jobbstatusdiagrammet](../../integrations/p360/diagrams/p360-archive-job-state.mmd) og same diagram i [gjennomgangen](../../integrations/p360/steg-for-steg-gjennomgang.md) er korrigerte: forfallen `Failed` går direkte til `In Progress` ved claim; worker set ikkje-retrybar/uttømt feil direkte til `Manual Review`; berre fire automatiske ventesteg blir brukte før femte forsøk. Manuell frigiving og lease-recovery er ikkje framstilte som ferdige handlingar.
- [ADR-0001](../../adr/0001-arkitekturprinsipp-lagdeling-og-namnestandard.md) står **UNDER BEHANDLING**; [ADR-0004](../../adr/0004-p360-composition-root-og-kontraktsgrense.md) står **Foreslått** med uttrykkeleg krav om teamavklaring. Skriven ADR er ikkje det same som normativ godkjenning. Ingen ADR-status eller historisk spegelkopi er endra.

**Vidare dokumentvedlikehald:** Oppdater diagram og flytbeskrivingar når endeleg case-/journalpost-/filkontrakt blir implementert. Oversiktsdiagram er ikkje åleine bevis for runtime-kopling; mapperane er ikkje kopla inn i dagens worker-request. Godkjenningsstatus for ADR-ar må avklarast menneskeleg, ikkje utleiast frå at D1 er ferdig.

## CRMAAREG-315 / D2 — kontrollert 2026-11-05

[Jira-parenten](https://nav.atlassian.net/browse/CRMAAREG-315) står **Under arbeid**, 319 **Ferdig**, og 316–318/320 **Backlog**, utan statusendring. Fase 2 og teknisk gjeld er skildra i roadmap og dei konkrete K5-/X3-/FLS3- og kontraktsakene. Det beviser ikkje ferdig drift eller gjennomført overleveringsmøte.

Eksisterande Jira-avhengigheiter frå D2 til **D1, O2 og R2** er verifiserte. [#997](https://github.com/navikt/crm-arbeidsforhold/issues/997) hadde ein forelda påstand om at slike lenkjer ikkje fanst; saksteksten er oppdatert. Det er framleis ikkje verifisert éin namngjeven eigar, éin autoritativ Confluence-runbook eller eit avtalt vedlikehaldsløp.

[Mock-testguiden](../../integrations/p360/user-testing-guide.md) er intern teststøtte, ikkje produksjonsdriftsguide. [Datamodellen](../../architecture/p360-data-model-og-arkiveringsjob.md) dokumenterer målprosessen for manuell frigiving med grunn/brukar/tid og overgang til `Pending`, men den operative handlinga, atomisk claim og utløpt-lease-recovery står att. Ein slik målprosess er ikkje ein trygg, køyrbar re-køyringsinstruks.

**Attstår:** Avtale eigar og felles Confluence-kjelde for R2/O2/D2; ferdigstille drifts-/feilsøkingsguide med alarmrespons, pause/gjenopptaking, trygg re-køyring og godkjenningar; gjennomføre og dokumentere overlevering. Ingen ny operasjonell runbook eller godkjenning er funnen på eller oppretta i denne gjennomgangen.

**Validering for D1–D2:** Repo-dokumentasjon, diagram, relevant factory-/adapter-/client-/orkestrator-/worker-/claimkode, GitHub og live Jira er lesne. Ingen org er kontakta eller Apex-test køyrd. Diagramendringane er samanlikna statisk med koden; automatisk Mermaid-rendering er ikkje køyrd, sidan repoet ikkje har den validatoren installert.

## Namne- og exception-samordning — oppdatert og kontrollert 2026-11-05

[K2 / CRMAAREG-155](https://nav.atlassian.net/browse/CRMAAREG-155) har fått retta namna i brukarbehov og akseptansekriterium frå `IP360CodeTableService` / `P360CodeTableMetadataService` til `P360_ICodeTableService` / `P360_CodeTableMetadataService`. Resten av beskrivinga og status **Ferdig** er bevarte. Begge namna er kontrollerte mot klassedeklarasjonane og lagra Jira-beskriving etter omlasting.

[F5 / CRMAAREG-121](https://nav.atlassian.net/browse/CRMAAREG-121) har fått presisert det første akseptansekriteriet med eksisterande exception-namn og avgjerda om `P360_ContractException` for input-/kontraktvalidering. Ein separat `P360ValidationException` skal ikkje opprettast. Resten av beskrivinga er bevart; F5 held fram **Under arbeid**, og alle deloppgåvene 122–128 held fram **Ferdig**.

Desse fem deloppgåvetitlane er retta og kontrollerte i F5-tabellen etter ny innlasting:

| Jira         | Korrigert tittel                             |
| ------------ | -------------------------------------------- |
| CRMAAREG-122 | Lage `P360_IntegrationException`             |
| CRMAAREG-123 | Lage `P360_AuthenticationException`          |
| CRMAAREG-125 | Lage `P360_TimeoutException`                 |
| CRMAAREG-126 | Lage `P360_RetryableException`               |
| CRMAAREG-127 | Lage `P360_MissingCodeTableMappingException` |

124 hadde allereie rett namn og avgrensing; 128 gjeld bruksmønster og er ikkje omdøypt. Ingen Apex-API eller metadata er endra.

**Attstår under [#993](https://github.com/navikt/crm-arbeidsforhold/issues/993):** [ADR-0001](../../adr/0001-arkitekturprinsipp-lagdeling-og-namnestandard.md#exceptions) skisserer generelle exceptions som integrasjonsspesifikke klassar kan utvide. [Den faktiske P360-basen](../../../force-app/integration/p360/classes/exception/P360_IntegrationException.cls) arvar direkte frå plattforma si `Exception`. [#976](https://github.com/navikt/crm-arbeidsforhold/issues/976) gjeld det separate generelle hierarkiet og har eiga avhengigheit til #975. Ei tekst-/namneretting avgjer ikkje om P360 seinare skal arve frå ein felles base. ADR-en er framleis under behandling og historisk spegla; han er ikkje endra eller godkjend her.

**Vidare namnesamordning under [#994](https://github.com/navikt/crm-arbeidsforhold/issues/994):** K3-namna og det forkasta service-locator-scopet er no samordna som dokumentert i K3-oppfølginga ovanfor. I [CRMAAREG-175 / K5](https://nav.atlassian.net/browse/CRMAAREG-175) er `P360CodeTableRpcService` retta til `P360_CodeTableRpcService` i akseptansekriteriet. Ny tekst er kontrollert etter omlasting. Namnet gjeld ei framtidig teneste; ingen slik Apex-implementasjon er funnen i P360-koden. K5 og deloppgåvene CRMAAREG-176–179 står framleis i **Backlog**, og K3-avhengigheita er bevart. Eksisterande DI-dokumentasjon skildrar bytteprinsippet, ikkje eit ferdig K5-design med konfigurasjon og metadata-til-RPC-mapping. Ingen produksjonskode, metadata eller status er endra i denne K5-runden.

**Attstår under [#994](https://github.com/navikt/crm-arbeidsforhold/issues/994):** Fullføre den breiare namnegjennomgangen av andre historier og deloppgåver og oppdatere kjeldeeksporten. K2-, F5-, K3- og K5-rettingane er registrerte, men saka er ikkje lukka. Den historiske [Jira-oversikta](jira-oversikt.md) er merkt `speilkopi: ja` og skal først oppdaterast gjennom ny eksport; nyare funn er registrerte her i staden.

**Validering:** Faktiske klassedeklarasjonar, exception-README, ADR-tekst, GitHub og lagra Jira-tekst er kontrollerte. Ingen statusar er endra, ingen org er kontakta og ingen Apex-test er køyrd.

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
