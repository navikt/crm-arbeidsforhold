# Testgjennomgang: P360 og crm-arbeidsforhold med mock

**Utarbeidd:** 2026-10-14  
**Grunnlag:** kode og dokumentasjon i arbeidskopien på denne datoen  
**Status:** testplan; ingen org-testresultat er registrerte i dette dokumentet

## Føremål og avgrensing

Denne gjennomgangen skal verifisere den eksisterande crm-arbeidsforhold-løysinga og den interne P360-flyten i scratch-org og integrasjonssandbox. P360 skal bruke mock inntil live-kontrakten og transporten er ferdige og godkjende.

Planen er ikkje eit bevis på at testane har bestått. Kvar test må få eit faktisk resultat og evidens frå miljøet der han blir køyrd. Planen dekkjer sentrale brukarreiser og kjende P360-grenser; ho er ikkje ein garanti for at alle variantar i løysinga er testa.

Gjennomfør tre rundar i denne rekkjefølgja:

1. **Scratch-org, P360 av:** eksisterande funksjonalitet og regresjon.
2. **Scratch-org, P360 på med mock:** jobbar, tilgang, låsing og prosessering.
3. **Integrasjonssandbox, framleis mock:** dei same brukarreisene med realistiske roller, deling, community og automatisering.

Org-oppretting, pakkeinstallasjon, deploy, konfigurasjonsendringar og bruk av ein annan org enn default scratch-org krev separat godkjenning. Kommandoane under er instruksjonar, ikkje handlingar som allereie er utførte.

## 1. Viktige funn før testing

| Område              | Dagens implementasjon                                                                                                                                                              | Konsekvens for testen                                                          |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| P360-mock           | Stub returnerer suksess utan callout. Workeren sender idempotensnøkkelen, ikkje komplett dokument-/filmapping.                                                                     | `Succeeded` beviser intern jobbprosessering, ikkje arkivering av rett innhald. |
| Søknadsvedlegg      | Hook reagerer på ny `ContentVersion` med `FirstPublishLocationId` direkte til søknaden. Ekstern søknads-UI opprettar fila først og koplar henne etterpå med `ContentDocumentLink`. | Smoke kan passere sjølv om faktisk UI-opplasting ikkje opprettar arkivjobb.    |
| Søknadsdokument     | Jobbservice finst; automatisk forretningsutløysar manglar.                                                                                                                         | Innsending er ikkje ein komplett P360-flyt.                                    |
| Vedtaksdokument     | Overgang til `Ready_For_P360_Archive__c=true` opprettar jobb når gate er på og søknaden har tilgangsforespurnad.                                                                   | Test frigiving separat frå «Complete decision».                                |
| Avtaledokument      | Jobbservice finst; automatisk utløysar og endeleg scope manglar.                                                                                                                   | Avtaleoppretting beviser ikkje automatisk arkivering.                          |
| Lease/recovery      | Claim set ti minutt lease, men vel berre `Pending` og forfalne `Failed`.                                                                                                           | Utgått `In Progress` blir ikkje automatisk teken opp att.                      |
| Andre integrasjonar | P360-mock gjeld berre P360. Distribusjonsmocken som vart kartlagd, er test-only.                                                                                                   | Stadfest runtime-mock for andre kall før funksjonell testing.                  |

Grunnlag:

- [P360 teknisk oversikt](../integrations/p360/teknisk-oversikt.md)
- [Attachment-handler](../../force-app/integration/p360/classes/P360_ContentVersionArchiveHandler.cls)
- [Worker](../../force-app/integration/p360/classes/job/P360_ArchiveJobWorker.cls)
- [Claim-service](../../force-app/integration/p360/classes/job/P360_ArchiveJobClaimService.cls)

**Merk:** Den eksisterande [mock-testguiden](../integrations/p360/user-testing-guide.md) omtalar reclaim etter utgått lease. Dette samsvarer ikkje med utvalet i dagens claim-kode. Bruk ikkje den formuleringa som akseptansekriterium for implementert recovery.

## 2. Testprotokoll

### Miljø og testkøyring

Fyll ut før start. Bruk godkjend intern dokumentasjon for miljøtilgang; ikkje legg org-URL-ar, persondata, credentials eller secrets i repoet.

| Opplysning                                    | Scratch-org | Integrasjonssandbox |
| --------------------------------------------- | ----------- | ------------------- |
| Dato og testansvarleg rolle                   |             |                     |
| Commit/pakkeversjon faktisk installert        |             |                     |
| Avhengigheitspakker og versjonar              |             |                     |
| Feature-flagg før testen                      |             |                     |
| Mock/stub-konfigurasjon                       |             |                     |
| Aktive flows og planlagde jobbar kontrollerte |             |                     |
| Testvindauge og køansvarleg avklart           |             |                     |
| Evidens lagra i godkjend system               |             |                     |

Lokal kjeldekode er ikkje bevis på at same kode er installert i sandbox.

### Resultatverdiar

- **PASS:** faktisk resultat samsvarer med akseptansekriteriet; evidens finst.
- **FAIL:** testen er køyrd og avvik er observerte.
- **BLOCKED:** ein føresetnad manglar; åtferda er ikkje verifisert.
- **IKKJE IMPLEMENTERT:** nødvendig funksjon/kopling manglar i dagens løysing.
- **IKKJE KØYRD:** testen er enno ikkje utført.

Tom resultatcelle betyr **IKKJE KØYRD**, ikkje PASS.

### Mal for detaljresultat

Kopier malen for kvar test eller bruk tilsvarande felt i testverktøyet:

```text
Test-ID:
Miljø og versjon:
Brukarrolle:
Syntetisk datasett / intern referanse:
Føresetnader:
Handling:
Forventa resultat:
Faktisk resultat:
PASS / FAIL / BLOCKED / IKKJE IMPLEMENTERT / IKKJE KØYRD:
Evidensreferanse:
Avvik / issue:
Opprydding:
```

Les lagra resultat tilbake etter refresh eller ny innlogging. Ein grøn toast er ikkje tilstrekkeleg evidens.

## 3. Klargjering

### Steg 1 — Klargjer scratch-org

- [ ] Undersøk [scratch-oppsettet](../../bin/README.md), installasjonsføresetnader og post-steg.
- [ ] Kontroller hjelp og dry-run før faktisk oppretting.
- [ ] Få godkjenning før org-oppretting, pakkeinstallasjon eller deploy.
- [ ] Kontroller hovudpakke og nødvendige avhengigheiter.
- [ ] Kontroller testdata, brukarar og permission assignments.
- [ ] Kontroller at community er tilgjengeleg for ekstern UI-testing.
- [ ] Kontroller at Apex-testklassane er deploya; produktpakkeinstallasjon er ikkje i seg sjølv bevis på dette.

```bash
rtk proxy npm run scratch-org -- --help
rtk proxy npm run scratch-org -- --dry-run
```

[Launcher-testane i PowerShell](../../bin/tests/create-scratch-org.Tests.ps1) testar oppsettslogikk. Dei erstattar ikkje funksjonell org-testing.

### Steg 2 — Klargjer roller

Ikkje test berre som administrator.

| Rolle                                    | Testansvar                                                     |
| ---------------------------------------- | -------------------------------------------------------------- |
| Ekstern brukar, syntetisk organisasjon A | Søknader, avtalar, vedlegg, vedtak og dialog                   |
| Ekstern brukar, syntetisk organisasjon B | Negativ tilgangstest mot A sine data                           |
| Saksbehandlar utan frigivingsrett        | Vanleg behandling; P360-frigiving skal avvisast når gate er på |
| Saksbehandlar med frigivingsrett         | Frigiving og låsing                                            |
| Teknisk prosesseringsbrukar              | Claim, scheduler og worker                                     |
| Support / read-only                      | Supportflyt og avgrensa endringsrettar                         |

Relevante sett omfattar `AAREG_Arbeidsforhold_Saksbehandling`, `AAREG_CommunityPermission`, `P360_Archive_Release` og `P360_Archive_Job_Processing`.

`P360_Integration_User` inneheld ikkje frigivingsretten. Test `P360_Archive_Release` som separat autorisasjon. Sjå [P360 permission sets](../../force-app/integration/p360/permissionsets/README.md).

### Steg 3 — Sikre utgåande kanalar

- [ ] P360 brukar `Use_Mock_Transport__c=true`.
- [ ] Runtime-mock/stub for distribusjonstilgang og andre API-kall er stadfesta.
- [ ] E-post går berre til godkjende testmottakarar.
- [ ] SMS er blokkert eller styrt til godkjend testløysing.
- [ ] Ingen ekte persondata eller produksjonsmottakarar blir brukte.
- [ ] Unike syntetiske datasett finst for godkjenning, delvis godkjenning, avslag og suspensjon.

Ein `HttpCalloutMock` i ein Apex-testklasse gjeld ikkje vanleg bruk av community. Manglande runtime-mock er ein blocker for den aktuelle brukarreisa.

## 4. Runde A — Eksisterande løysing med P360 av

Set `P360_Archive_Processing=false`. Køyr alle scenario først i scratch-org, deretter i integrasjonssandbox.

For kvar rad: utfør handlinga, les tilbake resultatet, registrer status og evidens. Bruk separate data der ei handling fullfører, låser eller deaktiverer noko.

| ID  | Handling                                                                                         | Forventa resultat                                                                                            |
| --- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| R01 | Logg inn i community og vel organisasjon.                                                        | Rett organisasjonskontekst. Søknader, avtalar, brukerstøtte og meldingar visast etter rettane.               |
| R02 | Start ny søknad. Prøv innsending utan påkravde felt og bruksvilkår.                              | Innsending blir stoppa med forståeleg validering; ingen halvferdig innsending.                               |
| R03 | Fyll søknaden, vel «Lagre», logg ut og inn igjen.                                                | Utkastet finst, innhaldet er bevart, og brukaren kan halde fram.                                             |
| R04 | Last opp syntetiske vedlegg, lagre og opne att.                                                  | Rett innhald, filnamn og søknadskopling. Organisasjon B har ikkje tilgang.                                   |
| R05 | Vel «Send inn». Kontroller ekstern liste og intern post.                                         | Rett innsendingsdato og status for flyten; søknaden er faktisk lagra og tilgjengeleg internt.                |
| R06 | Opne som saksbehandlar. Test tildeling, frist, kommentar og relevante statusendringar.           | Endringar blir lagra og visast etter refresh; rett aktivitet/historikk der flyten brukar dette.              |
| R07 | Set saksbehandlarstatus til `Additional Information Required`.                                   | Søknadsstatus blir synkronisert, rett varsel/e-postkø blir oppretta, og ekstern brukar kan følgje opp.       |
| R08 | Vel «Opprett vedtak» og legg inn innhald og detaljlinjer.                                        | Rett vedtak er kopla til rett søknad; innhald og linjer blir lagra.                                          |
| R09 | Køyr «Complete decision» for godkjenning.                                                        | Sjekkliste, vedtaksstatus `Completed`, søknadsstatus og eventuell avtale blir oppdaterte rett.               |
| R10 | Gjenta fullføring for delvis godkjenning, avslag og suspensjon.                                  | Rett utfall, tekst, tilgangsomfang og eventuell avtale; ingen utilsikta tilgang ved avslag.                  |
| R11 | Opne og last ned vedtaks-PDF internt og eksternt.                                                | Rett organisasjon, dato, vedtak og detaljar. Rett dokumentkopling; ikkje nedlasting før dokumentet finst.    |
| R12 | Kontroller vedtaksvarsling.                                                                      | Rett testmottakar, mal og søknad. Kontroller kø og kontrollert levering kvar for seg.                        |
| R13 | Prøv å fullføre same vedtak igjen.                                                               | «Complete decision» er ikkje synleg når prosessen ikkje lenger er `In progress`; ingen utilsikta duplikat.   |
| R14 | Opne «Mine avtaler», filtrer og last ned vedtak.                                                 | Rett avtale/status og PDF; ingen innsyn i andre organisasjonar.                                              |
| R15 | Start/stopp intern revisjon og test endring av kontaktpersonar.                                  | Revisjonsflagg, `Under review`/`Active`, kontaktar og aktivitet er konsistente.                              |
| R16 | Avslutt avtale eksternt. Test intern «Remove Access» og «Deactivate Agreement» på separate data. | Rett deaktivering og tilgang; forventa request/resultat i distribusjonsstubben.                              |
| R17 | Opprett supporthenvending med vedlegg. Send melding og svar internt.                             | Utkast blir til `New`; tråd, vedlegg og varsling er kopla til rett brukar og rolle.                          |
| R18 | Test read-only support og lukking utan varsling.                                                 | Read-only kan ikkje endre; rett sluttstatus utan utilsikta varsel.                                           |
| R19 | Test sikkerheits-/feilhenvending med kontrollert SMS-kanal.                                      | Forventa eskalering, oppgåve og stub-varsel; ingen ekte SMS.                                                 |
| R20 | Gjenta sentrale visingar og handlingar som organisasjon B og utan nødvendige rettar.             | Ingen kryssorganisasjonsinnsyn, filnedlasting eller uautorisert endring, heller ikkje via direkte postlenke. |

### P360-kontroll medan flagget er av

- [ ] Søknadsvedlegg og vedtaksendringar opprettar ikkje jobbar via dei gatede inngangane.
- [ ] Scheduler claimar ikkje jobbar.
- [ ] Vanleg behandling blir ikkje låst av P360-guarden.

Jobbservicen kan kallast direkte også når flagget er av. Kravet om ingen jobboppretting her gjeld dei automatiske inngangane, ikkje alle direkte Apex-kall.

## 5. Runde B — P360 på med mock i scratch-org

### Steg 4 — Metadata og tilgang

- [ ] Kontroller at `P360_Archive_Job__c` og nødvendige felt finst.
- [ ] Kontroller feltrettar separat frå metadata. Eit felt kan finnast utan at testbrukaren ser det.
- [ ] Kontroller triggerregistrering for `BEFORE_INSERT`, `BEFORE_UPDATE` og `AFTER_UPDATE`.
- [ ] Kontroller jobbtilgang og separat frigivingsrett for testrollene.
- [ ] Kartlegg eksisterande kvalifiserte jobbar før scheduler blir køyrd.

Sjå [metadata-preflight i mock-testguiden](../integrations/p360/user-testing-guide.md).

### Steg 5 — Aktiver mock og prosessering kvar for seg

Etter godkjenning:

1. Set `P360_Integration_Setting__c.Use_Mock_Transport__c=true`.
2. Set `Feature_Flag__mdt.P360_Archive_Processing.Is_Enabled__c=true`.
3. Kontroller at `Required_Custom_Permission__c` på feature-flagget er tomt.

Eit ikkje-tomt permission-felt held dagens gate av. Det er ikkje ein mekanisme for å aktivere prosessering berre for utvalde brukarar.

### Steg 6 — Automatiserte testar

Køyr først den fokuserte gruppa i default scratch-org:

```bash
rtk proxy sf apex run test \
  --target-org crm-arbeidsforhold \
  --tests P360_AdapterFactoryTest,P360_ContentVersionArchiveHandlerTest,P360_ApplicationDecisionArchiveGuardTest,P360_ArchiveJobServiceTest,P360_ArchiveJobClaimServiceTest,P360_ArchiveJobSchedulerTest,P360_ArchiveJobWorkerTest \
  --result-format human \
  --wait 30
```

Dersom kommandoen returnerer eit pågåande testløp, hent sluttresultatet med den faktiske test-run-ID-en før resultatet blir kalla bestått.

Køyr deretter:

- [ ] Heile P360-suita; 55 testklassar ligg i kjelda på kartleggingstidspunktet.
- [ ] `IntegrationLoggerTest`, `IntegrationLogRedactorTest`, `CorrelationContextTest` og `IntegrationLogContextTest`.
- [ ] Relevante eksisterande søknads-, vedtaks-, avtale- og supporttestar.
- [ ] Full lokal Apex-regresjon i org når fokuserte testar er grøne.
- [ ] Lokal Jest og formateringskontroll.

```bash
rtk proxy npm test -- --runInBand
rtk proxy npm run prettier:check
```

Jest og formatering erstattar ikkje Apex-, PDF- eller community-testing. Registrer eksakt kommando, exit-kode, pass/fail-tal og evidens for kvar køyring. Historiske testtal i dokumentasjonen er ikkje nye testresultat.

### Steg 7 — Eksisterande mock-smoke

```bash
rtk proxy npm run test:p360:mock
```

Før køyring:

- Runneren er hardkoda til `crm-arbeidsforhold`.
- Han opprettar testdata og set mock til `true`; feature-flagget må allereie vere på.
- Scheduler kan ta andre kvalifiserte jobbar i orgen.
- Testdata blir ikkje automatisk sletta.

Forventa resultat:

- [ ] Éin `ApplicationDocument` og éin `ApplicationAttachment`.
- [ ] Begge `Succeeded`, med eitt forsøk kvar.
- [ ] Worker `Completed` utan feil.
- [ ] Ingen duplikatnøklar.
- [ ] Mock er vald; ingen live-P360-callout.

Dersom runneren feilar medan worker framleis køyrer, undersøk sluttstatus før du konkluderer. Runneren har berre nokre få raske statusoppslag.

Ny smoke-køyring opprettar nye kjelder. Det er ikkje ein tilstrekkeleg test av gjenbruk av same jobb.

### Steg 8 — Funksjonelle P360-scenario

| ID  | Handling                                                                                | Forventa resultat / tolking                                                                                                        |
| --- | --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| P01 | Publiser ny fil direkte på søknad med tilgangsforespurnad.                              | Éin `ApplicationAttachment` i `Pending`, med rette kjeldekoplingar og nøkkel.                                                      |
| P02 | Last opp vedlegg gjennom faktisk ekstern søknads-UI.                                    | Registrer om jobb blir oppretta. Dagens publiseringsveg peikar på eit integrasjonshol; ikkje godkjenn berre fordi P01 passerer.    |
| P03 | Publiser fil på anna objekt eller søknad utan tilgangsforespurnad.                      | Ingen application-attachment-jobb frå denne handleren.                                                                             |
| P04 | Kall jobbservice to gonger med same kjelde og filversjon.                               | Same jobb-ID og éin rad; ingen ny jobb eller utilsikta nullstilling av eksisterande status.                                        |
| P05 | Last opp ny filversjon gjennom faktisk UI.                                              | Registrer publiseringsmåte og jobbresultat. Denne vegen er ikkje dokumentert som dekt av hooken.                                   |
| P06 | Fullfør vedtak og kontroller PDF før frigiving.                                         | Normal vedtaksflyt fungerer. «Complete decision» er ikkje i seg sjølv P360-frigiving.                                              |
| P07 | Set frigivingsfeltet utan custom permission.                                            | Lagring blir avvist; ingen `DecisionDocument`.                                                                                     |
| P08 | Frigi eksisterande vedtak med rett permission og komplett kjeldekopling.                | Éin `DecisionDocument` i `Pending`.                                                                                                |
| P09 | Endre ordinære vedtaksfelt eller nullstill frigiving etter P08.                         | Endring blir avvist når gate er på.                                                                                                |
| P10 | Oppdater dei tre P360-referansefelta som autorisert teknisk brukar.                     | Guarden tillèt tekniske endringar. Dette beviser ikkje automatisk tilbakeføring frå P360.                                          |
| P11 | Frigi vedtak utan tilgangsforespurnad; test også insert med frigivingsfelt allereie på. | Jobb kan utebli i dagens kode. Registrer manglande preflight/kopling, ikkje bestått arkivflyt.                                     |
| P12 | Opprett søknads- og avtaledokumentjobb gjennom service.                                 | Jobbane kan prosesserast med mock. Automatisk utløysing frå innsending/avtale manglar framleis.                                    |
| P13 | Køyr scheduler på `Pending`, og igjen etter suksess.                                    | Claim gir `In Progress`, eitt ekstra forsøk og ti minutt lease; worker gir `Succeeded`. `Succeeded` blir ikkje valt på nytt.       |
| P14 | Slå av flagget før claima worker køyrer.                                                | Jobben blir `Pending`, claim-forsøket blir trekt tilbake og start/lease blir nullstilte. Bruk deterministisk Apex-test for timing. |
| P15 | Slå på igjen etter flagg-av-perioden.                                                   | Eksisterande `Pending` kan prosesserast. Hendingar medan flagget var av, blir ikkje automatisk etterregistrerte.                   |

Frigiving skal skje etter nødvendige ordinære vedtaksoppdateringar. Test om seinare flows prøver å endre låste felt og feilar.

Ved flagg av er også P360-låsen av. Flagget er ikkje ein permanent, uavhengig integritetslås.

## 6. Feil, retry, logging og recovery

Runtime-stubben returnerer alltid suksess. Bruk eksisterande Apex-testdoblar til feilstiane; ikkje slå av mock i delt sandbox for å framprovosere feil.

| ID  | Scenario                       | Akseptanse / dagens avgrensing                                                                                                |
| --- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| F01 | Retrybar adapterfeil           | `Failed`, feilkode/melding og framtidig `Next_Attempt_Date__c`.                                                               |
| F02 | Retry/backoff                  | 1, 5, 15 og 60 minutt etter dei første fire feila; femte feil gir `Manual Review`.                                            |
| F03 | Ikkje-retrybar feil            | Direkte `Manual Review`, utan automatisk retry.                                                                               |
| F04 | Adapter utan stadfesta suksess | Kontrollert feil; ikkje `Succeeded`.                                                                                          |
| F05 | Lang feilmelding               | Blir avgrensa til feltlengda.                                                                                                 |
| F06 | Kontrollert worker-feil        | Avgrensa felles logg med system, arkivtype, utfall og correlation-verdi; ikkje request/response eller exception-tekst.        |
| F07 | Ugyldig correlation-ID         | Redigert i felles logg. Automatisk genererte verdiar er ikkje full ende-til-ende-korrelasjon.                                 |
| F08 | `Manual Review`                | Blir ikkje automatisk claimet. Recovery-prosedyre må avklarast.                                                               |
| F09 | Utgått `In Progress`-lease     | Automatisk reclaim manglar. Ikkje merk implementert recovery som PASS.                                                        |
| F10 | Samtidige dispatcharar         | Test separat i kontrollert miljø. Claim har ikkje eksplisitt radlås; lease aleine beviser ikkje vern mot dobbel prosessering. |

Kontroller jobbar i scratch-org:

```bash
rtk proxy sf data query \
  --target-org crm-arbeidsforhold \
  --query "SELECT Id, Archive_Event_Type__c, Status__c, Attempt_Count__c, Idempotency_Key__c, Correlation_Id__c, Started_Date__c, Lease_Expires_Date__c, Next_Attempt_Date__c, Last_Error_Code__c, Last_Error_Message__c FROM P360_Archive_Job__c ORDER BY CreatedDate DESC LIMIT 30" \
  --result-format table
```

`AsyncApexJob=Completed` betyr ikkje åleine at arkiveringa lukkast. Kontroller også jobbtabellen. Ein vellykka mock-jobb beviser ikkje at gamle feilmeldingar og retry-/lease-felt er rydda; observer desse separat ved gjenkøyring.

## 7. Runde C — Integrasjonssandbox med mock

### Steg 9 — Preflight utan aktivering

- [ ] Godkjend målmiljø og testvindauge er avklart.
- [ ] Installert kode/pakke samsvarer med scratch-baselinen.
- [ ] Metadata, aktive flows og triggerregistrering er kontrollerte.
- [ ] Permission assignments og permission-set-group-status er kontrollerte.
- [ ] Realistiske interne og eksterne testroller er klare.
- [ ] Alle aktuelle API-, e-post- og SMS-kanalar er mocka eller kontrollerte.
- [ ] Eksisterande `Pending`, `Failed` og `In Progress` er kartlagde.
- [ ] Køansvarleg har godkjent eventuell prosessering av eksisterande jobbar.

Aktivering i delt sandbox kan behandle eksisterande jobbar. Ikkje slå på før omfanget er kjent.

### Steg 10 — Gjenta regresjon med P360 av

Køyr R01–R20 med nye syntetiske data. Legg særleg vekt på:

- community-innlogging og organisasjonsbyte;
- record sharing, feltrettar og filtilgang;
- PDF-generering og nedlasting;
- asynkrone flows og varsling;
- observerte requestar/resultat i distribusjonsstubben;
- eksisterande søknader og avtalar, ikkje berre nye data.

### Steg 11 — Gjenta P360 med mock på

Køyr P01–P15 og relevante automatiserte testar etter godkjenning.

Ikkje bruk scratch-smokerunneren som sandbox-runner eller endre hardkodinga som ein improvisert snarveg. Bruk godkjende testdata og kontrollerte service-/schedulerhandlingar for det avtalte miljøet.

### Steg 12 — Samla brukarreise

Køyr minst éi heil godkjenningsreise:

1. Ekstern brukar opprettar og sender søknad med vedlegg.
2. Saksbehandlar behandlar søknaden og opprettar vedtak.
3. Vedtak blir fullført; PDF blir generert og kontrollert.
4. Varsling og avtale/tilgang blir kontrollerte mot testkanalane.
5. Autorisert brukar frigir vedtaket for P360.
6. Jobboppretting, scheduler og mock-worker blir kontrollerte.
7. Ekstern brukar opnar resultatet og lastar ned rett vedtak.
8. Organisasjon B prøver same visingar/nedlasting og blir avvist.

Registrer manglande attachment-jobb og andre koplingshol sjølv om resten av reisa fungerer.

## 8. Resultatmatrise

Fyll ut status og evidensreferanse for begge miljø. Ved fleire variantar, bruk detaljprotokoll per variant.

| Test-ID           | Scratch: status / evidens | Sandbox: status / evidens | Avvik / issue |
| ----------------- | ------------------------- | ------------------------- | ------------- |
| R01               |                           |                           |               |
| R02               |                           |                           |               |
| R03               |                           |                           |               |
| R04               |                           |                           |               |
| R05               |                           |                           |               |
| R06               |                           |                           |               |
| R07               |                           |                           |               |
| R08               |                           |                           |               |
| R09               |                           |                           |               |
| R10               |                           |                           |               |
| R11               |                           |                           |               |
| R12               |                           |                           |               |
| R13               |                           |                           |               |
| R14               |                           |                           |               |
| R15               |                           |                           |               |
| R16               |                           |                           |               |
| R17               |                           |                           |               |
| R18               |                           |                           |               |
| R19               |                           |                           |               |
| R20               |                           |                           |               |
| P01               |                           |                           |               |
| P02               |                           |                           |               |
| P03               |                           |                           |               |
| P04               |                           |                           |               |
| P05               |                           |                           |               |
| P06               |                           |                           |               |
| P07               |                           |                           |               |
| P08               |                           |                           |               |
| P09               |                           |                           |               |
| P10               |                           |                           |               |
| P11               |                           |                           |               |
| P12               |                           |                           |               |
| P13               |                           |                           |               |
| P14               |                           |                           |               |
| P15               |                           |                           |               |
| F01               |                           |                           |               |
| F02               |                           |                           |               |
| F03               |                           |                           |               |
| F04               |                           |                           |               |
| F05               |                           |                           |               |
| F06               |                           |                           |               |
| F07               |                           |                           |               |
| F08               |                           |                           |               |
| F09               |                           |                           |               |
| F10               |                           |                           |               |
| Samla brukarreise |                           |                           |               |

### Automatisert validering

| Miljø   | Eksakt kommando / testgruppe | Exit-kode | Pass / fail / skip | Test-run / evidens | Resultat |
| ------- | ---------------------------- | --------- | ------------------ | ------------------ | -------- |
| Lokal   | Jest                         |           |                    |                    |          |
| Lokal   | Prettier                     |           |                    |                    |          |
| Scratch | Fokusert P360-gruppe         |           |                    |                    |          |
| Scratch | Full P360-suite              |           |                    |                    |          |
| Scratch | Felles logging/context       |           |                    |                    |          |
| Scratch | Full Apex-regresjon          |           |                    |                    |          |
| Scratch | Mock-smoke                   |           |                    |                    |          |
| Sandbox | Godkjend Apex-regresjon      |           |                    |                    |          |

## 9. Stans og opprydding

- [ ] Set `P360_Archive_Processing=false` etter testen.
- [ ] Kontroller pågåande workerar og attståande jobbar.
- [ ] Registrer kva som vart utført før flagget vart slått av; flagget trekkjer ikkje tilbake utført arbeid.
- [ ] Fjern berre testdata og mellombelse rettar frå denne køyringa etter godkjend prosedyre.
- [ ] Bevar nødvendig evidens i godkjend system.
- [ ] Kontroller at ingen testkø eller planlagt jobb er etterlaten utilsikta.
- [ ] Registrer endeleg konfigurasjon i begge miljø.

Ikkje set mock til `false` som opprydding før live-transport er ferdig og godkjend.

## 10. Godkjenning

### crm-arbeidsforhold regresjon verifisert

Krev beståtte avtalte brukarreiser og negative tilgangstestar i begge miljø, inkludert PDF, varsling, avtalar, support og mocka distribusjonstilgang. Blokkerte scenario skal vere synlege i beslutninga.

### P360 intern mock-flyt verifisert

Krev evidens for jobboppretting, idempotens, frigivingsrett, låsing, scheduler/worker, feilklassifisering og trygg pause. Kjende hol skal stå uttrykkeleg att; ein bestått smoke er ikkje heilskapsverifikasjon.

### P360 ende-til-ende klar

Kan ikkje godkjennast med dagens mock. Følgjande er framleis uverifisert eller uferdig:

- faktisk UI-vedleggskopling og godkjende automatiske utløysarar;
- komplett mapping og filinnhald;
- ekte SIF-transport og autentisering;
- P360-ID-ar og tilbakeføring;
- ekstern idempotens og delvis feil;
- automatisk lease-recovery og samtidigheitsvern;
- operativ overvaking og manuell recovery.

Sjå [completion roadmap](../../.github/specs/p360-completion-roadmap.md) for vidare arbeid og separate aktiveringskriterium.

| Beslutning                         | Resultat / avgrensing | Godkjennande rolle | Dato / evidens |
| ---------------------------------- | --------------------- | ------------------ | -------------- |
| Regresjon for eksisterande løysing |                       |                    |                |
| Intern P360-mock-flyt              |                       |                    |                |
| Attståande blockers og eigarskap   |                       |                    |                |
| Endeleg flagg-/mock-konfigurasjon  |                       |                    |                |

Bestått mock-testing er ikkje godkjenning til produksjonsdeploy, pakkeutgiving eller live-aktivering.
