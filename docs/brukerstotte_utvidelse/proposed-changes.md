# Foreslåtte endringer

## 1. Felles startside for brukergruppevalg

Det anbefales å utvikle en liten ny inngangsside som i første omgang er ansvarlig for å:

- vise valgt brukergruppe,
- samle inn organisasjonsnummer når det er relevant,
- navigere brukeren videre til riktig del av applikasjonen,
- validere input før videre navigasjon.

Dagens hjemmeside i [force-app/externalAccess/lwc/aareg_home/aareg_home.js](../force-app/externalAccess/lwc/aareg_home/aareg_home.js) skal beholdes som eksisterende organisasjonsbaserte flyt. Den nye inngangen skal være et tynt lag på toppen av dagens modell, ikke en helt ny app fra bunnen av.

For den nye startside bør dette utvides med en brukergruppe-selection layer som velger hvilket funksjonsområde brukeren skal åpne. Dette skal ikke gi tilgang i seg selv; det skal kun velge hvilken kontekst som skal brukes videre.

Det viktigste er at:

- virksomhetsrepresentanter går inn via dagens `aareg_home`-flyt,
- arbeidsgiver og samarbeidspartner må enten ha organisasjonsnummer eller velge organisasjon på homepage,
- privatpersoner går direkte inn i personbasert kontekst uten organisasjonsvalg,
- vi begrenser antall nye komponenter og holder eksisterende flyt intakt.

## 2. Skille brukergruppe, representasjonskontekst og tilgang

Det er nødvendig å gjøre denne modellen eksplisitt i designet:

- Brukergruppe: virksomhetsrepresentant, arbeidsgiver, samarbeidspartner, privatperson osv.
- Representasjonskontekst: organisasjon eller person som brukeren opererer på vegne av.
- Faktiske tilganger: de rettighetene som faktisk verifiseres på serversiden.

Det anbefales ikke å bruke én enkelt variabel for alle disse konseptene. I stedet bør konteksten bygges opp som et modelleringslag i Apex og LWC:

- `userType`
- `selectedOrganizationNumber` eller `selectedPersonContext`
- `effectiveAccess` / `canAccessFeature`

Dette bør håndteres i serverlogikken, ikke bare i UI-et.

Samtidig er det viktig at:

- `LastUsedOrganization__c` bare brukes for virksomhetsrepresentanter,
- arbeidsgiver og samarbeidspartner bruker personbasert kontekst og ett valgt organisasjonsnummer i arbeidsflyten,
- privatpersoner ikke trenger organisasjonsnummer eller valg,
- vi ikke støtter flere samtidige aktive organisasjonsvalg i samme flyt for de nye brukergruppene.

## 3. Direkte URL-ingang

Direkte inngang via query params bør implementeres som et separat kontekstlag i navigasjonsmodellen.

Anbefalt mønster:

- `?type=arbeidsgiver&org=123456789`
- `?type=privatperson`
- `?type=fullmektig&org=123456789`

Gjøring:

- validere `type` på klient og server,
- validere organisasjonsnummerformat,
- håndtere manglende eller ugyldige parametre med sikker fallback,
- sikre at URL-verdi ikke brukes som tilgangsgrunnlag,
- oppdatere valgt kontekst først etter server-validering.

Dagens `CurrentPageReference`-mønster i `aareg_application.js` er en fungerende føring, men det bør ikke brukes som eneste tilgangsmodell. Det skal kun brukes som navigasjons- og kontekstinformasjon, ikke som sikkerhetskontroll.

## 4. Endringer i funksjonalitetsvisning

For virksomhetsrepresentanter skal dagens oppførsel beholdes som før.

For andre grupper skal funksjonaliteten begrenses slik:

- Ny søknad: skjult / utilgjengelig
- Mine søknader: skjult / utilgjengelig
- Mine avtaler: skjult / utilgjengelig
- Brukerstøtte: tilgjengelig
- Mine meldinger: kun personlige meldinger, ikke organisasjonsbaserte meldinger

Det bør være en eksplisitt applikasjonsregel som bygger menyen fra brukergruppe + faktisk tilgang, ikke kun fra valgt organisasjonsnummer.

## 5. Meldingsmodell

Dette er et kritisk område.

Dagens modell i `AAREG_MyThreadsController.getUsersThreads()` henter tråder ut fra `User.LastUsedOrganization__c` og `CRM_Account__c`. Dette er godt for virksomhetsrepresentanter, men ikke for arbeidsgiver, samarbeidspartner eller privatperson.

Anbefalt endring:

- For virksomhetsrepresentanter: behold organisasjonsbasert visning uten endring.
- For arbeidsgiver og samarbeidspartner: bruk personbasert filtrering i tillegg til valgt organisasjonsnummer som arbeidskontekst. Organisasjonen brukes som filter, ikke som eneste identifikator.
- For privatperson: bruk personbasert visning uten organisasjonsnummer.

Dette bør implementeres både i LWC-visning og i Apex-koden. UI-skjuling alene er ikke nok.

## 6. Reuse av eksisterende komponenter

Det anbefales å være konservativ i gjenbruk:

- `aareg_home` kan utvides til felles valgside.
- `AAREG_HomeController` kan gjenbrukes som grunnlag for organisasjons- og tilgangslogikk.
- `AAREG_ApplicationController` og `AAREG_MyApplicationsController` kan beholdes uten endring for virksomhetsrepresentanter.
- `AAREG_MyThreadsController` må eventuelt utvides med en personbasert metode eller ny filterlogikk, uten å endre dagens organisasjonsmodell for eksisterende kunder.
- `AAREG_contactSupportController` bør kunne brukes videre for brukerstøtteflyten; dette er allerede et re-usable støttepunkt.

## 7. Nytt oppsett for tilgangskontroll

Det anbefales å introdusere en tydelig serverbasert tilgangstjeneste eller en liten helper som bestemmer:

- brukertype,
- valgt kontekst,
- om brukeren kan åpne funksjonen,
- om henting av meldinger eller andre data må filtreres mot person eller organisasjon.

Dette bør være designet som en liten, fokuseret util tilpasset AAREG, ikke som et generisk audit- eller autorisasjonsrammeverk.

## 8. Hvorfor ikke større refactoring

En større refaktorering av all navigasjons- og autorisasjonslogikk er ikke nødvendig i denne fasen. Dagens design er allerede godt nok til å støtte en mellomlagring av kontekst, men den mangler tydelig modellering av flere brukerroller og personlige kontekster. Den beste løsningen er derfor å bygge på dagens mønster uten å gjøre en stor redesign av kjernearkitekturen.
