# Implementeringsplan

## Fase 1: Kartlegging og avklaring

### Mål for fase 1

- avklare hvilke brukergrupper som trenger egne veier,
- definere hvilke funksjoner som skal være skjult eller synlige for hver gruppe,
- avklare hvordan representasjonskontekst skal håndteres for arbeidsgiver, samarbeidspartner og privatperson.

### Berørte områder i fase 1

- [force-app/externalAccess/lwc/aareg_home/aareg_home.js](../force-app/externalAccess/lwc/aareg_home/aareg_home.js)
- [force-app/externalAccess/classes/AAREG_HomeController.cls](../force-app/externalAccess/classes/AAREG_HomeController.cls)
- [force-app/dialog/classes/AAREG_MyThreadsController.cls](../force-app/dialog/classes/AAREG_MyThreadsController.cls)

### Tester

- verifiser eksisterende oppførsel for virksomhetsrepresentanter,
- dokumenter forventet oppførsel for ny brukergruppe per felt.

## Fase 2: ACR- og e-postmodell for representasjonsforhold

### Mål for fase 2

- bruke ACR som eneste gyldige kilde for relasjon mellom person og virksomhet,
- definere hvilke roller som skal tolkes som arbeidsgiver, samarbeidspartner og selv,
- fastsette hvordan e-post lagres og hentes i Salesforce uten å stole på UI-state alene.

### Berørte områder i fase 2

- `AccountContactRelation`
- person-/kontaktmodell i Salesforce,
- e-postfelt eller liten AAREG-spesifikk email-tabell,
- Apex-helper for å løse relevant kontakt og e-post basert på valgt kontekst.

### Tester for fase 2

- verifiser riktig ACR-matching for arbeidsgiver, samarbeidspartner og selv,
- verifiser at utgåtte eller inaktive ACR-er ignoreres,
- verifiser at relevant e-post hentes uten å bruke `LastUsedOrganization__c` som eneste kilde.

## Fase 3: Felles startside og kontekstvalg

### Mål for fase 3

- bygge en liten ny inngangsside som håndterer valg av brukergruppe,
- beholde dagens `aareg_home`-flyt for virksomhetsrepresentanter,
- legge til logikk for organisasjonsnummer når det er relevant for arbeidsgiver og samarbeidspartner,
- støtte privatpersoner uten organisasjonsvalg,
- sikre at klienten ikke kan gi tilgang på egen hånd.

### Berørte områder i fase 3

- LWC-komponenter for startside og navigasjon,
- eventuelle Apex-metoder for inputvalidering og kontekstvalidering,
- potensielle oppdateringer i `AAREG_HomeController`.

### Avhengigheter for fase 3

- må være på plass før ny navigasjonsflyt for andre grupper kan testes.

## Fase 4: Tilgangsmodell og servervalidering

### Mål for fase 4

- definere tydelig autorisasjon per brukergruppe,
- sørge for at UI-skjuling ikke er eneste tilgangssjekk,
- håndtere at URL-parametere kun brukes som kontekst og ikke som tilgang.

### Berørte områder i fase 4

- `AAREG_HomeController.checkAndShareIfAuthorized()`
- eventuelle nye Apex-hjelpeklasser for rettighetsmodellering
- eventuell bruk av custom permissions eller andre eksisterende tillatelser

### Tester for fase 4

- positiv/negativ test av tilgang basert på validerte parametre,
- test av ugyldige URL-verdier,
- test av manglende organisasjonsnummer.

## Fase 5: Meldinger og personbasert tilgang

### Mål for fase 5

- gjøre skille mellom organisasjonsbaserte meldinger og personbaserte meldinger,
- holde dagens organisasjonsbaserte meldingsflyt uendret for virksomhetsrepresentanter,
- utvide støtte for arbeidsgiver, samarbeidspartner og privatperson via personbasert kontekst og valgt organisasjonsnummer når det er relevant.

### Berørte områder i fase 5

- [force-app/dialog/classes/AAREG_MyThreadsController.cls](../force-app/dialog/classes/AAREG_MyThreadsController.cls)
- relevante LWC-komponenter for visning av mine meldinger

### Avhengigheter for fase 5

- må håndtere alle brukergrupper før dette går i produksjon.

## Fase 6: Funksjonsvisning og navigasjonsregler

### Mål for fase 6

- skjule insensitive funksjoner for arbeidsgiver, samarbeidspartner og privatperson,
- vise relevante menyer og knapper basert på faktisk tilgang.

### Berørte områder i fase 6

- LWC-komponenter for nav og dashboard
- kontrollert logikk i Apex for funksjonsliste

### Tester for fase 6

- verifiser at kun relevante funksjoner vises per rolle,
- verifiser at virksomhetsrepresentantens eksisterende flyt ikke endres.

## Fase 7: Verifisering og regresjonstesting

### Mål for fase 7

- verifisere at eksisterende virksomhetsrepresentantflyt er uendret,
- verifisere rolle-/kontekstbaserte regler,
- verifisere serverstyrt tilgang i Apex.

### Testtilnærming for fase 7

- eksisterende Apex-tester for AAREG-moduler oppdateres eller utvides,
- relevante LWC-tester vurderes der det finnes eksisterende tester,
- ekstra sikkerhetstester for tilgangs- og meldingslogikk.

## Fase 8: Godkjenning og overgang

- dokumentere åpne spørsmål,
- bekrefte innstilling av brukergrupper,
- bekrefte at servervalidering er på plass før release.
