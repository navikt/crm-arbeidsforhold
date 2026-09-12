# Lokal implementasjonsstatus mot Jira

Oppdatert 2026-09-12 frå repository og verifiserte Salesforce-testkøyringar.

Dette dokumentet er repo-eigd status og ikkje ei speilkopi av Jira. Kolonnen «Jira-status» må oppdaterast frå Jira når integrasjonen er kopla til. «Lokal evidens» seier berre kva som kan dokumenterast frå kode, metadata og testar.

## Status per Jira-historie

| Jira              | Lokal status                                      | Evidens                                                                                                      | Restarbeid                                                               |
| ----------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| CRMAAREG-89 / F2  | Fullført som avgrensa skeleton- og kontraktgrense | Interfaces, adapter, RPC-klient, domenegrenser, orchestrator og kontrollerte exceptions med fokuserte testar | Produksjonsflyt ligg i seinare historier                                 |
| CRMAAREG-101 / F3 | Delvis                                            | Case-, Document-, File- og fleire delkontrakt-DTO-ar med serialiseringstestar                                | Salesforce context-klassar, UpdateDocument og full komposisjon manglar   |
| CRMAAREG-121 / F5 | Delvis                                            | Base-, contract-, transport-, auth-, timeout-, retryable-, mapping- og config-exceptions med hierarkitest    | Endeleg feilmodell og manglande Jira-namna exceptions må avklarast       |
| CRMAAREG-129 / F6 | Delvis                                            | `CorrelationContext` og `IntegrationLogContext` med testar                                                   | Strukturert logger, transportpropagering, persistens og maskeringspolicy |
| CRMAAREG-135 / F7 | Delvis                                            | `P360_TestDataFactory`, builders, stub adapter og RPC-testdobbel                                             | Dei Jira-namngitte fake-servicene og base test class finst ikkje         |
| CRMAAREG-268 / R1 | Delvis, intern Salesforce-slice fullført          | Fire deterministiske nøkkelformat, unik metadata og idempotent `ApplicationDocument`-jobb                    | Ekstern P360 duplicate/recovery og andre jobbtypar                       |
| CRMAAREG-274 / R2 | Design og metadata                                | Status-, retry-, lease- og manuell-oppfølgingsfelt finst                                                     | Worker, scheduler, klassifisering, statusservice og runbook              |
| CRMAAREG-296 / T1 | Delvis, omfattande                                | P360-testsuite med alle P360-testklassar; DTO-, grense-, release-, metadata-, idempotens- og jobbtestar      | Mapper- og komplette produksjonsflytar manglar                           |
| CRMAAREG-310 / D1 | Delvis, vesentleg oppdatert                       | ADR-ar, datamodell, denne statusen og teknisk oversikt med arkitektur- og sekvensdiagram                     | Ende-til-ende diagram må oppdaterast når worker og transport finst       |

## Verifiserte leveransar

### Frigiving og låsing

- MyTriggers-registrering for `Application_Decision__c` før insert og update.
- Custom permission `P360_Archive_Release`.
- Einvegs frigivingssignal og låsing av ordinære felt.
- Dry-run `0AfRR00000g2QhN0AU`: 11/11 komponentar og 5/5 fokuserte testar.

### Idempotens og jobboppretting

- `P360_IdempotencyKey` for fire arkivhendingar.
- `P360_ArchiveJobService` for idempotent `ApplicationDocument`-jobb.
- `P360_Archive_Job_Processing` med avgrensa tilgang.
- Deploy `0AfRR00000g2PtN0AU`: 27/27 komponentar og 4/4 testar.
- Test run `707RR00001XtOIQ`: 4/4 testar, 84 prosent service-dekning og 100 prosent key-dekning.

## Jira-oppdateringar som bør gjerast

Når Jira-tilkopling er tilgjengeleg:

1. Kommenter CRMAAREG-89 med at den avgrensa F2 skeleton-kontrakten er implementert og testdekt.
2. Oppdater CRMAAREG-101, 121, 129, 135, 268, 274, 296 og 310 med tabellen over.
3. Ikkje marker CRMAAREG-268 heilt ferdig før eigar avgjer om historia omfattar ekstern P360-deduplisering.
4. Ikkje marker CRMAAREG-274 ferdig før worker/retry/manuell oppfølging finst.
5. Registrer og kvalitetssikre avhengigheitene spora i GitHub #998.

Jira vart ikkje endra 2026-09-12 fordi Jira-provider ikkje var kopla til GitKraken i utviklingsmiljøet.
