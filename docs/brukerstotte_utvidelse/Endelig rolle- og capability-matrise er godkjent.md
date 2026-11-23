# Endelig rolle- og capability-matrise er godkjent

**Status:** For avklaring — ikke godkjent før beslutninger, ansvarlige og dato er fylt ut

Dette dokumentet skal fange den endelige matrise som bestemmer hvilke handlinger hver rolle kan utføre i den utvidede eksterne brukerflaten.

## Beslutningsregel

Rollen bestemmer brukeropplevelse og kontekst. Rollen gir ikke tilgang alene.

Serveren skal på hvert kall finne frem:

- valgt rolle,
- virksomhets- eller personkontekst,
- godkjent datakilde,
- effektive capabilities, og
- ett av statusene `GRANTED`, `DENIED` eller `TECHNICAL_ERROR`.

UI skal bare vise handlinger som serveren har godkjent. Samme beslutning skal brukes både for portalvisning og direkte Apex-kall.

## Roller som skal avklares

- [ ] Virksomhetsrepresentant
- [ ] Arbeidsgiver
- [ ] Samarbeidspartner/fullmektig
- [ ] Privatperson/arbeidstaker
- [ ] Eksisterende brukerstøttebruker
- [ ] Fremtidige roller, for eksempel styremedlem

## Capabilities

- `APPLICATION`: opprette eller sende ny søknad.
- `MY_APPLICATIONS`: lese søkerens søknader.
- `AGREEMENTS`: lese, opprette, endre eller slette avtaler og relevant kontaktdata.
- `SUPPORT`: opprette en støttehenvendelse eller Inquiry.
- `MESSAGES`: lese og svare på godkjente tråder.

Angi for hver celle om handlingen er `LES`, `SKRIV`, `LES + SKRIV`, `NONE` eller en annet eksplisitt nivå.

## Baseline-matrise

| Rolle                           | Påkrevd kontekst                  | Godkjent datakilde                                        | APPLICATION        | MY_APPLICATIONS    | AGREEMENTS                                        | SUPPORT            | MESSAGES                                           |
| ------------------------------- | --------------------------------- | --------------------------------------------------------- | ------------------ | ------------------ | ------------------------------------------------- | ------------------ | -------------------------------------------------- |
| Virksomhetsrepresentant         | Organisasjon                      | Altinn for valgt organisasjon                             | Fyll ut            | Fyll ut            | Fyll ut, behold dagens regler der de skal bevares | Fyll ut            | Fyll ut, behold dagens organisasjonsbaserte modell |
| Arbeidsgiver                    | Organisasjon                      | Altinn for valgt organisasjon                             | Fyll ut            | Fyll ut            | Fyll ut                                           | Fyll ut            | Fyll ut                                            |
| Samarbeidspartner/fullmektig    | Organisasjon eller person         | Godkjent kilde for representasjon, etter særlig avklaring | Fyll ut            | Fyll ut            | Fyll ut                                           | Fyll ut            | Fyll ut                                            |
| Privatperson/arbeidstaker       | Person; organisasjon ikke påkrevd | Godkjent person-/selvkilde, etter særlig avklaring        | Fyll ut            | Fyll ut            | Fyll ut                                           | Fyll ut            | Fyll ut                                            |
| Eksisterende brukerstøttebruker | Dagens kontekst                   | Dagens eksisterende tilgangsmodell                        | Behold dagens flyt | Behold dagens flyt | Behold dagens flyt                                | Behold dagens flyt | Behold dagens flyt                                 |

## Spesifikke beslutninger som må fylles ut

### 1. Rettighet som gir hver capability

For hver rolle må det avklares hvilke av de eksisterende rettighetene som gir hver capability:

- `sok-tilgang`
- `brukerstotte`
- annen godkjent rettighet eller kilde

| Rolle eller capability                        | Rettighet     | Krav | Beslutning |
| --------------------------------------------- | ------------- | ---- | ---------- |
| Virksomhetsrepresentant / alle capabilities   |               |      | Uavklart   |
| Arbeidsgiver / APPLICATION og MY_APPLICATIONS | `sok-tilgang` |      | Uavklart   |
| Arbeidsgiver / SUPPORT og MESSAGES            |               |      | Uavklart   |
| Arbeidsgiver / AGREEMENTS                     |               |      | Uavklart   |
| Partner/fullmektig / alle capabilities        |               |      | Uavklart   |
| Privatperson / SUPPORT                        |               |      | Uavklart   |
| Privatperson / MESSAGES                       |               |      | Uavklart   |

### 2. Sammenheng mellom rettigheter

Beslutningen må angi om følgende gjelder:

- [ ] Én rettighet er tilstrekkelig.
- [ ] Alle påkrevde rettigheter må finnes.
- [ ] Forskjellige rettigheter gir forskjellige skrive-/lesenivåer.
- [ ] Manglende rettighet gir `DENIED`.
- [ ] Teknisk feil ved kildeoppslag gir `TECHNICAL_ERROR`.

**Beslutning:**

### 3. Arbeidsgiver og organisasjonskontekst

- [ ] Må ha valgt eller levert organisasjonsnummer.
- [ ] Serveren validerer organisasjonen på nytt ved hvert kall.
- [ ] URL-parametere brukes bare som kontekst og ikke som autorisasjonsbevis.
- [ ] Ugyldig, manipulert eller utdatert organisasjonsnummer skal håndteres som `DENIED` eller avvist input.
- [ ] Bare én aktiv arbeidskontekst støttes per handling.

**Beslutning:**

### 4. Partner/fullmektig

- [ ] Godkjent datakilde for representasjon er bestemt.
- [ ] Godkjent datakilde for tilgang er bestemt og skilt fra representasjonsdata.
- [ ] ACR og Altinn brukes ikke om hverandre som samme type beslutning.
- [ ] Organisasjonskontekst er avklart.
- [ ] Aktiv, tidsbegrenset og tilbakekalt representasjon er avklart.

**Godkjent representasjonskilde:**

**Godkjent tilgangskilde:**

### 5. Privatperson/arbeidstaker

- [ ] Person-/selvkilden er bestemt.
- [ ] Organisasjonskontekst er ikke påkrevd.
- [ ] Rettlederen for personbaserte meldinger er avklart.
- [ ] Mulig tilgang til søknader, Mine søknader eller avtaler er bestemt.
- [ ] Mulig skrivetilgang er bestemt.

**Beslutning:**

### 6. Brukerstøtterettighet

Det må uttrykkelig avklares om `brukerstotte` gir:

- [ ] Kun `SUPPORT` og `MESSAGES`.
- [ ] Også `AGREEMENTS` med leseadgang.
- [ ] Også skriveadgang til avtaler og/eller kontaktdata.
- [ ] Ingenting utover dagens eksisterende støtteflyt.

**Beslutning:**

**Begrunnelse:**

## Flere samtidige roller

Hvis samme person har flere aktive roller, må følgende avklares:

- valgt rolle er en brukerkontekst, ikke en uavhengig tilgangskilde,
- serveren kan slå sammen capabilities for valgt rolle og godkjent kontekst,
- en rolle kan være synlig uten å gi alle handlinger fra en annen rolle,
- organisasjon er revalidert for hver handling,
- samme person kan ha forskjellige tråd- og meldingsscoper per rolle,
- historiske eller inaktive roller ikke brukes som autorisasjon.

**Beslutning:**

## Negative og tekniske utfall

| Situasjon                                            | Forventet status             | Brukerrettet handling                                            |
| ---------------------------------------------------- | ---------------------------- | ---------------------------------------------------------------- |
| Rolle er ukjent                                      | `DENIED`                     | Returner til portalen med begrenset statuskode                   |
| Brukeren mangler capability                          | `DENIED`                     | Vis bare godkjente handlinger eller en tydelig manglende tilgang |
| Manglende eller ugyldig kontekst                     | `DENIED`                     | Be brukeren velge eller levere gyldig kontekst                   |
| Datakilden svarer ikke eller returnerer teknisk feil | `TECHNICAL_ERROR`            | Vis egen retry-feilmelding                                       |
| Resultatet er tomt                                   | Ikke automatisk teknisk feil | Vis relevant tomtilstand                                         |
| Direkte Apex-kall uten godkjent capability           | `DENIED`                     | Ikke utføre handlingen                                           |

## Regresjonskrav

Følgende eksisterende flater må være uendret med mindre den endelige matrisa uttrykkelig sier noe annet:

- [ ] Virksomhetsrepresentantens organisasjonsvalg
- [ ] Eksisterende søknadsflyt
- [ ] Mine søknader
- [ ] Eksisterende avtalevisning
- [ ] Eksisterende støtteflyt
- [ ] Eksisterende meldings- og trådmodell
- [ ] Direkte søknad- og portalnavigasjon

## Godkjenning

Matrisa regnes som godkjent når alle felt over har en faktisk beslutning, og godkjenningene er dokumentert.

| Rolle                                | Godkjent av | Dato | Kommentar |
| ------------------------------------ | ----------- | ---- | --------- |
| Produkt- og brukergruppeansvarlig    |             |      |           |
| Domene-/teknisk eier                 |             |      |           |
| Security/privacy-eier                |             |      |           |
| Tech lead, server- og kontekstmodell |             |      |           |

## Endelig beslutning

- [ ] Hele matrisa er godkjent.
- [ ] Alle capabilities har les-/skrivnivåer.
- [ ] Alle rettigheter og datakilder er dokumentert.
- [ ] Multi-role-scenarioer er avklart.
- [ ] Regresjonskravene er godkjent.
- [ ] Ingen kode startes før gate er oppfylt.

**Referanse til godkjenning/issue/PR:**

**Godkjent dato:**
