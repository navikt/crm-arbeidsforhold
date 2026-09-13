# P360 mock-flyt: stegvis brukar-/org-test

Denne testen køyrer P360-flyten utan live integrasjon. Han skal kunne brukast i scratch org og sandbox.

## Føresetnader

- Du er innlogga i target-org.
- Koden er deploya til orgen.
- Du har tilgang til Setup og kan tildele permission sets.
- Ingen secrets, tokens, cookies eller ekte persondata skal brukast i testen.

## Steg 1: Slå på mock-modus

I Setup, opne Custom Settings og `P360 Integration Setting`. Opprett eller oppdater org-default:

- `Use Mock Transport` = `true`
- `Named Credential Name` kan stå tomt i mock-modus

Mock-modus er eksplisitt. Han blir ikkje slått på automatisk dersom ekte transport feilar.

## Steg 2: Tildel tilgang

Tildel `P360_Integration_User` til test-/integrasjonsbrukaren. Gruppa samlar jobbtilgang, code-table-lesing og RPC/config-tilgang.

## Steg 3: Køyr fokuserte testar

```bash
sf apex run test --tests P360_AdapterFactoryTest --target-org <org-alias> --result-format human --synchronous
sf apex run test --tests AAREG_ApplicationToP360CaseMapperTest --target-org <org-alias> --result-format human --synchronous
sf apex run test --tests AAREG_CreateDocumentMapperTest --target-org <org-alias> --result-format human --synchronous
sf apex run test --tests AAREG_DecisionDocumentMapperTest --target-org <org-alias> --result-format human --synchronous
sf apex run test --tests AAREG_FileMapperTest --target-org <org-alias> --result-format human --synchronous
sf apex run test --tests P360_ArchiveJobClaimServiceTest --target-org <org-alias> --result-format human --synchronous
sf apex run test --tests P360_ArchiveJobWorkerTest --target-org <org-alias> --result-format human --synchronous
sf apex run test --tests AAREG_ArchiveApplicationOrchestratorTest --target-org <org-alias> --result-format human --synchronous
```

## Forventa resultat

- Factory-testen viser at `Use_Mock_Transport = true` vel `P360_StubArchiveAdapter`.
- CreateCase-testen returnerer `Aa-registerSalesForce`, status `B`, type `Sak`, tilgang `U` og ClassCode `359`.
- Søknadsdokument-testen returnerer `Saksdokument`, `J`, `U` og `Alle ansatte i Nav`.
- Vedtaksdokument-testen returnerer `Sak`, `Dokument ut`, `J`, `U` og `Alle ansatte i Nav`.
- File-testane viser base64-data i `request.files`, utan callout.
- Worker-testane viser `Pending -> In Progress -> Succeeded/Failed/Manual Review` med lease og backoff.
- Orchestrator-testen viser stub-respons utan HTTP-callout.

## Steg 4: Test faktisk jobb-flyt

Køyr anonym Apex som admin/testbrukar for å opprette og prosessere ein mock-jobb:

```apex
Access_Request__c accessRequest = new Access_Request__c();
insert accessRequest;
Application__c application = new Application__c(Access_Request__c = accessRequest.Id);
insert application;

P360_Archive_Job__c job = P360_ArchiveJobService.getOrCreateApplicationDocumentJob(
    accessRequest.Id,
    application.Id,
    'USER-TEST-' + application.Id
);
List<Id> claimedIds = P360_ArchiveJobClaimService.claimNextBatch(1);
System.enqueueJob(new P360_ArchiveJobWorker(new Set<Id>(claimedIds)));
System.debug('Claimed job: ' + job.Id);
```

Etter queueable-jobben er ferdig, sjekk jobben i Developer Console eller Query Editor:

```sql
SELECT Id, Status__c, Attempt_Count__c, Lease_Expires_Date__c,
       Last_Error_Code__c, Last_Error_Message__c
FROM P360_Archive_Job__c
ORDER BY CreatedDate DESC
LIMIT 1
```

Forventa status i mock-modus er `Succeeded`.

## Steg 5: Slå av mock-modus etter testen

Oppdater org-default Custom Setting:

- `Use Mock Transport` = `false` i miljø som skal bruke ekte transport
- I scratch org/sandbox kan han stå `true` så lenge orgen ikkje skal teste live P360

## Feilsøking

- `sObject type ... not supported`: sjekk at testbrukaren har relevant Permission Set/Group.
- `P360_MissingCodeTableMappingException`: sjekk at `P360_Code_Table_Value__mdt`-recorden er deploya og aktiv.
- `P360_ContractException` frå ekte adapter: mock-modus er truleg ikkje slått på, eller testen brukar direkte `P360_ArchiveAdapter` med vilje.
- Ingen jobb blir claima: sjekk status, `Next_Attempt_Date__c` og at jobben ikkje allereie er `Succeeded`/`Manual Review`.

Denne testen beviser intern mock-flyt. Han beviser ikkje at ekte P360 endpoint, auth, wire-format, upload eller feilkodar fungerer.
