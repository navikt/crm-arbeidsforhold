# Kjeldekart og teststrategi for Arbeidsforhold / Aa-registeret

Dette dokumentet supplerer [den eksisterande heilskaplege analysen](./helhetleg-analyse-og-teststrategi.md). Det legg til kjeldesporing og konkrete testscenario utan å endre den eksisterande teksten.

## Evidens og avgrensing

- **Kjeldebevis** kjem frå Salesforce-kjelda og metadata i arbeidskopien.
- **Historisk orgbevis** kjem frå den tidlegare lesande inventeringa av scratch-org-en `crm-arbeidsforhold`. Inventeringa er ikkje køyrd på nytt i denne gjennomgangen.
- **Testbevis** gjeld berre det som tidlegare er dokumentert eller køyrt. Scenarioa nedanfor er forslag, ikkje påstandar om eksisterande dekning.
- Ingen nye Salesforce-org-kommandoar, record-oppslag, deployar eller kall mot Altinn/P360 er utførte i denne gjennomgangen.

Les [CONTEXT.md](../../CONTEXT.md) saman med dette kartet for domenespråk. Pakkeeigde avhengnader er lese berre for kontekst og skal ikkje endrast utan godkjenning.

## Systemet i éi setning

Salesforce er arbeidsflytmotor og datalager for eksterne søknader, intern saksbehandling, avgjerder, avtalar og dialog. Altinn leverer eksternt tilgangsgrunnlag, medan tilgangsdistribusjon og P360 er separate integrasjonsgrenser. Flow og Apex driv statusovergangar, varsling, opprydding og arkiveringsjobbar.

## Ende-til-ende-kart

### 1. Ekstern identitet, verksemd og tilgang

Experience Cloud-heimesida lastar organisasjonar for den innlogga brukaren, lèt brukaren velje sist brukte verksemd og spør om rettar før avtalar eller søknadsfunksjonar blir viste. Kjeldeinngangane er [aareg_home](../../force-app/externalAccess/lwc/aareg_home/aareg_home.js), [AAREG_HomeController](../../force-app/externalAccess/classes/AAREG_HomeController.cls) og [AAREG_CommunityUtils](../../force-app/externalAccess/classes/AAREG_CommunityUtils.cls).

Altinn-tilgang til søknad og støtte blir vurdert som ulike ressursar. Den syntetiske scenario-provider-en er meint for avgrensa ikkje-produksjonstesting; scenariofeil skal ikkje bli tolka som løyve eller stille byte til live-tenesta. Organisasjonsval og tilgang må testast kvar for seg, inkludert byte mellom verksemder.

**Kjeldepunkt å teste:** `getOrganizationsWithRoles`, `refreshOrganizationsWithRoles`, `checkAndShareIfAuthorized` og `updateLastUsedOrganization` i `AAREG_HomeController`; tilgangskontroll frå søknadsskjemaet gjennom `AAREG_CommunityUtils.getUserRights`.

I søknadskomponenten returnerer `checkAccessToApplication()` ikkje Promise-kjeda frå Apex-kallet, sjølv om kallet skjer inne i ein `async`-metode som blir `await`-a. Verifiser at UI-tilgangskontrollen ikkje kan kome før rettssvaret; dette er ikkje i seg sjølv bevis på at server-side-autorisasjon manglar.

### 2. Søknad, utkast og vedlegg

Den eksterne søknadssida fyller verksemdsinformasjon frå sist valde organisasjon, handterer kontaktpersonar og grunnlagskodar, lagrar utkast og sender inn søknad med dokumentasjon. UI-inngangen er [aareg_application](../../force-app/externalApplication/lwc/aareg_application/aareg_application.js); servergrensa er [AAREG_ApplicationController](../../force-app/externalApplication/classes/AAREG_ApplicationController.cls).

Søknaden er knytt til `Access_Request__c` og verksemd; grunnlagskodar og kontaktar ligg i eigne record-typar. Vedlegg er Salesforce Files, ikkje berre felt på søknaden. Innsending og utkastlagring går gjennom ulike servermetodar. Koden viser `without sharing` på controlleren; `processApplication` har CRUD-/feltkontroll som ikkje blir brukt likt i `saveAsDraft`. Dette er eit eksplisitt område for menneskeleg tilgangs- og personverngjennomgang, ikkje ei konklusjon om sårbarheit.

### 3. Intern behandling og avgjerd

Interne record-sider viser søknadsdetaljar, grunnlag, kontaktar og relaterte oppgåver. [AAREG_ApplicationInternalController](../../force-app/internalApplication/classes/AAREG_ApplicationInternalController.cls) les detaljane, medan [AAREG_ApplicationDecisionController](../../force-app/internalApplicationDecision/classes/AAREG_ApplicationDecisionController.cls) opprettar eller hentar avgjerder. Avgjerder og avgjerdsdetaljar er eigne record-typar knytte til søknaden.

Flow definerer mykje av status-, oppgåve- og varslingsarbeidet rundt saksbehandlinga. Døme i kjelda er `AAREG_applicationChangingStatus`, `AAREG_applicationNotificationToCasehandler`, `AAREG_sendDecisionEmailNotification` og `AAREG_Decision_Completed`. PDF-generering har ein Flow-kopla Apex-grense i [AAREG_ApplicationDecisionPDFFileService](../../force-app/internalApplicationDecision/classes/AAREG_ApplicationDecisionPDFFileService.cls). At ei PDF-fil finst i Salesforce beviser ikkje at ho er arkivert i P360.

### 4. Avtale og distribusjonstilgang

Avgjerd kan føre til `Agreement__c`, som er knytt til søknad, tilgangsførespurnad og verksemd. Eksterne brukarar ser avtalar via [aareg_myAgreements](../../force-app/externalAgreement/lwc/aareg_myAgreements/aareg_myAgreements.js) og kan opne avtaledetaljar i [aareg_agreement](../../force-app/externalAgreement/lwc/aareg_agreement/aareg_agreement.js). Controllerane er [AAREG_MyAgreementsController](../../force-app/externalAgreement/classes/AAREG_MyAgreementsController.cls) og [AAREG_AgreementController](../../force-app/externalAgreement/classes/AAREG_AgreementController.cls).

Avtalen kan ha fleire relaterte kontaktar med ulike varslingsval. Avslutting er ein status-/deaktiveringshandling, ikkje sletting. `AAREG_Agreement_create_distribution_access` opprettar tilgang etter avtalehending, medan `AAREG_removeAccessToDistribution` trekkjer tilgang tilbake. Flowane kallar [AAREG_distributionAccessController](../../force-app/integration/distributionAccess/classes/AAREG_distributionAccessController.cls), som startar eit asynkront PUT/DELETE-kall via [AAREG_distributionAccessRequest](../../force-app/integration/distributionAccess/classes/AAREG_distributionAccessRequest.cls). Lokalt Flow-/Apex-resultat åleine stadfestar ikkje at den eksterne tenesta fullførte handlinga.

### 5. Dialog, meldingar og støtte

Eksterne brukarar ser trådar gjennom [aareg_myThreads](../../force-app/main/default/lwc/aareg_myThreads/aareg_myThreads.js); heimesida brukar òg trådteljinga frå den delte [AAREG_MyThreadsController](../../force-app/dialog/classes/AAREG_MyThreadsController.cls). Ny henvending går gjennom [aareg_contactSupportForm](../../force-app/main/default/lwc/aareg_contactSupportForm/aareg_contactSupportForm.js) og [AAREG_contactSupportController](../../force-app/dialog/classes/AAREG_contactSupportController.cls).

Skjemaet kan lage utkast før filopplasting, oppdatere utkast, fullføre henvendinga og kople opplasta filer til endeleg record. Henvendinga får tråd og første melding. Flow tek seg av eigarskap, interne kommentarar, status, SMS/e-post og varsling. Test både feil mellom utkast, filkopling, tråd og melding; ikkje berre den glatte suksessbana.

### 6. P360-arkivering

P360 har ein intern jobbmodell med idempotens, lease/claim, retry/backoff og batchkøyring. Vedlegg kan opprette arkiveringsjobb via [P360_ContentVersionArchiveHandler](../../force-app/integration/p360/classes/P360_ContentVersionArchiveHandler.cls); avgjerdsdokument går gjennom guard/trigger-bana i [P360_ArchiveGuardHandler](../../force-app/integration/p360/classes/P360_ArchiveGuardHandler.cls). [P360_ArchiveJobScheduler](../../force-app/integration/p360/classes/job/P360_ArchiveJobScheduler.cls) hentar jobbar og køyrer [P360_ArchiveJobWorker](../../force-app/integration/p360/classes/job/P360_ArchiveJobWorker.cls).

**Kritisk skilje mellom lokal og ekstern åtferd:** kjeldegjennomgangen fann at den reelle [P360_ArchiveAdapter](../../force-app/integration/p360/classes/adapter/P360_ArchiveAdapter.cls) og [P360_RpcClient](../../force-app/integration/p360/classes/client/P360_RpcClient.cls) ikkje utfører implementert transport. Stub-adapteren kan rapportere kontrollert suksess utan callout. Dei tidlegare dokumenterte 98 beståtte P360-testane dokumenterer dermed ikkje at eit dokument vart oppretta i P360. Ingen live P360-verifikasjon er gjort her.

### 7. Experience Cloud-ruter

Experience Bundle under `force-app/unpackagable/experiences/Aa_registret1` koplar ruter til LWC-visningar. Kjeldekonfigurasjonen viser mellom anna Home, Ny søknad, Mine søknader, Mine avtalar, Ny melding, Mine meldingar og record-detaljruter for søknad, avtale og tråd. Dette er **kjeldeføring**, ikkje bevis på at same bundle eller rute er aktiv i org-en no. Dei historiske org-oppslaga viste metadata-nærvær, ikkje publisert side eller effektiv brukartilgang.

## Datagraf for sentrale record-typar

Relasjonane under er avleidde frå metadata og controller-spørringar; installerbare avhengnader kan bidra med eigne objekt og feltsamband.

```text
Account / verksemd
  ├─ Access_Request__c
  │    ├─ Application__c
  │    │    ├─ ApplicationBasisCode__c
  │    │    ├─ RelatedContact__c
  │    │    └─ Application_Decision__c
  │    │          └─ Application_Decision_Details__c
  │    └─ Agreement__c
  └─ Agreement__c
       └─ RelatedContact__c

Inquiry__c ── Contact / Account
  └─ Thread__c ── Message__c
       └─ ContentDocumentLink ── ContentVersion

Application / Agreement / Decision / Inquiry
  └─ Salesforce Files (ContentDocument / ContentVersion)

Application attachment / released decision
  └─ P360_Archive_Job__c (internt kø-/statusobjekt)
```

`RelatedContact__c` kan vere knytt til søknad eller avtale. Når ein kontakt blir fjerna frå avtale, beheld controlleren recorden dersom han framleis er knytt til ei søknad; elles blir han sletta. Dette er viktig for testdata og for å unngå at ein test utilsikta fjernar kontaktinformasjon frå ein annan arbeidsflyt.

## Pakker, metadata og drift

- Manifestet i [sfdx-project.json](../../sfdx-project.json) deklarerer `crm-arbeidsforhold` og 19 separat eigde avhengnader. `src-temp` er ei synkroniseringsmappe, ikkje ei ekstra avhengnad.
- Historisk lesande org-inventering fann 19 installerte avhengnader, 382 `CustomObject`-metadataoppføringar, 110 Flow-oppføringar og 61 PermissionSet-oppføringar. Dette er metadata-nærvær, inkludert avhengnader; det viser ikkje aktive Flow-versjonar, assignments, runtime-konfigurasjon eller faktisk tilgang.
- Kjelda inneheld 37 Flow-definisjonar; ei kjeldesjekk fann 35 med status `Active` og to markerte `Obsolete`. Dette kjeldeutfallet må ikkje brukast som stadfesting av aktiv org-versjon.
- Avhengnadstabell og observerte versjonar er dokumenterte i [pakkeoversikta](./pakkeavhengigheiter.md). Bruk `sfdx-project.json` som kjelde for deklarerte versjonskrav og eit nytt, godkjent org-oppslag for installert status.
- Permission set-definisjonar viser kva tilgang dei er laga for å gi; dei viser ikkje kven som har fått dei. Effektiv tilgang krev både assignment- og brukar-/profilkontekst.

### Scratch-org runtime-sjekk

Etter fersk, uttrykkeleg godkjenning blei avgrensa lesande oppslag køyrde mot scratch-org-aliaset `crm-arbeidsforhold` den 2026-11-13. Ingen forretningsrecordar, brukaridentitetar, credentials, Named Credential-detaljar eller eksterne tenester blei lesne.

| Sjekk                          | Observasjon                                                                                                                                                                                                           | Tolkingsgrense                                                                                                                                                                                                                             |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Salesforce CLI                 | `@salesforce/cli/2.158.7`, Node `v22.20.0`                                                                                                                                                                            | Prosjektet krev Node `>=22.22.1` for npm-verktøya; ingen npm-test blei køyrd.                                                                                                                                                              |
| FlowDefinition via Tooling API | 36 Flow-definisjonar med `AAREG`-prefix og éin ytterlegare kjeldedefinisjon; alle aktive versjonar som fanst var også siste versjon. `AAREG_deactivateAccess` og `AAREG_getObjectTypeName` hadde ingen aktiv versjon. | Samsvarar med kjeldestatusen for dei to `Obsolete`-flytane. Dette stadfestar ikkje Flow-køyringsutfall eller at alle brukarane har Flow-tilgang.                                                                                           |
| Assignment-aggregat            | Éi assignment for `AAREG_CommunityPermission` og éi for `AAREG_Arbeidsforhold_Saksbehandling`.                                                                                                                        | Ingen assignee-identitetar blei henta; teljing viser ikkje effektiv tilgang eller kven som fekk assignment.                                                                                                                                |
| P360 processing flag           | `P360_Archive_Processing.Is_Enabled__c = false`; `Required_Custom_Permission__c` var tom.                                                                                                                             | P360-jobbprosesseraren er stengd av denne fail-closed-gaten i scratch-org-en.                                                                                                                                                              |
| P360 mock transport            | Éi innstillingsrad hadde `Use_Mock_Transport__c = true`.                                                                                                                                                              | Eigar-/hierarkikontekst blei ikkje henta. Mock-verdi er ikkje teikn på reell P360-transport.                                                                                                                                               |
| Altinn scenario-provider       | Éi innstillingsrad hadde `UseScenarioProvider__c = true`.                                                                                                                                                             | Eigar-/hierarkikontekst, brukartildeling og Custom Permission blei ikkje henta. Koden krev eksplisitt brukaroppdrag, ikkje-produksjonskontroll, permission og identitetsmatch; denne teljinga beviser ikkje at nokon brukar er autorisert. |
| Planlagd Flow                  | `AAREG_deleteDraftInquiriesANDrelatedDocuments-1` var `WAITING`; neste køyring var `2026-11-13T23:30:00Z`, førre køyring `2026-11-12T23:30:03.240Z`.                                                                  | Dette viser ein scheduler-registrering, ikkje at slettinga fullførte eller kva for recordar ho rørte.                                                                                                                                      |
| P360 scheduler                 | Ingen matchande `CronTrigger` for P360 arkivscheduleren i det avgrensa oppslaget.                                                                                                                                     | I kombinasjon med processing-flagget av tyder dette på at P360-jobbar ikkje blir automatisk prosesserte i denne scratch-org-en no.                                                                                                         |

Det første forsøket på Flow-oppslag med `FlowDefinitionView` blei avvist som ikkje-støtta type. Same avgrensa statuskontroll blei deretter køyrd via Tooling API-objektet `FlowDefinition` og lukkast.

## Testdatakontrakt

### Fixture-graf

Bygg små, syntetiske grafar med ein tydeleg eigar og éin variabel per scenario:

1. **Verksemd:** syntetisk `Account`, unik syntetisk organisasjonsnummerverdi og eksplisitt organisasjonskategori.
2. **Identitet:** brukar-/kontaktkopling og `LastUsedOrganization__c`; lag ein andre brukar/verksemd for isolasjonskontroll.
3. **Tilgang:** syntetisk Altinn-scenario med ressurs, verksemd og Permit/Deny/feil-resultat. Scenario må ha eksplisitt ikkje-produksjonsvern.
4. **Søknad:** `Access_Request__c`, `Application__c`, grunnlagskodar og kontaktar med kravde varslingsval.
5. **Behandling:** saksbehandlar, status, oppgåve og eventuelt avgjerd + avgjerdsdetaljar.
6. **Avtale:** `Agreement__c` kopla til søknad/verksemd og minst éin RelatedContact; bygg distribuert tilgang separat frå avtale-recorden.
7. **Dialog:** `Inquiry__c`, `Thread__c`, `Message__c` og Files via Salesforce sine ContentVersion-/ContentDocumentLink-banar.
8. **Arkiv:** `P360_Archive_Job__c` med deterministisk idempotensnøkkel og mocka adapter; aldri bruk ei grøn stub-status som bevis på eksternt arkiv.

Bruk `AAREG_TestDataFactory` og dei eksisterande Altinn-, integrasjons- og P360-fabrikkane som startpunkt. Opprett berre felt og relasjonar som scenarioet treng. Ingen verkelege organisasjonsnummer, e-postar, personnamn, filer, org-ID-ar eller Named Credential-hemmar i fixtures.

### Aktør- og tilgangsmatrise

| Aktør                                             | Skal kunne                                                                  | Må ikkje kunne                                                  |
| ------------------------------------------------- | --------------------------------------------------------------------------- | --------------------------------------------------------------- |
| Ekstern representant for verksemd A               | Sjå/lage søknader, avtalar og dialog som høyrer til A og som rettane tillèt | Sjå/endre data, filer eller trådar for verksemd B               |
| Ekstern brukar med støtte-, men ikkje søknadsrett | Opprette/følgje støtte der policy tillèt                                    | Få søknadsrett via støtte-tilgang                               |
| Intern saksbehandlar                              | Behandle tildelte søknader, registrere oppfølging og avgjerd                | Omgå avtalte tilgangs- og statusreglar                          |
| Bakgrunnsjobb                                     | Utføre avgrensa status-, varslings-, tilgangs- eller arkivhandling          | Rapportere ekstern suksess når motparten feila/ikkje vart kalla |

Bruk minimumstilgangsbrukar og `System.runAs` når scenarioet ikkje krev høgare rettar. Set opp fixture med nødvendig privilegium, men utfør handlinga som aktøren som blir testa. Bruk syntetiske brukarar/verksemder og ulike record-eigarar for å avdekke lekkasje.

## Scenario som bør vere del av heilskapleg regresjon

Prioritet: **P1** tilgang og hovudflyt, **P2** feil/robustheit, **P3** drift og randtilfelle. Scenarioa er testmål, ikkje påstand om dagens dekning.

| ID         | Pri. | Testscenario og handling                                                   | Forventa observasjon                                                                                           |
| ---------- | ---: | -------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| ALT-01     |   P1 | Brukar med Permit for søknadsressurs, vel verksemd A                       | A blir valt; søknadsflyt blir tilgjengeleg berre for A                                                         |
| ALT-02     |   P1 | Permit for støtte, Deny for søknad; test også omvendt                      | Ressursrettane er uavhengige                                                                                   |
| ALT-03     |   P1 | Brukar har A og B; byte frå Permit A til Deny B                            | Ingen forelda A-tilgang blir brukt etter byte                                                                  |
| ALT-04     |   P1 | Altinn-feil, manglande identitet eller manglande scenario-permission       | Lukka/eksplisitt feil, ingen live-fallback eller tilgang                                                       |
| ALT-05     |   P2 | Tom organisasjonsliste versus transportfeil                                | Tomtilstand blir skild frå feiltilstand                                                                        |
| APP-01     |   P1 | Opprett og lagre søknadsutkast; opne same utkast att                       | Éin søknad, rette kontaktar/grunnlag/vedlegg, framleis utkast                                                  |
| APP-02     |   P1 | Send komplett søknad med syntetisk vedlegg                                 | Status/record-koplingar er rette; interne oppgåver/varsling oppstår som venta                                  |
| APP-03     |   P1 | Manglande vilkår, dokument eller éin av dei fire varslingskontakt-rollene  | Innsending blir stoppa; ingen delvis innsending                                                                |
| APP-04     |   P1 | Prøv å lese/endre søknad eller fil for verksemd B som brukar A             | Ingen data eller vedlegg blir lese eller endra                                                                 |
| APP-05     |   P2 | Saksbehandlar ber om meir informasjon; ekstern brukar svarar og sender inn | Status og historikk blir konsistente; berre rett verksemd kan svare                                            |
| APP-06     |   P2 | Slett kontakt/grunnlagsrad frå eksisterande utkast                         | Rett underrecord blir fjerna; søknaden blir ikkje sletta                                                       |
| CASE-01    |   P1 | Opprett henvending med tråd, første melding og éi fil                      | Henvending, tråd, melding og fil blir kopla til same syntetiske sak                                            |
| CASE-02    |   P1 | Opplasting før innsending, oppdater skjema, fullfør, relink fil            | Utkast blir ikkje vist som fullført; endeleg fil er knytt til endeleg record                                   |
| CASE-03    |   P2 | Feil ved tråd-/meldingsoppretting etter henvending                         | Feil blir synleg; ingen falsk suksess eller uoppdaga delvis transaksjon                                        |
| CASE-04    |   P2 | To brukarar med ulike verksemder opprettar og les trådar                   | Kvar brukar ser berre rett tråd og ulest-teljing                                                               |
| APP-DEC-01 |   P1 | Opprett avgjerd med fleire grunnlagslinjer                                 | Éi avgjerd; alle rette detaljar blir kopierte utan duplikat                                                    |
| APP-DEC-02 |   P1 | Fullfør avslagsavgjerd og generer PDF                                      | Fil blir oppretta/kopla til rett avgjerd/søknad; nedlasting finn rett siste versjon                            |
| APP-DEC-03 |   P2 | Gjenta fullføring/filgenerering                                            | Idempotens eller tydeleg duplikatregel; ikkje fleire uønskte avgjerder/filer                                   |
| AGR-01     |   P1 | Godkjend søknad gir avtale og distribusjon                                 | Avtale og tilgang blir sende med same verksemd/omfang                                                          |
| AGR-02     |   P1 | Avslutt avtale etter stadfesting                                           | Status blir deaktivert/avslutta; historikk blir bevart; distribusjon blir trekt tilbake                        |
| AGR-03     |   P1 | Avslå stadfesting eller manglande rett til oppdatering                     | Avtale og ekstern tilgang blir uendra                                                                          |
| AGR-04     |   P1 | Fjern RelatedContact med og utan søknadskopling                            | Søknadskopla kontakt blir bevart og frikopla frå avtale; elles blir han sletta                                 |
| AGR-05     |   P2 | Endre varslingsval for kontaktar, også tom/null verdiar                    | Berre venta felt endrast; minst éin mottakar per påkravd varseltype blir handheva                              |
| DIST-01    |   P1 | Distribusjons-API returnerer 200 for PUT og DELETE                         | Riktig handling, org-nummer og payload blir sende                                                              |
| DIST-02    |   P1 | API returnerer annan status, timeout eller kastefeil                       | Feil blir logga/eksponert; Salesforce-tilstand påstår ikkje at ekstern handling lukkast                        |
| DIST-03    |   P2 | Flow sender fleire inputs i same invocable-kall                            | Alle input blir handterte eller kontrakten avgrensar eksplisitt til eitt; test noverande første-element-atferd |
| FLOW-01    |   P1 | Statusovergang til «meir informasjon»/«avslag»/«innvilga»                  | Rett Flow, oppgåve, varsel og dato oppstår éin gong                                                            |
| FLOW-02    |   P2 | Opprett/lukk Inquiry, Thread og Message i ulike rekkjefølgjer              | Eigar, aktiv-status, lukking og varsling blir konsistente                                                      |
| FLOW-03    |   P2 | Planlagd opprydding av gamle utkast                                        | Berre utkast som oppfyller alders-/statusvilkår og tilhøyrande dokument blir sletta                            |
| P360-01    |   P1 | Same arkiveringshending blir trigga fleire gonger                          | Idempotensnøkkel hindrar dupliserte jobbar                                                                     |
| P360-02    |   P1 | Worker får timeout/feil til permanent feil                                 | Lease, forsøkstal og backoff følgjer kontrakten; ingen evig retry                                              |
| P360-03    |   P1 | Arkivflagget manglar/er av eller config-lesing feilar                      | Processing gate stoppar lukka; ingen ekte callout                                                              |
| P360-04    |   P1 | Stub rapporterer suksess                                                   | Test beviser berre lokal stub-kontrakt; ikkje P360-oppretting                                                  |
| P360-05    |   P2 | To schedularkøyringar konkurrerer om same jobbar                           | Jobb blir claima éin gong og prosessert kontrollert                                                            |
| DATA-01    |   P1 | Brukar A førespør data medan B eig relaterte recordar                      | Sharing/CRUD/FLS blir handheva i dei konkrete Apex- og LWC-seamane                                             |
| DATA-02    |   P2 | Filer med feil eigar, manglande link eller fleire versjonar                | Ingen framand fil blir eksponert; siste relevante versjon blir vald                                            |

## Viktige kontrollpunkt før ein kan kalle dette end-to-end-verifisert

1. Hent fersk, godkjend org-status for aktiv Flow-versjonar, relevante feature flags, P360 mock-/processing-innstillingar, schedularkøyringar og permission-set assignments i aggregert form. Metadatafiler i kjelda er ikkje nok.
2. Stadfest at Flow-køyringane i org samsvarer med kjeldeversjonane. Org-oppslag må vere lesande og målretta; ikkje hent record-data, brukarar, Named Credential-hemmar eller token.
3. Kople kvart scenario til konkret testmetode og eksisterande testbevis i ei eiga testinventering. Denne gjennomgangen har ikkje køyrt Apex eller Jest.
4. Verifiser P360 berre mot godkjent ikkje-produksjonsintegrasjon, med syntetisk dokument og eksplisitt evidens frå P360. Lokal stub-/jobbsuksess er ikkje arkivbevis.
5. Køyr Altinn-testscenario isolert frå live-Altinn og verifiser at feil eller tomt scenario ikkje gjev tilgang.
