# Lokal implementasjonsstatus mot Jira

Oppdatert 2026-09-12 frå gjeldande arbeidskopi og verifiserte Salesforce-køyringar.

Dette dokumentet er repo-eigd teknisk evidens og ikkje ei speilkopi av Jira. Jira vart manuelt oppdatert 2026-09-12, og statusane vart stadfesta gjennom CSV-eksport 2026-09-13. Seinare statusendringar skal gjerast i Jira først og hentast inn gjennom ein ny eksport; denne fila skal berre dokumentere det som kan verifiserast frå kode, metadata og testar.

Eksporten viser 3 ferdige, 13 under arbeid og 18 backlog-historier. På epicnivå er 7 under arbeid og 4 i backlog.

## Status per Jira-historie

| Jira              | Jira-status 2026-09-13 | Lokal teknisk status                              | Evidens                                                                                                      | Restarbeid                                                               |
| ----------------- | ---------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| CRMAAREG-89 / F2  | Ferdig                 | Fullført som avgrensa skeleton- og kontraktgrense | Interfaces, adapter, RPC-klient, domenegrenser, orchestrator og kontrollerte exceptions med fokuserte testar | Produksjonsflyt ligg i seinare historier                                 |
| CRMAAREG-101 / F3 | Under arbeid           | Delvis                                            | Case-, Document-, File- og fleire delkontrakt-DTO-ar med serialiseringstestar                                | Salesforce context-klassar, UpdateDocument og full komposisjon manglar   |
| CRMAAREG-121 / F5 | Under arbeid           | Delvis                                            | Base-, contract-, transport-, auth-, timeout-, retryable-, mapping- og config-exceptions med hierarkitest    | Endeleg feilmodell og manglande Jira-namna exceptions må avklarast       |
| CRMAAREG-129 / F6 | Under arbeid           | Delvis                                            | `CorrelationContext` og `IntegrationLogContext` med testar                                                   | Strukturert logger, transportpropagering, persistens og maskeringspolicy |
| CRMAAREG-135 / F7 | Under arbeid           | Delvis                                            | `P360_TestDataFactory`, builders, stub adapter og RPC-testdobbel                                             | Dei Jira-namngitte fake-servicene og base test class finst ikkje         |
| CRMAAREG-268 / R1 | Under arbeid           | Delvis, intern Salesforce-slice fullført          | Fire deterministiske nøkkelformat, unik metadata og idempotent `ApplicationDocument`-jobb                    | Ekstern P360 duplicate/recovery og andre jobbtypar                       |
| CRMAAREG-274 / R2 | Under arbeid           | Design og metadata                                | Status-, retry-, lease- og manuell-oppfølgingsfelt finst                                                     | Worker, scheduler, klassifisering, statusservice og runbook              |
| CRMAAREG-296 / T1 | Under arbeid           | Delvis, omfattande                                | P360-testsuite med alle P360-testklassar; DTO-, grense-, release-, metadata-, idempotens- og jobbtestar      | Mapper- og komplette produksjonsflytar manglar                           |
| CRMAAREG-310 / D1 | Ferdig                 | Fullført for gjeldande D1-scope                   | ADR-ar, teknisk oversikt og 12 lenka komponent-, sekvens-, status- og relasjonsdiagram                       | Dokumenta må vidareførast når worker og transport blir implementerte     |

## Verifiserte leveransar

### Frigiving og låsing

- MyTriggers-registrering for `Application_Decision__c` før insert og update.
- Custom permission `P360_Archive_Release`.
- Einvegs frigivingssignal og låsing av ordinære felt.
- Release-guarden er non-bypassable, og release-settet gir ikkje ekstra objekt-CRUD.
- Dry-run `0AfRR00000g2QhN0AU`: 11/11 komponentar og 5/5 fokuserte testar.
- Desse siste release-hardening-endringane er ikkje dokumenterte som permanent deploya i dette dokumentet.

### Idempotens og jobboppretting

- `P360_IdempotencyKey` for fire arkivhendingar.
- `P360_ArchiveJobService` for idempotent `ApplicationDocument`-jobb.
- `P360_Archive_Job_Processing` med avgrensa tilgang.
- Deploy `0AfRR00000g2PtN0AU`: 27/27 komponentar og 4/4 testar.
- Test run `707RR00001XtOIQ`: 4/4 testar, 84 prosent service-dekning og 100 prosent key-dekning.

### Samla teststatus

- P360-testsuiten inneheld 44/44 P360-testklassar i gjeldande arbeidskopi.
- Heile 44-klassarsuiten er ikkje dokumentert som køyrd samla etter dei siste endringane.
- Dei verifiserte ID-ane over gjeld dei oppførte fokuserte slicene, ikkje ein full ende-til-ende P360-test.

## Vidare statusforvaltning

- Jira er autoritativ kjelde for arbeidsstatus, ansvar og prioritering.
- Repoet er autoritativ kjelde for teknisk evidens, arkitektur og testresultat.
- `docs/context/p360/jira-*` er spegel-/kontekstfiler og skal oppdaterast frå ein ny Jira-eksport, ikkje gjennom manuell parallell statusføring.
- Ekstern P360-deduplisering og recovery må framleis avklarast før den delen av CRMAAREG-268 kan reknast som ferdig.
- Worker, retry og manuell oppfølging må implementerast før CRMAAREG-274 kan reknast som teknisk ferdig.
