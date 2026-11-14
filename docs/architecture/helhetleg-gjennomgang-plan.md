# Plan: heilskapleg gjennomgang av Arbeidsforhold / Aa-registeret

**Status:** planlagd, ikkje gjennomført
**Spec:** [helhetleg-gjennomgang-aaregisteret.md](../../.github/specs/helhetleg-gjennomgang-aaregisteret.md)
**Arbeidsmodell:** GitHub Issues er system of record for deloppgåver og akseptanse.

## Mål

Byggje ei komplett, samanhengande og kjelde-/evidensforankra oversikt over produktet, avhengnadene, scratch-org-tilstanden, alle funksjonar og scenario, og testane som kan verifisere dei. Avslutt med ei prioritert tiltaks-/oppryddingsliste og ein dokumentasjonspakke som bevarer gjeldande informasjon fram til kvar endring er godkjend.

## Startpunkt og attståande evidens

Følgjande eksisterande arbeid er inngangsmateriale, ikkje fullført verifikasjon:

- [Kjeldekart og teststrategi](arbeidsforhold-kjeldekart-og-teststrategi.md) med kjedekart, datarelasjonar, tidlegare org-funn og scenarioforslag.
- [Eksisterande heilskapleg analyse](helhetleg-analyse-og-teststrategi.md) ligg allereie endra i arbeidskopien; les og samanlikn han før vidare dokumentarbeid, men ikkje overskriv eller rydd han i denne planen utan særskild avklaring.
- [Heile løysinga: arkitektur og flyt](hele-loysinga.md) og [pakkeavhengigheiter](pakkeavhengigheiter.md), inkludert 19 direkte dependency-pakkar.
- [Flow-katalog](aareg-flow-katalog.md) og [grupperte Flow-diagram](aareg-flow-diagrammer.md) med 37 Flow-definisjonar.
- [P360-kartlegging](../integrations/p360/kartlegging-av-dagens-flytar.md), P360-spesifikasjonar og aktiv [Issue #1095](https://github.com/navikt/crm-arbeidsforhold/issues/1095).
- Aktiv P360-dokumentasjons-Issue [#983](https://github.com/navikt/crm-arbeidsforhold/issues/983), runbook-eigar-Issue [#997](https://github.com/navikt/crm-arbeidsforhold/issues/997), og tidlegare, historisk scratch-verifikasjon [#1092](https://github.com/navikt/crm-arbeidsforhold/issues/1092).

Org-funn, tidlegare testresultat og issue/Jira-status er tidsavgrensa evidens. Dei må ikkje presenterast som ferske runtime- eller integrasjonsresultat.

## Arbeidsprinsipp og stop gates

1. **Evidens før konklusjon:** merk kvar opplysning som kjelde, køyrd test, org-observasjon, historisk evidens, inferens eller uavklart avgjerd.
2. **Org-sikkerheit:** arbeid i eksisterande `crm-arbeidsforhold` scratch-org krev ikkje ny brukargodkjenning. Verifiser eksplisitt mål og scratch-type før handling og respekter native verktøygodkjenningar. Bruk Salesforce CLI 2.158.7 på macOS-hostterminalen. Ikkje køyr autentiserte kommandoar i `cplt`; ikkje bruk produksjon eller annan org i denne kartlegginga.
3. **Least-data:** bruk aggregerte metadata/status-oppslag. Ikkje les tokens, secrets, Named Credential-innhald, reelle personopplysningar eller forretningsrecordar når teljing/metadata er nok.
4. **Read-only fyrst:** gjennomgang og inventar endrar ikkje Salesforce-metadata, org-data, feature flags, pakker eller eksterne system.
5. **Pakkeeigarskap:** les dependency-pakkar for kontrakt og bruk, men ikkje endre dei utan eksplisitt godkjenning frå eigar.
6. **Bevar før rydding:** ingen sletting, rename, flytting eller arkivering før klassifisering, originalkopi/kjelde, dependency-/lenkekontroll, rollback og eigargodkjenning er dokumentert.
7. **Separate løysings-Issues:** kodefiks, deploy, pakkeoperasjon og eksterne integrasjonstestar blir eigne, avgrensa arbeid etter funn og godkjenning.

## Fasar, oppgåver og avhengnader

### Fase 0 — Ramme og evidensregister

- [ ] T001 [Plan:0.1] Opprett hovud-Issue og del-Issues; lenk aktivt arbeid i staden for å kopiere P360-saker.
- [ ] T002 [Plan:0.2] Fastset evidensmal: påstand, kjelde/fil eller query, dato, mål, resultat, sensitivitet, avgrensing og status.
- [ ] T003 [Plan:0.3] Registrer kjende artefaktar og uferdig worktree-arbeid; ikkje overskriv dokument som finst frå før.

**Utgang:** scope, kjelder, godkjenningsgrenser og sporbar Issue-struktur er synlege.

### Fase 1 — Repository, produktfunksjonar og package-kart

Avhengnad: Fase 0.

- [ ] T004 [Plan:1.1] Inventer alle Salesforce-produktkjelder: Apex, LWC/Aura/Visualforce, Flow, triggers, objects/fields, permission sets, custom metadata/settings, Experience Cloud routes, labels og schedulering.
- [ ] T005 [Plan:1.2] Knyt kvar brukarhandling/systeminngang til implementasjon, test, metadata og sentrale relasjonar; skil mellom aktiv funksjon, ubrukt/obsolete kjelde og ukjend runtime-bruk.
- [ ] T006 [Plan:1.3] Inventer alle 19 direkte pakkedependencies og relevante transitive krav; kartlegg API/metadata som produktet brukar og eigarskap.
- [ ] T007 [Plan:1.4] Kartlegg alle integrasjonsgrenser og kjende contract gaps: Altinn, distribusjonstilgang, P360, e-post/SMS, filer og andre funne callouts/events.
- [ ] T008 [Plan:1.5] Sammenstill eksisterande docs/specs/issues og marker autoritativ kjelde, dato, status, overlapp og dokumentasjonsgap.

**Utgang:** funksjons-/kjeldekart og dependency-/eigaroversikt med kjeldepeikarar; ingen dependency-kode endra.

### Fase 2 — Scratch-org status og source/runtime samanlikning

Avhengnad: Fase 1. Kvar kommando krev fersk godkjenning av det eksakte målet `crm-arbeidsforhold` og handlinga.

- [ ] T009 [Plan:2.1] Utarbeid minimal lesande query-matrise for org-versjon, installerte pakkar, aktive Flow-versjonar, relevante schedulers/jobs, flagg og aggregerte assignments.
- [ ] T010 [Plan:2.2] Verifiser eksplisitt scratch-mål før CLI-køyring utan ny brukargodkjenning i `crm-arbeidsforhold`; loggfør faktisk kommando/resultat og stoppeffekt ved native verktøyavslag eller auth-blokkering.
- [ ] T011 [Plan:2.3] Samanlikn org-tilstand med source metadata og deklarerte dependencies; dokumenter avvik og kva oppslaget ikkje kan bevise.
- [ ] T012 [Plan:2.4] Ikkje utfør DML, testdataoppretting, deployment, package installation, flagg-/permission-endring eller eksterne kall i denne fasen.

**Utgang:** datert, sensitivt-minimal org-snapshot og source/runtime-gap-liste. Viss tilgang/approval manglar, marker punktet blokkert; ikkje erstatt det med inferens.

### Fase 3 — Funksjonelle reiser og komplett scenarioinventar

Avhengnader: Fasar 1–2.

- [ ] T013 [Plan:3.1] Kartlegg eksterne reiser: identitet/verksemd, tilgang, søknad/utkast/vedlegg, avgjerd, avtale og dialog.
- [ ] T014 [Plan:3.2] Kartlegg interne reiser: saksfordeling, status, meir informasjon, frist, kommentar, vedtak/PDF, avtaleendring og tilgangsoppfølging.
- [ ] T015 [Plan:3.3] Kartlegg systemreiser: Altinn scenario/feil, distribution PUT/DELETE, e-post/SMS, filbehandling, scheduled Flow, cleanup og P360 job/lifecycle.
- [ ] T016 [Plan:3.4] Lag scenariomatrise med positive, negative, tilgangs-, validerings-, feil-, retry-/async-, duplikat-, data-isolasjon- og operasjonelle tilfelle.
- [ ] T017 [Plan:3.5] Spor kvart scenario til Flow/API/UI/metadata og eksisterande eller manglande Jest/Apex/org-/mock-/manuell evidens.

**Utgang:** alle synlege funksjonar har minst eitt normal- og relevant feil-/tilgangsscenario; ingen scenario vert kalla verifisert utan testbevis.

### Fase 4 — Testdata og scenario-for-scenario testplan

Avhengnad: Fase 3.

- [ ] T018 [Plan:4.1] Definer syntetiske, deterministiske test-fixtures og relasjonsgraf for Account, Access Request, Application, basis, contacts, decisions, agreement, inquiry/thread/message, files og integration job.
- [ ] T019 [Plan:4.2] Definer aktør-/permission-matrise med minimumstilgang, rolle, eigarskap, ekstern verksemd A/B og positive/negative resource access.
- [ ] T020 [Plan:4.3] Skriv nøyaktige førebuings- og utføringssteg for kvart scenario, med UI-/API-/Flow-inngang, forventet resultat, asynkron venting, feilinjeksjon og cleanup.
- [ ] T021 [Plan:4.4] Knyt scenario til passande testmekanisme: Jest, Apex, metadata/deploy preview, mock contract, godkjend scratch smoke eller manuelt scenario. Merk blokkert/ikkje-køyrt tydeleg.
- [ ] T022 [Plan:4.5] Dokumenter rekkjefølgje, testvindauge og rollback av midlertidige flags, mock settings, permissions, schedules og syntetiske records.

**Utgang:** testdata-strategi og stegvis testplan der kvar rad kan gjennomførast og få PASS/FAIL/BLOCKED med sanert evidens.

### Fase 5 — Funn, prioritering og trygg opprydding

Avhengnader: Fasar 1–4.

- [ ] T023 [Plan:5.1] Samle funksjonsgap, sikkerheit/personvern, integrasjon, feilhandtering, testgap, docs-gap, drift og teknisk gjeld; skil verifisert funn frå spørsmål.
- [ ] T024 [Plan:5.2] Prioriter med påverknad, sannsyn/evidens, brukar-/driftskonsekvens, avhengnader, eigar, avgjerd og forslag til sjølvstendig Issue.
- [ ] T025 [Plan:5.3] Klassifiser eksisterande dokument som gjeldande, overlappande, historisk, Confluence-spegel eller arkivkandidat; verifiser alle inngåande lenker og eigarskap.
- [ ] T026 [Plan:5.4] Før eventuell arkivering: kopier original, registrer dato/grunn/erstatningsdokument/kjelde, få eigargodkjenning, oppdater lenker og verifiser rollback.
- [ ] T027 [Plan:5.5] Opprett separate Issues for godkjende kode-/metadatafiks; metadata-sletting/rename krev runbook og godkjend verifikasjonsplan.

**Utgang:** prioritert tiltaksbacklogg; ingen rydding som kan fjerne informasjon eller endre Salesforce-åtferd utan godkjent, sporbar endringsplan.

### Fase 6 — Dokumentasjonspakke, review og sign-off

Avhengnader: Fasar 1–5.

- [ ] T028 [Plan:6.1] Lag ny, repo-eigd inngangsside som bind saman eksisterande og nye dokument med tydeleg «start her»-navigasjon.
- [ ] T029 [Plan:6.2] Fullfør system-/funksjonskart, datagraf, dependency-/eigaroversikt, workflow/Flow-diagram og kjende integrasjons-/runtime-gap.
- [ ] T030 [Plan:6.3] Fullfør scenariooversikt, syntetisk testdatastrategi og testplan med konkrete teststeg og evidenskrav.
- [ ] T031 [Plan:6.4] Fullfør funn-/tiltaksregister, org-snapshot og arkivlogg; hald P360- og Confluence-/Jira-fasiten på sine autoritative stader.
- [ ] T032 [Plan:6.5] Kontroller relative lenker, duplikatinnhald, Mermaid, redaksjon av sensitivt materiale, evidensstatus og coverage mot REQ-001–REQ-009.
- [ ] T033 [Plan:6.6] Få review frå produkt-/domene-, plattform-/tilgangs-, integrasjons- og testansvarlege; registrer avvik og kvar opne avgjerd i Issue.

**Utgang:** navigerbar dokumentasjonspakke, dokumentert dekning/avgrensing og menneskeleg sign-off.

## Leveranseform for den samla dokumentasjonspakka

Nye målbaner som skal vurderast i fase 6; ikkje alle filer skal opprettast dersom eit eksisterande, korrekt dokument dekkjer behovet:

- `docs/architecture/aaregisteret-handbok.md` — inngang, systemkart, eigarskap og lenkjer.
- `docs/architecture/aaregisteret-funksjonsoversikt.md` — funksjonar etter brukar/arbeidsprosess, kjelde og verifikasjonsstatus.
- Eksisterande [Flow-katalog](aareg-flow-katalog.md), [Flow-diagram](aareg-flow-diagrammer.md) og [kjeldekart/teststrategi](arbeidsforhold-kjeldekart-og-teststrategi.md) — fullførast eller lenkjast; ikkje kopier same detaljar.
- `docs/testing/aaregisteret-testdata-strategi.md` — fixtures, roller, isolasjon, syntetiske data og cleanup.
- `docs/testing/aaregisteret-scenario-testplan.md` — alle scenariosteg, forventningar og testbevis.
- `docs/architecture/aaregisteret-funn-og-tiltak.md` — prioriterte gap og godkjende oppfølgings-Issues.
- `docs/operations/aaregisteret-scratchorg-status-<dato>.md` — berre sanert, dated evidence; secrets/PII/record contents er utelukka.
- `docs/archive/` — opprettast berre dersom stadfesta arkivkandidatar er repo-eigde. Bevar original, proveniens, erstatningsdokument, lenkjer og godkjenningsevidens for kvart element.

Confluence-spegel, Jira-export, operative runbooks og gjeldande P360-dokumentasjon skal ikkje kopierast inn som konkurrerande fasit; lenk til autoritativ kjelde og dokumenter dato/status.

## Scenario-radens obligatoriske mal

| Felt                    | Krav                                                                               |
| ----------------------- | ---------------------------------------------------------------------------------- |
| Scenario-ID / namn      | Stabil, unik og forretningsleseleg; eksisterande ID-ar blir bevarte ved utviding.  |
| Aktør / rolle           | Konkret brukar/systemrolle, sharing/permission og eigarskap.                       |
| Mål / forretningsutfall | Observerbart resultat, ikkje implementasjonsdetalj.                                |
| Føresetnader            | Org-/feature/config-status, record-state og avhengnader; merk godkjenningskrav.    |
| Testdata                | Syntetisk fixture, relasjonar og isolasjonsnøkkel; ingen verkelege persondata.     |
| Steg                    | Numererte UI/API-/Flow-/systemhandlingar i rett rekkjefølgje.                      |
| Forventa resultat       | UI, Salesforce-records, oppgåver/varsling, eventuelle kall og status.              |
| Negativ-/feilvariant    | Rolleavslag, ugyldige data, timeout, retry, duplikat eller delvis feil.            |
| Verifikasjonsmåte       | Jest/Apex/CLI-read-only/mock/manuell; eksakt kommando og godkjenning når relevant. |
| Evidens og status       | PASS/FAIL/BLOCKED/NOT RUN, dato, test-ID/output eller sanert skjermbilete.         |
| Opprydding              | Syntetiske records/config tilbakeførte og kontrollert; ikkje slett ukjend data.    |

## GitHub Issues

Hovud-Issue held samla akseptanse og status; kvar del-Issue har sjølvstendig leveranse og verifikasjon.

| Planområde                                   | Issue                                                                                                                       |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Overordna koordinering                       | [#1179 Heilskapleg produkt-, org- og testgjennomgang](https://github.com/navikt/crm-arbeidsforhold/issues/1179)             |
| Repository, funksjonskjelder og dependencies | [#1185 Kartlegg produktkjelde og pakkeavhengnader](https://github.com/navikt/crm-arbeidsforhold/issues/1185)                |
| Scratch-org runtime og source-samanlikning   | [#1182 Verifiser scratch-org runtime mot kjelda](https://github.com/navikt/crm-arbeidsforhold/issues/1182)                  |
| Arbeidsflytar og scenarioinventar            | [#1180 Kartlegg arbeidsflytar og alle funksjonsscenario](https://github.com/navikt/crm-arbeidsforhold/issues/1180)          |
| Syntetisk testdata og stegvis testplan       | [#1181 Lag syntetisk testdatastrategi og stegvis testplan](https://github.com/navikt/crm-arbeidsforhold/issues/1181)        |
| Prioritering, opprydding og arkiv            | [#1184 Prioriter funn og planlegg trygg dokumentasjonsopprydding](https://github.com/navikt/crm-arbeidsforhold/issues/1184) |
| Samla dokumentasjon og sign-off              | [#1183 Set saman og valider dokumentasjonspakka](https://github.com/navikt/crm-arbeidsforhold/issues/1183)                  |

Eksisterande [P360-roadmap #1095](https://github.com/navikt/crm-arbeidsforhold/issues/1095), [P360-kontraktdokumentasjon #983](https://github.com/navikt/crm-arbeidsforhold/issues/983) og [runbook-eigarskap #997](https://github.com/navikt/crm-arbeidsforhold/issues/997) blir vidareførte som autoritative arbeidsstraumar; dei blir ikkje erstatta av duplikat i denne gjennomgangen.

## Krav- og Issue-sporing

| Krav    | Planfasar | Oppgåver                          | GitHub Issue        |
| ------- | --------- | --------------------------------- | ------------------- |
| REQ-001 | 1, 3, 6   | T004, T005, T008, T028–T029, T032 | #1185, #1180, #1183 |
| REQ-002 | 1, 2, 6   | T006, T011, T029, T032            | #1185, #1182, #1183 |
| REQ-003 | 2, 6      | T009–T012, T031–T032              | #1182, #1183        |
| REQ-004 | 3, 6      | T013–T017, T029, T032             | #1180, #1181, #1183 |
| REQ-005 | 4, 6      | T018–T019, T022, T030             | #1181               |
| REQ-006 | 4, 6      | T020–T022, T030, T032             | #1181, #1183        |
| REQ-007 | 5, 6      | T023–T024, T027, T031             | #1184, #1183        |
| REQ-008 | 5, 6      | T025–T027, T031                   | #1184, #1183        |
| REQ-009 | 0, 6      | T001–T003, T028–T033              | #1179 + #1180–#1185 |

## Føresetnader og kjende grenser

- Bruk Salesforce CLI `2.158.7` frå hostterminalen; verifisert eksisterande `crm-arbeidsforhold` scratch-org er autorisert utan ny brukargodkjenning etter `AGENTS.md`.
- Org-funn frå 2026-11-13 er historiske, lesande observasjonar og må oppdaterast med ferske oppslag før dei blir brukte som dagens tilstand.
- P360-transport/mapping/recovery har framleis eigne opne avgjerder og er koordinert i #1095 og tilhøyrande Issues. Denne planlegginga skal ikkje opprette parallell P360-implementasjonsbacklogg.
- P360 kontraktsdokumentasjon er open i #983. Eigar av operativ runbook er open i #997.
- Review, doc-creation og lokale valideringar kan gjerast utan org-tilgang; org-runtime-bevis og org-avhengige testar blir BLOCKED til eksakt handling er stadfesta.
- Ingen Apex/Jest-testar eller Salesforce-org-kommandoar er køyrde i utarbeidinga av denne planen.
