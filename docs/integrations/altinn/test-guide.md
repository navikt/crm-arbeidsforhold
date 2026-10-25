# Stegvis testguide for Altinn-scenario

**Målmiljø:** berre scratch-org-aliaset `nav-community-dev`  
**Status:** klar for guida brukarprøving; nettlesarforløpa er ikkje stadfesta  
**Testlogg:** [altinn-test-log.md](./altinn-test-log.md)

## Føremål og avgrensing

Guiden hjelper ein testperson gjennom den faktiske Experience Cloud-opplevinga
med Altinn-scenario, syntetiske organisasjonar og kopla Salesforce-data. Han
skil mellom det som er testa med Apex/Jest, det som er kontrollert direkte i
scratch-org-en, og det testpersonen ser i nettlesaren.

Scenario-provideren simulerer Altinn-svar. Testen stadfestar derfor ikkje ekte
Altinn, Altinn-autentisering eller produksjonsdata.

### Sikker bruk

- Kontroller alltid at kommandoar rettar seg mot `nav-community-dev`.
- Ikkje bruk SIT2, produksjon, DevHub eller andre orgar.
- Ikkje send passord, token, cookie eller innloggingsopplysningar i chat eller
  testloggen.
- Scratch-seedet set ikkje passord på portalbrukarane. Bruk berre ein godkjend
  innloggingsmåte som alt er sett opp for testmiljøet. Ikkje nullstill eller
  del ut passord som del av denne testen.
- Ikkje endre scenarioinnstillingar under stega utan at guiden først ber om
  uttrykkeleg stadfesting. Etter eventuelle mellombelse endringar skal
  opphavleg scenario bli sett tilbake.
- Ta skjermbilete eller noter berre syntetisk scenario, organisasjonsbokstav,
  synleg resultat og feiltekst utan personopplysningar eller innloggingsdata.

## Scenariooversikt

| Scenario | Organisasjonar i Altinn-svaret            | Forventa rettar                                                  | Kva vi ser etter                                                             |
| -------- | ----------------------------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| S01      | A, B, C                                   | Alle tre: søknad Permit og brukerstøtte Permit                   | Vanleg søknadstilgang og at rett organisasjon sine aktive avtalar blir delte |
| S02      | A, B, C                                   | Alle tre: søknad Deny og brukerstøtte Permit                     | `hasAccess=true`, `hasApplicationAccess=false`                               |
| S03      | A, B, C                                   | Alle tre: Deny på begge ressursar                                | Ingen tilgang og ingen nye delingar for den reine brukaren                   |
| S04      | A, B, C                                   | A: søknad Permit; B: berre brukerstøtte Permit; C: søknad Permit | Byte mellom organisasjonar brukar rett matrise                               |
| S05      | Tom liste                                 | Ingen rettar                                                     | Tomtilstand; krev mellombels tildeling til eksisterande testbrukar           |
| S06      | A (AS), B (ENK), C (BEDR), D (AS), Person | Alle fire organisasjonar: Permit på begge ressursar              | UI viser berre A og D etter filtrering; Person har ikkje organisasjonsnummer |
| S07      | Feil ved organisasjonsoppslag             | Feil ved rettsoppslag                                            | Feil blir vist, ikkje omgjort til tilgang; krev mellombels tildeling         |
| S08      | Berre B                                   | B: søknad Deny, brukerstøtte Permit                              | Tidlegare valt A blir ikkje halde som gyldig val; krev mellombels tildeling  |

Nettlesarbrukarar er seed-a for S01–S04 og S06. S01 brukar den eine
Customer Community Plus-lisensen; S02–S04 og S06 brukar High Volume Customer
Portal-lisensar. Bruk S01 når du testar avtalevising og funksjonar som er
avhengige av den vanlege Salesforce-delingsmodellen. S05, S07 og S08 kan
framleis testast interaktivt ved å endre scenarioinnstillinga på ein eksisterande
syntetisk brukar, men det krev eit eige godkjent steg og at original innstilling
blir sett tilbake. Apex-testane dekkjer desse scenarioa utan nettlesar.

## Del 1 – Preflight

### Steg 1. Stadfest målorg

Køyr:

```bash
sf org display --target-org nav-community-dev
```

Kontroller at aliaset er `nav-community-dev` og at orgen er den aktive
scratch-org-en. Ikkje lim inn heile outputen; han kan innehalde miljødetaljar.
Stopp dersom alias eller miljø ikkje stemmer.

### Steg 2. Stadfest syntetiske data

Organisasjonskontoar:

```bash
sf data query --target-org nav-community-dev \
  --query "SELECT INT_OrganizationNumber__c, Name FROM Account WHERE Name LIKE 'Synthetic Altinn Organization %' AND INT_OrganizationNumber__c IN ('111111111','222222222','333333333','444444444') ORDER BY INT_OrganizationNumber__c" \
  --result-format table
```

Søknader:

```bash
sf data query --target-org nav-community-dev \
  --query "SELECT OrganizationNumber__c, Status__c, Account__r.Name FROM Application__c WHERE Email__c LIKE 'aareg.altinn.application.%@example.invalid' AND OrganizationNumber__c IN ('111111111','222222222','333333333','444444444') ORDER BY OrganizationNumber__c" \
  --result-format table
```

Avtalar:

```bash
sf data query --target-org nav-community-dev \
  --query "SELECT OrganizationNumber__c, Status__c, Application__r.Status__c FROM Agreement__c WHERE OrganizationNumber__c IN ('111111111','222222222','333333333','444444444') ORDER BY OrganizationNumber__c" \
  --result-format table
```

Scenarioinnstillingar:

```bash
sf data query --target-org nav-community-dev \
  --query "SELECT ScenarioName__c, UseScenarioProvider__c, SubjectAlias__c FROM AAREG_AltinnScenarioSetting__c WHERE ScenarioName__c IN ('S01','S02','S03','S04','S06')" \
  --result-format table
```

Lisensar:

```bash
sf data query --target-org nav-community-dev \
  --query "SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense WHERE Name IN ('Customer Community Plus','High Volume Customer Portal') ORDER BY Name" \
  --result-format table
```

Forventa utgangspunkt: fire syntetiske organisasjonar A–D, fire søknader med
status `New`, fire aktive avtalar og éi aktiv brukarinnstilling for kvart av
S01, S02, S03, S04 og S06.

Lisensfordelinga skal vise éin `Customer Community Plus User` og fire
`High Volume Customer Portal User`. S01-brukaren brukar Customer Community
Plus, medan dei andre scenario-brukarane brukar High Volume. Berre éin brukar
kan få tildelt den eine Plus-lisensen om gongen; deaktivering av brukaren gjer
ikkje lisensen tilgjengeleg for ein annan brukar. Bruk den same S01-brukaren
for funksjonar som krev Customer Community Plus. For å køyre eit anna Altinn-
scenario med Plus-lisensen, endrar du den same brukaren si
`AAREG_AltinnScenarioSetting__c`-innstilling mellombels og set henne tilbake
til S01 etterpå. Ikkje opprett fleire Plus-brukarar.

Ved avvik: stopp før nettlesartest. Assistenten kan hente meir read-only
informasjon frå scratch-org-en for å finne ut kva som manglar. Ikkje køyr seed
på nytt før avviket er forstått.

### Steg 3. Stadfest testversjon

Scenarioressursen og dei fokuserte Apex-testklassane skal vere deploya til
scratch-org-en. Den registrerte deploymenten køyrde 21/21 Apex-testar. Katalogen
skal svare med 3 organisasjonar for S01 og S04 og 5 ufiltrerte oppføringar for
S06. LWC-suiten har 16/16 grøne testar.

Dette er automatisert evidens, ikkje nettlesarverifikasjon.

## Del 2 – Opne testbrukaren

### Steg 4. Finn godkjend community-innlogging

Bruk den etablerte, godkjende måten de loggar inn syntetiske Experience Cloud-
brukarar på. Seed-skriptet har ikkje sett passord. Ikkje send innloggingsdata
til assistenten.

Start med den eksisterande syntetiske Permit-brukaren (S01). Stadfest i
nettlesaren at du er på Aa-registeret community-sida som denne brukaren, ikkje
berre innlogga i intern Salesforce Setup.

Testpersonen opplyste at den vanlege innloggingsflyten er via kontakten som er
knytt til portalbrukaren. Finn kontakten for `Synthetic Permit Scenario User`
og bruk den etablerte handlinga for å logge inn i Experience Cloud. Ikkje endre
brukaren eller kontakten, og ikkje vel **Reset Password**. Om handlinga ikkje
fører til Experience Cloud, stopp og fortel kva som skjedde; ikkje prøv andre
innloggingshandlingar.

Om du ikkje har ein godkjend måte å autentisere community-brukaren på, stopp
her og sei det. Vi finn først rett innloggingsflyt; vi skal ikkje lage eller
dele passord i testloggen.

## Del 3 – Gå gjennom nettlesartestane

For kvart scenario:

1. Noter scenario-ID og kva syntetisk brukarrolle som er aktiv, men ikkje
   brukarnamn eller e-post.
2. Last Aa-registeret community-sida på nytt.
3. Noter kva organisasjonar som faktisk står i veljaren.
4. Vel organisasjonen som er nemnd i teststeget.
5. Vent til kontrollen er ferdig. Noter synlege handlingar/tilgang og eventuell
   feiltekst.
6. Samanlikn med forventa resultat og meld tilbake før vi går vidare.

### Steg 5. S01 – vanleg Permit

- Forventa val: A, B og C.
- Vel A. Forventa: søknadstilgang og ordinær tilgangsvising.
- Vel B, deretter C. Forventa: søknadstilgang for kvar vald organisasjon.
- Etter at C er vald, gå til kortet **Mine avtaler** frå startsida. Avtaleoversikta
  brukar organisasjonen som sist blei vald; for C ventar vi å sjå den aktive
  syntetiske avtalen. Kontroller berre visinga no — ikkje avslutt eller endre
  avtalen.
- Om avtalen manglar, noter det som eit avvik og stopp denne delen. Ikkje opprett
  avtale eller delingspost manuelt.
- S01-brukaren har Customer Community Plus-lisens. Bruk denne brukaren for å
  verifisere avtalevising og den vanlege Salesforce-delingsmodellen.
- Noter om bytte av organisasjon oppdaterer tilgang og innhald.

### Steg 6. S04 – ulike rettar per organisasjon

- Forventa val: A, B og C.
- A: søknad Permit; forvent søknadstilgang.
- B: søknad Deny, brukerstøtte Permit; forvent brukerstøtte, ikkje
  søknadstilgang.
- C: søknad Permit; forvent søknadstilgang.
- Byt fram og tilbake mellom A og B. Kontroller at B ikkje arvar A sine
  søknadsrettar.

### Steg 7. S02 og S03 – tilgangsgrenser

S02:

- Test A. Forventa: `hasAccess=true`, `hasApplicationAccess=false`.
- Kontroller at søknadshandlingar ikkje blir viste som tilgjengelege.

S03:

- Test A. Forventa: ingen tilgang.
- Brukaren er meint å vere rein for dette scenarioet. Ikkje fjern eller rydd
  delingar automatisk; noter berre observerte delingar.

### Steg 8. S06 – UI-filtrering

- Altinn-svaret har A (AS), B (ENK), C (BEDR), D (AS) og Person.
- Forventa synlege val i dagens UI: A og D.
- Vel A og D. Begge har Permit på søknad og brukerstøtte.
- B, C og Person skal ikkje bli viste som valbare organisasjonar.

### Steg 9. Oppfrisk organisasjonar

- Vel ein organisasjon med tilgang.
- Trykk «Oppdater organisasjoner».
- Forventa: lista blir ståande medan oppfriskinga går; gyldig val blir vurdert
  på nytt; tilgang blir nullstilt dersom valet eller oppslaget feilar.
- Noter om lista forsvinn, om tomtilstand kjem, og eventuell feilmelding.

## Del 4 – Valfrie kanttilfelle i nettlesaren

S05, S07 og S08 krev ikkje nye community-lisensar. Vi kan mellombels tildele eitt
av dei til ein eksisterande syntetisk testbrukar i Setup. Dette endrar
Custom Setting i scratch-org-en. Før vi gjer det, stadfestar assistenten
scenario, alias og tilbakeføringsverdi med deg. Etter kvar test skal den
opphavlege innstillinga setjast tilbake og kontrollerast.

- S05: tom liste og tydeleg tomtilstand.
- S07: kontrollert oppslagsfeil, feilvising og ingen tilgang.
- S08: start med A vald frå S01, byt mellombels til S08 og oppdater; A skal ikkje
  framleis vere eit gyldig val. S08 listar B.

Ikkje endre Custom Setting manuelt før denne delen er avtalt.

## Del 5 – Avslutt

1. Stadfest at scenarioinnstillingar ikkje blei endra, eller at mellombelse
   endringar er sette tilbake.
2. Noter eventuelle uventa avtaledelingar, feilmeldingar eller manglande data.
3. Ikkje endre integrasjonsmodus, passord eller produksjonsoppsett som del av
   denne guiden.
4. Oppdater [testloggen](./altinn-test-log.md) med stadfesta resultat.

## Korleis vi køyrer dette saman

Vi tek berre eitt steg om gongen. Assistenten forklarer steget, hentar relevante
read-only data frå `nav-community-dev` ved behov, ventar på det du ser eller
gjer, og fører resultatet i testloggen. Vi markerer eit brukarsteg som bestått
først når du har stadfesta nettlesarresultatet. Ikkje send passord, token eller
cookie.
