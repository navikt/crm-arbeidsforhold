# P360 mock-flyt: stegvis brukar-/org-test

Denne runbooken testar den interne P360-flyten utan live P360-kall. Han skal køyrast berre mot default scratch org `crm-arbeidsforhold`.

> Arbeid i eksisterande `crm-arbeidsforhold` scratch-org krev ikkje ny brukargodkjenning etter `AGENTS.md`. Verifiser eksplisitt mål og scratch-type før handling og respekter native verktøygodkjenningar. Andre ikkje-produksjonsorg krev fersk mål-/handlingsgodkjenning; produksjon er alltid forbode. Guiden dokumenterer instruksjonar, ikkje gjennomførte testar.

## Slik brukar vi guiden saman

Guiden er referanse for føresetnader, forventningar og tekniske detaljar. Han er ikkje ein automatisk wizard eller ei full klikk-for-klikk-skildring av Salesforce UI.
For ei forklaring av kallkjeda, metadata, testar og kjende kodegrenser, sjå [P360-kodegjennomgangen](kodegjennomgang.md).

I ei menneskestyrt gjennomgang:

1. Assistenten gir eitt avgrensa steg og seier kva du skal sjå etter.
2. Du utfører steget i Salesforce UI eller lokalt og svarer med resultatet.
3. Assistenten registrerer status og evidens i [P360 testlogg](test-log.md), forklarer avvik og gir først deretter neste steg.
4. I denne menneskestyrte modusen utfører du stega sjølv. Ved agentstyrt køyring kan assistenten lese, teste, deploye og endre data/metadata i verifisert eksisterande `crm-arbeidsforhold` scratch-org utan ny brukargodkjenning; rapporter dette som agentutført, ikkje som eit manuelt UI-resultat.

Svaralternativa for kvart steg skal vere: **Utført**, **Blokkert**, **Uventa resultat**, **Treng hjelp**, eller **Hopp over**. Eit steg utan stadfesta resultat er ikkje bestått.

Testloggen skil mellom automatiserte testar og manuelle UI-scenario. Han skal føre dato, miljø, steg-ID, forventa og faktisk resultat, status, evidens, avvik og opprydding. Ikkje legg secrets, org-URL-ar eller ekte persondata i loggen.

Mock-flyten verifiserer:

- at `P360_AdapterFactory` vel `P360_StubArchiveAdapter`;
- at ApplicationDocument- og ApplicationAttachment-jobbar blir oppretta idempotent;
- at `P360_ArchiveJobScheduler` claimar jobbar og dispatchar worker;
- at mock-worker kan ende i `Succeeded` utan HTTP-callout;
- at lease, attempt count og feilstiar kan observerast i `P360_Archive_Job__c`.

Han verifiserer ikkje P360 endpoint, OAuth, Named Credential, wire-format, ekte upload eller eksterne feilkodar.

## Føresetnader

- Målorg er `crm-arbeidsforhold`.
- Koden og P360-metadata er deploya til scratch orgen.
- For UI-only statusinnsyn skal menneskeleg testoperatør ha `P360_Archive_Job_Viewer`.
- For `npm run test:p360:mock` må køyrande teknisk brukar ha `P360_Integration_User` eller minst `P360_Archive_Job_Processing`. Ikkje tildel processing-set-et til ein menneskeleg UI-brukar berre for å vise fana; Salesforce-rettar er additive, så Create/Edit blir verande dersom brukaren også har det settet.
- Det finst ikkje secrets, tokens, cookies eller ekte persondata i testen.
- Bruk aldri produksjon, heller ikkje ein produksjonstilknytt Dev Hub. Denne runbooken gjeld berre `crm-arbeidsforhold`; bruk av `SIT2`, ein annan ikkje-produksjonsorg eller ein ikkje-produksjons-Dev Hub krev fersk mål-/handlingsgodkjenning og ei eiga tilpassa testprosedyre.

### P360 Archive Jobs-listevisingar

Metadataen definerer desse delte listevisingane:

- **All Archive Jobs** – alle jobbar brukaren elles har tilgang til.
- **Pending Archive Jobs** og **In Progress Archive Jobs** – aktive køstatusar.
- **Needs Attention**, **Failed Archive Jobs** og **Manual Review Archive Jobs** – feil og jobbar som krev manuell oppfølging.
- **Succeeded Archive Jobs** – fullførte jobbar.

Visingane blir delte med interne brukarar, men gir ikkje i seg sjølve objekt- eller posttilgang og omgår ikkje delingsreglane. Dei må vere deploya til orgen før dei blir synlege. Testoperatøren treng `P360_Archive_Job_Viewer` for fana og lesetilgang; ei eventuell tildeling er ei eiga godkjend org-handling. `P360_Archive_Job_Processing` gir framleis Create/Edit dersom det også er tildelt.

Kontroller målorg før kommandoar:

```bash
sf org display --target-org crm-arbeidsforhold
```

### Metadata-preflight

Før smoke-testen må `P360_Archive_Job__c` vere komplett i **target orgen**, og brukaren som køyrer scriptet må ha tilgang til felta. Dette er to separate krav:

1. **Metadata:** Felta må finnast på objektet i org-skjemaet.
2. **FLS:** Felta må vere synlege for køyrande brukar. Elles blir dei filtrerte bort frå `Schema.Describe`, og scriptet kan rapportere dei som «manglande» sjølv om dei finst i orgen.

Smoke-scriptet brukar metadata-preflighten til å kontrollere at desse felta er synlege på `P360_Archive_Job__c`:

- `Access_Request__c`
- `Application__c`
- `Application_Decision__c`
- `Agreement__c`
- `Idempotency_Key__c`
- `Archive_Event_Type__c`
- `Status__c`

Felta har desse rollene i testen:

| Felt                      | Bruk                                                                                                                       |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `Access_Request__c`       | Koplar arkivjobben til tilgangssøknaden. Påkravd ved oppretting av jobb.                                                   |
| `Application__c`          | Identifiserer søknaden som skal arkiverast eller har vedlegget. Brukast også av smoke-scriptet for å hente dei to jobbane. |
| `Application_Decision__c` | Identifiserer vedtaket for `DecisionDocument`-jobbar.                                                                      |
| `Agreement__c`            | Identifiserer avtalen for `AgreementDocument`-jobbar.                                                                      |
| `Idempotency_Key__c`      | Hindrar at same arkivhending opprettar fleire jobbar.                                                                      |
| `Archive_Event_Type__c`   | Angir hendingstype, til dømes `ApplicationDocument` eller `ApplicationAttachment`.                                         |
| `Status__c`               | Styrer livsløpet, til dømes `Pending`, `In Progress` og `Succeeded`.                                                       |

`Application_Decision__c` og `Agreement__c` er ikkje nødvendige for akkurat den enklaste ApplicationDocument-testen, men dei er med i preflighten fordi objektet støttar alle fire arkivhendingane og service-/worker-koden spør etter eit felles jobbskjema.

Kontroller først at felta finst som org-metadata:

```bash
sf data query \
  --target-org crm-arbeidsforhold \
  --use-tooling-api \
  --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'P360_Archive_Job__c' AND QualifiedApiName IN ('Access_Request__c','Application__c','Application_Decision__c','Agreement__c','Idempotency_Key__c','Archive_Event_Type__c','Status__c')" \
  --result-format table
```

Kontroller deretter at køyrande brukar har `P360_Archive_Job_Processing`, eller gruppa `P360_Integration_User` som inneheld dette permission set-et:

```bash
sf org assign permset \
  --name P360_Archive_Job_Processing \
  --target-org crm-arbeidsforhold
```

Tilordninga er ei org-endring. Køyr henne berre når det er godkjent for scratch orgen. Permission set-et gir eksplisitt read/edit-FLS for dei valfrie lookup-felta `Application__c`, `Application_Decision__c` og `Agreement__c`; required-felt får ikkje eigne `<fieldPermissions>`-oppføringar fordi Salesforce handterer dei implisitt.

Tidlegare feilmeldingar må tolkast med denne skilnaden i mente: `Application__c` mangla først faktisk i org-skjemaet, men etter at feltet var deploya var dei same feilmeldingane eit resultat av manglande FLS/permission-set-tilordning. Den noverande preflight-feilen betyr derfor ikkje automatisk at metadata må deployast på nytt.

Preview utan org-endring:

```bash
sf project deploy preview \
  --source-dir force-app/integration/p360 \
  --target-org crm-arbeidsforhold \
  --json
```

Etter godkjend deployment til default scratch org kan metadata deployast med:

```bash
sf project deploy start \
  --source-dir force-app/integration/p360 \
  --target-org crm-arbeidsforhold \
  --test-level RunSpecifiedTests \
  --tests P360_ArchiveJobServiceTest,P360_ContentVersionArchiveHandlerTest,P360_ArchiveJobSchedulerTest \
  --wait 30
```

Deployment er ein org-mutasjon og skal køyrast som eksplisitt godkjend handling. Køyr ikkje smoke-scriptet før deploymenten har lukkast.

## Steg 1: Slå på eksplisitt mock

For godkjend ikkje-produksjonstest må feature-flagget og mock-transporten aktiverast kvar for seg:

- I Setup under Custom Metadata Types, set `Feature_Flag__mdt.P360_Archive_Processing.Is_Enabled__c` til `true`.
- I Setup under Custom Settings, `P360 Integration Setting`, set `Use Mock Transport` til `true`.
- `Named Credential Name` kan stå tomt i mock-modus

Eller køyr den repo-eigde smoke-runneren:

```bash
npm run test:p360:mock
```

Runneren opprettar også testdata, dispatchar scheduler og verifiserer sluttstatus. Det skal ikkje gjere eit live callout.

## Steg 2: Køyr fokuserte testar

Køyr først dei interne seam-testane:

```bash
sf apex run test --tests P360_AdapterFactoryTest --target-org crm-arbeidsforhold --result-format human --synchronous
sf apex run test --tests P360_ArchiveJobServiceTest --target-org crm-arbeidsforhold --result-format human --synchronous
sf apex run test --tests P360_ArchiveJobClaimServiceTest --target-org crm-arbeidsforhold --result-format human --synchronous
sf apex run test --tests P360_ArchiveJobSchedulerTest --target-org crm-arbeidsforhold --result-format human --synchronous
sf apex run test --tests P360_ArchiveJobWorkerTest --target-org crm-arbeidsforhold --result-format human --synchronous
sf apex run test --tests P360_ContentVersionArchiveHandlerTest --target-org crm-arbeidsforhold --result-format human --synchronous
```

Køyr deretter mapping/orchestration utan transport:

```bash
sf apex run test --tests AAREG_ApplicationToP360CaseMapperTest --target-org crm-arbeidsforhold --result-format human --synchronous
sf apex run test --tests AAREG_CreateDocumentMapperTest --target-org crm-arbeidsforhold --result-format human --synchronous
sf apex run test --tests AAREG_DecisionDocumentMapperTest --target-org crm-arbeidsforhold --result-format human --synchronous
sf apex run test --tests AAREG_FileMapperTest --target-org crm-arbeidsforhold --result-format human --synchronous
sf apex run test --tests AAREG_ArchiveApplicationOrchestratorTest --target-org crm-arbeidsforhold --result-format human --synchronous
```

## Steg 3: Køyr smoke-scriptet

```bash
npm run test:p360:mock
```

Runneren skriv ei kort rapport med:

- Application-, ContentVersion- og ApplicationDocument-jobb-ID
- Queueable worker-ID, status og feiltal
- ApplicationDocument- og ApplicationAttachment-status med forsøkstal
- kontroll av forventa jobbtypar, `Succeeded`, idempotens og mock transport
- endeleg `Result: PASS` eller `Result: FAIL`

ContentVersion-triggeren opprettar ApplicationAttachment-jobben. Runneren spør etter statusen til den nyaste `P360_ArchiveJobWorker`-jobben opptil fem gonger utan eit synleg ventesteg mellom spørjingane. Han returnerer exitkode 1 dersom worker-jobben ikkje er `Completed` utan feil, eller dersom ein annan kontroll feilar. Ein worker som bruker lengre tid enn desse spørjingane kan difor føre til feil sjølv om han fullfører seinare; runneren ventar ikkje til async-behandlinga garantert er ferdig. For full Apex-debuglogg kan det underliggjande scriptet framleis køyrast direkte:

```bash
sf apex run \
  --target-org crm-arbeidsforhold \
  --file scripts/apex/p360MockArchiveFlow.apex
```

## Steg 4: Sjå jobbstatus før og etter worker

Runneren viser sluttstatus automatisk. Bruk denne queryen dersom du vil undersøkje fleire eller eldre jobbar:

```bash
sf data query \
  --target-org crm-arbeidsforhold \
  --query "SELECT Id, Archive_Event_Type__c, Status__c, Attempt_Count__c, Correlation_Id__c, Idempotency_Key__c, Started_Date__c, Lease_Expires_Date__c, Next_Attempt_Date__c, Last_Error_Code__c, Last_Error_Message__c FROM P360_Archive_Job__c ORDER BY CreatedDate DESC LIMIT 10" \
  --result-format table
```

Forventa overgang:

```text
Pending -> In Progress -> Succeeded
```

Forklaring:

1. `P360_ArchiveJobService` opprettar eller gjenbrukar jobben med stabil idempotensnøkkel.
2. `P360_ArchiveJobClaimService` finn `Pending`, set `In Progress`, aukar `Attempt_Count__c` og set lease.
3. `P360_ArchiveJobScheduler` enqueuear `P360_ArchiveJobWorker` når minst éin jobb blei claimet.
4. Factoryen vel stub-adapter fordi `Use Mock Transport = true`.
5. Stub-adapteren returnerer suksess utan callout, og worker set status `Succeeded`.

## Steg 5: Verifiser idempotens

Køyr smoke-scriptet fleire gonger og query same felt. Kvar ny ContentVersion får ein ny ApplicationAttachment-nøkkel, men same servicekall med same `(ApplicationId, ContentVersionId)` skal gjenbruke eksisterande jobb.

Kontroller duplikat per nøkkel:

```bash
sf data query \
  --target-org crm-arbeidsforhold \
  --query "SELECT Idempotency_Key__c, COUNT(Id) jobCount FROM P360_Archive_Job__c GROUP BY Idempotency_Key__c HAVING COUNT(Id) > 1" \
  --result-format table
```

Forventa resultat er ingen rader.

## Steg 6: Forstå feilstiar

`P360_ArchiveJobWorkerTest` dekker mockbare feilstiar. Statusmodellen er:

- Retrybar feil før maks forsøk: `Failed` med `Next_Attempt_Date__c` og backoff.
- Ikkje-retrybar feil eller maks forsøk: `Manual Review` med feilkode og melding.
- Ein `In Progress`-jobb blir ikkje automatisk claima på nytt berre fordi lease går ut. Dagens claim-service vel `Pending` og tidsmodne `Failed`-jobbar; trygg automatisk recovery av utgått lease er ikkje implementert.

Query feilstiar:

```bash
sf data query \
  --target-org crm-arbeidsforhold \
  --query "SELECT Id, Status__c, Attempt_Count__c, Next_Attempt_Date__c, Lease_Expires_Date__c, Last_Error_Code__c, Last_Error_Message__c FROM P360_Archive_Job__c WHERE Status__c IN ('Failed', 'Manual Review') ORDER BY Last_Attempt_Date__c DESC LIMIT 20" \
  --result-format table
```

## Steg 7: Slå av mock etter testen

Mock-modus er eksplisitt og fell ikkje automatisk tilbake frå ekte transport. Når testen er ferdig:

- set `Feature_Flag__mdt.P360_Archive_Processing.Is_Enabled__c` til `false` etter testen slik at P360-triggerar, scheduler og workerar stoppar;
- scratch org som berre skal brukast lokalt: la `Use Mock Transport` stå `true`;
- org som skal klargjerast for ekte integrasjon: set `Use Mock Transport` til `false` først når auth, Named Credential og P360-kontrakt er stadfesta.

Ikkje legg secrets eller miljøspesifikke verdiar i scriptet eller Git.

## Feilsøking

| Symptom                                   | Sjekk                                                                                                                                                           |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `P360_Archive_Job__c` blir ikkje oppretta | Sjekk at Application har `Access_Request__c`, og at ContentVersion er publisert direkte på Application.                                                         |
| Jobb står `Pending`                       | Scheduler/claim er ikkje køyrd, eller brukaren manglar `P360_Archive_Job_Processing`.                                                                           |
| Jobb står `In Progress`                   | Worker kan framleis køyre. Utgått lease fører ikkje automatisk til ny claim i dagens kode; stopp og avklar recovery i staden for å vente på automatisk reclaim. |
| Jobb blir `Manual Review`                 | Sjå `Last_Error_Code__c` og `Last_Error_Message__c`.                                                                                                            |
| `P360_MissingCodeTableMappingException`   | Sjekk at P360-kodeverkmetadata er deploya og aktiv.                                                                                                             |
| Ekte callout blir forsøkt                 | Kontroller `P360_Integration_Setting__c.Use_Mock_Transport__c = true` og at testen bruker factory/orchestrator, ikkje `P360_ArchiveAdapter` direkte.            |
| Testklassen blir ikkje funnen             | Koden/testen er ikkje deploya til `crm-arbeidsforhold` enno. Verifiser scratch-målet og køyr deploy-preview før deploy; ny brukargodkjenning trengst ikkje der. |

Denne runbooken beviser intern mock-flyt og jobbstatus. Han beviser ikkje ekte P360 endpoint, auth, wire-format, upload eller eksterne feilkodar.

## Record-detaljar: Processing Timeline

Etter deploy av `P360 Archive Job Layout` skal Details på ein arkivjobb vise seksjonen **Processing Timeline** med Queued Date, Started Date, Last Attempt Date, Lease Expires Date og Next Attempt Date. Felta er skriveverna i layoutet; eksisterande feltrettar gjeld framleis.

Kontroller at alle fem feltnamna er synlege, også når verdiar er tomme. Tomme lease-/retryfelt kan vere normalt på fullførte jobbar; synlegheit og innhald er to ulike kontrollar. Created/Last Modified erstattar ikkje desse behandlingsfelta.

### Last Attempt Date: kontrakt etter rettinga

Worker-rettinga registrerer tidspunktet når eit faktisk adapterforsøk startar, og lagrar det med Succeeded-, Failed- eller Manual Review-utfallet. Feltet blir oppdatert ved nye forsøk, men ikkje ved claim åleine eller når feature-flagget avbryt worker før adapterkallet. Uventa feil som rullar tilbake worker-transaksjonen kan også rulle tilbake tidsstempelet; feltet er ikkje ei separat callout-auditløysing.

Etter godkjend deploy skal ein ny mock-jobb som er ferdigbehandla ha Last Attempt Date. Dette må kontrollerast med ein ny jobb; rettinga fyller ikkje inn historiske verdiar. Sjå [testloggen](test-log.md) for gjeldande deploy- og verifikasjonsstatus.
