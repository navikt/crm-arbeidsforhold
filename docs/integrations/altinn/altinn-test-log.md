# Testlogg for Altinn-scenario

**Gjeldande målorg:** `nav-community-dev`; første økt nedanfor er historisk
frå `crm-arbeidsforhold`  
**Testguide:** [test-guide.md](./test-guide.md)  
**Loggregel:** Berre observerte resultat blir markerte som bestått. Nettlesar-
resultat blir stadfesta av testpersonen; CLI/Apex-resultat blir stadfesta av
køyringa.

## PR-CI: utdaterte provider-forventningar og testbrukaroppretting — 2026-10-26

CI på PR #1162 køyrde 455 testar og rapporterte 12 feil:

- Fire provider-testar venta organisasjonstala frå før utvidinga av katalogen:
  S01/S04 har no A/B/C, og S06 har A/B/C/D pluss Person.
- Åtte journey-testar stoppa i testfactory ved `insert User` med melding om
  utilgjengelege User-felt. Dei kom ikkje fram til åtferda dei skulle teste.
- Metadata-kompilering bestod. Dei etterfølgjande samlegatane feila fordi
  testjobben feila; coverage-jobben blei ikkje køyrd.

Den første lokale dry-run-køyringa av provider og journey reproduserte dei
fire utdaterte assertionane, medan journey-testane bestod i `nav-community-dev`.
CI sin felttilgangsfeil er derfor ikkje lokalt reprodusert.

Rettinga er avgrensa til testkode:

- Provider-forventningane er oppdaterte med eksplisitte B/C- og D-kontrollar,
  inkludert C sine ressursrettar. Ingen assertions er fjerna eller svekte til
  berre å krevje eit ikkje-tomt svar.
- Berre community-brukarinnsettinga i `@IsTest`-factory bruker no eksplisitt
  `insert as system`. Dette fjernar avhengigheita til testkøyraren sine
  felt-skriverettar ved fixture-oppretting. Sjølve journey-operasjonane køyrer
  framleis med `System.runAs` som community-brukaren, med uendra runtime-vern.
  Ingen profiler, permission sets eller produksjonsklassar er endra.
- Den tidlegare sluttkontrollen før PR dekte ikkje heile provider-suita.
  Den utvida kontrollen nedanfor omfattar alle fire scenario-/factory-testklassar
  og dei tre relaterte controller-/journey-testklassane.

```bash
rtk sf project deploy start --dry-run \
  --source-dir force-app/tests/classes/integration/altinn \
  --source-dir force-app/tests/classes/externalAccess/AAREG_AltinnScenarioJourneyTest.cls \
  --target-org nav-community-dev --test-level RunSpecifiedTests \
  --tests AAREG_AltinnScenarioProviderTest --tests AAREG_AltinnScenarioJourneyTest \
  --tests AAREG_AltinnScenarioPolicyTest --tests AAREG_AltinnScenarioRepositoryTest \
  --tests AAREG_AltinnServiceFactoryTest --tests AAREG_HomeControllerTest \
  --tests AAREG_CommunityUtilsTest --wait 10 --json
```

**Bestått lokalt mot godkjend org:** dry-run `0AfJW00000nnghp0AA`,
86/86 testar, ingen coverage warnings. Ingen vedvarande deploy eller endring
av nettlesartestdata. Prettier-kontroll av dei to endra Apex-filene og
`git diff --check` av lokale endringar bestod.

**Open verifikasjon:** Ny CI-køyring må stadfeste at User-innsettinga fungerer
med CI-køyraren sine tilgangar, og at heile 455-testarsuita og coverage-gaten
består. Lokal 86/86 erstattar ikkje dette.

## Review og opprydding — 2026-10-26

Brukaren godkjende forenkling av seed og sletting av berre dei fire gamle
inaktive scenario-brukarsettingane i `nav-community-dev`, og retting av
sikkerheitsfunnet om cross-user-oppslag.

| Kontroll                                         | Resultat          | Evidens                                                                                                                                 |
| ------------------------------------------------ | ----------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Strengare verifier før opprydding                | Raud som venta    | Venta 0 gamle settingar; fann 4.                                                                                                        |
| Settings-seed                                    | Bestått to gonger | Fire gamle settingar sletta ved første køyring; berre generisk S01/subject-a/true står att.                                             |
| Forenkla Account/Contact-seed                    | Bestått to gonger | Kompilert og køyrd; same identitet, inga ny brukaroppretting.                                                                           |
| Verifier etter opprydding                        | Bestått           | Éin aktiv generisk Plus-brukar, to permissions og eksplisitt brukarsetting; ingen gamle settingar.                                      |
| Produktdata etter andre seed                     | Bestått           | Nøyaktig éin Account, søknad og aktiv avtale per A–D. Éin scenario-record totalt.                                                       |
| Negative tilgangstestar før retting              | Raude             | Begge gamle endepunkt gjekk vidare til live-bana for ein annan målbrukar og feila på utilgjengeleg live-metadata i staden for å avvise. |
| Same-user kontrakt etter retting                 | Bestått dry-run   | `0AfJW00000nnYYz0AM`: 27/27 Apex, ingen coverage warnings. Negative testar krev avvising før SOQL/callout når scenario er av.           |
| Vedvarande deploy / nettlesar av tilgangsretting | Bestått           | Brukaren godkjende deploy og nettlesarkontroll. `0AfJW00000nnYcD0AU`: success, checkOnly=false, 27/27 Apex, ingen coverage warnings.    |

Kommandoar for dataopprydding og verifikasjon, alle med godkjent målorg:

```bash
rtk sf apex run --target-org nav-community-dev --file bin/seed-altinn-scenario-settings.apex
rtk sf apex run --target-org nav-community-dev --file bin/seed-altinn-scenario-accounts.apex
rtk sf apex run --target-org nav-community-dev --file bin/verify-altinn-test-user.apex
```

Alle tre fullførte. Ingen andre Custom Settings, historiske Users, Contacts
eller Accounts blei sletta. Seedet er ikkje ein generell oppryddingsjobb.

Eksakt tilgangsvalidering (**Bestått**, dry-run, ingen metadata lagra):

```bash
rtk sf project deploy start --dry-run \
  --source-dir force-app/externalAccess/classes/AAREG_HomeController.cls \
  --source-dir force-app/externalAccess/classes/AAREG_CommunityUtils.cls \
  --source-dir force-app/externalAccess/classes/AAREG_HomeControllerTest.cls \
  --source-dir force-app/externalAccess/classes/AAREG_CommunityUtilsTest.cls \
  --source-dir force-app/tests/classes/externalAccess/AAREG_AltinnScenarioJourneyTest.cls \
  --target-org nav-community-dev --test-level RunSpecifiedTests \
  --tests AAREG_AltinnScenarioJourneyTest --tests AAREG_HomeControllerTest \
  --tests AAREG_CommunityUtilsTest --wait 10 --json
```

Før grøn køyring avdekte `runAs` at eldre positive testar valde Altinn 2 via
feature-permission i staden for den tilsikta v3-fixturen. Testane fekk
eksplisitt versjonsval; ingen test-bypass eller avhengigheitspakke blei endra.

Lokal regresjon: `rtk npm run test:unit -- -- --runInBand` bestod med
6/6 suiter og 24/24 testar. Prettier-kontroll av endra støtta Apex- og
dokumentasjonsfiler bestod; `.apex`-seedskripta blei verifiserte ved kompilering
og køyring i org-en, ikkje ved Prettier. Lisenskontrollen viste Plus 1/1 og
High Volume 0/5 i bruk.

Etter eksplisitt godkjenning blei same fem klassar deploya med kommandoen
ovanfor utan `--dry-run`: **Bestått**, `0AfJW00000nnYcD0AU`, 27/27 Apex.
Ingen andre orgar eller avhengigheitspakkar blei endra.

Assistent-observert nettlesarkontroll etter denne deployen, i eksisterande delt
fane som den generiske brukaren:

- Reload og «Oppdater organisasjoner»: A/B/C, A valt, søknads- og
  brukerstøttetilgang, ingen teknisk feilmelding.
- Val A→B→A: begge tilgangane synlege etter kvart val; A gjenoppretta utan feil.
- Sluttstatus: S01/subject-a/true og A valt. Ingen søknader eller avtalar blei
  redigerte. Cross-user-sikkerheit blei testa med isolerte Apex-fixtures, ikkje
  ved oppslag mot andre vedvarande brukarar i nettlesaren.

## Testøkt 2026-10-25

| Steg        | Kontroll                          | Resultat                    | Evidens / merknad                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ----------- | --------------------------------- | --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Preflight   | Scratch-org identitet             | Bestått                     | `sf org display --target-org crm-arbeidsforhold` viste aktiv scratch-org med aliaset `crm-arbeidsforhold`. Ingen org-URL eller credentials er lagra her.                                                                                                                                                                                                                                                                                                                                                                           |
| Preflight   | Scenarioressurs deploya           | Bestått                     | Deployment `0AfJW00000nnC8f0AE`; 3 komponentar deploya/endra eller uendra; status `Succeeded`.                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Preflight   | Apex scenario- og journey-testar  | Bestått                     | Deploy-køyring: 21/21 testar bestod.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| Preflight   | LWC-testar                        | Bestått                     | `npm run test:unit -- -- --runInBand`: 6 suiter, 16 testar bestod.                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Preflight   | Node-regresjonstestar             | Bestått                     | `npm run test:node` fullførte med exitkode 0.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| Preflight   | Formatering                       | Bestått                     | Prettier-kontroll av scenarioressurs, scenario-spesifikasjon og dei to Apex-testklassane bestod.                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| Preflight   | Syntetiske organisasjonar         | Bestått                     | Fire Accounts finst for 111111111–444444444.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| Preflight   | Søknader og avtalar               | Bestått                     | Fire søknader med status `New`; fire aktive avtalar, kvar kopla til ei syntetisk organisasjon.                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Preflight   | Interaktive scenarioinnstillingar | Bestått                     | S01, S02, S03, S04 og S06 har aktiv brukarsetting med `subject-a`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Preflight   | Portalbrukarlisensar              | Informasjon                 | 5 av 5 High Volume Customer Portal-lisensar er i bruk.                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| Preflight   | S01-testbrukar                    | Bestått                     | Éin aktiv `High Volume Customer Portal User` med syntetisk Permit-rolle finst. Ingen innloggingsdata eller Salesforce-ID er lagra her.                                                                                                                                                                                                                                                                                                                                                                                             |
| Nettlesar   | Innloggingskontekst               | Pågår                       | Testpersonen stadfesta at nettlesaren er innlogga internt i Salesforce, ikkje som ein Experience Cloud-brukar. Community-testen har ikkje starta.                                                                                                                                                                                                                                                                                                                                                                                  |
| Nettlesar   | Overgang til S01                  | Bestått                     | Testpersonen brukte den etablerte Experience Cloud-flyten via kontakten og stadfesta at community-sida er open som S01.                                                                                                                                                                                                                                                                                                                                                                                                            |
| Nettlesar   | S01-organisasjonsliste            | Bestått                     | Testpersonen stadfesta at A, B og C blir viste i Experience Cloud.                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Nettlesar   | S01-A                             | Bestått                     | Testpersonen valde A og stadfesta at søknadstilgang blir vist.                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Nettlesar   | S01-B                             | Bestått                     | Testpersonen valde B og stadfesta at søknadstilgang blir vist.                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Nettlesar   | S01-C                             | Bestått                     | Testpersonen valde C og stadfesta at søknadstilgang blir vist.                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Scratch-org | S01-organisasjonsdata             | Bestått                     | Read-only kontroll fann syntetiske Account-, søknads- og avtale-records for A, B og C. Org.nummeret samsvarar på kvart nivå; søknadene har `New`, avtalane `Active`.                                                                                                                                                                                                                                                                                                                                                               |
| Nettlesar   | S01-avtalar                       | Blokkert av lisensforskjell | Med C vald viste **Mine avtaler** ingen aktive avtalar. Data og organisasjonsval er på plass, men scratch-brukaren har High Volume Customer Portal-lisens. Testpersonen opplyser at den fungerande produksjonsbrukaren har Customer Community Plus.                                                                                                                                                                                                                                                                                |
| Apex        | S01-avtalevising                  | Ikkje representativ         | Ein fokusert diagnostisk test fekk Permit, men returnerte 0 avtalar for High Volume-brukaren. Testmetoden blei fjerna frå kjelda; han testa ikkje lisensen som blir brukt i produksjon.                                                                                                                                                                                                                                                                                                                                            |
| Plattform   | High-volume-deling                | Avgrensing stadfesta        | S01 brukar `CspLitePortal` / High Volume Customer Portal. Direkte `Agreement__Share`-innsetting feilar med `invalid user or group`. Kontaktkontoen er ein syntetisk identitetskonto utan organisasjonsnummer, ikkje A/B/C. Salesforce si [sharing-arkitektur](https://architect.salesforce.com/docs/architect/fundamentals/guide/platform-sharing-architecture.html) seier at high-volume-brukarar ikkje nyttar den vanlege delingsmodellen; tilgang må baserast på Account/Contact-koplingar med Sharing Sets eller Share Groups. |
| Scratch-org | Ekstern lisenskapasitet           | Informasjon                 | High Volume Customer Portal har 5 av 5 lisensar i bruk; ingen Customer Community Plus-lisens blei funnen. Scratch-definisjonen har allereie Enterprise, `Communities` og `enableNetworksEnabled`; ingen manglande Experience Cloud-flagg er identifisert.                                                                                                                                                                                                                                                                          |
| Utvikling   | Vidare løysing                    | Blokkert                    | Ingen produksjonskode eller delingsdata er endra. Ei produksjonslik avtaletest krev at scratch-org-en kan bruke same Customer Community Plus-lisens som produksjonsbrukaren.                                                                                                                                                                                                                                                                                                                                                       |
| Nettlesar   | S02–S06                           | Ikkje testa                 | Ventar på at S01-forløpet er ferdig. Ingen passord er sette eller etterspurde.                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Nettlesar   | S05/S07/S08                       | Ikkje testa                 | Krev eventuelt godkjend mellombels scenarioinnstilling på eksisterande testbrukar; skal avklarast og tilbakeførast under guida økt.                                                                                                                                                                                                                                                                                                                                                                                                |

## Oppsett av Community Plus-scratch 2026-10-25

**Målmiljø:** scratch-org-alias `nav-community-dev`  
**Org-oppretting:** ikkje utført; eksisterande scratch-org blei brukt.  
**Datagrunnlag:** syntetiske testdata; ingen credentials eller persondata lagra.

| Steg      | Kontroll                                       | Resultat       | Evidens / merknad                                                                                                                                                                                                                     |
| --------- | ---------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pakker    | Avhengigheitspakkar                            | Bestått        | Alle 19 avhengigheitspakkane i `sfdx-project.json` blei installerte.                                                                                                                                                                  |
| Deploy    | Hovudkjelda                                    | Bestått        | Full deploy av `force-app` fullførte med status `Succeeded`.                                                                                                                                                                          |
| Oppsett   | Permission sets, data og community             | Bestått        | Oppsettsstega fullførte; Aa-registret-community er `Live`.                                                                                                                                                                            |
| Altinn    | Scenario- og organisasjonsdata                 | Bestått        | S01, S02, S03, S04 og S06 er aktive. Fire syntetiske organisasjonar har søknader og aktive avtalar.                                                                                                                                   |
| Lisens    | Customer Community Plus                        | Bestått        | 1 av 1 lisens er i bruk av den aktive S01-brukaren med profilen `Customer Community Plus User`.                                                                                                                                       |
| Lisens    | High Volume Customer Portal                    | Bestått        | 4 av 5 lisensar er i bruk av dei andre fire scenario-brukarane.                                                                                                                                                                       |
| Apex      | `AAREG_MyAgreementsControllerTest`             | Bestått        | 30/30 testar bestod i `nav-community-dev`.                                                                                                                                                                                            |
| Apex      | Samla køyring av Home- og My Agreements-testar | Delvis bestått | 44/45 bestod. `AAREG_HomeControllerTest.shouldShareAgreementsForSelectedOrganizationInTestContext` feila med eksisterande `MIXED_DML_OPERATION` mellom User og Account i testdataoppsettet. Dei delingsrelevante Home-testane bestod. |
| Apex      | Fokuserte Home-delingsscenario                 | Bestått        | 3/3 testar bestod, inkludert `shouldGrantAccessAndShareAgreement` og `shouldShareAgreementsAndRelatedContacts`.                                                                                                                       |
| Nettlesar | Community Plus-innlogging og avtalevising      | Ikkje testa    | Klar for guida nettlesartest; ventar på testpersonen.                                                                                                                                                                                 |

**Retta lisensråd:** Den tidlegare påstanden her om at deaktivering ikkje
frigjer lisenskapasitet var ikkje verifisert og er trekt tilbake. No bruker vi
éin generisk Community Plus-brukar for alle scenario. Dei fire gamle High
Volume-brukarane er deaktiverte; siste lisensquery viser 0 i bruk for High
Volume. Brukarmodellen er vald for enkel testing med same historikk, ikkje
fordi ein inaktiv brukar må halde på ei aktiv lisens.

## Løpande nettlesarlogg

### S08 med Community Plus, 2026-10-25

- Testpersonen stadfesta utgangspunktet i S01: A var vald og gav
  søknadstilgang. Testpersonen godkjende mellombels byte til S08 i
  `nav-community-dev`, med tilbakeføring til S01 etter testen.
- CLI stadfesta S01 før endringa, oppdaterte berre `ScenarioName__c` og
  stadfesta S08 med `subject-a` og `UseScenarioProvider__c=true`.
- Forventa etter oppfrisking: berre B i lista, A ikkje lenger eit gyldig
  val og ingen vidareført søknadstilgang. B skal gi berre brukerstøtte.
- Eksisterande avtaledelingar er bevarte; tilbakekalling av
  avtaletilgang blir ikkje testa.
- **S08 – bortfall av A: Bestått.** Etter oppfrisking stadfesta
  testpersonen at berre B blei vist, B blei vald automatisk og
  søknadstilgangen var borte.
- **S08 – brukerstøtte: Avvik til undersøking.** Testpersonen melde at
  brukerstøtte ikkje var synleg etter automatisk val av B. S08 er derfor
  ikkje fullstendig bestått; årsaka er ikkje diagnostisert.
- **S08 – manuelt val av B gjenopprettar brukerstøtte.** Testpersonen
  stadfesta at ingen inngang til brukerstøtte fanst på startsida eller i
  navigasjonen etter automatisk val av B; standardmeldinga om manglande
  tilgang blei vist. Etter val av plasshaldaralternativet i veljaren kom
  «feilmeldinga frå før» (eksakt tekst ikkje stadfesta). Ved manuelt val
  av B etterpå blei brukerstøtte vist som forventa. Observasjonen skil
  automatisk og manuelt val; teknisk årsak er ikkje diagnostisert.
- **Tilbakeføring: Bestått.** CLI sette `ScenarioName__c` tilbake til S01
  og stadfesta S01 med `subject-a` og `UseScenarioProvider__c=true`.
- **S08 → S01 – gjenoppretting: Bestått.** Testpersonen stadfesta A, B
  og C etter oppfrisking og søknadstilgang etter manuelt val av A.
  Ingen feil blei meldt.

### S07 med Community Plus, 2026-10-25

- Testpersonen godkjende mellombels byte av S01-brukaren til S07 i
  `nav-community-dev`, med tilbakeføring til S01 etter testen.
- CLI stadfesta S01 før endringa, oppdaterte berre `ScenarioName__c` og
  stadfesta S07 med `subject-a` og `UseScenarioProvider__c=true`.
- Testen gjeld synleg feil ved organisasjonsoppslag, nullstilling av
  tilgang på startsida og gjenoppretting. Eksisterande avtaledelingar er
  bevarte; tilbakekalling av avtaletilgang blir ikkje testa.
- **S07 – feilvarsel og tilgangssperre: Bestått.** Testpersonen såg
  «Henting av brukerrettigheter fra Altinn feilet. Vennligst prøv igjen
  eller refresh siden.» Verken søknad eller brukerstøtte var tilgjengeleg.
- **S07 – varig feiltilstand: Avvik til undersøking.** Organisasjonar
  kunne framleis veljast. Testpersonen såg først feil for A, men meldinga
  forsvann og kom ikkje tilbake ved ny oppfrisking eller byte av
  organisasjon og tilbake. Sida viste i staden den ordinære meldinga om
  manglande Altinn-rett, med rettleiing om nødvendig rett og val av verksemd.
  Det er ikkje avklart om observasjonen gjeld organisasjons- eller
  rettsoppslaget; årsaka er ikkje diagnostisert.
- **Tilbakeføring: Bestått.** CLI sette `ScenarioName__c` tilbake til S01
  og stadfesta S01 med `subject-a` og `UseScenarioProvider__c=true`.
- **S07 → S01 – gjenoppretting: Bestått.** Etter oppfrisking stadfesta
  testpersonen A, B og C i lista og søknadstilgang for A utan Altinn-feil.

### S05 med Community Plus, 2026-10-25

- Testpersonen godkjende mellombels byte av S01-brukaren til S05 i
  `nav-community-dev`, med tilbakeføring til S01 etter testen.
- CLI stadfesta S01 før endringa, oppdaterte berre `ScenarioName__c` og
  stadfesta S05 med `subject-a` og `UseScenarioProvider__c=true`.
- Testen gjeld tom organisasjonsliste og nullstilling av tilgang på
  startsida. Eksisterande avtaledelingar er bevarte; tilbakekalling av
  avtaletilgang blir ikkje testa.
- **S05 – tomtilstand og tilgang: Bestått.** Testpersonen stadfesta at
  ingen organisasjonar kunne veljast, ingen gyldig organisasjon var vald,
  og verken søknad eller brukerstøtte var tilgjengeleg.
- Organisasjonsveljaren blei erstatta av «Ingen organisasjoner er
  tilgjengelige.» Sida viste også «Du mangler rettighet i Altinn for å kunne
  søke», med rettleiing om nødvendig rett og val av verksemd i
  nedtrekksmenyen. Rettleiinga viser dermed til ein veljar som ikkje er
  tilgjengeleg i tomtilstanden; dette er notert for UX-oppfølging.
- **Tilbakeføring: Bestått.** CLI sette `ScenarioName__c` tilbake til S01
  og stadfesta S01 med `subject-a` og `UseScenarioProvider__c=true`.
- **S05 → S01 – gjenoppretting: Bestått.** Testpersonen brukte
  **Oppdater organisasjoner**, fekk A, B og C tilbake og stadfesta at
  søknadstilgangen for A var tilbake. Ingen feil blei meldt.

### S06 med Community Plus, 2026-10-25

- Testpersonen godkjende mellombels byte av S01-brukaren til S06 i
  `nav-community-dev`, med tilbakeføring til S01 etter testen.
- CLI stadfesta S01 før endringa, oppdaterte berre `ScenarioName__c` og
  stadfesta S06 med `subject-a` og `UseScenarioProvider__c=true`.
- Forventa organisasjonsliste etter filtrering: berre A og D (AS).
  B (ENK), C (BEDR) og personoppføringa skal ikkje visast.
- **S06 – filtrering: Bestått.** Testpersonen stadfesta at berre A og D
  blei viste etter oppfrisking, og at A var vald. Ingen feil blei meldt.
  Eksisterande avtaledelingar er bevarte.
- **S06 – tilgang for A og D: Bestått.** Testpersonen stadfesta
  søknadstilgang for begge organisasjonane.
- **S06 – avtalevising for D: Bestått.** Med D vald såg testpersonen
  `AVT-000006`, datert 25. oktober 2026, med status **Aktiv**.
- **Tilbakeføring: Bestått.** CLI sette `ScenarioName__c` tilbake til S01
  og stadfesta S01 med `subject-a` og `UseScenarioProvider__c=true`.
  Nettlesaren må oppfriskast før vidare testing.

### S03 med Community Plus, 2026-10-25

- Testpersonen godkjende mellombels byte av S01-brukaren til S03 i
  `nav-community-dev`, med tilbakeføring til S01 etter testen.
- CLI stadfesta S01 før endringa, oppdaterte berre `ScenarioName__c` og
  stadfesta S03 med `subject-a` og `UseScenarioProvider__c=true`.
- Testen gjeld avvist søknads-/brukerstøttetilgang. Eksisterande
  avtaledelingar er bevarte; tilbakekalling av avtaletilgang og fråvær av
  nye delingar er ikkje verifisert.
- **S03 – oppfrisking og A: Bestått.** Testpersonen stadfesta A, B og C
  i lista. A gav verken søknads- eller brukerstøttetilgang. Sida viste:
  «Du mangler rettighet i Altinn for å kunne søke», med rettleiing om
  rettigheten «Søke om tilgang til Aa-registeret og forvalte avtaleforhold»
  og val av representert verksemd i nedtrekksmenyen.
- **S03 – B og C: Bestått.** Testpersonen stadfesta at verken søknad
  eller brukerstøtte var tilgjengeleg for B og C. Ingen andre avvik blei meldt.
- **Tilbakeføring: Bestått.** CLI sette `ScenarioName__c` tilbake til S01
  og stadfesta S01 med `subject-a` og `UseScenarioProvider__c=true`.
  Nettlesaren må oppfriskast før vidare testing.

### S02 med Community Plus, 2026-10-25

- Testpersonen godkjende mellombels byte av S01-brukaren til S02 i
  `nav-community-dev`, med tilbakeføring til S01 etter testen.
- CLI stadfesta S01 før endringa, oppdaterte berre `ScenarioName__c` og
  stadfesta S02 med `subject-a` og `UseScenarioProvider__c=true`.
- Testen gjeld søknads-/brukerstøttetilgang. Eksisterande avtaledelingar
  er bevarte; tilbakekalling av avtaletilgang blir ikkje testa.
- **S02 – oppfrisking og A: Bestått.** Testpersonen stadfesta A, B og C
  i lista etter oppfrisking. A gav ingen søknadstilgang, medan brukerstøtte
  var tilgjengeleg. Ingen feil blei meldt.
- **S02 – B og C: Bestått.** Testpersonen stadfesta berre brukerstøtte
  for både B og C, utan søknadstilgang. Ingen feil blei meldt.
- **Tilbakeføring: Bestått.** CLI sette `ScenarioName__c` tilbake til S01
  og stadfesta S01 med `subject-a` og `UseScenarioProvider__c=true`.
  Nettlesaren må oppfriskast før vidare testing.

### S04 med Community Plus, 2026-10-25

- Testpersonen godkjende mellombels byte av S01-brukaren til S04 i
  `nav-community-dev`, med tilbakeføring til S01 etter testen.
- CLI oppdaterte berre `ScenarioName__c` og stadfesta S04 med `subject-a`
  og `UseScenarioProvider__c=true`. Nettlesarresultat er ikkje stadfesta enno.
- Eksisterande avtaledelingar frå S01 er bevarte. Testen gjeld
  scenarioavhengig søknads-/brukerstøttetilgang, ikkje tilbakekalling av
  avtaletilgang.
- **S04 – oppfrisking og A: Bestått.** Testpersonen stadfesta A, B og C
  etter oppfrisking og søknadstilgang / synleg søknadsskjema for A.
  Ingen feil blei meldt.
- **S04 – B etter A: Bestått.** Testpersonen stadfesta at B ikkje gav
  søknadstilgang, medan brukerstøtte var tilgjengeleg. Søknadstilgangen
  frå A blei ikkje vidareført i denne overgangen. Ingen feil blei meldt.
- **S04 – B → C → A → B: Bestått.** Testpersonen stadfesta søknadstilgang
  for C og A, deretter berre brukerstøtte for B. Ingen feil blei meldt.
- **Tilbakeføring: Bestått.** CLI sette `ScenarioName__c` tilbake til S01
  og stadfesta S01 med `subject-a` og `UseScenarioProvider__c=true`.
  Nettlesaren må oppfriskast før vidare testing.

### Ny testøkt i `nav-community-dev`, 2026-10-25

- **S01 – innlogging: Bestått.** Testpersonen stadfesta at community opna som
  S01 via kontaktflyten. Read-only kontroll stadfesta at brukaren er aktiv
  og har Customer Community Plus.
- **S01 – organisasjonsliste: Bestått.** Testpersonen stadfesta A, B og C
  i organisasjonsveljaren. Ingen feiltekst blei meldt.
- **S01 – søknadstilgang for A: Bestått.** Testpersonen valde A, fekk
  søknadstilgang og såg søknadsskjemaet.
- **S01 – søknadstilgang for B: Bestått.** Testpersonen valde B og
  stadfesta søknadstilgang. Ingen feil blei meldt.
- **S01 – søknadstilgang for C: Bestått.** Testpersonen valde C og
  stadfesta søknadstilgang. Ingen feil blei meldt.
- **S01 – avtalevising for C: Bestått.** Med C vald opna testpersonen
  **Mine avtaler** og såg `AVT-000005` med status **Aktiv**. Dette stadfestar
  positiv avtalevising for C med Customer Community Plus i denne økta.
- **S01 – oppfrisking av organisasjonar: Bestått.** Etter
  **Oppdater organisasjoner** stadfesta testpersonen at A, B og C framleis
  blei viste, C framleis var vald og søknadstilgangen var tilgjengeleg.
  Ingen feil eller merknad om knappen blei meldt.

Legg til ei rad per steg når testpersonen har utført steget:

| Dato/tid | Scenario | Handling | Forventa | Observert | Status | Oppfølging |
| -------- | -------- | -------- | -------- | --------- | ------ | ---------- |

## Avvik og oppfølging

S05, S07 og S08 har stadfesta nettlesaravvik, som dokumentert ovanfor.
Rettingane nedanfor er automatisk validerte og deploya, men avvika er ikkje
lukka før ny stadfesta nettlesartest.

## Rettings- og oppsettsøkt 2026-10-25

### S05/S08-regresjon av ikkje-cachebar oppdatering — 2026-10-26

- Brukaren godkjende at assistenten gjennomførte og loggførde begge testane
  i den delte community-fana i `nav-community-dev`. Dette er
  assistent-observert nettlesarevidens, ikkje berre Jest-resultat.
- **Grunnlinje: Bestått.** CLI viste éi aktiv setting med S01 / subject-a /
  true. Nettlesaren viste A vald med søknadstilgang og utan feil.
- **S05: Bestått.** To oppdateringsforsøk viste «Ingen virksomheter er
  tilgjengelige», forklaring og neste handling. Begge gongene var veljar,
  tilgangspanel, teknisk feil og Deny-panel fråverande.
- **S05 → S01: Bestått utan reload.** Oppdateringsknappen gav A/B/C og A vald
  med søknadstilgang. Tomtilstanden forsvann og ingen feil blei viste.
- **S08 etter A: Bestått.** Etter oppdatering fanst berre B som organisasjon.
  Plasshaldaren var vald, utan tilgangspanel, teknisk feil eller Deny-panel.
- **Direkte B → plasshaldar → B: Bestått.** B gav brukerstøtte, men ingen
  søknadstilgang, begge gongene. Plasshaldaren fjerna tilgangen utan feil
  eller Deny-panel.
- **S08 → S01: Bestått utan reload.** Etter tilbakeføring og oppdatering
  blei A vald eksplisitt. A/B/C var tilgjengelege, søknad og brukerstøtte
  fungerte, og tomtilstand/feil var borte.
- **Sluttkontroll: Bestått.** CLI stadfesta nøyaktig éi aktiv setting:
  S01 / subject-a / true. Den delte fana blei ståande med A vald og tilgang.
- Ingen kodeendring, deploy, innsending av søknader eller redigering av avtalar
  blei utført i denne runden. Testen gjeld UI/ferskhenting; tilbakekalling av
  gamle record-delingsrettar er ikkje verifisert.

### Nettlesartest — S07 / subject-throws

#### Endeleg deploy og faktisk gjenoppretting — Bestått

- Brukaren godkjende målretta deploy og nettlesarretest i den delte fana.
  Faktisk deploykommando:

    ```bash
    rtk sf project deploy start \
      --source-dir force-app/externalAccess/classes/AAREG_HomeController.cls \
      --source-dir force-app/tests/classes/externalAccess/AAREG_AltinnScenarioJourneyTest.cls \
      --source-dir force-app/externalAccess/lwc/aareg_home \
      --target-org nav-community-dev --test-level RunSpecifiedTests \
      --tests AAREG_AltinnScenarioJourneyTest --tests AAREG_HomeControllerTest \
      --wait 10 --json
    ```

- **Deploy: Bestått.** `0AfJW00000nnWov0AE`, `checkOnly=false`,
  `success=true`, tre komponentar, 23/23 Apex-testar og ingen dekningsvarsel.
  Lokal full LWC-suite bestod med 24/24 testar.
- **Før test:** Assistenten lasta fana på nytt for å hente den nye koden.
  S01, A vald og søknadstilgang blei kontrollerte.
- **Exception under oppfrisking: Bestått.** Etter S07/subject-throws blei
  oppdatering køyrd tre gonger. Alle tre gav teknisk feil, ingen veljar,
  søknadstilgang, tomtilstand eller Deny-panel.
- **Gjenoppretting i same sideøkt: Bestått.** Etter tilbakeføring til
  S01/subject-a gav eitt klikk A/B/C, A vald, søknads- og brukerstøttetilgang,
  og null feilvarsel. Ingen reload blei gjort mellom exception og gjenoppretting.
- **Initial wire-exception: Bestått.** I ein andre variant blei sida lasta
  med S07/subject-throws, slik at sjølve første wire-oppslaget kasta exception.
  Teknisk feil blei observert utan veljar/tilgang. Deretter blei S01/subject-a
  sett tilbake; eitt klikk gav A/B/C, A vald og begge tilgangstypane, utan
  feilvarsel eller reload mellom feil og gjenoppretting.
- Dette er **assistent-observert nettlesarevidens** frå den delte fana, ikkje
  ei ny manuell stadfesting frå testpersonen eller berre mock-resultat.
- **Sluttstatus:** CLI viste nøyaktig éi aktiv scenarioinnstilling,
  S01 / subject-a / true. Den delte fana stod med A vald og fungerande tilgang.
  Det observerte gjenopprettingsavviket er lukka; eldre opne statuser nedanfor
  skildrar tidlegare fasar. Ingen søknader/avtalar blei endra i nettlesartesten.

#### Diagnose og ny eksplisitt oppdateringsbane

- Testpersonen delte den eksisterande community-fana i VS Code og godkjende
  ein ny S07/subject-throws → S01/subject-a-runde styrt av assistenten.
- **Reprodusert i ekte nettlesar:** S07 gav ein 500-feil med sanitert tekst
  «Synthetic organization exception.». Etter tilbakeføring til S01 fekk
  gjentekne oppdateringsforsøk framleis same exception, utan veljar.
  Diagnosen las berre kort feiltekst/status og kallmetadata; ingen credentials
  eller raw request-/responseinnhald er lagra her.
- S01 blei gjenoppretta som lagra innstilling. Reload i den delte fana gav
  A vald og søknadstilgang igjen. Reload er mellombels gjenoppretting, ikkje
  løysing på knappeavviket.
- Brukaren godkjende ny ikkje-cachebar `refreshOrganizationsWithRoles` på
  HomeController, med same lookup/scenario-policy som eksisterande lesing.
  Første sidelasting held fram med cachebar wire. Knappen bruker det nye
  kallet; sein gammal wire-tilstand får ikkje overskrive oppdateringsresultatet.
- Den nye metoden avviser null/annan målbrukar og logger berre statisk feiltekst
  ved exception. Response-level feil blir returnerte utan å bli tom suksess.
  Eksisterande debug av heile organisasjonsresponsen er fjerna frå felles
  lookup. Ingen scenario-sperrer, avtalereglar eller pakkeavhengigheiter er endra.
- **Jest raud:** Testen for ferskt oppslag etter initial wire-exception feila
  fordi det nye endpointet ikkje blei kalla. **Grøn:** 14/14 fokuserte testar.
  Dei eksisterande refresh-testane er flytta til det nye offentlege kallet,
  med same UI-forventningar for tom liste, feil, filtrering, val, tilgang og
  sperring av overlappande klikk.
- **Apex raud:** Dry-run feila med fire manglande-metode-kompileringsfeil før
  implementasjon. **Grøn:** 23/23 testar i samla Home-/journey-dry-run,
  `checkOnly=true`, utan testfeil eller dekningsvarsel. Nye testar dekkjer
  S01-suksess, response-level feil, exception og avvising av annan målbrukar.
- **Breiare Jest:** `rtk npm run test:unit -- -- --runInBand`: 6 suiter /
  24/24 grøne. Produksjonsendringane er enno ikkje deploya.

- Brukaren stadfesta A vald med søknadstilgang under S01 og godkjende
  mellombels S07 / subject-throws på den generiske brukaren i
  `nav-community-dev`. CLI kontrollerte innstillinga før testen.
- **Exception-bana ved organisasjonsoppslag: Bestått.** Testpersonen
  stadfesta stabil teknisk feil gjennom gjenteken oppfrisking, ingen gamle
  organisasjonsval eller tilgang, og verken S05-tomtilstand eller Deny-panel.
- Synleg feiltekst: «Henting av organisasjoner feilet. Vennligst prøv igjen
  eller refresh siden.»
- Testen gjeld organisasjonsoppslaget. Direkte rights-exception er ikkje
  nettlesarverifisert gjennom denne flyten, sidan organisasjonsfeilen sperrar
  vidare val.
- **CLI-tilbakeføring: Bestått.** Både scenario og alias er gjenoppretta:
  S01 / subject-a / true. Query stadfesta verdiane.
  Nettlesargjenoppretting ventar på testpersonen.

- **Nettlesargjenoppretting etter subject-throws: Avvik.** Testpersonen
  melde «Ingen velger og fortsatt feiltekst» etter oppdatering under
  gjenoppretta S01. Ny CLI-kontroll stadfesta framleis S01 / subject-a / true.
  Exception-testen er ikkje avslutta som bestått ende-til-ende; årsaka til
  manglande gjenoppretting er under undersøking.
- **Diagnostisk hard oppfrisking: Bestått.** Testpersonen stadfesta at A/B/C
  kom tilbake ved hard oppfrisking. Etterpå fungerte oppdateringsknappen og
  søknadstilgang for A. Dette er ei mellombels gjenoppretting, ikkje lukking
  av avviket ved oppfrisking i same sideøkt.
- Ny lokal DOM-test simulerer wire-exception og avvist refresh-promise,
  gjenteken feil og deretter ny wire-emisjon med det opphavlege S01-svaret.
  Fokusert Jest: **13/13 grøne utan produksjonsendring**. Komponenten
  gjenopprettar når mock-adapteren faktisk leverer suksess. Testen reproduserer
  derfor ikkje det observerte runtime-avviket og beviser ikkje at
  Salesforce sin wire/cache-bane fungerer etter exception.
- Ingen ny produksjonsretting eller deploy er gjort for dette avviket.
  Vidare diagnose treng skilje mellom avvist refresh, manglande ny wire-
  emisjon og ny serverfeil i den faktiske nettlesarøkta.

### S05 — utvida forklaring og neste handling

- Etter godkjend teknisk regresjonsrunde bad brukaren om neste steg:
  betre tomtilstand. Endringa er avgrensa til Home-UI, tre Custom Labels
  med norsk omsetjing og den fokuserte Jest-testen. Ingen tilgangsregel
  eller Apex-kontrakt er endra.
- Den korte teksten ved veljaren blir erstatta med ein eigen seksjon under
  organisasjonshandlingane, med overskrift, forklaring og neste handling.
  Eksisterande oppdateringsknapp blir brukt vidare.
- Norsk tekst:
    - «Ingen virksomheter er tilgjengelige»
    - «Vi finner ingen virksomheter du kan representere på denne siden. Du må
      velge en virksomhet før du kan bruke søknader, avtaler og brukerstøtte.»
    - «Prøv «Oppdater organisasjoner» for å hente listen på nytt. Hvis du
      forventer å se en virksomhet, be den som administrerer tilganger i
      virksomheten om å kontrollere tilgangen din i Altinn.»
- Seksjonen har `role="status"`, semantisk overskrift og avsnitt. Dette er
  informasjon om tomt resultat, ikkje ei teknisk feilmelding eller ein
  påstand om manglande rettar.
- **Raud:** Fokusert Jest gav 1 feil / 11 grøne fordi forklarande seksjon
  med overskrift mangla.
- **Grøn:** Same kommando
  `rtk npm run test:unit -- -- --runInBand force-app/externalAccess/lwc/aareg_home/__tests__/aareg_home.test.js`
  gav 12/12 grøne. Testen kontrollerer forklaring, neste handling,
  ingen tilgang/teknisk feil/misvisande rettigheitspanel og at seksjonen
  forsvinn ved vellukka oppfrisking tilbake til S01-data.
- **Breiare validering:** `rtk npm run test:unit -- -- --runInBand`:
  6 suiter, 22/22 grøne. Prettier-kontroll av dei seks endra UI-/test-/
  metadatafilene bestod.
- **Deploy-preview:** Berre `aareg_home`, dei tre nye Custom Labels og norsk
  Translations-komponent blei valde, utan konfliktar. Salesforce deployer
  norsk omsetjing som ein samla Translations-komponent. Registry-varsel om
  `GenOpAgentConfig` blei meldt; preview fullførte med status 0.
- **Ikkje deploya / ikkje nettlesarverifisert enno.** Den aktive scenario-
  innstillinga er ikkje endra som del av denne lokale UI-rettinga.

#### Første deploy og brukarprøving av S05-forklaringa

- Brukaren godkjende deploy av `aareg_home`, tre nye Custom Labels og norsk
  omsetjing til `nav-community-dev`.
- Kommandoen
  `rtk sf project deploy start --metadata LightningComponentBundle:aareg_home --metadata CustomLabel:AAREG_No_Organizations_Title --metadata CustomLabel:AAREG_No_Organizations_Description --metadata CustomLabel:AAREG_No_Organizations_Guidance --metadata Translations:no --target-org nav-community-dev --wait 10 --json`
  gav **Succeeded**, fem komponentar, null komponentfeil og `checkOnly=false`,
  deploy `0AfJW00000nnU2L0AU`. Ingen Apex-testar blei køyrde.
- Testpersonen stadfesta ny kode og A med søknadstilgang under S01 og godkjende
  mellombels S05. CLI stadfesta S05 / subject-a / true.
- **Funksjon: Bestått, visuell utforming: Må justerast.** Testpersonen
  stadfesta at det tekniske var riktig, men bad om sentrert plassering og
  same utforming, font og storleik som den eksisterande meldinga om manglande
  tilgang.
- CLI sette tilbake S01 / subject-a / true og kontrollerte verdiane før
  vidare kodearbeid. Nettlesargjenoppretting etter dette forsøket er ikkje
  stadfesta enno.
- Neste lokale justering bruker same community-temaklassar for bakgrunn og
  overskrift som `aareg_missingAccess`, med same padding og brødtekstfont/
  storleik. Teksten er framleis tomtilstandsteksten, ikkje Deny-meldinga.
  Ingen eksisterande Deny-komponent eller community-tema er endra.
- DOM-test for temaklassar feila før justeringa (1 feil / 11 grøne) og bestod
  etterpå (12/12). Dette verifiserer markup og funksjon, ikkje faktisk
  plassering eller font i nettlesaren. Ny visuell kontroll står att.

#### Godkjend justert utforming og avslutta S05 UX-test

- Etter uttrykkeleg godkjenning blei berre `aareg_home` deploya på nytt:
  `rtk sf project deploy start --metadata LightningComponentBundle:aareg_home --target-org nav-community-dev --wait 10 --json`.
  Deploy `0AfJW00000nnUjt0AE` gav **Succeeded**, éin komponent,
  `checkOnly=false` og null komponentfeil. Ingen Apex-testar blei køyrde.
  CLI gav same registry-varsel om `GenOpAgentConfig`; deployen fullførte.
- Før deploy bestod heile LWC-suiten på nytt:
  `rtk npm run test:unit -- -- --runInBand`, 6 suiter / 22 testar.
  Prettier-kontroll av endra HTML, CSS og Jest-test bestod.
- S05 / subject-a / true blei aktivert og kontrollert for ny visuell test.
- **S05 UX-retest: Bestått.** Testpersonen stadfesta at visinga var sentrert
  og i samsvar med den eksisterande tilgangsmeldinga, utan fleire merknader.
  Teststeget omfatta ny kode, forklaring/neste steg, ingen veljar/tilgang og
  stabil vising ved oppfrisking.
- **CLI-tilbakeføring: Bestått.** S01 / subject-a / true blei gjenoppretta og
  kontrollert.
- **Nettlesargjenoppretting: Bestått.** Testpersonen stadfesta at forklaringa
  forsvann, A/B/C kom tilbake og A gav søknadstilgang.
- Den opne S05-oppfølginga om forklaring og visuell utforming er **lukka**
  etter denne prøvinga. Tidlegare opne statuser nedanfor er historiske.
  `subject-throws` og tilbakekalling av gamle avtaledelingar er ikkje
  nettlesartesta som del av denne UX-endringa.

### Nettlesarretest etter deploy — S01-grunnlinje, 2026-10-25

- **Innlogging med generisk kontakt: Bestått.** Testpersonen stadfesta
  innlogging som den generiske testbrukaren.
- **S01-grunnlinje: Bestått.** Etter oppfrisking stadfesta testpersonen A/B/C
  i lista og søknadstilgang for A utan teknisk feil.
- Testpersonen såg òg plasshaldaren «-- Velg virksomheit --» i lista.
  Dette er tilsikta: eit eksplisitt tomt val skal vere tilgjengeleg, særleg
  når ein tidlegare vald organisasjon fell bort.
- CLI-kontroll før steget viste nøyaktig éi aktiv innstilling:
  S01 / subject-a / true. S05/S07/S08 er ikkje retesta i denne økta enno.

### Nettlesarretest etter deploy — S05, 2026-10-25

- Brukaren godkjende byte frå S01 med A vald til S05 på den generiske
  brukaren. CLI stadfesta S05 / subject-a / true før nettlesarsteget.
- **Teknisk S05-regresjon: Bestått.** Testpersonen stadfesta stabil
  tomtilstand, ingen veljar/tilgang og inga misvisande rettleiing.
  Synleg tekst: «Ingen organisasjoner er tilgjengelige.»
- **UX-oppfølging: Open.** Testpersonen opplevde resten av sida som heilt
  tom og venta ei tydelegare forklaring på manglande organisasjonar/tilgang.
  Det gamle misvisande panelet er borte, men tomtilstanden treng vurdering av
  forklaring og neste handling. Eit vellukka tomt organisasjonssvar beviser
  ikkje teknisk feil eller manglande Altinn-rettar; teksten må ikkje påstå det.
- **CLI-tilbakeføring: Bestått.** S01 / subject-a / true er gjenoppretta og
  kontrollert. Nettlesargjenoppretting ventar på testpersonen.
- **Nettlesargjenoppretting: Bestått.** Testpersonen stadfesta A/B/C tilbake
  og søknadstilgang for A utan feil.
- **Nytt avvik — historikkavhengig rekkjefølgje:** Ved val av C etter A hamnar
  A nedst, medan val av C etter B gir C/A/B. Koden byter vald organisasjon
  med elementet på første plass i den allereie omordna lista. Dermed kan
  A/B/C → C/B/A, medan B/A/C → C/A/B. Dette samsvarer med observasjonen;
  dette forklarte avviket før sorteringsrettinga nedanfor.
- Brukaren valde regelen **vald organisasjon først, resten alfabetisk og
  uavhengig av tidlegare val**.
- **Lokal raud–grøn:** To DOM-regresjonar med høvesvis A og B som lagra val
  feila før rettinga (2 feil / 10 grøne). Etter rettinga bestod 12/12.
  Testane brukar usortert kjeldeliste og kontrollerer første vising,
  gjentekne val, faktisk selected-verdi, rettssjekk på rett organisasjon og
  oppfrisking med C vald.
- Sorteringa byter ikkje lenger element i den historiske lista. Ho sorterer
  ei ny liste med vald organisasjon først, deretter norsk namnesortering og
  organisasjonsnummer som sekundærnøkkel ved like namn.
  Filtreringa av Person/organisasjonsformer ligg framleis i `setOrganizations`;
  tilgangsreglar og lagring er uendra.
- **Breiare lokal validering: Bestått.**
  `rtk npm run test:unit -- -- --runInBand` gav 6 suiter / 22 grøne testar.
  Prettier-kontroll av endra JS-/test-/guide-/loggfiler bestod.
- Brukaren godkjende deploy av berre `aareg_home` til `nav-community-dev`.
  `rtk sf project deploy start --source-dir force-app/externalAccess/lwc/aareg_home --target-org nav-community-dev --wait 10 --json`
  gav **Succeeded**, `checkOnly=false`, éin komponent og null komponentfeil,
  deploy `0AfJW00000nnSyD0AU`. Ingen Apex-testar blei køyrde i denne reine
  LWC-deployen. CLI gav registry-varselet
  «Unable to find type GenOpAgentConfig in registry»; deployen fullførte.
- Sorteringsrettinga blei deploya før nettlesarretesten nedanfor.
- **Nettlesarretest av sortering: Bestått.** Testpersonen stadfesta C/A/B
  både ved A → C og B → C, og etter oppfrisking med C vald. C gav
  søknadstilgang utan feil. Sorteringsavviket er dermed lukka i denne økta.

### Nettlesarretest etter deploy — S07, 2026-10-25

- Brukaren godkjende mellombels S07 på den generiske brukaren i
  `nav-community-dev`, med gyldig S01-val som utgangspunkt.
- CLI stadfesta S07 / subject-a / true før testen.
- **S07-regresjon: Bestått.** Testpersonen stadfesta at teknisk feil blei
  ståande gjennom gjenteken oppfrisking, utan gamle val eller tilgang.
  Ingen avvik blei meldt. Dette stadfestar response-error-flyten, ikkje
  den separate `subject-throws`-varianten eller direkte rights-oppslag.
- **CLI-tilbakeføring: Bestått.** S01 / subject-a / true er gjenoppretta
  og kontrollert. Nettlesargjenoppretting ventar på testpersonen.
- **Nettlesargjenoppretting etter S07: Bestått.** Testpersonen stadfesta at
  feilen forsvann, A/B/C kom tilbake og A gav søknadstilgang.

### Nettlesarretest etter deploy — S08, 2026-10-25

- Brukaren godkjende mellombels byte til S08 etter å ha stadfesta A vald
  med søknadstilgang under S01. CLI stadfesta S08 / subject-a / true.
- **Bortfall av A: Bestått.** Testpersonen stadfesta berre B tilgjengeleg,
  plasshaldar som synleg val og ingen tilgang før eksplisitt organisasjonsval.
- **Direkte val av B: Bestått.** Berre brukerstøtte, ikkje søknadstilgang.
  Det var ikkje nødvendig å velje plasshaldaren først.
- **Plasshaldar og nytt val: Bestått.** Plasshaldaren fjerna tilgangen utan
  feil, og nytt val av B gav berre brukerstøtte.
- **CLI-tilbakeføring: Bestått.** S01 / subject-a / true er gjenoppretta og
  kontrollert. Siste nettlesargjenoppretting ventar på testpersonen.
- **Siste nettlesargjenoppretting: Bestått.** Testpersonen stadfesta A/B/C
  tilbake og søknadstilgang for A utan teknisk feil.
- **Oppsummering av regresjonsrunden:** Generisk innlogging, S01-grunnlinje,
  stabil sortering, teknisk S05-regresjon, S07/subject-a, S08 og
  nettlesargjenoppretting etter kvart negativt scenario er bestått.
  S05 si forklaring/neste handling er framleis open UX-oppfølging.
  `subject-throws` er ikkje nettlesarretesta i denne runden.

### Éin generisk Community Plus-brukar

- Brukaren godkjende konsolidering til éin generisk testbrukar.
- Den tidlegare Permit-brukaren/kontakten er omnamna til
  **Synthetic Community Test User**. User/Contact er migrerte, ikkje erstatta;
  historikk, identitetskjede og gamle delingar er bevarte.
- Dei fire gamle scenario-brukarane er deaktiverte, og settingane deira har
  `UseScenarioProvider__c=false`. Historiske postar er ikkje sletta.
- Ny `verify-altinn-test-user.apex` feila først fordi gamle scenario-brukarar
  framleis var aktive. Etter migrering bestod han. Seed + verifikasjon er
  gjentekne med vellukka resultat for å kontrollere idempotens.
- Første seedforsøk viste at `upsert User` ikkje er støtta; skriptet bruker no
  eksplisitt insert/update avhengig av om brukaren finst.
- Read-only query stadfesta éin aktiv generisk brukar med Plus-lisens og fire
  inaktive gamle brukarar. Lisensquery: Plus 1 totalt / 1 i bruk; High Volume
  5 totalt / 0 i bruk. Aktiv brukarsetting er S01/subject-a/true.

Kommandoar som er køyrde med vellukka resultat:

```bash
rtk bash bin/create-scratch-org.sh --alias nav-community-dev \
  --post-steps-only --post-steps altinn-scenario-users
rtk sf apex run --target-org nav-community-dev --file bin/verify-altinn-test-user.apex
```

Dette er brukt i org-en, ikkje berre lokalt eller som dry-run.

### S05/S07/S08 – årsak og tilsikta åtferd

- **S05:** Manglar-rett-panelet blei vist utan gyldig organisasjonsval.
  Det blir no berre vist ved faktisk vald organisasjon og ordinær Deny,
  ikkje ved tom liste eller teknisk feil.
- **S07:** Feiltilstanden blei fjerna før ein ny wire-respons fanst.
  Gjenteken identisk feil kunne derfor etterlate gamle val/feilfri tilstand.
  Feilen blir no bevart fram til faktisk vellukka respons; gamle
  organisasjonar/tilgang blir tømde ved feil. Controlleren skil i tillegg
  teknisk rights-feil utan avgjerd frå eit eksplisitt Deny-svar.
- **S08:** Native select kunne vise B som første val etter at A fall bort,
  medan intern tilstand mangla eit gyldig val og ingen rettssjekk var køyrd.
  Eksplisitt vald plasshaldar gjer UI og tilstand like. Manuelt val av B
  utløyser lagring og rettssjekk; tomt/ugyldig val går ikkje til Apex.
- Feil ved lagring av organisasjonsval blir viste eksplisitt utan tilgang.
  Vellukka gjenoppretting frå response-feil til S01 er òg DOM-testa.

### Automatisk evidens

- **Jest raud:** Den fokuserte regresjonskøyringa gav 6 feil / 3 grøne før
  implementasjon.
- **Jest grøn:** 9/9 etter retting; utvida med feil ved lagring og
  gjenopprettingsassertions til 10/10.
- **Apex raud:** Journey-testen som krev teknisk exception feila med
  «A technical lookup failure must not become an ordinary denial.»
- **Apex grøn:** Samla controller-/journey-dry-run bestod 19/19, med
  `checkOnly=true` og utan dekningsblokkering.
  Ein gammal test for tom upstream-respons er oppdatert til teknisk
  feilkontrakt; testar for eksplisitt Deny er bevarte.
- Eksisterande `MIXED_DML_OPERATION` i
  `shouldShareAgreementsForSelectedOrganizationInTestContext` er isolert
  med `System.runAs` rundt User-oppdateringa i testoppsettet.

Vellukka fokuserte kommandoar:

```bash
rtk npm run test:unit -- -- --runInBand force-app/externalAccess/lwc/aareg_home/__tests__/aareg_home.test.js

rtk sf project deploy start --dry-run \
  --source-dir force-app/externalAccess/classes/AAREG_HomeController.cls \
  --source-dir force-app/externalAccess/classes/AAREG_HomeControllerTest.cls \
  --source-dir force-app/tests/classes/externalAccess/AAREG_AltinnScenarioJourneyTest.cls \
  --source-dir force-app/externalAccess/lwc/aareg_home \
  --target-org nav-community-dev --test-level RunSpecifiedTests \
  --tests AAREG_AltinnScenarioJourneyTest --tests AAREG_HomeControllerTest \
  --wait 10 --json
```

### Manuell verifikasjon — status ved første deploy

Tabellen viser status før den guida retestøkta ovanfor. Retestøkta stadfestar
no innlogging, S05/S07/S08 og gjenoppretting; berre S05 si UX-oppfølging står
open av dei observerte regresjonane.

| Kontroll                                   | Status      | Forventa                                                                |
| ------------------------------------------ | ----------- | ----------------------------------------------------------------------- |
| Permanent deploy av rettingar              | Bestått     | Godkjend deploy 0AfJW00000nnQA10AM, fire komponentar, 19/19 Apex-testar |
| Innlogging med generisk kontaktnamn        | Ikkje køyrd | Same community-brukar/historikk                                         |
| S05-regresjon                              | Ikkje køyrd | Tomtilstand utan misvisande manglar-rett-panel                          |
| S07-regresjon                              | Ikkje køyrd | Varig teknisk feil ved gjenteken oppfrisking; ingen gamle val           |
| S08-regresjon                              | Ikkje køyrd | Eksplisitt plasshaldar, deretter berre støtte ved direkte val av B      |
| S01-gjenoppretting etter kvar negativ test | Ikkje køyrd | A/B/C og søknadstilgang utan teknisk feil                               |

Følg [den sjølvbetente testguiden](./test-guide.md). Før nye resultat som
nye observasjonar; dei historiske avvika ovanfor skal ikkje skrivast om til
bestått på grunnlag av Jest/Apex åleine.

### Endeleg validering og godkjend deploy

- `rtk npm run test:unit -- -- --runInBand`: **Bestått**, 6 suiter / 20 testar.
- `rtk bash bin/tests/create-scratch-org.test.sh`: **Bestått**, 530 assertions,
  0 feil.
- Prettier `--write` og deretter `--check` på dei ti endra støtta
  Apex-/UI-/test-/dokumentasjonsfilene: **Bestått**. Dei anonyme `.apex`-
  skripta inngår ikkje i prosjektets vanlege Prettier-glob; seed- og
  verifikasjonsskripta er kompilerte/køyrde i scratch-org-en.
- Brukaren godkjende uttrykkeleg den avgrensa permanente deployen til
  `nav-community-dev`. Ingen andre orgar eller avhengigheitspakkar blei endra.
- Deploy `0AfJW00000nnQA10AM`: **Bestått**, `checkOnly=false`,
  `success=true`, fire komponentar og 19/19 Apex-testar, 0 testfeil.

Faktisk deploykommando:

```bash
rtk sf project deploy start \
  --source-dir force-app/externalAccess/classes/AAREG_HomeController.cls \
  --source-dir force-app/externalAccess/classes/AAREG_HomeControllerTest.cls \
  --source-dir force-app/tests/classes/externalAccess/AAREG_AltinnScenarioJourneyTest.cls \
  --source-dir force-app/externalAccess/lwc/aareg_home \
  --target-org nav-community-dev --test-level RunSpecifiedTests \
  --tests AAREG_AltinnScenarioJourneyTest --tests AAREG_HomeControllerTest \
  --wait 10 --json
```

Etter deploy:

- `rtk sf apex run --target-org nav-community-dev --file bin/verify-altinn-test-user.apex`:
  **Bestått**, utan dataendringar.
- `rtk sf data query --target-org nav-community-dev --query "SELECT ScenarioName__c, SubjectAlias__c, UseScenarioProvider__c FROM AAREG_AltinnScenarioSetting__c WHERE UseScenarioProvider__c = true"`:
  **Bestått**, nøyaktig éi rad med S01 / subject-a / true.
- Ved denne deploykontrollen var nettlesarinnlogging og S05/S07/S08-retest
  enno ikkje køyrde. Dei seinare stadfesta resultata står i
  nettlesarretestavsnitta ovanfor.
