# P360 teknisk oversikt

Status per 2026-10-04. P360 runtime-koden er i `main` etter PR #1094; den avgrensa felles loggeren kom inn med PR #1097, og worker-feilkoplinga kom med PR #1102. Produksjonsbehandling er framleis av som standard, og ekte SIF-transport er ikkje ferdig.

## Statusnøklar

| Status                        | Meining                                                                                   |
| ----------------------------- | ----------------------------------------------------------------------------------------- |
| Implementert og CI-verifisert | Kode er i `main`, og relevant PR-kontroll har bestått.                                    |
| Scratch-verifisert            | Test eller deployment er køyrd i det godkjende scratch-org-et; run-ID/evidens er oppgitt. |
| Kontraktgrense                | Intern kontrakt er testa, men produksjonskoplinga stoppar kontrollert.                    |
| Avventar avklaring            | Krev godkjend fag-, P360-, sikkerheits- eller driftsavgjerd.                              |

## Implementert i main

- `P360_Archive_Processing` bruker `FeatureToggleBase.getFeatureFlag` og er fail-closed. Metadata-defaulten er `false`; manglande/null setting, lookup-feil eller ikkje-tom `Required_Custom_Permission__c` held prosessering av.
- `P360_ContentVersionArchiveHandler` opprettar `ApplicationAttachment`-jobb for Application-publiserte filer berre når prosessering er slått på.
- `P360_ArchiveGuardHandler` brukar gate rundt P360-validering/låsing og opprettar `DecisionDocument`-jobb etter at eit vedtak blir frigjeve med gyldig brukarrett.
- `P360_ArchiveJobService` støttar idempotent oppretting av `ApplicationDocument`, `ApplicationAttachment`, `DecisionDocument` og `AgreementDocument`.
- `P360_ArchiveJobClaimService`, `P360_ArchiveJobScheduler` og `P360_ArchiveJobWorker` støttar claim/lease, dispatch, retryklassifisering og manuell oppfølging. Workeren sjekkar gate på nytt og returnerer ein claim utan å bruke opp forsøk dersom behandling er slått av.
- `P360_Archive_Release` er brukarautorisasjon. `AAREG_Arbeidsforhold_Saksbehandling` gir vanleg les/skriv-FLS til frigjevingsfeltet; P360-guarden krev framleis den separate custom permission-en når gate er på.
- DTO-ar, mapper, domenegrenser, mock-adapter, logging-/korrelasjonsgrunnlag, Custom Metadata-kodeverk og P360-testsuite ligg i repoet. Worker-feil blir logga med avgrensa teknisk kontekst; dette er ikkje ende-til-ende-korrelasjon gjennom SIF.

## Faktisk kopling per arkivhending

| Hending                 | Automatisk inngang i dag                                                      | Kva som framleis manglar                                                                                |
| ----------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `ApplicationAttachment` | Application-publisert `ContentVersion` utløyser jobb når gate er på.          | Godkjend storleiksgrense, upload-kontrakt og live filtransport.                                         |
| `DecisionDocument`      | Gyldig overgang av `Ready_For_P360_Archive__c` opprettar jobb når gate er på. | Endeleg vedtaksfeltmapping, SIF-svar og live transport.                                                 |
| `ApplicationDocument`   | Jobbservice kan opprette jobben; smoke-flyten kallar service eksplisitt.      | Godkjend forretningshending som automatisk skal opprette jobben, komplett mapping og live transport.    |
| `AgreementDocument`     | Jobbservice kan opprette jobben.                                              | Produkteigar må avgjere om avtaledokument er i MVP, kva hending som utløyser det, og godkjenne mapping. |

`P360_ArchiveJobScheduler` er ein schedulable klasse, ikkje ein oppretta org-cron. Produksjonsfrekvens, overlapp, driftsvakt og trygg pause/gjenopptaking er ikkje fastsette.

## Kontraktgrensa mot SIF

`P360_ArchiveAdapter` og `P360_RpcClient` er interne grenser. Reell endpoint, RPC-envelope, operasjonsnamn, headers, autentisering og miljøkonfigurasjon er ikkje godkjende; klienten stoppar kontrollert i staden for å gjette. `Use_Mock_Transport__c=true` vel stub-adapter i utvikling, medan `false` ikkje er ein trygg aktiveringsmekanisme før live-kontrakten er implementert og godkjend.

Følgjande eksterne avgjerder blokkerer live-flyten:

- [#1017](https://github.com/navikt/crm-arbeidsforhold/issues/1017): endpoint, RPC og autentisering.
- [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016): Salesforce-til-SIF-mapping, kodeverdiar, dataomfang og personvern.
- [#1018](https://github.com/navikt/crm-arbeidsforhold/issues/1018): filformat, storleik, upload og delvis-feil-handtering.
- [#1015](https://github.com/navikt/crm-arbeidsforhold/issues/1015): ekstern idempotens, duplicate-semantikk, retry og recovery.
- [#993](https://github.com/navikt/crm-arbeidsforhold/issues/993) og [#994](https://github.com/navikt/crm-arbeidsforhold/issues/994): harmonisering av exception-/namnestandard med Jira/ADR.

## Målarkitektur

Berre godkjende forretningshendingar skal gå gjennom denne flyten. Mappere og domenegrenser byggjer SIF-requestar etter godkjend mapping; jobbtabellen er kjelda for teknisk status, ikkje P360-ID-felta.

```text
Godkjend Salesforce-hending
    -> domain context og godkjend mapper
    -> idempotent P360_Archive_Job__c
    -> gated scheduler og lease/claim
    -> worker, retry og manuell recovery
    -> adapterkontrakt
    -> RPC-klient / godkjend Named Credential
    -> P360/SIF
```

Før produksjon må målarkitekturen også ha avtalt retry/duplicate-kontrakt, external-ID-oppslag, overvaking, runbook og eigarskap. Full målscope og fasar ligg i [completion roadmap](../../../.github/specs/p360-completion-roadmap.md).

## Verifikasjon

- PR #1094: metadata compile, Apex tests, 85% coverage gate og Jest/Prettier bestod på merged head.
- PR #1097: Jest/Prettier, metadata compile, Apex tests, coverage, setup og cleanup bestod før merge.
- P360 Apex suite etter loggerendringen i godkjent scratch-org: 90/90 bestod (test run `707QI00001IdqiI`).
- Logger, context og redactor etter loggerendringen: 6/6 bestod (test run `707QI00001IdNeK`).
- PR #1102: worker-testklassen bestod 6/6 i godkjent scratch-org (test run `707QI00001IeSQt`); Jest/Prettier, metadata compile, Apex tests, coverage, setup og cleanup bestod i CI.
- Post-merge mock smoke `npm run test:p360:mock` bestod: to jobbar (`ApplicationDocument`, `ApplicationAttachment`) vart `Succeeded` med eitt forsøk, worker vart `Completed` utan feil, ingen duplikatnøklar og ingen live-callout. Evidensen står i #1092.
- Etter testen er `P360_Archive_Processing=false`, `Use_Mock_Transport__c`-org-default og mellombels permission assignment fjerna, og smoke-data kontrollert sletta.
- Den tidlegare full-deploy-kommandoen med `--ignore-errors` tel ikkje som komponentvis deploy-evidens.

## Logging og neste kopling

PR #1097 har mergea `IntegrationLogger.logFailure(IntegrationLogContext)` til `main`, og #1096 er lukka. Helperen persisterer berre system, operasjon, status og ein validert opaque correlation-ID gjennom `LoggerUtility`. PR #1102 koplar workeren sitt kontrollerte exception-path til loggeren med faste labels (`P360`, `ArchiveJob`, `Failed`) og jobbens correlation-ID. Kallet er best-effort; exception-melding og request-/response-payload blir ikkje sende til loggeren. Dette stadfestar ikkje live transportkorrelasjon eller komplett ende-til-ende-logging.

## Trygg aktiveringsrekkjefølgje

1. Hald flagget av som normaltilstand.
2. #1092 er fullført i godkjend scratch/sandbox; ved framtidig re-validering skal feature-flagget setjast tilbake til `false` etter testen.
3. Lukk eksterne kontrakt- og mappingavgjerder og implementer dei avtalte flytane med focused tests.
4. Valider scheduler, worker, retry, logging, tilgang og recovery i godkjend ikkje-produksjonsmiljø.
5. Skaff eksplisitt eigar-/sikkerheits-/driftsgodkjenning før separat produksjonsdeploy eller aktivering via #1093.
