# Implementation Plan: Konsumentstyrte Altinn-scenario

**Dato:** 2026-10-20  
**Status:** T005–T013 er utførte etter klarsignal og dry-run-verifiserte.
D01 er valt A, og T014–T016 er gjennomførte med fokuserte LWC Jest-testar.
Samla validering, nettlesarverifikasjon og andre opne gater står att; dette
dokumentet gir ikkje løyve til varig deploy eller andre org-endringar.

## Summary

La crm-arbeidsforhold velje ein scenario-provider ved tenestegrensa.
Integrasjonspakka leverer berre injeksjonsmoglegheita. Første leveranse har Setup,
ikkje Admin-app eller administrasjonsteneste. Alle testscenario er sperra i
produksjon. Ingen setting-record er nødvendig for ordinær drift.

**Spesifikasjonar:**
[pakkegrense](../../../.github/specs/altinn-provider-injection.md) og
[konsumentscenario](../../../.github/specs/altinn-consumer-scenarios.md).

**Designgrunnlag:** [design og filoversikt](README.md),
[kritisk avklaringsrunde](grill.md), [diagram](diagrams/consumer-scenarios.mmd).
Dette er designet planen konsumerer; planen introduserer ikkje ein eigen datamodell.

## Technical Context

- **Plattform:** Salesforce DX, Apex og Experience Cloud LWC.
- **Avhengigheit:** Eksisterande `IAltinnCalloutService` og fasade med additiv
  konstruktør frå eigaren av `crm-platform-integration`.
- **Lagring:** Føreslått app-eigd hierarkisk setting med rå brukaroppslag og
  versjonerte scenarioressursar bak ein typa lesar.
- **Tilgang:** Eigen permission, verifisert ikkje-produksjonsmiljø og binding til
  innlogga syntetisk brukar.
- **Validering:** Fokuserte Apex-testar i godkjend scratch, Jest for eventuell
  UI-endring, guida UI med isolerte data.
- **Avgrensing:** Ingen auth-/transport-/token-testing, v2-utfasing eller
  produksjonstest. Ingen nye npm-avhengigheiter er planlagde.
- **Yting:** Ingen SOQL i løkker; les scenario/config avgrensa per transaksjon.
  Ingen cache på tvers av brukarar som kan blande tildelingar.
- **Verifisert pakkegrense:** Konsumenttest mot installert `crm-platform-integration`
  0.177.0.4; manifestet er låst til denne versjonen etter særskild godkjenning.
- **Valt:** D01/A, med dynamisk oppfrisking via `@wire` og `refreshApex`.
  Pakkeeigarens separate review-/releasearbeid blir ikkje automatisk lukka av
  konsumentverifikasjonen.

## Constitution Check

Ingen separat constitution er funnen i dokumentasjonsgrunnlaget. Repositoryreglane
er førande:

| Føring                             | Planvurdering                                                                          |
| ---------------------------------- | -------------------------------------------------------------------------------------- |
| Hovudpakke og dependency-eigarskap | Separat leveranse frå pakkeeigar; referansemappa er ikkje implementasjonsmål           |
| Bevar offentlege kontraktar        | Additiv konstruktør; inga endring av eksisterande interface/DTO                        |
| TDD og minimumstilgang             | Fokuserte raud-grøn-sløyfer; `System.Assert`, `System.Test` og relevant `System.runAs` |
| Raud sone                          | Menneskeleg gjennomgang av miljøvern, identitet, feil og deling før merge              |
| Ingen implisitt org-handling       | Deploy/installasjon/pakkeutgiving er eigne godkjenningar                               |
| Personvern og eksplisitte feil     | Ingen personident i fixtures/loggar; ingen fallback frå øydelagt mock til live         |
| Framtidig Admin-app                | UI-uavhengig policy/katalog no; administrasjons-/skrivefunksjonar seinare              |

## Applied Guidelines

Dette er ikkje ein rammeverksmigrasjon; ingen migrasjonstransformasjonar blir brukte.
Følg [agentarbeidsflyten](../../../.github/instructions/agentic-development.instructions.md),
[Apex-reglane](../../../.github/instructions/salesforce-apex.instructions.md),
[testreglane](../../../.github/instructions/salesforce-testing.instructions.md),
[LWC-reglane](../../../.github/instructions/salesforce-lwc.instructions.md) og
[TDD-skillen](../../../.github/skills/tdd-salesforce/SKILL.md).
Les relevante lokale instruksjonar på nytt før kodeendring.

## Implementation Steps

Oppgåvene er planlagde med mindre dei er markerte utførte nedanfor. Filbaner for ikkje-implementerte komponentar er
føreslåtte frå designet. Ingen oppgåve autoriserer ei pakkeutgiving eller deploy.

### 1.1 - Godkjenne scope og pakkegrense

**Krav:** REQ-001, REQ-003, REQ-010, REQ-015, REQ-020, REQ-021, REQ-024.  
**Input:** Begge specs, designet og grill-runden.

- [ ] T001 [Plan:1.1] Stadfest eigar, autoritativt repository og tilgangen på tvers av pakker for `crm-platform-integration`; registrer kontrakt og godkjenningsbehov i `docs/integrations/altinn/README.md`, utan å gjette repository eller versjon.
- [ ] T002 [Plan:1.1] Godkjenn forslag til scenarioformat, pakkelevert teststøtte og utsett Admin-scope i `docs/integrations/altinn/grill.md`; opprett ikkje GitHub-issues utan eigen avtale.

**Avhengigheit:** Ingen. D01 treng ikkje vere valt for felles grunnarbeid.

### 2.1 - Levere additiv provider-injeksjon i integrasjonspakka

**Krav:** REQ-001, REQ-002, REQ-003.  
**Input:** Pakkegrensespec.  
**Avhengigheit:** T001.

- [ ] T003 [US1] [Plan:2.1] I pakkeeigarens repository: skriv fokusert raud test i `AltinnCalloutServiceTest.cls` for injeksjon utan live-oppsett, begge delegeringar, vidareført feil og null. Bruk testplasseringa som det repositoryet krev.
- [ ] T004 [US1] [Plan:2.1] Legg til konstruktøren i `AltinnCalloutService.cls`, dokumenter offentleg kontrakt og køyr same test grøn samt eksisterande fasaderegresjon. Bevar standardkonstruktøren.
- [x] T005 [Plan:2.1] Få separat godkjend kompatibel pakkeleveranse; oppdater først då avhengigheita i `sfdx-project.json` med faktisk verifisert versjon. Installer/deploy berre etter særskild godkjenning.

Installert 0.177.0.4 er verifisert med godkjend pakkeinspeksjon og ein grøn
konsumentgrensetest i dry-run `0AfJW00000nmREb0AM`. Brukaren godkjende deretter
eksakt manifestversjon. Ingen installasjon eller publisering er utført her;
T003–T004 og pakkeeigarens review/release blir ikkje markerte ferdige på dette
grunnlaget. Sjå [pakke- og providerbevis](README.md#implementert-provider-og-factory).

Lokale referansefiler er berre kjeldegrunnlag. Test/deploy i pakkeeigarens miljø krev
eiga godkjenning, ikkje bruk av andre autentiserte org-ar her.

### 3.1 - Default-off og hard miljø-/brukarpolicy

**Krav:** REQ-004, REQ-005, REQ-006, REQ-007, REQ-008, REQ-019, REQ-021, REQ-022.  
**Input:** Designets innstillingstabell og produksjonspolicy.  
**Avhengigheit:** T002; kan utviklast uavhengig av pakke-API.

- [x] T006 [US1] [US3] [Plan:3.1] Skriv raude testar i `force-app/tests/classes/integration/altinn/AAREG_AltinnScenarioPolicyTest.cls`: ingen org-record, ingen brukarrecord, null/false, brukar true utan org-record, ulovleg org/profil-arv, manglande permission, annan målbrukar, feil identitet, produksjon, ukjent miljø og lesefeil.
- [x] T007 [US1] [US3] [Plan:3.1] Implementer `force-app/integration/altinn/classes/AAREG_AltinnScenarioPolicy.cls`, setting under `force-app/integration/altinn/objects/AAREG_AltinnScenarioSetting__c/` og runtime-permission/-sett under same funksjonsmappe. Køyr T006 grøn. Stadfest rå-record-semantikk og scratch-miljøstatus i godkjend scratch.

Utført 2026-10-25: 15/15 testar grøne i dry-run, 34/34 policylinjer dekte.
Rå `getValues`-semantikk og faktisk `Organization.IsSandbox` er verifiserte.
Checkbox kan ikkje lagre eksplisitt null; utelaten aktivering blir testa som
default false. Privilegert plattformlesing er avgrensa til to eksplisitte
system-mode-oppslag, godkjende av brukaren. Kommando, resultat, testavgrensingar
og gjenståande arbeid står i [implementasjonsstatusen](README.md#implementert-policygrunnlag--2026-10-25).

Policy får ein smal testbar miljølesing, ikkje eit offentleg produksjons-override.
Testpermission skal ikkje leggjast til det generelle community-settet.

### 3.2 - Versjonert scenariokatalog

**Krav:** REQ-010, REQ-011, REQ-012, REQ-013, REQ-018, REQ-020, REQ-022.  
**Input:** S01-S08 og designets identitetskontrakt.  
**Avhengigheit:** T002.

- [x] T008 [US2] [Plan:3.2] Skriv raude katalogtestar i `force-app/tests/classes/integration/altinn/AAREG_AltinnScenarioRepositoryTest.cls` for ID/versjon, alias, rettsmatrise, tomt resultat og ukjent/ugyldig innhald.
- [x] T009 [US2] [Plan:3.2] Implementer typa lesing i `force-app/integration/altinn/classes/AAREG_AltinnScenarioRepository.cls` og `force-app/integration/altinn/staticresources/AAREG_AltinnScenarios.resource` med metadata-følgesfil. Lever S01-S08 og køyr T008 grøn; ingen rå personidentar i ressursen.

Utført 2026-10-25: schema- og definisjonsversjon 1, alle S01–S08, eksplisitt
rettsmatrise og separate S07-alias for responsfeil/exception. Eitt avgrensa
systemoppslag les berre den namngitte ressursen, godkjent av brukaren. Samla dry-run
gav 31/31 grøne testar (16 katalog, 15 policy), med 116/117 repositorylinjer og
34/34 policylinjer dekte. Sjå [katalogstatus og testbevis](README.md#implementert-scenariokatalog--2026-10-25).
Dette verifiserer definisjonane, ikkje faktisk provider-mapping eller UI-utfall.

### 3.3 - Provider og eksplisitt factory

**Krav:** REQ-007, REQ-008, REQ-009, REQ-010, REQ-011, REQ-012, REQ-014,
REQ-018, REQ-021, REQ-023.  
**Input:** Additivt API og godkjend policy/katalog.  
**Avhengigheit:** T005, T007, T009.

- [x] T010 [US2] [US3] [Plan:3.3] Skriv raude offentlege seam-testar i `force-app/tests/classes/integration/altinn/AAREG_AltinnServiceFactoryTest.cls` og `AAREG_AltinnScenarioProviderTest.cls`. Bevis korrekt provider, null callouts i mock, ingen live-konstruksjon, feil utan fallback og vern også ved direkte providerbruk.
- [x] T011 [US2] [US3] [Plan:3.3] Implementer `force-app/integration/altinn/classes/AAREG_AltinnServiceFactory.cls` og `AAREG_AltinnScenarioProvider.cls` med metadata-følgesfiler. Returner konkrete DTO-ar, handhev policy og køyr T010 grøn; ingen produkt-DML i desse klassane.

Samla dry-run `0AfJW00000nmRjF0AU`: 59/59 grøne testar, provider 54/54 og
factory 7/7 linjer dekte. Kvar operasjon revaliderer tildeling og sperrer;
berre katalogen blir halde per instans. Feil blir vidareførte utan fallback.
Standard v2-transport blir testa som scratch-administrator fordi dependencyens
metadataoppslag feila med minimumsprofilen; scenario/sperrer blir testa med
minimumstilgang. Sjå [kontrakt og valideringsavgrensingar](README.md#provider-factoryverifikasjon).

### 4.1 - Kople på dei faktiske applikasjonsinngangane

**Krav:** REQ-004, REQ-009, REQ-012, REQ-013, REQ-014, REQ-017, REQ-018,
REQ-023, REQ-024.  
**Input:** Godkjend factory og S01-S08.  
**Avhengigheit:** T011.

- [x] T012 [US1] [US2] [Plan:4.1] Skriv fokuserte scenario-regresjonstestar i `force-app/tests/classes/externalAccess/AAREG_AltinnScenarioJourneyTest.cls` ved dei offentlege controller-/utils-metodane. Bruk eksisterande testfactory og relevante minimumstilgangs-/community-brukarar. Test søknad Permit, ekte ressursavhengig brukerstøtte-fallback, rein Deny utan nye delingar og feil.
- [x] T013 [US1] [US2] [Plan:4.1] Byt dei to direkte fasadeopprettingane i `force-app/externalAccess/classes/AAREG_HomeController.cls` og `AAREG_CommunityUtils.cls` til felles factory. Køyr T012 grøn og eksisterande `AAREG_HomeControllerTest`/`AAREG_CommunityUtilsTest`; bevar legacy-testane utan unødig flytting.

Verifisert 2026-10-25 i dry-run `0AfJW00000nmT6j0AE`: 80/80 testar grøne
med Altinn-, journey-, controller- og utility-testar samla. Testane brukar
syntetisk community-identitet frå den faktiske konto-kjeda. Scratch-en har berre
High Volume Customer Portal-profilar, så positive `Agreement__Share`-rader for
den eksterne lisensen er ikkje verifiserte; ordinær delingsregresjon er grøn.
Testspesifikk overstyring av organisasjonsvalet vart testa raud (14 testar, éin
feil) og fjerna; same fokuserte køyring vart grøn (14/14). Ho maskerte
scenarioorganisasjonen. Ingen permanent deploy eller scenarioaktivering.
Sjå [journey-evidens og avgrensingar](README.md#controllerkopling-og-apex-journey--2026-10-25).

Journey-testen brukar scenarioets syntetiske organisasjonsnummer. Positiv
delingsverifikasjon for community-lisensen står att, fordi scratch-org-en berre
tilbyr High Volume Customer Portal-profilar.

### 5.1 - Velje cache-strategi etter omfang

**Krav:** REQ-015, REQ-016, REQ-017, REQ-024.  
**Input:** D01 i design/spec.  
**Avhengigheit:** T002; valet er teke før 5.2.

- [x] T014 [Plan:5.1] Brukaren valde A etter gjennomgang av endringsflate og repeterbar testflyt. Valet er registrert i `docs/integrations/altinn/README.md`, `grill.md` og konsumentspesifikasjonen; B er ikkje vald.

### 5.2 - Alternativ A: eksplisitt dynamisk oppfrisking

**Krav:** REQ-015, REQ-016, REQ-023, REQ-024.  
**Input:** Oppfriskingskontrakten.  
**Avhengigheit:** T013, T014 og eksplisitt val av A.

- [x] T015 [US4] [Plan:5.2] Skriv fokuserte LWC-testar i `force-app/externalAccess/lwc/aareg_home/__tests__/aareg_home.test.js` for ny liste, filtrert bortfall av valt organisasjon, rettssjekk på nytt, feil og overlappande oppfrisking.
- [x] T016 [US4] [Plan:5.2] Implementer ferskhenting med `@wire`/`refreshApex` og oppfriskingshandling i `aareg_home.js` og `.html`, med Custom Label og norsk omsetjing. Fokusert Jest-test er grøn; breiare regresjon og nettlesarverifikasjon står att.

Wire-/refresh-endring og eventuell medviten retting av forelda val skal ha
eksplisitt godkjende akseptansar; ikkje bruk mock-modus til å skjule UI-feil.

### 5.3 - Alternativ B: faste scenario og separate testøkter

**Krav:** REQ-015, REQ-017, REQ-024.  
**Input:** Prosedyrekontrakten.  
**Avhengigheit:** T013, T014 og eksplisitt val av B.

- [ ] T017 [US4] [Plan:5.3] Dokumenter og prøv faste scenariotildelingar, godkjend brukar-/lisenskapasitet, isolerte nettlesarøkter og kontroll av rett organisasjonsliste i `docs/operations/scratch-testlogg-2026-10-15.md`. Registrer B som utilstrekkeleg dersom rein teststart/Permit-til-Deny ikkje kan demonstrerast. Ingen automatisk brukaroppretting.

Ingen oppfriskingsknapp blir levert i B. REQ-016 blir då eksplisitt ikkje
gjeldande for denne leveransen, ikkje merkt som implementert.

### 6.1 - Samla verifikasjon, dokumentasjon og release-gate

**Krav:** REQ-001 til REQ-024, med REQ-016 vilkårsavhengig av D01.  
**Input:** Vald og verifisert cache-grein.  
**Avhengigheit:** T013 og anten T016 eller T017, ikkje begge.

- [ ] T018 [Plan:6.1] Køyr fokusert samla Apex-regresjon og relevant Jest. Kontroller S01-S08, normal modus, default-off, sperrer, feil, calloutfråvær og delingar i godkjend scratch; før kommandoar/resultat og brukarrapporterte UI-funn i `docs/operations/scratch-testlogg-2026-10-15.md`.
- [ ] T019 [Plan:6.1] Oppdater `docs/integrations/altinn/README.md` og specs med faktisk implementasjon/evidens. Køyr toakse-review og relevant security-review før commit/push/PR. Få menneskeleg godkjenning; pakkeutgiving, deploy og integrasjonssandbox-testing krev eigne eksplisitte godkjenningar.

## Project Structure

```text
.github/specs/
  altinn-provider-injection.md
  altinn-consumer-scenarios.md
docs/integrations/altinn/
  README.md
  grill.md
  implementation-plan.md
  diagrams/consumer-scenarios.mmd
  checkpoints/spec-to-plan.yaml
  checkpoints/plan-to-tasks.yaml
force-app/integration/altinn/             # planlagt runtime og metadata
force-app/tests/classes/integration/altinn/
force-app/tests/classes/externalAccess/
force-app/externalAccess/                # eksisterande inngangar; inga flytting
```

## Testing Strategy

- **appType:** Experience Cloud med Apex-backend.
- **Kritiske reiser:** normal drift utan oppsett, søknad Permit, berre
  brukerstøtte, rein Deny, fleire organisasjonar, tom/filtrert liste, feil og
  forelda val. Permit-til-Deny blir observert separat.
- **Primær validering:** offentlege Apex-seams og konkrete lagra delingar i
  godkjend scratch; Jest/DOM ved LWC-endring; guida UI.
- **TDD:** éi vertikal slice om gongen. Skriv test, observer raud, implementer
  minste endring, køyr same test grøn, refaktorer og køyr relevant regresjon.
- **Tilgang:** `System.Assert.*`, `System.Test.*`, relevant
  `System.runAs(minimumAccessUser)` frå Minimum Access - Salesforce; community-lisens
  der den faktiske reisa krev det. Ingen reelle persondata i fixtures.
- **Produksjonssperre:** test injisert miljøstatus og direkte provider-inngang.
  Ikkje bruk ekte produksjonsorg eller `Test.isRunningTest()` som miljøløyve.
- **Fallback:** Utan godkjend/autentisert org kan Apex ikkje kallast grøn.
  Lokal formatering/Jest erstattar ikkje Apex-kompilering, metadata eller UI-evidens.
- **Delingar:** tel/undersøk før og etter rein Deny; observer eksisterande
  delingar ved Permit-til-Deny. Ingen automatisk reset eller tilgangsretting.
- **Andre kanalar:** kontroller e-post og øvrige integrasjonar før UI-DML.
  Null Altinn-callouts er ikkje det same som null andre sideeffektar.
- **Miljø:** berre default `crm-arbeidsforhold` er førehandsavtalt for autentiserte
  kommandoar. Deploy krev likevel eigen godkjenning. Andre org-ar krev ny avtale.
- **Integrasjonssandbox:** separat godkjend oppfølging etter scratch; produksjon
  inngår ikkje i testplanen for scenario-runtime.

Føreslåtte kommandoar ved implementering, ikkje køyrde som del av denne planen:

```bash
rtk proxy sf apex run test --target-org crm-arbeidsforhold --tests AAREG_AltinnScenarioPolicyTest --result-format human --wait 10
rtk proxy npm test -- --runInBand force-app/externalAccess/lwc/aareg_home/__tests__/aareg_home.test.js
```

Første kommando køyrer berre den første policy-slicen; eskaler til andre nye
testklassar og eksisterande controller-testar etter grønt. Om kommandoen ikkje
blir ferdig, hent resultat frå faktisk test run ID; ikkje tolk innsending som PASS.
Bruk same fokuserte kommando for raud og grøn. Pakkeeigar bruker eigne godkjende
kommandoar/miljø for pakkegrensespec.

## Requirement Mapping

Dette er planlagt evidens, ikkje ein påstand om implementasjon.

| REQ ID  | Kort beskriving                 | Plan Items                   | Implementation Evidence                                |
| ------- | ------------------------------- | ---------------------------- | ------------------------------------------------------ |
| REQ-001 | Injisert provider               | 1.1, 2.1                     | Fasade og test i pakkeeigarens repository              |
| REQ-002 | Bakoverkompatibilitet           | 2.1                          | Standardkonstruktør og fasaderegresjon                 |
| REQ-003 | Null og eigarskap               | 1.1, 2.1                     | Null-test og ingen app-avhengigheit i pakka            |
| REQ-004 | Fråvær/null/false betyr av      | 3.1, 4.1                     | PolicyTest og normal controller-bane                   |
| REQ-005 | Eksplisitt brukarrecord         | 3.1                          | Rå-record-/arvetestar                                  |
| REQ-006 | Hard produksjonssperre          | 3.1, 3.3                     | PolicyTest og direkte ProviderTest                     |
| REQ-007 | Permission og identitet         | 3.1, 3.3                     | PolicyTest, permission og runtime-kontroll             |
| REQ-008 | Feil utan fallback              | 3.1, 3.3                     | Policy-/Factory-/ProviderTest                          |
| REQ-009 | Felles val og null callouts     | 3.3, 4.1                     | FactoryTest og JourneyTest                             |
| REQ-010 | Stabil katalogkontrakt          | 1.1, 3.2, 3.3                | RepositoryTest og scenarioressurs                      |
| REQ-011 | Eksplisitt rettsmatrise         | 3.2, 3.3                     | Repository-/ProviderTest                               |
| REQ-012 | Eksisterande responskontrakt    | 3.2, 3.3, 4.1                | DTO- og journey-assertions                             |
| REQ-013 | S01-S08                         | 3.2, 4.1, 6.1                | Ressurs, testar og guida UI-logg                       |
| REQ-014 | Appen eig åtferd                | 3.3, 4.1                     | Ingen avgjerd/DML i provider; JourneyTest              |
| REQ-015 | Repeterbar cache-strategi       | 1.1, 5.1, 5.2, 5.3           | D01 og vald greins evidens                             |
| REQ-016 | Dynamisk oppfrisking dersom A   | 5.1, 5.2                     | LWC-test og UI, eller eksplisitt ikkje gjeldande ved B |
| REQ-017 | Delingssemantikk                | 4.1, 5.1, 5.3, 6.1           | JourneyTest og før/etter UI-logg                       |
| REQ-018 | Ingen produkt-DML i mock        | 3.2, 3.3, 4.1                | Provider-test og isolert UI-prosedyre                  |
| REQ-019 | Setup utan skrive-API           | 3.1                          | Permission-review og Setup-prosedyre                   |
| REQ-020 | Admin seinare                   | 1.1, 3.2                     | UI-uavhengig policy/katalog; ingen Admin-API           |
| REQ-021 | Pakkelevert, sperra i prod      | 1.1, 3.1, 3.3                | Metadata i appen, produksjonsvern                      |
| REQ-022 | Ingen sensitive data            | 3.1, 3.2, 6.1                | Alias, trygg feil/logg og review                       |
| REQ-023 | Bevar normal åtferd             | 3.3, 4.1, 5.2, 6.1           | Av-bane og relevant regresjon                          |
| REQ-024 | Reell validering og godkjenning | 1.1, 4.1, 5.1, 5.2, 5.3, 6.1 | Faktiske testresultat og menneskeleg review            |

Alle krav er sporbare i planen; REQ-016 er medvite vilkårsavhengig.
Checkpointane kontrollerer berre sporbarheit, ikkje at funksjonen er godkjend
eller ferdig. D01/A er valt og implementert; samla validering, UI-verifikasjon
og pakkeeigarens separate review-/releasearbeid er framleis opne gater.
