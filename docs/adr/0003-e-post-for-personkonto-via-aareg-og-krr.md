---
adr: 0003
tittel: Håndtering av e-postadresse for personkonto via AAREG og KRR
status: Foreslått
dato: 2026-08-27
kilde: Confluence — ADR-0003 (PDF-eksport)
hentet: 2026-09-08
speilkopi: ja
merknad: Navngitte beslutningstakere er utelatt ved speiling.
---

# ADR-0003: Håndtering av e-postadresse for personkonto via AAREG og KRR

**Status:** Foreslått
**Dato:** 2026-08-27
**Beslutningstakere:** Se Confluence

## 1.1. Kontekst og problemstilling

Dagens systemløsning mangler mulighet for å registrere, lagre eller vedlikeholde e-postadresser direkte på privatpersoner. Dette hindrer effektiv digital kommunikasjon og oppfølging.

Vi har derfor behov for å etablere en strukturert metode i Salesforce for å fange opp og lagre e-postadresser for personkontoer (privatpersoner) basert på Aa-registeret (AAREG) og Kontakt- og reservasjonsregisteret (KRR). Brukerstøtte og sluttbrukere (selv) må også kunne oppdatere denne e-postadressen manuelt ved feil.

I tillegg skal privatpersoner kunne sende inn en forespørsel til NAV via brukerstøtte/brukerportalen, og vi må kunne motta og behandle e-posten som kommer i retur fra NAV på en strukturert måte.

## 1.2. Beslutningsdrivere

- **Løse funksjonelt gap:** Etablere en pålitelig datamodell i Salesforce som fungerer som master («Single Source of Truth») for privatpersoners e-post for alle applikasjoner på Salesforce i NAV.
- **Datakvalitet via fallback:** Sikre høyest mulig treffprosent på e-postadresser ved å kombinere AAREG og KRR som sekundærkilde.
- **Operasjonell smidighet:** Gi brukerstøtte/privatpersoner mulighet til å korrigere eller legge til e-postadresser via brukerstøtteløsning og brukerportalen.
- **Lukket kommunikasjonssløyfe:** Sikre at utgående og inngående e-postdialog med NAV blir automatisk sammenkoblet for å unngå tapte meldinger eller manuelle mellomstasjoner.

## 2. Beslutning

Vi implementerer følgende arkitektur for å løse mangelen på e-posthåndtering og NAV-kommunikasjon:

- **Etablering av e-poststruktur:** Siden vi i dag ikke kan legge på e-postadresser for privatpersoner i brukerstøtteløsning, tar vi i bruk det eksisterende Kontakt-kortet (`Contact`) på Personkontoen til dette formålet (som er foreslått i [ADR-0002](0002-accountcontactrelation-for-personkontoer.md)).
- **Datamodell og fallback:** Vi oppretter et nytt, egendefinert felt: `email_AAREG_KRR__c`. Hvis dette feltet er tomt, skal systemet automatisk hente e-postadressen fra AAREG/KRR og vise den til brukeren i standard `Email`-feltet.
- **Endring fra brukerstøtte / brukerportalen:** Brukerstøtte/Brukerportalen brukes for å registrere eller overstyre e-postadressen manuelt når automatiske kilder mangler data.
- **NAV-forespørsler (Inngående):** Når en privatperson sender en forespørsel mot NAV, opprettes det en henvendelse (`Inquiry`) i Salesforce. Forespørselen sendes ut som en e-post til NAV.
- **Svar fra NAV (Utgående):** Vi aktiverer Email-to-Case. Svaret fra NAV rutes automatisk tilbake og knyttes til den opprinnelige saken ved hjelp av unike referansetråder (Threads), slik at brukerstøtte har full historikk.

### 2.1. Positive konsekvenser

- **Løser funksjonelt gap:** Vi etablerer en etterlengtet mulighet til å lagre og bruke e-postadresser for privatpersoner.
- **Ett kontaktpunkt:** All historikk rundt NAV-forespørselen og e-postutvekslingen samles på ett sted (på Casen tilknyttet Personkontoen).
- **Automatisert sporing:** Salesforce håndterer trådingen av e-posten automatisk, slik at svar fra NAV ikke blir liggende i en felles innboks.

### 2.2. Negative konsekvenser

- **Synkroniseringsbehov:** Siden dette er en ny funksjonalitet for privatpersoner, må vi sikre at manuelle endringer fra brukerstøtte ikke blir overskrevet av nattlige batch-jobber fra AAREG/KRR uten at det er ønskelig.
- **Sikkerhet og personvern:** E-postutveksling med NAV og lagring av e-post på privatpersoner krever streng tilgangsstyring (GDPR/taushetsplikt) på Case- og Personkonto-nivå.

### 2.3. Annet

Kilden har ingen innhold under denne overskriften.

## Merknader ved speiling

- Navngitte beslutningstakere er utelatt fordi repoet er offentlig. Se Confluence.
- **Dato rettet.** PDF-eksporten oppgir 2025-08-27. Riktig år er 2026, bekreftet av dokumenteier. Rettet her.
- Kildens punkt om «Svar fra NAV (Utgående)» beskriver innkommende e-post fra NAV. Retningsmerkingen i kilden ser inkonsistent ut, men er ikke endret her. Avklar mot Confluence.
- **Rød sone.** Denne ADR-en gjelder lagring av personopplysninger (e-post på privatpersoner), tilgangsstyring og GDPR/taushetsplikt. Krever menneskelig gjennomgang før implementasjon.
