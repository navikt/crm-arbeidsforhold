# Verifisering av kontaktkopling ved innsending i SIT og PROD

Guiden verifiserer feilen og rettinga som er skildra i
[feilrapporten](../operations/feilrapport-kontaktkopling-ved-innsending.md).
Han er skriven for menneske. Agentar skal ikkje bruke SIT utan fersk
godkjenning av mål og handling, og skal aldri bruke PROD.

## Reglar for heile verifiseringa

- Bruk berre syntetiske organisasjonar og e-postadresser du sjølv kontrollerer
  i SIT. Bruk aldri ekte søkjardata i SIT.
- I PROD: les berre. Opprett, endre eller send ingenting for å teste.
- Del aldri e-postadresser, namn, organisasjonsnummer eller søknadstekst i
  chat, Issue eller PR. Rapporter berre **fylt/tomt**, **likt/ulikt**, tal og
  søknadsnummer (`Name`) dersom det trengst.
- Noter dato, pakkeversjon og kven som utførte kontrollen.

## Kva du kontrollerer

| Felt på søknaden                  | Forventa etter innsending                      | Tyder ved feil                   |
| --------------------------------- | ---------------------------------------------- | -------------------------------- |
| `Casehandler_Status__c`           | `New`                                          | —                                |
| `Contact__c` (Kontakt)            | Fylt, og kontaktens e-post = søknadens e-post  | Feil 1 (direkte innsending)      |
| `IsEmailConfirmationSent__c`      | `true`                                         | Kontaktflyten køyrde ikkje       |
| `ApplicationDeadlineForReply__c`  | Fylt                                           | Tekstflyten køyrde ikkje         |
| `AA_register_application_text__c` | Inneheld gjeldande e-post til varslingskontakt | Feil 2 (utkast med endra e-post) |

## SIT

### Førebuing

1. Finn pakkeversjonen som er installert i SIT (_Setup → Installed Packages →
   crm-arbeidsforhold_). Noter versjonen.
2. Skaff ein portalbrukar med tilgang til ein syntetisk organisasjon, og to til
   tre e-postadresser du kontrollerer (kalla A, B og C nedanfor).
3. Skaff ein intern brukar som kan opne søknaden i Salesforce.

### Del 1: reproduser feilen før rettinga er installert

Gjer dette berre dersom SIT framleis har versjonen utan rettinga.

| Steg | Handling                                                                                                    | Forventa med feilen                                    |
| ---- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| 1    | Logg inn i portalen. Start ny søknad. Søkjar-e-post A, varslingskontakt med e-post B. **Send inn direkte.** | Søknaden blir sendt.                                   |
| 2    | Opne søknaden internt.                                                                                      | `Kontakt` tom, stadfesting ikkje sendt, svarfrist tom. |
| 3    | Start ny søknad med varslingskontakt e-post B. **Lagre utkast.**                                            | Utkast lagra.                                          |
| 4    | Opne utkastet, endre varslingskontakten til e-post C, og send inn.                                          | Søknaden blir sendt.                                   |
| 5    | Opne søknaden internt og les søknadsteksten under _Kontaktperson og type varsler_.                          | Viser B, ikkje C. `Kontakt` er fylt.                   |

Noter søknadsnummera. Dei er referansar for samanlikning etter installasjon.

### Del 2: verifiser rettinga

Installer pakkeversjonen med rettinga i SIT via vanleg leveranse
(`[PUSH] Create Package` installerer i SIT, eller `[HELPER] Deployment`).
Noter versjonen. Gjenta deretter:

| Steg | Scenario                       | Handling                                                                                 | Forventa                                                                                      |
| ---- | ------------------------------ | ---------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| 1    | Direkte innsending             | Ny søknad, søkjar-e-post A, varslingskontakt B. Send inn direkte.                        | `Kontakt` fylt med e-post A. Stadfesting sendt. Svarfrist fylt. Tekst inneheld A og B.        |
| 2    | Stadfestings-e-post            | Sjå i innboksen til A.                                                                   | Éi stadfesting for søknaden.                                                                  |
| 3    | Gjenbruk av kontakt            | Ny søknad for same organisasjon med same e-post A. Send inn direkte.                     | Same `Kontakt` som i steg 1. Ingen ny kontakt for A.                                          |
| 4    | Utkast, endra varslings-e-post | Ny søknad med varslingskontakt B, lagre utkast, endre til C, send inn.                   | Tekst inneheld C, ikkje B. `Kontakt` fylt.                                                    |
| 5    | Utkast, endra søkjar-e-post    | Ny søknad med søkjar-e-post A, lagre utkast, endre til C, send inn.                      | `Kontakt` har e-post C.                                                                       |
| 6    | Meir informasjon               | Saksbehandlar ber om meir informasjon på søknaden frå steg 1. Søkjar sender inn på nytt. | Begge statusar `In Progress`. Same `Kontakt`. Ingen ny stadfesting. Saksbehandlar får varsel. |

Rettinga er verifisert i SIT når steg 1–6 er som forventa.

### Kontrollspørjing i SIT (valfri)

Køyr i Developer Console eller _sf data query_ av ein person med tilgang.
Spørjinga hentar berre status og ID-ar, ikkje e-post eller namn.

```sql
SELECT Name, Casehandler_Status__c, Contact__c, IsEmailConfirmationSent__c,
       ApplicationDeadlineForReply__c, CreatedDate
FROM Application__c
WHERE CreatedDate = TODAY AND Status__c != 'Draft'
ORDER BY CreatedDate DESC
```

Forventa etter rettinga: `Contact__c`, `IsEmailConfirmationSent__c = true` og
`ApplicationDeadlineForReply__c` er fylte for alle innsende søknader.

## PROD

PROD-kontrollar blir utførte av ein person med lesetilgang. Endring av
produksjonsmetadata krev godkjenning frå Team Platforce. Installasjon skjer
via `[HELPER] Deploy to Production`.

### Før installasjon: mål omfanget

Køyr desse aggregerte spørjingane. Dei returnerer berre tal.

Innsende søknader utan kopla kontakt, per månad:

```sql
SELECT CALENDAR_YEAR(ApplicationSubmittedDate__c) yr,
       CALENDAR_MONTH(ApplicationSubmittedDate__c) mnd,
       COUNT(Id) antal
FROM Application__c
WHERE ApplicationSubmittedDate__c = LAST_N_DAYS:365
  AND Status__c != 'Draft'
  AND Contact__c = null
GROUP BY CALENDAR_YEAR(ApplicationSubmittedDate__c), CALENDAR_MONTH(ApplicationSubmittedDate__c)
```

Innsende søknader utan svarfrist (teikn på at tekstflyten ikkje køyrde):

```sql
SELECT COUNT()
FROM Application__c
WHERE ApplicationSubmittedDate__c = LAST_N_DAYS:365
  AND Status__c != 'Draft'
  AND ApplicationDeadlineForReply__c = null
```

Til samanlikning, alle innsende søknader i same periode:

```sql
SELECT COUNT()
FROM Application__c
WHERE ApplicationSubmittedDate__c = LAST_N_DAYS:365
  AND Status__c != 'Draft'
```

Del berre tala. Dersom dei to første tala er om lag like store, stadfestar det
at feilen gjeld direkte innsendingar.

### Kontroll av éin råka søknad (valfri)

Opne éin søknad frå ein klage eller frå spørjinga over. Kontroller utan å
kopiere verdiar:

1. Er `E-post` (`Email__c`) fylt? (ja/nei)
2. Er `Kontakt` (`Contact__c`) tom? (ja/nei)
3. Er svarfrist tom? (ja/nei)

_Ja, ja, ja_ samsvarar med feil 1.

### Etter installasjon: verifiser rettinga

1. Noter installert pakkeversjon og tidspunkt.
2. Vent til minst éin ny søknad er sendt inn av ein ekte søkjar. Ikkje send
   inn testsøknader i PROD.
3. Køyr spørjinga nedanfor dagen etter:

```sql
SELECT COUNT()
FROM Application__c
WHERE ApplicationSubmittedDate__c > YYYY-MM-DD
  AND Status__c != 'Draft'
  AND (Contact__c = null OR ApplicationDeadlineForReply__c = null)
```

Bytt `YYYY-MM-DD` med installasjonsdatoen. Datoen må vere strengt etter
installasjonsdatoen, sidan feltet berre har datopresisjon. Forventa resultat
er `0`.

4. Saksbehandlar opnar éin ny søknad og stadfestar at _Kontaktperson som
   søker_ og varslingskontaktar er fylte i søknadsteksten (ja/nei).
5. Kontroller at feilloggen (`Application_Log__c`) ikkje har nye feil frå `AAREG_createContactSendConfirmation` eller
   `AAREG_populateApplicationFieldAfterSubmit` etter installasjonen. Del berre
   talet.

### Eldre søknader

Søknader sende før installasjonen blir **ikkje** retta automatisk. Bruk tala
frå _Før installasjon_ som grunnlag for å avgjere om dei skal ryddast. Ei
opprydding krev eigen runbook, godkjenning og SIT-verifisering før PROD.

## Rapporter resultatet

Legg dette i PR-en eller Issue-en:

| Miljø | Pakkeversjon | Dato | Kontroll                    | Resultat (fylt/tomt, tal, ok/feil) | Utført av |
| ----- | ------------ | ---- | --------------------------- | ---------------------------------- | --------- |
| SIT   |              |      | Del 1 reprodusert           |                                    |           |
| SIT   |              |      | Del 2 steg 1–7              |                                    |           |
| PROD  |              |      | Omfang før installasjon     |                                    |           |
| PROD  |              |      | Spørjing etter installasjon |                                    |           |
