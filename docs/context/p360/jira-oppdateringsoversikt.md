# Jira-oppdateringsoversikt for P360

Oppdatert 2026-09-14. Dette er ein Jira-klar statuspakke basert på verifisert kode, metadata og scratch-org testar. Statusane skil mellom intern teknisk slice og full ende-til-ende leveranse.

## Klar for Jira-statusoppdatering

| Jira/tema                     | Føreslått status            | Jira-kommentar/evidens                                                                                                                                                                                                                                                                                                                     |
| ----------------------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| CRMAAREG-89 / F2              | Ferdig                      | Intern grunnmur er implementert: interfaces, adaptergrense, RPC-grense, orchestrator-validering og mock-kompatibel request/response-kopling. Application- og Agreement-domain context er typed og schema-safe på verifiserte record-ID-ar. Testar: orchestrator 3/3, domain 4/4. Ekte transport og full mapping er ikkje del av F2-slicen. |
| CRMAAREG-143 / K1             | Ferdig intern slice         | `P360_Code_Table_Value__mdt` og 10 ikkje-sensitive standardrecordar er deploya. `P360_Code_Table_Access` er lagt i `P360_Integration_User`. Deploy `0AfQI00000jLALp0AO`, lookup-test 2/2. Konkrete Salesforce-feltmappingar utover `Default`-profilen ligg i #1016.                                                                        |
| CRMAAREG-155 / K2             | Ferdig intern slice         | `P360_ICodeTableService`, `P360_CodeTableMetadataService`, per-transaksjon-cache og kontrollert missing-mapping-feil er implementert. Treff og manglande mapping er testa. Jira-namna må harmoniserast med `P360_`-standarden, jf. #994.                                                                                                   |
| CRMAAREG-163 / K3 / #996      | Avgjort / klar for lukking  | Constructor injection er valt. `P360_AdapterFactory` er composition root; ingen service locator skal byggjast. Dette er dokumentert i `docs/integrations/p360/di-og-adapterval.md` og verifisert av factory-testar.                                                                                                                        |
| #993 / F5 + R2 retry-grunnmur | Intern avgjerd implementert | `isRetryable`/`withRetryable(Boolean)` og `P360_RetryableException` er implementert og testa. R2 claim/lease/worker/statusklassifisering er implementert mot stub med 8/8 testar grøne. P360-spesifikke feilkodar og duplicate-semantikk står framleis opne mot P360.                                                                      |
| CRMAAREG-129 / F6             | Intern logging-slice ferdig | Redaksjon, correlation-ID og `Application_Log__c`-persistens via `LoggerUtility` er verifisert. HTTP-transportpropagering står open.                                                                                                                                                                                                       |
| CRMAAREG-115 / F4             | Delvis, mock-slices ferdige | CreateCase-, søknadsdokument-, vedtaksdokument- og file-parameter-mapper er implementert med godkjende standardverdiar. Live transport, ContentVersion-henting og komplett Salesforce-feltmapping manglar.                                                                                                                                 |
| X1 / CRMAAREG-255             | Intern lagring ferdig       | Eksisterande Text-felt for case-, document- og file-ID-ar er dokumentert som lagringsmodell. Endeleg P360-format/eigarskap må stadfestast før ekstern recovery.                                                                                                                                                                            |

## Skal framleis stå opne

| Sak      | Kvifor open                                                                                                                                        |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| #1016    | Standardkodeverk er lagt inn, men full Salesforce-feltmapping, obligatoriske felt, kondisjonelle verdiar og personvernvurdering er ikkje komplett. |
| #1017    | Mock-modus gjer utvikling mogleg. Live Named Credential/External Credential og ekte RPC-verifisering er ikkje aktivert i repoet.                   |
| #1018    | Mock-filer kan leggjast i CreateDocument-payload, men ContentVersion, storleik, upload-endpoint og cleanup/retry er ikkje implementert.            |
| #1015    | Intern retry/backoff/lease er implementert. P360 duplicate-, timeout-, feilkode- og recovery-semantikk er ikkje endeleg verifisert.                |
| F7       | TestDataFactory/stubbar finst, men Jira sine fire Fake-serviceklassar manglar produksjonsinterfaces å implementere.                                |
| O2/D2/T2 | Scheduler, drift/runbook og ekte integrasjonstest krev endeleg transport- og driftsavklaring.                                                      |

## Lukking

Repoet kan ikkje lukke Jira/GitHub-saker automatisk frå denne fila. For saker merkte «klar for lukking» bør Jira-eigar oppdatere status etter å ha kontrollert evidenslenkene. Saker med ekstern avhengigheit skal ikkje lukkast berre fordi mock-slicen er grøn.

## Evidens

- [Lokal implementasjonsstatus](lokal-implementasjonsstatus.md)
- [Teknisk oversikt](../../integrations/p360/teknisk-oversikt.md)
- [F2 validation spec](../../../.github/specs/p360-f2-validation-status.md)
- [Orchestrator validation spec](../../../.github/specs/p360-orchestrator-validation.md)
- [User testing guide](../../integrations/p360/user-testing-guide.md)
