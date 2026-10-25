# Testguide: Altinn-scenario med éin Community Plus-brukar

**Målorg:** `nav-community-dev`, aldri produksjon, SIT2 eller DevHub  
**Testbrukar/kontakt:** `Synthetic Community Test User`  
**Testlogg:** [altinn-test-log.md](./altinn-test-log.md)  
**Status:** Brukarmigrering og godkjende deployar er gjennomførte i
`nav-community-dev`. S05/S07/S08-regresjonane, sortering og S01-gjenoppretting
er stadfesta i nettlesaren. S05 si utvida forklaring med same sentrerte
utforming som Deny-meldinga er deploya og visuelt godkjend. Gjenoppretting til
S01 etter UX-testen er òg stadfesta.
Siste LWC-suite: 22/22 grøne; controller-deploy: 19/19 Apex.

## 1. Kva testen beviser

Scenario-provideren gir syntetiske Altinn-svar til den vanlege applikasjonen.
Vi testar organisasjonsval, søknads-/brukerstøttetilgang og vising av kopla
søknader/avtalar. Dette testar **ikkje** ekte Altinn, autentisering mot Altinn
eller produksjonsdata.

Den same generiske Plus-brukaren skal brukast i alle scenario og i andre
community-testar som krev vanleg Salesforce-deling. Byt scenario, ikkje brukar.
Dei fire gamle scenario-brukarane er inaktive historiske postar; dei er ikkje
sletta. Den tidlegare Permit-brukaren og kontakten er omnamna, ikkje erstatta.
Eksisterande historikk, identitet og delingar er bevarte.

**Viktig tilgangsgrense:** Scenariobyte trekkjer ikkje tilbake tidlegare
`Agreement__Share`-postar. Ein nettlesartest med denne gjenbrukte brukaren
beviser derfor ikkje at gamle avtalar er utilgjengelege på record-nivå etter
Deny. Isolerte Apex-testar kontrollerer at nye delingar ikkje blir oppretta ved
Deny/feil. Ikkje rydd gamle delingar manuelt som del av guiden.

Bruk berre syntetiske data. Ikkje send inn søknader, avslutt avtalar, nullstill
passord eller loggfør personident, brukarnamn, Salesforce-ID, token, cookie
eller org-URL. Ta berre med scenario, organisasjonsbokstav, synleg resultat
og sanitert feiltekst i testloggen.

## 2. Klargjering og målorg

Køyr kommandoane frå repository-rota i ein terminal med Salesforce CLI.
Eksempla bruker `rtk`, som i dette prosjektet. Utan RTK kan du køyre same
kommando utan det første `rtk`. CLI-kommandoar skal alltid ha eksplisitt alias;
ikkje endre standardorg eller stol på han.

### 2.1 Kontroller miljøet

```bash
rtk sf data query --target-org nav-community-dev \
  --query "SELECT IsSandbox FROM Organization"
```

Forventa: éi rad med `IsSandbox=true`. Stadfest òg at aliaset peikar på den
scratch-org-en du fekk oppretta for Community Plus. Stopp ved feil miljø,
utgått org eller manglande autentisering; ikkje prøv ein annan org.

### 2.2 Berre dersom org-en manglar oppsett

`nav-community-dev` er allereie sett opp. **Hopp over denne delen ved vanleg
testing.** Oppsett endrar metadata og data, og krev godkjenning frå
miljøansvarleg før køyring.

For ein eksisterande, tom og godkjend scratch-org med dette aliaset og
`CustomerCommunityPlus`-feature, sjå først skripthjelpa:

```bash
rtk bash bin/create-scratch-org.sh --help
```

Installer manifestavhengigheiter og køyr deploy, permission sets, grunnlagsdata,
community-publisering og generisk testbrukaroppsett, **utan** å opprette eller
slette org-en:

```bash
rtk bash bin/create-scratch-org.sh --alias nav-community-dev --skip-org \
  --post-steps deploy,permsets,data,community,altinn-scenario-users
```

Ikkje køyr standardvarianten utan `--skip-org` på ein eksisterande testorg.
Ikkje finn på installasjonsnøklar eller pakkeversjonar; bruk dokumentert
oppsett i [bin-guiden](../../../bin/README.md). Stopp ved installasjonsfeil.

For å reparere berre testdata/testbrukar i ein ferdig installert org:

```bash
rtk bash bin/create-scratch-org.sh --alias nav-community-dev \
  --post-steps-only --post-steps altinn-scenario-users
```

Dette seedet er idempotent, men er **ikkje read-only**: det oppdaterer
syntetiske data, migrerer/aktiverer den generiske brukaren, deaktiverer gamle
seed-brukarar og set den aktive brukarinnstillinga tilbake til S01.
Avslutt pågåande testar før du køyrer det. Ikkje bruk seedet for vanlege
scenariobyte.

### 2.3 Kontroller testbrukar og lisens

```bash
rtk sf apex run --target-org nav-community-dev \
  --file bin/verify-altinn-test-user.apex

rtk sf data query --target-org nav-community-dev \
  --query "SELECT Name, IsActive, Profile.UserLicense.Name FROM User WHERE Username LIKE 'aareg.community.test.%' OR Username LIKE 'aareg.altinn.%' ORDER BY IsActive DESC, Name"

rtk sf data query --target-org nav-community-dev \
  --query "SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense WHERE Name IN ('Customer Community Plus','High Volume Customer Portal') ORDER BY Name"
```

Forventa:

- Verifikasjonsskriptet fullfører utan assertion-feil.
- Éin aktiv seed-brukar heiter `Synthetic Community Test User`, med lisens
  `Customer Community Plus`. Gamle scenario-brukarar, dersom dei finst, er
  inaktive.
- Dei to permission sets `AAREG_CommunityPermission` og
  `AAREG_AltinnScenarioUser` er tildelte, og den eksplisitte brukarsettinga
  er aktiv med eit kjent scenario og `subject-a`.
- I den noverande org-en: Plus `TotalLicenses=1`, `UsedLicenses=1`;
  High Volume `UsedLicenses=0`.

Verifikasjonsskriptet les data og gjer assertions, men endrar ikkje scenario.
Det godtek S01–S08 med `subject-a`; gjenopprett dette aliaset først dersom du
har testa `subject-throws`.

**GUI-alternativ:** Setup → Users → Users → finn den generiske brukaren.
Kontroller Active, User License/Profile og Permission Set Assignments.
Ikkje aktiver dei gamle scenario-brukarane.

### 2.4 Kontroller organisasjonar og produktdata

```bash
rtk sf data query --target-org nav-community-dev \
  --query "SELECT INT_OrganizationNumber__c, Name FROM Account WHERE Name LIKE 'Synthetic Altinn Organization %' AND INT_OrganizationNumber__c IN ('111111111','222222222','333333333','444444444') ORDER BY INT_OrganizationNumber__c"

rtk sf data query --target-org nav-community-dev \
  --query "SELECT OrganizationNumber__c, Status__c, Account__r.Name FROM Application__c WHERE Email__c LIKE 'aareg.altinn.application.%@example.invalid' AND OrganizationNumber__c IN ('111111111','222222222','333333333','444444444') ORDER BY OrganizationNumber__c"

rtk sf data query --target-org nav-community-dev \
  --query "SELECT Name, OrganizationNumber__c, Status__c, Application__r.Status__c FROM Agreement__c WHERE OrganizationNumber__c IN ('111111111','222222222','333333333','444444444') ORDER BY OrganizationNumber__c"
```

| Bokstav | Syntetisk organisasjonsnummer | Forventa grunnlag                 |
| ------- | ----------------------------- | --------------------------------- |
| A       | `111111111`                   | Konto, søknad `New`, aktiv avtale |
| B       | `222222222`                   | Konto, søknad `New`, aktiv avtale |
| C       | `333333333`                   | Konto, søknad `New`, aktiv avtale |
| D       | `444444444`                   | Konto, søknad `New`, aktiv avtale |

Noter avtalane frå den faktiske queryen; autogenererte avtalenummer kan vere
ulike mellom orgar. Ved manglande data: stopp og undersøk oppsettet. Ikkje
opprett avtalar eller delingspostar manuelt for å få testen til å sjå grøn ut.

## 3. Opne testbrukaren i GUI

1. Opne intern Salesforce med den godkjende administratorinnlogginga:
   `rtk sf org open --target-org nav-community-dev`.
2. Ha intern Salesforce/Setup i éi fane og community i ei anna.
3. Opne **Contacts** frå navigasjonen eller App Launcher.
4. Finn og opne **Synthetic Community Test User**.
5. Bruk kontaktens etablerte **Log in to Experience as User**-handling
   (kan liggje under handlingsmenyen).
6. Vel Aa-registeret-community dersom du får nettstadval.
7. Kontroller at Aa-registeret-startsida opnar som testbrukaren, ikkje som
   intern administrator.

Det skal ikkje vere nødvendig å setje eller dele passord. Dersom handlinga
manglar, kontroller at du har rett kontakt, at brukaren er aktiv, og at
community er publisert med rett medlemskap. Stopp dersom dette ikkje er på
plass; ikkje bruk ein tilfeldig annan portalbrukar.

## 4. Slik byter du scenario – GUI eller CLI

Bruk same brukar gjennom heile testen. Vel **éin** av metodane nedanfor.
Endring av innstillinga åleine oppdaterer ikkje nettlesarens cache.

### 4.1 GUI: hierarchy Custom Setting

1. Gå til administratorfana → **Setup**.
2. Søk etter **Custom Settings** i Quick Find.
3. Finn **Altinn Scenario Setting**, og vel **Manage**.
4. Under brukar-/profilinnstillingar: finn rada for
   **Synthetic Community Test User**, og vel **Edit**.
5. Kontroller at **Location** er denne brukaren. Ikkje rediger eller opprett
   org-default eller profilinnstilling. Dersom brukar-rada manglar, stopp og
   reparer seedoppsettet.
6. Set **Scenario Name** til til dømes `S04`.
7. Set **Subject Alias** til `subject-a`.
8. La **Use Scenario Provider** vere avkryssa.
9. Lagre, opne rada igjen og kontroller dei tre verdiane.

### 4.2 CLI: finn den faktiske setting-ID-en

```bash
rtk sf data query --target-org nav-community-dev \
  --query "SELECT Id, Name FROM User WHERE IsActive = true AND Username LIKE 'aareg.community.test.%'"
```

Det skal vere nøyaktig éin brukar. Kopier den faktiske `Id`-verdien til
terminalen, ikkje til testloggen:

```bash
read -r ALTINN_USER_ID
```

Lim inn ID-en og trykk Enter. Finn deretter berre denne brukaren si setting:

```bash
rtk sf data query --target-org nav-community-dev \
  --query "SELECT Id, SetupOwnerId, ScenarioName__c, SubjectAlias__c, UseScenarioProvider__c FROM AAREG_AltinnScenarioSetting__c WHERE SetupOwnerId = '$ALTINN_USER_ID'"
```

Det skal vere nøyaktig éi rad. Kopier denne rada sin `Id` til ein ny variabel:

```bash
read -r ALTINN_SETTING_ID
```

Lim inn setting-ID-en og trykk Enter. ID-en er ikkje brukar-ID-en.
Køyr kommandoane vidare i **same terminal**. Ved ny terminal må variablane
lesast inn på nytt frå faktiske queryresultat.

For kvart steg set du ønskja scenario og oppdaterer:

```bash
ALTINN_SCENARIO=S04
rtk sf data update record --target-org nav-community-dev \
  --sobject AAREG_AltinnScenarioSetting__c --record-id "$ALTINN_SETTING_ID" \
  --values "ScenarioName__c='$ALTINN_SCENARIO' SubjectAlias__c='subject-a' UseScenarioProvider__c=true"

rtk sf data query --target-org nav-community-dev \
  --query "SELECT ScenarioName__c, SubjectAlias__c, UseScenarioProvider__c FROM AAREG_AltinnScenarioSetting__c WHERE Id = '$ALTINN_SETTING_ID'"
```

Byt `S04` på første linje til `S01`, `S02`, `S03`, `S05`, `S06`, `S07` eller
`S08` etter teststeget. Fortset berre dersom oppdateringa lukkast og queryen
viser ønskja scenario, `subject-a` og `true`.

### 4.3 Hent ny tilstand i community

Etter **kvart** scenariobyte:

1. Gå tilbake til community-startsida.
2. Trykk **Oppdater organisasjoner**, også dersom sida viser tom liste/feil.
3. Vent til oppfrisking/rettskontroll er ferdig. Knappen skal vere sperra
   medan oppfriskinga går. Ikkje dobbeltklikk.
4. Kontroller organisasjonsliste, valt organisasjon, feiltekst og tilgang.
5. Ved manglande gyldig val: vel organisasjon manuelt og vent på ny kontroll.

Ein vanleg reload åleine er ikkje bevis på at nye scenarioverdiar er henta:
organisasjonsoppslaget er cacheable. Ikkje slå av scenario-provideren for å
«rette» ein test; det ville velje ordinær integrasjon i staden.

## 5. Scenario og testrekkjefølgje

| Scenario | Val i UI               | Søknad                | Brukerstøtte                  |
| -------- | ---------------------- | --------------------- | ----------------------------- |
| S01      | A, B, C                | Ja, alle              | Ja, alle                      |
| S04      | A, B, C                | Ja for A/C, nei for B | Ja, alle                      |
| S02      | A, B, C                | Nei                   | Ja, alle                      |
| S03      | A, B, C                | Nei                   | Nei                           |
| S06      | A, D                   | Ja, begge             | Ja, begge                     |
| S05      | Ingen                  | Nei                   | Nei                           |
| S07      | Ingen ved oppslagsfeil | Nei                   | Nei                           |
| S08      | B                      | Nei                   | Ja, etter eksplisitt val av B |

Alle bruker `subject-a` med mindre steget seier noko anna. «Ja» gjeld
tilgangsstyrt UI, ikkje påstand om tilbakekalling av gamle record-delingsrettar.

### 5.1 S01 – grunnlinje og kopla data

1. Set S01 med metoden i del 4, og oppfrisk.
2. Kontroller at A, B og C står i veljaren. Ingen teknisk feil skal visast.
3. Vel A. Kontroller søknadstilgang og synleg søknadsskjema.
4. Gå gjennom relevante felt/visingar **utan** innsending eller lagring.
   Noter kva felt/visingar du faktisk kontrollerer; tilgang åleine beviser
   ikkje at heile søknadsflyten er testa.
5. Opne **Mine avtaler** frå startsida. Kontroller den aktive avtalen for A
   mot preflight-queryen. Ikkje endre eller avslutt han.
6. Gå tilbake til startsida; gjenta val og avtalevising for B og C.
7. Med C vald: trykk **Oppdater organisasjoner**.
8. Forventa: A/B/C finst framleis, C er faktisk vald og tilgang blir
   kontrollert på nytt. Ingen tomtilstand eller feil skal bli ståande.
9. Loggfør resultata for kvar organisasjon og avtale, ikkje berre S01 samla.

**Sorteringsregresjon:** Vald organisasjon skal stå først, resten alfabetisk
etter namn, uavhengig av tidlegare val. Vel A → C og kontroller C/A/B.
Vel deretter B → C og kontroller same C/A/B. Plasshaldaren skal framleis vere
tilgjengeleg øvst i menyen. Trykk oppdater med C vald og kontroller at både
valet og rekkjefølgja blir bevarte. Sorteringsrettinga er Jest-verifisert,
deploya og stadfesta i nettlesaren i `nav-community-dev`.

### 5.2 S04 – ulik tilgang ved organisasjonsbyte

1. Set S04 og oppfrisk.
2. Vel A → B → C → A → B, og vent etter kvart val.
3. A/C skal ha søknadstilgang. B skal berre ha brukerstøtte, ikkje
   søknadsskjema. B skal ikkje arve A/C si søknadstilgang.
4. Loggfør kvart avvik med vald organisasjonsbokstav.
5. Gjenopprett S01 etter del 6.

### 5.3 S02 – berre brukerstøtte

1. Set S02 og oppfrisk.
2. Vel A, B og C etter tur.
3. Kontroller brukerstøtte, men ikkje søknadstilgang, for alle tre.
4. Ikkje bruk eventuelle gamle avtaledelingar som bevis på feil Altinn-avgjerd.
5. Gjenopprett S01 etter del 6.

### 5.4 S03 – eksplisitt Deny

1. Set S03 og oppfrisk.
2. Vel A, B og C etter tur.
3. For kvar organisasjon: ingen søknads-/brukerstøttetilgang.
   Det vanlege panelet om manglande Altinn-rett kan visast; ingen teknisk
   oppslagsfeil skal visast.
4. Testen beviser UI-gating. Han beviser ikkje at tidlegare avtaledelingar
   er trekte tilbake.
5. Gjenopprett S01 etter del 6.

### 5.5 S06 – filtrering og organisasjon D

1. Set S06 og oppfrisk.
2. Kontroller at berre A og D er valbare.
   Råsvaret har òg B/ENK, C/BEDR og Person; dei skal ikkje visast i dagens UI.
3. Vel A og D. Begge skal gi søknadstilgang.
4. Med D vald: opne **Mine avtaler** og kontroller D sin aktive avtale mot
   preflight-queryen.
5. Gjenopprett S01 etter del 6.

### 5.6 S05 – tom liste utan misvisande rettleiing

1. Start med S01 og A vald, med synleg tilgang.
2. Set S05 og trykk **Oppdater organisasjoner**.
3. Forventa: tydeleg tomtilstand, ingen organisasjonsveljar og ingen tilgang.
4. Panelet «Du mangler rettighet i Altinn …» skal **ikkje** visast under
   tomtilstanden eller be deg velje i ein nedtrekksmeny som ikkje finst.
5. Trykk oppdater igjen. Tomtilstanden skal vere stabil.
6. Gjenopprett S01 etter del 6.

**Ny UX-retest etter deploy:** Tomtilstanden skal vere ein sentrert seksjon med
same bakgrunn og typografi som den eksisterande meldinga om manglande tilgang,
under organisasjonshandlingane, med overskrifta «Ingen virksomheter er
tilgjengelige». Teksten skal forklare at ei verksemd må veljast før bruk av
søknader, avtalar og brukerstøtte, og be brukaren prøve «Oppdater organisasjoner».
Dersom brukaren ventar ei verksemd, skal teksten vise til den som administrerer
tilgangar i verksemda for kontroll i Altinn, utan å påstå at rettar manglar.
Knappen skal framleis kunne brukast. Etter tilbakeføring til S01 og oppfrisking
skal seksjonen forsvinne, og A/B/C og tilgang fungere igjen.

### 5.7 S07 – teknisk feil og gjenoppretting

1. Start med S01 og A vald, med synleg tilgang.
2. Set S07 med `subject-a`, og trykk **Oppdater organisasjoner**.
3. Forventa: teknisk feilvarsel, ingen gammal organisasjonsveljar og ingen
   søknads-/brukerstøttetilgang. Feilen skal ikkje presenterast som vanleg Deny.
4. Trykk oppdater to gonger til, og vent mellom forsøka.
   Feilen skal framleis visast; A/B/C skal ikkje bli valbare frå gammal tilstand.
   Ikkje lukk feilvarselet manuelt når du testar at det blir ståande.
5. Gjenopprett S01 etter del 6, og stadfest både liste og tilgang.

**Ekstra exception-test:** Set S07 og **Subject Alias** til `subject-throws`
i same brukarsetting. Oppfrisk, kontroller teknisk feil/ingen tilgang, og
gjenopprett både S01 **og** `subject-a` etterpå. I CLI kan du bruke:

```bash
rtk sf data update record --target-org nav-community-dev \
  --sobject AAREG_AltinnScenarioSetting__c --record-id "$ALTINN_SETTING_ID" \
  --values "ScenarioName__c='S07' SubjectAlias__c='subject-throws' UseScenarioProvider__c=true"
```

Organisasjonsfeilen sperrar den vidare rights-flyten i nettlesaren.
S07-feil ved direkte rettsoppslag er derfor i tillegg dekt av Apex-journey-
testen, ikkje påstått nettlesarverifisert gjennom denne flyten.

### 5.8 S08 – vald organisasjon fell bort

1. Set S01, oppfrisk og **vel A**. Stadfest søknadstilgang.
2. Set S08 utan å logge ut eller endre organisasjon først.
3. Trykk **Oppdater organisasjoner**.
4. Forventa: berre B finst som organisasjon, men veljaren viser
   **-- Velg virksomhet --**, ikkje eit tilsynelatande automatisk val av B.
   A si tilgang er borte; ingen søknad eller brukerstøtte er aktiv før nytt val.
5. Vel B direkte. Du skal ikkje måtte velje plasshaldaren først.
6. Forventa: berre brukerstøtte, ikkje søknadstilgang.
7. Vel plasshaldaren. Ingen tilgang eller misvisande Deny-panel skal visast.
8. Vel B igjen og kontroller brukerstøtte på nytt.
9. Gjenopprett S01 etter del 6.

## 6. Gjenoppretting – også ved avbroten test

1. I Setup brukar du del 4.1 med **Scenario Name=S01**,
   **Subject Alias=subject-a** og **Use Scenario Provider=true**.
   Alternativt, i terminalen der setting-ID-en er kontrollert:

    ```bash
    rtk sf data update record --target-org nav-community-dev \
      --sobject AAREG_AltinnScenarioSetting__c --record-id "$ALTINN_SETTING_ID" \
      --values "ScenarioName__c='S01' SubjectAlias__c='subject-a' UseScenarioProvider__c=true"

    rtk sf data query --target-org nav-community-dev \
      --query "SELECT ScenarioName__c, SubjectAlias__c, UseScenarioProvider__c FROM AAREG_AltinnScenarioSetting__c WHERE Id = '$ALTINN_SETTING_ID'"
    ```

2. Kontroller dei lagra verdiane. Ein vellukka kommando åleine er ikkje
   nettlesarbevis.
3. Gå til community-startsida og trykk **Oppdater organisasjoner**.
4. Stadfest A/B/C, vel A og kontroller søknadstilgang utan teknisk feil.
5. Køyr `rtk sf apex run --target-org nav-community-dev --file bin/verify-altinn-test-user.apex`.
6. Før både CLI-/GUI-innstillingskontrollen og nettlesargjenopprettinga i loggen.
7. Dersom gjenoppretting feilar: loggfør blokkeringa og stopp vidare testing.

## 7. Testlogg og feilsøking

Før éi rad per handling i [testloggen](./altinn-test-log.md):

| Dato/tid | Scenario/alias | Organisasjon | Handling                | Forventa     | Observert | Status      | Evidens/oppfølging |
| -------- | -------------- | ------------ | ----------------------- | ------------ | --------- | ----------- | ------------------ |
| Fyll inn | S08/subject-a  | B            | Vel B etter oppfrisking | Berre støtte | Fyll inn  | Ikkje køyrd | Fyll inn           |

Bruk **Bestått**, **Avvik**, **Blokkert** eller **Ikkje køyrd**.
Automatisk Jest/Apex-resultat er ikkje erstatning for observert GUI-resultat.
Før også tilbakeføring, og marker scenarioet som uavslutta dersom ho manglar.

Ved avvik:

- **Gamle organisasjonar:** query/reopne den faktiske brukarsettinga; kontroller
  alias, brukar og scenario. Trykk oppdater, ikkje berre reload.
- **Ingen organisasjonar:** skil S05-tomtilstand frå S07-teknisk feil.
- **Gamalt namn i kontaktlista:** kontroller migreringa med del 2.3; ikkje
  opprett ein ny Plus-brukar.
- **Tom avtaleoversikt:** kontroller vald organisasjon, preflight-data,
  Plus-lisens og permission sets. Ikkje lag manuelle delingar.
- **Permission-/policy-feil:** kontroller brukarsetting og scenario-permission;
  ikkje aktiver org-/profil-default eller fjern sandbox-sperra.
- **Nettlesaren har ikkje rettinga:** den registrerte deployen er gjennomført
  i `nav-community-dev`. Ved ei ny kodeendring er kontrollen nedanfor berre
  dry-run; ein ny permanent deploy må vere godkjend og fullført.

### Automatiske kontrollar før nettlesarretest

```bash
rtk npm run test:unit -- -- --runInBand

rtk sf project deploy start --dry-run \
  --source-dir force-app/externalAccess/classes/AAREG_HomeController.cls \
  --source-dir force-app/externalAccess/classes/AAREG_HomeControllerTest.cls \
  --source-dir force-app/tests/classes/externalAccess/AAREG_AltinnScenarioJourneyTest.cls \
  --source-dir force-app/externalAccess/lwc/aareg_home \
  --target-org nav-community-dev --test-level RunSpecifiedTests \
  --tests AAREG_AltinnScenarioJourneyTest --tests AAREG_HomeControllerTest \
  --wait 10 --json
```

Dry-run endrar ikkje org-en permanent. Etter eksplisitt deploy-godkjenning kan
same deploykommando køyrast **utan `--dry-run`**, med uendra målorg, source-
avgrensing og testar. Noter faktisk deployresultat før du testar GUI på nytt.

## 8. Når vi testar saman

Vi tek eitt steg om gongen. Assistenten forklarer handlinga, kan hente
read-only data frå `nav-community-dev`, spør kva du faktisk såg og fører
resultatet i loggen. Ingen GUI-test blir kalla bestått før du har stadfesta
han. Guiden over kan òg følgjast utan assistenten.
