# Risikoer og teststrategi

## 1. Risikoer

### 1.1 Regresjon for virksomhetsrepresentanter

Den største risikoen er at eksisterende oppførsel for virksomhetsrepresentanter blir endret ved forsøk på å utvide brukergruppene.

Dette gjelder spesielt:

- organisasjonsvalg og `LastUsedOrganization__c`,
- mine søknader,
- mine avtaler,
- mine meldinger,
- tilgang til brukerstøtte.

### 1.2 Feil tilgangskontroll

Hvis tilgang kun baseres på UI-skjuling, kan brukeren få tilgang til data eller funksjonalitet via direkte kall eller manipulerte parametre. Derfor må serverlogikk i Apex være den faktiske autorisasjonsmekanismen.

### 1.3 Modellblanding mellom brukergruppe og representasjon

Hvis brukergruppe og valgt organisasjonsnummer blandes sammen i samme variabel eller samme flyt, kan det føre til feil kontekst og uønsket tilgang.

### 1.4 Meldingsfeil

Dagens meldingsmodell er organisasjonsbasert. Det er en stor risiko ved å utvide uten eksplisitt personbasert filtrering for andre grupper.

## 2. Testtilnærming

### 2.1 Eksisterende Apex-tester

Det finnes allerede testklasser i flere AAREG-moduler, for eksempel:

- AAREG_ApplicationControllerTest
- AAREG_MyApplicationsControllerTest
- AAREG_ContactSupportControllerTest
- AAREG_MyThreadsControllerTest

Disse må vurderes og utvides, spesielt når tilgangskontroll eller meldingsoppsett endres.

### 2.2 Nye tester som bør opprettes

- tilgangstest for arbeidsgiver uten søknadstilgang,
- tilgangstest for samarbeidspartner uten organisasjonsvisning av søknader og avtaler,
- tilgangstest for privatperson med kun personlige meldinger,
- negativ test for ugyldige URL-parametere,
- negativ test for manipulert organisasjonsnummer,
- test på at virksomhetsrepresentantens eksisterende flyt blir uendret.

### 2.3 LWC-testdekning

Det finnes LWC-tester i delområdene som allerede bruker Apex-wires, for eksempel `aareg_home`-testen. Disse bør utvides for nytt brukergruppemønster og for feilhandtering av valgt kontekst.

### 2.4 Verifisering av serverbasert tilgang

Det må testes i Apex at ikke bare UI-elementer skjules, men at serveren faktisk nektar uautoriserte kall.

## 3. Rekommendasjon

For å begrense regressjonsrisiko bør implementasjonen deles i små faser og verifiseres etter hver fase. Dette er viktig fordi dagens organisasjonsbaserte flyt er sentral i løsningen og ikke bør endres uten målrettet regresjonstest.
