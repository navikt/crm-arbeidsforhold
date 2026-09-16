# P360 mock-flyt: stegvis brukar-/org-test

Denne runbooken testar den interne P360-flyten utan live P360-kall. Han skal køyrast berre mot default scratch org `crm-arbeidsforhold`.

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
- Test-/integrasjonsbrukaren har `P360_Integration_User` eller minst `P360_Archive_Job_Processing`.
- Det finst ikkje secrets, tokens, cookies eller ekte persondata i testen.
- Bruk aldri `SIT2`, produksjon, DevHub eller annan org i denne runbooken utan eksplisitt godkjenning.

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

Mock-modus kan setjast i Setup under Custom Settings, `P360 Integration Setting`:

- `Use Mock Transport` = `true`
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

ContentVersion-triggeren opprettar ApplicationAttachment-jobben. Runneren følgjer workeren gjennom den asynkrone overgangen og returnerer exitkode 1 dersom ein kontroll feilar. For full Apex-debuglogg kan det underliggjande scriptet framleis køyrast direkte:

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
- Ny claim etter forfallen lease: jobb kan takast opp att av claim-service.

Query feilstiar:

```bash
sf data query \
  --target-org crm-arbeidsforhold \
  --query "SELECT Id, Status__c, Attempt_Count__c, Next_Attempt_Date__c, Lease_Expires_Date__c, Last_Error_Code__c, Last_Error_Message__c FROM P360_Archive_Job__c WHERE Status__c IN ('Failed', 'Manual Review') ORDER BY Last_Attempt_Date__c DESC LIMIT 20" \
  --result-format table
```

## Steg 7: Slå av mock etter testen

Mock-modus er eksplisitt og fell ikkje automatisk tilbake frå ekte transport. Når testen er ferdig:

- scratch org som berre skal brukast lokalt: la `Use Mock Transport` stå `true`;
- org som skal klargjerast for ekte integrasjon: set `Use Mock Transport` til `false` først når auth, Named Credential og P360-kontrakt er stadfesta.

Ikkje legg secrets eller miljøspesifikke verdiar i scriptet eller Git.

## Feilsøking

| Symptom                                   | Sjekk                                                                                                                                                |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `P360_Archive_Job__c` blir ikkje oppretta | Sjekk at Application har `Access_Request__c`, og at ContentVersion er publisert direkte på Application.                                              |
| Jobb står `Pending`                       | Scheduler/claim er ikkje køyrd, eller brukaren manglar `P360_Archive_Job_Processing`.                                                                |
| Jobb står `In Progress`                   | Worker køyrer asynkront, eller lease må bli forfallen før reclaim.                                                                                   |
| Jobb blir `Manual Review`                 | Sjå `Last_Error_Code__c` og `Last_Error_Message__c`.                                                                                                 |
| `P360_MissingCodeTableMappingException`   | Sjekk at P360-kodeverkmetadata er deploya og aktiv.                                                                                                  |
| Ekte callout blir forsøkt                 | Kontroller `P360_Integration_Setting__c.Use_Mock_Transport__c = true` og at testen bruker factory/orchestrator, ikkje `P360_ArchiveAdapter` direkte. |
| Testklassen blir ikkje funnen             | Koden/testen er ikkje deploya til `crm-arbeidsforhold` enno. Køyr deploy-preview først, og få eksplisitt godkjenning før faktisk deployment.         |

Denne runbooken beviser intern mock-flyt og jobbstatus. Han beviser ikkje ekte P360 endpoint, auth, wire-format, upload eller eksterne feilkodar.
