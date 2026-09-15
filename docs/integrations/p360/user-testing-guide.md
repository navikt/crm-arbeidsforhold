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

## Steg 1: Slå på eksplisitt mock

Mock-modus kan setjast i Setup under Custom Settings, `P360 Integration Setting`:

- `Use Mock Transport` = `true`
- `Named Credential Name` kan stå tomt i mock-modus

Eller køyr det repo-eigde smoke-scriptet:

```bash
sf apex run \
  --target-org crm-arbeidsforhold \
  --file scripts/apex/p360MockArchiveFlow.apex
```

Scriptet opprettar også testdata og dispatchar scheduler. Det skal ikkje gjere eit live callout.

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
sf apex run \
  --target-org crm-arbeidsforhold \
  --file scripts/apex/p360MockArchiveFlow.apex
```

Forventa output inneheld tre ID-ar:

- Application-ID
- ContentVersion-ID
- ApplicationDocument-jobb-ID

ContentVersion-triggeren opprettar i tillegg ApplicationAttachment-jobben. Begge jobbane skal ha `Pending` før scheduler claimar dei.

## Steg 4: Sjå jobbstatus før og etter worker

Køyr denne queryen etter smoke-scriptet:

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
