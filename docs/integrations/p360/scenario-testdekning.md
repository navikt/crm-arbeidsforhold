# P360: scenariodekning og attståande testarbeid

Dette dokumentet knyter P360-01–P360-05 frå
[scenarioinventaret](../../architecture/arbeidsforhold-kjeldekart-og-teststrategi.md)
til konkrete testar og historisk evidens. Det er eit arbeidsgrunnlag for
[testplanen](https://github.com/navikt/crm-arbeidsforhold/issues/1181), ikkje
ein påstand om at desse scenarioa er komplett testa.

## Felles rammer

- **Mål:** scratch-org `crm-arbeidsforhold`. Før kvar org-kommando må brukar
  stadfeste dette målet og den eksakte handlinga. Deploy, dataskriving,
  flagg- og tilgangsendringar krev separat godkjenning.
- **Testdata:** bruk isolerte, syntetiske data og eksisterande
  [P360_TestDataFactory](../../../force-app/tests/classes/integration/p360/test/P360_TestDataFactory.cls)
  og [AAREG_TestDataFactory](../../../force-app/utility/classes/AAREG_TestDataFactory.cls).
  Ikkje bruk faktiske dokument, identitetar eller kontaktopplysningar.
- **Aktør:** testane nedanfor brukar mellom anna ein minimumstilgangsbrukar
  med dei eksplisitte permission-seta som den enkelte testklassen tildeler.
  Dette er testisolerte tildelingar, ikkje instruks om å endre ein org-brukar.
- **Opprydding:** Apex-testar nyttar Salesforce si testisolering. For manuell
  smoke-test må ansvarleg først avtale isolering, testvindauge og tilbakeføring
  av innstillingar, tildelingar og syntetiske data. Ikkje slett delte data.
- **Evidens:** registrer dato, mål, eksakt test/kommando, resultat og
  PASS/FAIL/BLOCKED/NOT RUN utan sensitive data. Testkjelde åleine er ikkje
  ein bestått test. Mock-suksess er ikkje dokumentasjon på ekstern arkivering.

## P360-01 — same arkiveringshending fleire gonger

**Mål:** gjentekne jobbførespurnader for same identitet opprettar ikkje fleire
jobbar. **Testseam:** Apex-service, ikkje samtidig scheduler-køyring.

1. Opprett ein syntetisk `Access_Request__c` og `Application__c` i ein
   isolert Apex-test; for vedlegg opprett også ein syntetisk `ContentVersion`.
2. Kall jobbservicen to gonger med same søknadsidentitet, eventuelt same
   filversjon, men ulike korrelasjonsverdiar.
3. Kontroller at returnert jobb-ID er den same og at talet på jobbar med
   idempotensnøkkelen er éin. Kontroller eventtype og `Pending`.
4. Gjenta med ulike avgjerds- og avtalehendingar etter behov; ein annan
   filversjon er ein annan identitet og skal ikkje forvekslast med retry.

**Kjelde:** [service-testen](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobServiceTest.cls)
har separate testar for ApplicationDocument, ApplicationAttachment,
DecisionDocument og AgreementDocument. Dei to første kontrollerer òg
databaseradeteljing per nøkkel.

**Avgrensing:** sekvensiell gjenbruk er ikkje bevis for at samtidige
opprettingsforsøk eller eksterne P360-duplikat blir handterte korrekt.
Samtidig oppretting og ekstern recovery høyrer til
[P360-idempotensarbeidet](https://github.com/navikt/crm-arbeidsforhold/issues/1015).
Ingen ny Apex-køyring er utført i denne gjennomgangen.

## P360-02 — feil, retry og permanent feil

**Mål:** ein retrybar adapterfeil blir følgd opp utan falsk suksess; ein
ikkje-retrybar feil eller oppbrukt forsøksgrense går til manuell vurdering.
**Testseam:** isolert Apex-worker med injisert testadapter.

1. Opprett og claim ein syntetisk jobb som prosesseringsbrukar.
2. Injiser ein adapter som kastar ein retrybar integrasjonsfeil, og køyr
   workeren. Kontroller `Failed`, framtidig `Next_Attempt_Date__c` og
   tidspunkt for faktisk forsøk.
3. Kontroller at claim-service ikkje tek ein `Failed` jobb før retry-tid,
   men tek ein jobb som er moden og aukar forsøkstalet.
4. I ein ny isolert test, simuler feil ved maksimal forsøksgrense og
   kontroller `Manual Review`; kontroller separat at ikkje-retrybar feil
   ikkje får automatisk retry.

**Kjelder:** [worker-testen](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobWorkerTest.cls#L203)
og [claim-testen](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobClaimServiceTest.cls#L75).
Worker-testen kontrollerer framtidig retry-tid, men ikkje alle eksakte
backoff-intervall. Den set maksimalgrensa direkte i fixture i staden for å
simulere alle forsøk ende-til-ende.

**Avgrensing:** ein utgått `In Progress`-lease blir ikkje automatisk henta
opp att av [dagens claim-query](../../../force-app/integration/p360/classes/job/P360_ArchiveJobClaimService.cls#L29).
Timeout mot ekte P360, nøyaktig tidsplan og full recovery er ikkje bevist av
desse testane. Sjå [retry- og recoveryarbeidet](https://github.com/navikt/crm-arbeidsforhold/issues/1015).

## P360-03 — flagg manglar, er av eller kan ikkje lesast

**Mål:** prosessering skal stoppe lukka, utan falsk arkivsuksess.
**Testseam:** gate, ContentVersion-trigger, scheduler og worker.

1. I isolerte testar, set flagg-fixture til manglande, `null` og `false`
   i eigne variantar. Kontroller at `P360_ArchiveProcessingGate.isEnabled()`
   returnerer `false`.
2. Opprett eit syntetisk direktepublisert vedlegg i av-/manglande-variantane
   og kontroller at ingen tilknytt arkivjobb blir oppretta.
3. Lag ein eksisterande `Pending` jobb før flagget blir slått av; køyr
   scheduler og kontroller uendra `Pending` og forsøkstal.
4. For ein allereie claima jobb, slå flagget av før worker og kontroller at
   jobben blir tilbakeført og ikkje registrerer nytt adapterforsøk.

**Kjelder:** [ContentVersion-testen](../../../force-app/tests/classes/integration/p360/P360_ContentVersionArchiveHandlerTest.cls#L55),
[scheduler-testen](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobSchedulerTest.cls#L53)
og [worker-testen](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobWorkerTest.cls#L403).
[Gate-koden](../../../force-app/integration/p360/classes/P360_ArchiveProcessingGate.cls#L23)
fangar `FeatureToggleException` og returnerer `false`.

**Attstår:** ein eksplisitt test som injiserer denne lesefeilen og observerer
at adapter/callout ikkje blir kalla på den aktuelle inngangen. Koden si
catch-grein er ikkje i seg sjølv eit testresultat.

## P360-04 — stub gir suksess

**Mål:** dokumentere lokal stub-kontrakt utan å forveksle han med ekte P360.

1. Vel stub i ein isolert test ved hjelp av mock-setting; kontroller at
   factoryen faktisk vel `P360_StubArchiveAdapter`.
2. Send ei syntetisk førespurnad til stuben; kontroller suksess og at
   ekstern-ID-verdien blir vidareført i det lokale svaret.
3. Køyr ein claima jobb med injisert stub og kontroller `Succeeded` og
   `Last_Attempt_Date__c`.

**Kjelder:** [factory-test](../../../force-app/tests/classes/integration/p360/adapter/P360_AdapterFactoryTest.cls#L68),
[stub-test](../../../force-app/tests/classes/integration/p360/adapter/P360_StubArchiveAdapterTest.cls#L16)
og [worker-test](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobWorkerTest.cls#L311).
Den historiske [mock-smoke-loggen](test-log.md#runde-2026-11-05--automatisk-preflight-og-mock-smoke)
rapporterer to vellykka mock-jobbar etter etterkontroll, medan runneren sjølv
returnerte exitkode 1. Det er ikkje eit nytt testresultat.

**Attstår:** kontrakt, autentisering, transport, responslagring og ekte
arkivering i godkjent ikkje-produksjonsmiljø. Dette krev eiga planlegging og
eigne godkjenningar; det er ikkje del av mock-testen.

## P360-05 — samtidige schedularkøyringar

**Mål:** same jobb blir ikkje behandla dobbelt når to køyringar konkurrerer.

1. Etabler ein eigen, isolert ikkje-produksjonstest med éin syntetisk
   `Pending` jobb og ein kontrollert barriere som gjer at to uavhengige
   transaksjonar konkurrerer om same jobb.
2. Registrer begge claim-resultata og kontroller at nøyaktig éin transaksjon
   får jobben, at forsøkstalet blir auka éin gong, og at éin worker blir
   dispatcha for jobben.
3. Køyr fleire repetisjonar og registrer feil/timeout særskilt. Kontroller
   deretter at testjobben og eventuelle mellombelse innstillingar blir rydda
   opp etter godkjend plan.

**Status: BLOCKED — testharness og trygg parallellkøyring er ikkje avklarte.**
[Scheduler-testen](../../../force-app/tests/classes/integration/p360/job/P360_ArchiveJobSchedulerTest.cls#L16)
kontrollerer éi køyring, ikkje konkurranse. Claim-queryen bruker ikkje
`FOR UPDATE`; det er ein identifisert konkurranserisiko, ikkje bevis på
korleis ei konkret parallellkøyring fall ut.
[Eksisterande oppfølgingsarbeid](https://github.com/navikt/crm-arbeidsforhold/issues/1015)
omfattar atomisk claim og recovery.

## P02 — innsending med eksisterande vedlegg

[P02-loggen](test-log.md#p02-ny-lesekontroll-av-innstillingar--2026-11-12)
registrerer at brukaren 2026-11-12 sende inn søknaden og rapporterte
kvittering, synleg testfil og ingen P360-jobb ved undersøking av både søknad
og tilgangsforespurnad. Dette er **brukarrapportert observasjon**, ikkje
uavhengig verifisert årsak: effektiv gate under sjølve innsendinga er ikkje
stadfesta, og krava til automatisk søknadsarkivering må avklarast.

Eksisterande `ContentVersion`-test publiserer fila direkte på søknaden; han
beviser ikkje bana der fila vart lagra på utkastet før innsending. Prioriter
ein kravavklart regresjonstest for denne brukarvegen før ein konkluderer med
retting eller feil. Ikkje køyr ny innsending før testvindauge, utgåande
kanalar og separat godkjenning er avklarte.
