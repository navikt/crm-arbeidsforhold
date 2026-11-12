# Dagens tekniske implementasjon

## 1. Hjemmeside og organisasjonsvalg

Hjemmesiden for den eksterne brukerflaten er implementert i LWC-en [force-app/externalAccess/lwc/aareg_home/aareg_home.js](../force-app/externalAccess/lwc/aareg_home/aareg_home.js) og serverkontrolleren [force-app/externalAccess/classes/AAREG_HomeController.cls](../force-app/externalAccess/classes/AAREG_HomeController.cls).

Dagens modell er hentet fra Altinn-organisasjoner og brukerens sist brukte organisasjonsnummer. Dette er en solid modell for virksomhetsrepresentanter, men den er ikke den riktige policy for de nye brukergruppene:

- `LastUsedOrganization__c` skal kun brukes for virksomhetsrepresentanter,
- arbeidsgiver, samarbeidspartner og privatperson bruker personbasert kontekst i tillegg til eventuelt valgt organisasjonsnummer,
- privatpersoner trenger ikke organisasjonsnummer,
- de andre gruppene skal ha én aktiv organisasjonskontekst per flyt og ikke flere samtidige aktive organisasjonsvalg.

- `AAREG_HomeController.getOrganizationsWithRoles()` henter organisasjoner for innlogget bruker.
- `AAREG_HomeController.getLastUsersLastUsedOrganization()` leser `User.LastUsedOrganization__c`.
- `AAREG_HomeController.updateLastUsedOrganization()` oppdaterer valgt organisasjonsnummer.
- `AAREG_HomeController.checkAndShareIfAuthorized()` verifiserer om brukeren har tilgang til valgt organisasjon og deler relevante avtaler med brukeren.

Dette betyr at dagens brukerflyt er sterkt knyttet til organisasjonsvalg som kontekst. LWC-en `aareg_home` håndterer også sortering, visning av tilgjengelige organisasjoner og sikkerhetskontroll før brukeren får tilgang til organisasjonsbaserte funksjoner.

## 2. Nåværende tilgangsmodell

Hjemmesiden gjør ikke bare visning. Den gjør også en serverbasert autorisasjon:

- `checkAndShareIfAuthorized` kaller `AAREG_CommunityUtils.getUserRights()` for rettighetskontroll.
- Hvis brukeren har tillatelse for Altinn-rollen `nav_arbeidsforhold_aa-registeret-sok-tilgang` eller `nav_arbeidsforhold_aa-registeret-brukerstotte`, settes tilgangsstatus på server.
- Det skjer ikke bare skjuling av UI-elementer; det er faktisk autorisasjon i Apex.

Dette er viktig å ta med når nye brukergrupper skal støttes. Det samme mønsteret bør gjenbrukes for nye typer brukere, selv om hvilke rettighetsroller som gir tilgang vil variere.

## 3. Mine søknader og mine avtaler

Dagens applikasjonslogikk for ekstern søknadsflyt ligger i følgende filer:

- [force-app/externalApplication/classes/AAREG_ApplicationController.cls](../force-app/externalApplication/classes/AAREG_ApplicationController.cls)
- [force-app/externalApplication/classes/AAREG_MyApplicationsController.cls](../force-app/externalApplication/classes/AAREG_MyApplicationsController.cls)
- [force-app/externalAgreement/classes/AAREG_MyAgreementsController.cls](../force-app/externalAgreement/classes/AAREG_MyAgreementsController.cls)

`AAREG_ApplicationController` håndterer:

- opprettelse og lagring av søknad,
- draft-lagring,
- oppdatering av Access_Request__c,
- oppdatering av RelatedContact__c,
- upsert av basiskoder,
- dokumentkobling og innlevering.

`AAREG_MyApplicationsController.getUsersApplications()` henter søknader for den siste valgte organisasjonen. Det betyr at dagens modell er organisasjonssentrert og ikke personssentrert for disse funksjonene.

`AAREG_MyAgreementsController` er tilsvarende fokusert på organisasjonen eller den valgte konteksten, og inkluderer operasjoner som oppdatering, sletting og henting av avtalekontaktinformasjon.

## 4. Brukerstøtte og meldinger

Brukerstøtteflyten og meldingshåndteringen er i dag implementert i dialogmodulen:

- [force-app/dialog/classes/AAREG_contactSupportController.cls](../force-app/dialog/classes/AAREG_contactSupportController.cls)
- [force-app/dialog/classes/AAREG_MyThreadsController.cls](../force-app/dialog/classes/AAREG_MyThreadsController.cls)

`AAREG_MyThreadsController.getUsersThreads()` henter tråder basert på `User.LastUsedOrganization__c` og finner deretter den tilknyttede kontoen via organisasjonsnummer.

Dette er viktig: dagens meldingsmodell er typisk organisasjonssentrert for virksomhetsrepresentanter. Det betyr at den ikke dekker dagens krav for personlige meldinger for arbeidsgivere, samarbeidspartnere eller privatpersoner uten videre utvidelse.

## 5. Direkte inngang via URL og state-parameter

Det finnes allerede bruk av `CurrentPageReference` og `state`-parametere i LWC-en for applikasjonsflyten:

- [force-app/externalApplication/lwc/aareg_application/aareg_application.js](../force-app/externalApplication/lwc/aareg_application/aareg_application.js)

Denne komponenten leser `this.currentPageReference.state` og bruker felter som:

- `c__applicationType`
- `c__isDraft`
- `c__status`

Dette gir et mønster for direkte inngang via URL, men dagens bruk er rettet mot søknadsflyten og ikke mot bredere brukergruppevalg. Første versjon av en felles startside må derfor bygges uten å gjøre store endringer i samme navigasjonsmodell, men samtidig ta hensyn til eksisterende `state`-baserte navigasjonsmønstre.

## 6. Hva som må forstås i analysen

Dagens løsning har et tydelig mønster:

- organisasjonsvalg er kontekst for mye av virksomhetsfunksjonalitet,
- brukergruppe og representasjon er ikke tydelig separert i en egen kontekstmodell,
- meldinger og søknader er delvis organisasjonsfokuserte,
- serverlogikken gjør faktiske tilgangskontroller, mens UI-er kun viser/skjuler elementer i tillegg.

Dette er et godt fundament for utvidelsen, men det krever en bevisst modell for å skille virksomhetspåvirkning fra personlig kontekst og faktisk rettighet.
