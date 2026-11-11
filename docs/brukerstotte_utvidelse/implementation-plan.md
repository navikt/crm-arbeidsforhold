# Implementeringsplan

## Fase 1: Kartlegging og avklaring

### Mål

- avklare hvilke brukergrupper som trenger egne veier,
- definere hvilke funksjoner som skal være skjult eller synlige for hver gruppe,
- avklare hvordan representasjonskontekst skal håndteres for arbeidsgiver, samarbeidspartner og privatperson.

### Berørte områder

- [force-app/externalAccess/lwc/aareg_home/aareg_home.js](../force-app/externalAccess/lwc/aareg_home/aareg_home.js)
- [force-app/externalAccess/classes/AAREG_HomeController.cls](../force-app/externalAccess/classes/AAREG_HomeController.cls)
- [force-app/dialog/classes/AAREG_MyThreadsController.cls](../force-app/dialog/classes/AAREG_MyThreadsController.cls)

### Tester

- verifiser eksisterende oppførsel for virksomhetsrepresentanter,
- dokumenter forventet oppførsel for ny brukergruppe per felt.

## Fase 2: Felles startside og kontekstvalg

### Mål

- bygge en felles startside som håndterer valg av brukergruppe,
- legge til logikk for organisasjonsnummer når relevant,
- sikre at klienten ikke kan gi tilgang på egen hånd.

### Berørte områder

- LWC-komponenter for startside og navigasjon,
- eventuelle Apex-metoder for inputvalidering og kontekstvalidering,
- potensielle oppdateringer i `AAREG_HomeController`.

### Avhengigheter

- må være på plass før ny navigasjonsflyt for andre grupper kan testes.

## Fase 3: Tilgangsmodell og servervalidering

### Mål

- definere tydelig autorisasjon per brukergruppe,
- sørge for at UI-skjuling ikke er eneste tilgangssjekk,
- håndtere at URL-parametere kun brukes som kontekst og ikke som tilgang.

### Berørte områder

- `AAREG_HomeController.checkAndShareIfAuthorized()`
- eventuelle nye Apex-hjelpeklasser for rettighetsmodellering
- eventuell bruk av custom permissions eller andre eksisterende tillatelser

### Tester

- positiv/negativ test av tilgang basert på validerte parametre,
- test av ugyldige URL-verdier,
- test av manglende organisasjonsnummer.

## Fase 4: Meldinger og personbasert tilgang

### Mål

- gjøre skille mellom organisasjonsbaserte meldinger og personbaserte meldinger,
- utvide støtte for andre brukergrupper uten å påvirke virksomhetsrepresentanter.

### Berørte områder

- [force-app/dialog/classes/AAREG_MyThreadsController.cls](../force-app/dialog/classes/AAREG_MyThreadsController.cls)
- relevante LWC-komponenter for visning av mine meldinger

### Avhengigheter

- må håndtere alle brukergrupper før dette går i produksjon.

## Fase 5: Funksjonsvisning og navigasjonsregler

### Mål

- skjule insensitive funksjoner for arbeidsgiver, samarbeidspartner og privatperson,
- vise relevante menyer og knapper basert på faktisk tilgang.

### Berørte områder

- LWC-komponenter for nav og dashboard
- kontrollert logikk i Apex for funksjonsliste

### Tester

- verifiser at kun relevante funksjoner vises per rolle,
- verifiser at virksomhetsrepresentantens eksisterende flyt ikke endres.

## Fase 6: Verifisering og regresjonstesting

### Mål

- verifisere at eksisterende virksomhetsrepresentantflyt er uendret,
- verifisere rolle-/kontekstbaserte regler,
- verifisere serverstyrt tilgang i Apex.

### Testtilnærming

- eksisterende Apex-tester for AAREG-moduler oppdateres eller utvides,
- relevante LWC-tester vurderes der det finnes eksisterende tester,
- ekstra sikkerhetstester for tilgangs- og meldingslogikk.

## Fase 7: Godkjenning og overgang

- dokumentere åpne spørsmål,
- bekrefte innstilling av brukergrupper,
- bekrefte at servervalidering er på plass før release.
