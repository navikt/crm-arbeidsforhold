# Testlogg for Altinn-scenario

**Gjeldande målorg:** `nav-community-dev`; første økt nedanfor er historisk
frå `crm-arbeidsforhold`  
**Testguide:** [test-guide.md](./test-guide.md)  
**Loggregel:** Berre observerte resultat blir markerte som bestått. Nettlesar-
resultat blir stadfesta av testpersonen; CLI/Apex-resultat blir stadfesta av
køyringa.

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
