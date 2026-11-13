# P360: kartlegging av dagens flytar

Kartlegging 2026-11-13 av P360-relatert kjeldekode, metadata, lokale
spesifikasjonar og den menneskestyrte P02-testen. Dette er ei beskriving av
arbeidskopien, ikkje eit bevis på at same versjon er deploya i eit bestemt
miljø. Orgtilstand og historiske testresultat er merkte særskilt.

## Kort status

**Løysinga opprettar ikkje i dag ei faktisk P360-sak med søknadsdokument og
vedlegg frå innsendinga.** Brukaren har presisert at søknaden må arkiverast
for å opprette saka og dokumenta, inkludert vedlegga. Det kravet må dekkjast
som ein samla flyt; ein isolert vedleggsjobb er ikkje tilstrekkeleg.

| Del                            | Dagens status                                                                                                                                             |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Søknad og vedlegg i Salesforce | Portalinnsending og filkoplingar finst. P02 gav mottakskvittering, status `New` og synleg testvedlegg på søknad og tilgangsforespurnad.                   |
| Automatisk søknadsarkivering   | Ingen automatisk inngang frå innsendinga til søknadsjobben er funnen. Jobbservice finst og kan kallast eksplisitt.                                        |
| Automatisk vedleggsjobb        | Finst for ein bestemt direkte `ContentVersion`-publisering. Den faktiske portalvegen og tidlegare lagra utkastvedlegg er ikkje kopla til denne inngangen. |
| Vedtaksjobb                    | Autorisert frigiving på eit eksisterande vedtak kan opprette ein intern jobb, dersom gate og triggeroppsett er aktive.                                    |
| Avtalejobb                     | Jobbservice finst, men ingen automatisk forretningsutløysar er funnen.                                                                                    |
| Arbeidskø                      | Intern jobb, claim, worker, mock og avgrensa retry finst. Automatisk recovery av utgått lease og komplett operatørflyt er ikkje funne.                    |
| P360/SIF                       | Reell adapter og RPC-klient stoppar med kontrollerte exceptions. Mock returnerer suksess utan callout. Inga faktisk P360-sak er oppretta av mocktesten.   |
| Mapping og eksterne ID-ar      | DTO-ar, enkle mapparar, kodeverk og referansefelt finst. Worker nyttar ikkje mapparane og lagrar ikkje returnerte P360-referansar.                        |

Grunnlaget er mellom anna [P360-kjeldene](../../../force-app/integration/p360/),
[søknadskontrolleren](../../../force-app/externalApplication/classes/AAREG_ApplicationController.cls),
[testloggen](test-log.md), [testgjennomgangen](../../operations/p360-og-crm-arbeidsforhold-testgjennomgang.md)
og [completion roadmap](../../../.github/specs/p360-completion-roadmap.md).

## Omfang og lesemåte

- **Kjeldekode:** P360-inngangar, jobbservice, scheduler, worker, adapter,
  klient, orkestrator, domenegrenser, mapparar, kodeverk og metadata under
  `force-app/integration/p360`; søknadsportalen og aktuelle Flow-referansar
  utanfor denne mappa; eksisterande P360-testar og smoke-skript.
- **Krav:** Brukaren sitt krav om sak med søknad og vedlegg er eit avklart
  mål. Detaljane i SIF-operasjonar, filtransport, datamapping, feilhandtering
  og P360-identitet er ikkje fastsette av dette kravet åleine.
- **Evidensnivå:** «Koden gjer» er statisk lesing. «Brukaren rapporterte» er
  observasjon i scratch-org. Historiske testresultat gjeld den køyringa som er
  loggført; dei stadfestar ikkje noverande deploy eller live P360.
- **Avgrensing:** Ingen produksjonsorg er aksessert. Andre system kan ha
  integrasjonar som ikkje finst i dette repositoriet.

## Frå portal til lagra søknad

1. Portalbrukaren fyller ut søknad, kontaktar, tilgangstype og vedlegg.
   [LWC-skjemaet](../../../force-app/externalApplication/lwc/aareg_application/aareg_application.js)
   sender dei innsamla verdiane til Apex. Allereie lagra filer kan oppfylle
   vedleggsvalideringa utan ny fil i minnet.
2. `saveAsDraft` lagrar utkast og koplar ei eventuell ny fil til både
   `Application__c` og `Access_Request__c`. Utkast skal ikkje utløyse
   arkivering.
3. `processApplication` set normalt søknad og saksbehandlarstatus til `New`,
   set innsendingsdato, opprettar eller brukar tilgangsforespurnaden og lagrar
   kontaktar og grunnlag. Dersom nye fildata er med, blir fila lagra og kopla.
   Ved `Additional Information Required` finst ei eiga statusgrein.
4. [Innsendingsflowen](../../../force-app/main/default/flows/AAREG_createContactSendConfirmation.flow-meta.xml)
   kan opprette kontakt, e-postkøpost, tråd og melding. Dette er separate
   sideeffektar; P360-mock hindrar ikkje e-post eller SMS.
5. Den eksisterande
   [populate-flowen](../../../force-app/main/default/flows/AAREG_populateApplicationFieldAfterSubmit.flow-meta.xml)
   byggjer mellom anna søknadstekst for arkivbruk. Flowbeskrivinga stiller
   spørsmål om framtidig gjenbruk til P360; ho er ikkje bevis på at teksten
   blir send til P360.

### Kvifor P02 ikkje gav arkivjobb

- `processApplication` kallar ikkje
  `P360_ArchiveJobService.getOrCreateApplicationDocumentJob`. Søk etter denne
  metoden fann service-definisjon, testar og eit eksplisitt smoke-kall, men
  ingen automatisk produksjonsinngang frå søknadsinnsending.
- [ContentVersion-triggeren](../../../force-app/integration/p360/triggers/P360_ContentVersionArchive.trigger)
  kallar [handleren](../../../force-app/integration/p360/classes/P360_ContentVersionArchiveHandler.cls)
  etter innsetting. Handleren krev aktiv gate og at
  `FirstPublishLocationId` peikar direkte på ein søknad med
  tilgangsforespurnad.
- Portalcontrolleren opprettar `ContentVersion` utan å setje dette feltet og
  lagar `ContentDocumentLink` etterpå. Eit vedlegg som vart lagra på utkastet
  tidlegare, blir heller ikkje automatisk behandla på nytt ved innsending.
- Handleren sjekkar ikkje søknadsstatus. Direkte filpublisering på eit utkast
  med aktiv gate kan derfor etter kjeldekoden opprette jobb, i konflikt med
  regelen om at utkast ikkje skal arkiverast. Dette er ikkje runtime-verifisert
  i P02.
- P02 fann ingen jobb med direkte søknads- eller tilgangsforespurnadskopling.
  Dette samsvarer med kodefunnet, men effektiv gate vart ikkje uavhengig
  kontrollert under sjølve innsendinga.

P02 er dermed gjennomført som observasjon av portalvegen, **ikkje bestått
som ende-til-ende arkivering**. Detaljane står i
[testloggen](test-log.md).

## Dei fire arkivhendingane

| Jobbtype                | Inngang i dagens produksjonskode                                                                | Kjelde og avgrensing                                                                                                                                                                                  |
| ----------------------- | ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ApplicationDocument`   | Ingen automatisk inngang frå innsending er funnen.                                              | [Jobbservice](../../../force-app/integration/p360/classes/job/P360_ArchiveJobService.cls) kan opprette eller gjenbruke ein jobb per søknad. Smoke-skriptet kallar servicen direkte.                   |
| `ApplicationAttachment` | Ny `ContentVersion` med direkte søknadspublisering når gate er på og tilgangsforespurnad finst. | [Handler](../../../force-app/integration/p360/classes/P360_ContentVersionArchiveHandler.cls); ingen sjekk av utkaststatus og inga kopling til portalens etterfølgjande `ContentDocumentLink`.         |
| `DecisionDocument`      | Overgang til `Ready_For_P360_Archive__c = true` ved oppdatering.                                | [Guard-handler](../../../force-app/integration/p360/classes/P360_ArchiveGuardHandler.cls) krev aktiv gate og tilgangsforespurnad. Frigiving ved insert opprettar ikkje jobb i after-update-handleren. |
| `AgreementDocument`     | Ingen automatisk inngang funnen.                                                                | Jobbservice og avtaledomenegrense finst; hending og mapping er ikkje kopla til ein produksjonsflyt.                                                                                                   |

Hendingane ovanfor er ikkje i seg sjølve ei definert rekkjefølgje for
oppretting av sak, dokument og filer i P360. Ein slik avhengig flyt er ikkje
implementert i dagens worker.

## Vedtak og frigiving

1. [Vedtaks-triggeren](../../../force-app/integration/p360/triggers/P360_ApplicationDecisionArchiveGuard.trigger)
   brukar `MyTriggers` og metadataregistreringar for før- og etterhendingar.
2. Med gate på krev [guarden](../../../force-app/integration/p360/classes/P360_ApplicationDecisionArchiveGuard.cls)
   custom permission `P360_Archive_Release` for å setje frigivingsfeltet.
   Etter frigiving er ordinære felt låste, medan tre tekniske P360-felt er
   unntak. Frigivingsfeltet kan ikkje setjast tilbake gjennom denne guarden.
3. Etter oppdatering opprettar handleren `DecisionDocument` ved ny frigiving,
   dersom vedtaket kan koplast til ei tilgangsforespurnad. Utan kopling blir
   ingen jobb oppretta av denne handleren.
4. Med gate av returnerer guarden utan P360-spesifikk validering eller låsing.
   Vanleg «complete decision» er ikkje det same som arkivfrigiving.
5. Ein [vedtaksmappar](../../../force-app/integration/p360/classes/mapper/AAREG_DecisionToP360DocumentMapper.cls)
   finst, men dagens worker kallar han ikkje. Ferdig vedtaksjobb i mock er
   derfor ikkje bevis på eit arkivert vedtak.

## Jobb, scheduler og worker

[P360_Archive_Job__c](../../../force-app/integration/p360/objects/P360_Archive_Job__c/)
er intern teknisk status, med kjeldekoplingar, hendelsetype, unik
idempotensnøkkel, forsøk, tidspunkt og feilfelt.

1. Jobbservicen validerer nødvendige ID-ar og korrelasjon, lagar deterministisk
   nøkkel og returnerer eksisterande jobb eller opprettar `Pending`. Vedlegg
   får nøkkel per søknad og filversjon. Den unike nøkkelen er intern
   deduplisering, ikkje verifisert P360-deduplisering.
2. [Scheduler](../../../force-app/integration/p360/classes/job/P360_ArchiveJobScheduler.cls)
   sjekkar gate, ber om opptil ti jobbar og køyrer ein queueable worker. At
   schedulable-klassen finst, betyr ikkje at ein planlagd org-jobb er oppretta.
3. [Claim-servicen](../../../force-app/integration/p360/classes/job/P360_ArchiveJobClaimService.cls)
   vel `Pending` og tidsmodne `Failed`, set `In Progress`, starttid, ti
   minutt lease og aukar forsøket. Utgått lease blir ikkje vald opp att her.
   Spørringa brukar ikkje `FOR UPDATE`; tryggleik ved overlappande claims må
   verifiserast særskilt før ein legg atomisk claim til grunn.
4. [Worker](../../../force-app/integration/p360/classes/job/P360_ArchiveJobWorker.cls)
   sjekkar gate på nytt. Er ho av, blir claim sette tilbake til `Pending`
   utan at eit faktisk forsøk blir registrert. Er ho på, vel worker adapter
   og sender ein request som i dag berre inneheld den interne nøkkelen som
   `externalId`.
5. Mock-suksess gir `Succeeded`. Ei `P360_IntegrationException` gir anten
   `Failed` med neste forsøk eller `Manual Review`. Dei første fire
   retry-intervalla er 1, 5, 15 og 60 minutt; ved femte forsøk blir feilen
   manuell. Uventa exceptions fell utanfor denne klassifiseringa.
6. `Last_Attempt_Date__c` blir lagra med worker-utfallet. Ein rollback kan
   rulle tilbake både status og tidsstempel. Vanleg suksess tømmer ikkje
   lease-feltet. Arbeidskopien inneheld ingen automatisk utgått-lease-recovery
   eller komplett manuell frigivingshandling.

Workeren behandlar jobbane likt på adaptergrensa: han lastar ikkje inn
søknad, vedtak, avtale eller fil, byggjer ikkje ein `CreateCase`/
`CreateDocument`-request og lagrar ikkje P360-referansar tilbake på kjelda.
`Succeeded` med mock betyr derfor berre at stubben rapporterte suksess.

## Adapter, SIF og mapping

- [Adapterfabrikken](../../../force-app/integration/p360/classes/adapter/P360_AdapterFactory.cls)
  vel stub berre når org-default `Use_Mock_Transport__c` er eksplisitt
  `true`. Elles blir den vanlege adapteren vald.
- [Stubben](../../../force-app/integration/p360/classes/adapter/P360_StubArchiveAdapter.cls)
  returnerer suksess utan callout. Han speglar requestens eksterne ID som
  eksempel på ekstern saks-ID; det er ikkje ein faktisk P360-ID.
- [P360_ArchiveAdapter](../../../force-app/integration/p360/classes/adapter/P360_ArchiveAdapter.cls)
  validerer request og ekstern ID, men kastar deretter kontrollert exception.
  [P360_RpcClient](../../../force-app/integration/p360/classes/client/P360_RpcClient.cls)
  kastar også exception; endpoint, autentisering, RPC-envelope og operasjonar
  er ikkje implementerte her.
- DTO-ar finst for blant anna oppretting, oppdatering og oppslag av sak og
  dokument, kontaktar og filer. Dei definerer interne datastrukturar, ikkje
  ei verifisert live SIF-kopling.
- Søknads-, dokument-, fil- og vedtaksmapparane validerer inndata og brukar
  [kodeverkstenesta](../../../force-app/integration/p360/classes/codetable/P360_CodeTableMetadataService.cls).
  Dei er ikkje kopla inn i workerflyten. Domene-tenestene lastar berre kjelde-ID
  inn i enkle kontekstar; orkestratoren sender ein minimal request til injisert
  adapter og er ikkje kopla til portalinnsendinga.
- Kodeverksmetadata og P360-referansefelt eksisterer. Referansefelta er ikkje
  bevis på at returar blir lagra, og aktive kodeverdiar er ikkje i seg sjølve
  bevis på godkjend live mapping.

## Konfigurasjon, tilgang og logging

- [Feature-flagget](../../../force-app/integration/p360/customMetadata/Feature_Flag.P360_Archive_Processing.md-meta.xml)
  er av i metadata. [Gaten](../../../force-app/integration/p360/classes/P360_ArchiveProcessingGate.cls)
  krev aktiv verdi og tom `Required_Custom_Permission__c`; ved manglande
  konfigurasjon eller handtert lookup-feil stoppar ho behandling.
- `P360_Archive_Release` er separat autorisasjon for vedtaksfrigiving.
  `P360_Archive_Job_Viewer` gir innsyn, medan `P360_Archive_Job_Processing`
  er behandlingstilgang. Permission-set-gruppa samlar behandling, kodeverk og
  RPC-tilgang; tildeling skjer separat per miljø.
- Named Credential-innstilling og tilgangsmetadata finst, men den faktiske
  transporten brukar ikkje ein ferdig implementert credential-basert callout.
- Worker loggar handterte feil gjennom
  [IntegrationLogger](../../../force-app/integration/common/classes/IntegrationLogger.cls)
  med avgrensa tekniske felt. Det er best-effort og ikkje ende-til-ende
  korrelasjon. Jobbens feiltekst blir lagra separat og lengdeavgrensa; han
  må ikkje forvekslast med loggeren sin avgrensa payload.
- Arkivjobb-fane, listevisingar og tidslinjelayout gir operatøren innsyn.
  Tidlegare UI-testing stadfesta desse i scratch-org, men ikkje at alle
  recovery- og driftsfunksjonar er implementerte.

## Testar og kva dei beviser

| Evidens                                                                                                            | Dekning                                                                                                                                    | Avgrensing                                                                                                                                                    |
| ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [P360-suiten](../../../force-app/tests/testSuites/P360.testSuite-meta.xml)                                         | DTO-ar, gate/handler, jobbservice, scheduler, worker, guard, adapter og andre grunnkomponentar.                                            | Ein suite er ei liste, ikkje eit resultat. Fleire mapper- og kodeverkstestar finst utan å vere lista i denne suiten.                                          |
| [ContentVersion-test](../../../force-app/tests/classes/integration/p360/P360_ContentVersionArchiveHandlerTest.cls) | Direkte publisering med `FirstPublishLocationId` gir vedleggsjobb når gate er på; deaktivert gate gir ingen jobb.                          | Testar ikkje faktisk portalopplasting, innsending av eksisterande utkastvedlegg eller at utkast skal vere utan jobb.                                          |
| [Mock-smoke](../../../scripts/apex/p360MockArchiveFlow.apex)                                                       | Opprettar syntetisk fil med direkte publisering, kallar søknadsjobbservice eksplisitt og køyrer scheduler/worker.                          | Går ikkje gjennom portalinnsending og sender ikkje til P360. Skriptet endrar mocksetting og opprettar data; det skal ikkje køyrast utan særskild godkjenning. |
| Historiske orgtestar                                                                                               | 25/25 relevante jobbtestar og mock-smoke med to `Succeeded` er dokumenterte i [testloggen](test-log.md).                                   | Historiske resultat gjeld den aktuelle køyringa, ikkje dagens deploy eller live transport.                                                                    |
| P02                                                                                                                | Menneskestyrt innsending med lagra vedlegg; status `New`, filkoplingar, ingen tilknytt P360-jobb og ei kølagd bekrefting vart rapporterte. | Effektiv gate vart ikkje uavhengig målt under innsending. Ingen ende-til-ende P360-verifikasjon.                                                              |

Ein ny køyring av eksisterande orgtestar vil vere nyttig for noverande
orgtilstand, men vil ikkje i seg sjølv bevise at arbeidskopien er deploya,
at portalvegen opprettar jobb, eller at P360 får sak og dokument.

**Nytt testforsøk 2026-11-13:** Etter godkjenning vart
`rtk proxy cplt exec -- sf apex run test --suite-names P360 --target-org crm-arbeidsforhold --result-format human --wait 30`
forsøkt. Salesforce CLI stoppa med `EPERM` ved opning av lokale CLI-filer
inne i sandkassa. Etter avgrensa tilgang til Salesforce CLI sine lokale
konfigurasjonsmapper kom CLI vidare, men fann ikkje autorisasjonsinformasjon
for target-aliaset. Testane starta ikkje; det finst ikkje eit nytt
testresultat. Ein avgrensa retry med cplt sin Keychain-tilgang mellombels
aktivert gav same resultat. Ingen credentials vart vist eller kopiert.
Innstillinga `sandbox.keychain_substitute` vart sett tilbake til `true`
etterpå; Salesforce-innlogginga er framleis ikkje tilgjengeleg i CLI.

## Prioriterte gap og avgjerder

1. **Samla søknadsflyt:** Avklar og implementer kopling frå innsending til
   oppretting/gjenfinning av P360-sak, søknadsdokument og alle aktuelle
   vedlegg. Utkast skal ikkje arkiverast. Handter fleire vedlegg og
   etterfølgjande filversjonar ut frå godkjent forretningskontrakt.
2. **Rekkjefølgje og recovery:** Definer avhengigheiter mellom sak, dokument
   og filer, persistens av returnerte referansar, delvis suksess og trygg
   gjenkøyring utan duplikat. Dagens fire uavhengige jobbtypar beviser ikkje
   dette.
3. **Transport og mapping:** Avklar og implementer SIF-operasjonar,
   autentisering, mapping, kodeverk, filformat og grenser; verifiser mot
   godkjent ikkje-produksjonsmiljø. Ikkje gjett ekstern kontrakt.
4. **Vedtak og avtale:** Stadfest forretningshendingar, saksavhengigheit,
   dokumentmapping og behandling av manglande kjeldekopling.
5. **Drift:** Verifiser overlappande claim, utgått lease, manuell recovery,
   planlegging, logging, alarmar og ansvar. Feature-flagget må framleis vere
   av utanfor særskilt godkjend validering.
6. **Testdekning:** Legg til åtferdstestar gjennom faktisk portal- og
   innsendingseam, inkludert utkast, eksisterande og nye vedlegg, fleire filer,
   gate av/på, feil, retry og idempotens. Test saman med reell SIF berre etter
   eksplisitt miljø- og datagodkjenning.

Ingen kode, orginnstilling, deploy eller produksjonsaktivering blir endra av
denne kartlegginga.
