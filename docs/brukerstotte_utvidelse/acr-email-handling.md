# ACR og e-posthåndtering for brukerstøtteutvidelse

## 1. Kontekst

For å kunne identifisere riktig e-postadresse for en person som representerer en arbeidsgiver, samarbeidspartner eller seg selv, må vi bruke AccountContactRelation (ACR) som elvergangen mellom person og virksomhet. ACR er den sikre kilden til at en person faktisk er knyttet til en konkret konto og i hvilken rolle den personen opererer.

Dette er nødvendig fordi dagens løsning i stor grad bygger på `User.LastUsedOrganization__c` og valgt organisasjonsnummer. Det er ikke nok for personbaserte representasjonsforhold, siden samme person kan ha flere relevante roller og flere tilknyttede kontoer.

## 2. Problemstilling

Vi trenger å løse tre ting samtidig:

1. finne riktig person som er knyttet til valgt organisasjon eller eget brukerforhold,
2. finne riktig e-postadresse til den personen,
3. lagre e-postadressen i Salesforce på en måte som er søkbar, validerbar og robust mot endringer i KRR/Altinn.

## 3. Krav til løsning

### 3.1 ACR som kilde til representasjonsforhold

- `AccountContactRelation` er master for relasjonen mellom person og virksomhet.
- Relasjonen skal kun være aktiv når `IsActive = true`.
- Rollen på relasjonen må kunne skille mellom:
    - arbeidsgiver,
    - samarbeidspartner,
    - egen person / selv,
    - eventuelt andre relevante typer representasjon.
- Relasjonen må kunne ha tidsbegrensning gjennom `StartDate` og `EndDate` dersom dette er nødvendig for historie eller reell endring i tilgang.

### 3.2 Identifisering av riktig kontakt

For hver innlogget bruker skal systemet kunne løse:

- hvilken personkonto eller kontakt som er relevant for brukeren,
- hvilken konto eller virksomhet personen representerer,
- om personen skal betraktes som "selv", "arbeidsgiver" eller "samarbeidspartner".

Det bør ikke være mulig å tolke bare `User.LastUsedOrganization__c` som gyldig representasjonskontekst for disse brukergruppene. `LastUsedOrganization__c` kan fortsatt brukes som fallback for eksisterende organisasjonsbaserte brukere, men ikke som eneste kilde for nye representasjonsmønstre.

I praksis innebærer dette at:

- virksomhetsrepresentanter bruker dagens organisasjonsmodell,
- arbeidsgiver og samarbeidspartner bruker personbasert kontekst og ett valgt organisasjonsnummer,
- privatpersoner bruker personbasert kontekst uten organisasjonsnummer,
- vi ikke støtter flere samtidige organisasjonsvalg i samme flyt for disse nye gruppene.

### 3.3 E-post som data i Salesforce

Vi trenger et oppbevaringsmønster som gjør at e-post kan brukes i:

- kontaktinformasjon,
- Varsling/kommunikasjon,
- støtteflyt og meldinger,
- historikk og søkbarhet,
- senere videreføring til KRR eller andre datakilder.

Det finnes allerede flere steder i repoet hvor e-post lagres på transactional objekter som `Application__c.Email__c`, `RelatedContact__c.Email__c` og `Inquiry__c.Email__c`. Dette er nyttig, men det er ikke nok som master for representasjonskontekst. Vi trenger derfor en normalisert, tydelig datakilde for kontakt-e-post i person-/kontekstmodellen.

## 4. Forslått design

### 4.1 Bruk ACR som relasjonsmodell

Vi anbefaler å bygge en liten og konkret kontekstmodul rundt ACR:

- `AccountContactRelation` brukes til å finne alle aktive relasjoner for den aktuelle personen.
- `Roles` eller en AAREG-spesifikk feltmodell brukes til å klassifisere relasjonen.
- En liten Apex-tjeneste, for eksempel `AAREG_ContactContextService`, ansvarlig for å knytte sammen:
    - bruker,
    - relativ kontakt,
    - konto,
    - rolle,
    - relevant e-postadresse.

Dette holder løsningen liten og begrenset til AAREG, uten å introdusere et stort generisk audit-/access-system.

### 4.2 E-post i Salesforce

Vi anbefaler å bruke en av to modeller, avhengig av hvilken datakilde som faktisk er master:

#### Variant A: Bruk Contact.Email / PersonEmail som primærfelt

Dette er den enkleste modellen hvis Salesforce er den autoritative kilden for den aktuelle personen. Fordeler:

- liten endring i kode,
- enkel tilganger,
- god søkbarhet,
- støtter standard Salesforce-felter.

Krav for dette:

- feltet må oppdateres som en del av AAREG/KRR-synkronisering,
- det må være tydelig hvilke kilder som kan overskrive e-posten,
- feltet må aldri brukes uten validering.

#### Variant B: Egen liten AAREG-tabell for e-postsnapshot

Hvis KRR/AAREG har egne krav om historikk, flere e-postadresser eller datakilde-sporing, bør vi bruke en liten custom object, for eksempel:

- `AAREG_PersonEmail__c`

Dette objektet bør inneholde:

- `ContactId` eller `PersonAccountId`
- `Email__c`
- `Source__c` (KRR, AAREG, Manual, Import)
- `IsPrimary__c`
- `ValidFrom__c`
- `ValidTo__c`
- `LastValidated__c`

Dette er et godt valg når vi trenger å lagre flere adresser eller ha historikk uten å overbelaste standard `Contact.Email`.

### 4.3 Rekommendasjon

For denne løsningen anbefaler vi en liten og praktisk modell:

- ACR er source of truth for representasjonsrelasjon.
- E-post lagres i Salesforce i et normalisert felt eller liten custom object.
- En utils/service henter relevant e-post basert på ACR og valgt kontekst.
- Vi unngår et stort generisk "email framework"; vi bruker kun det som faktisk trengs for AAREG.

## 5. Endringer som kreves i AAREG-løsningen

### 5.1 Apex og tjenestelag

Det må opprettes en ny liten Apex-tjeneste med ansvar for å:

- finne aktive ACR-forekomster for en person,
- bestemme hvilken konto som er aktuell,
- klassifisere relasjonen som arbeidsgiver / samarbeidspartner / selv,
- returnere relevant e-postadresse.

Eksempler på metoder:

- `resolvePersonContext(User currentUser)`
- `resolveAccountContactRelations(Id personContactId)`
- `resolveRelevantEmail(Id contactId, Id accountId)`
- `resolveApplicableContactsForSupport(Id accountId)`

### 5.2 Oppdatering av eksisterende søk og flyt

Følgende områder må oppdateres så de bruker ACR-kontext i stedet for bare `LastUsedOrganization__c`:

- støtte-/meldingsvisning,
- brukergruppe-/representasjonslogikk,
- e-posttilknytning i support/inquiry-scenario,
- personalisering av e-postadresse for relevante kontaktpersoner.

Dette bør ikke gjøres som en stor refaktorering av hele appen. Den riktige endringen er å legge kontekstresolusjon i én liten service og bruke den der dagens organisasjonslogikk er for snever.

### 5.3 Testdekning

For hver ny funksjon må vi ha en liten men tydelig testdekning:

- person med ACR til arbeidsgiver får korrekt e-post,
- person med ACR til samarbeidspartner får korrekt e-post,
- person uten aktiv ACR får ingen eller korrekt feil/blank,
- gammel / utgått ACR ignoreres,
- historiske e-postadresser håndteres riktig,
- kun aktiv relasjon brukes i support- og meldingsflyten.

## 6. Adopsjonsregler

- ACR er the source of truth for representasjonsforhold.
- `LastUsedOrganization__c` brukes fortsatt som kontekst for eksisterende organisasjonsbaserte operasjoner, men ikke som eneste mekanisme for personrelasjoner.
- E-postdata må valideres før bruk i utsendelser.
- E-post i Salesforce må kunne spores tilbake til kilde og dato.
- Ingen funksjon skal bruke direkte URL-/UI-state som tilgangsgrunnlag.

## 7. Akseptansekriterier

Løsningen er godkjent når:

1. systemet kan identifisere riktig person og konto for arbeidsgiver, samarbeidspartner og selv via ACR,
2. systemet kan hente riktig e-postadresse for den aktuelle relasjonen,
3. e-post er lagret i Salesforce på et stabilt og søkbart format,
4. bruk av `LastUsedOrganization__c` ikke lenger er eneste spor for personbasert representasjon,
5. relevante support- og meldingsflyter er verifiserbare med tester.
