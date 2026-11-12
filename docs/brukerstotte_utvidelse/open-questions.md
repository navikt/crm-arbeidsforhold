# Åpne spørsmål og beslutninger som må tas før implementasjon

## 1. Hvilke brukergrupper skal faktisk støttes i første leveranse?

Ja, første versjon skal støtte privatpersoner i tillegg til arbeidsgiver og samarbeidspartnere.

Dette betyr at første leveranse skal dekke tre brukergrupper:

- arbeidsgiver,
- samarbeidspartner,
- privatperson.

Dette påvirker både URL-mønsteret, tilgangsmodellen og hvordan personbasert kontekst skal velges og valideres i UI og serverlogikk.

## 2. Skal brukergruppe være definert i en egen Apex-kontekstmodell?

Det anbefales ja, men dette må besluttes eksplisitt. En enkel modell er bedre enn en overordnet og generisk tilgangsramme.

## 3. Skal meldingsvisning være personbasert eller organisasjonsbasert per gruppe?

Beslutning: dagens meldingsvisning for virksomhetsrepresentanter og for brukere som allerede har tilgang til brukerstøtte skal fungere nøyaktig som i dag og skal ikke endres.

For de nye representasjonsrollene som gjelder personer som representerer arbeidsgivere, samarbeidspartnere og seg selv, skal meldingsvisning være personbasert som hovedmodell. Organisasjon brukes da som kontekst eller filter, men ikke som det eneste eller primære kriteriet for hvilke meldinger som skal vises.

Det betyr at:

- dagens organisasjonsbaserte flyt beholdes uendret for eksisterende brukere,
- den nye personbaserte modellen brukes kun for de nye representasjonsrollene,
- en persons aktive ACR-relasjoner til arbeidsgiver eller samarbeidspartner skal kunne hente riktig meldingskontekst,
- organisasjonsvalg kan brukes for å avgrense eller sette kontekst, men ikke som eneste kriterium for hvem som skal se hvilke meldinger,
- personens identitet og relasjon er den bærende faktoren for tilgang til meldinger og e-post i den nye brukergruppen.

Dette gjør at vi unngår regressjon i dagens løsning samtidig som vi får støtte for de nye representasjonsmønstrene.

## 4. Er det nødvendig å støtte flere organisasjonsvalg per bruker?

Nei. `LastUsedOrganization__c` skal bare brukes for virksomhetsrepresentanter.

For de andre brukergruppene skal vi bruke personbasert kontekst, og samtidig støtte valgt organisasjonsnummer som arbeidskontekst for den aktuelle oppgaven. Det betyr at hver bruker kun skal kunne ha ett aktivt organisasjonsvalg i en gitt arbeidsflyt, ikke flere samtidige organisasjonsvalg som er aktive i samme kontekst.

Kort sagt:

- virksomhetsrepresentanter: eksisterende modell med `LastUsedOrganization__c` som hovedkontekst,
- arbeidsgiver, samarbeidspartner og privatperson: personbasert kontekst + ett valgt organisasjonsnummer som arbeidskontekst,
- ingen støtte for flere samtidige aktive organisasjonsvalg for disse gruppene.

Dette er forståelig og gjør at vi unngår dobbelt kontekstmodell i samme flyt.

## 5. Hva er ønsket oppførsel for brukere uten organisasjonskontekst?

For privatpersoner som representerer seg selv, trenger de ikke å komme inn med et organisasjonsnummer og heller ikke å velge en organisasjon. De skal kunne gå inn i sin personlige kontekst direkte.

For arbeidsgivere og samarbeidspartnere er det viktig at de enten:

- kommer inn med et organisasjonsnummer, eller
- må velge en organisasjon på homepage før de kan fortsette i arbeidsflyten.

Det vil si at disse brukerne må ha en gyldig organisasjonskontekst, mens privatpersoner ikke trenger det.

## 6. Er det behov for nye Custom Metadata eller permission set for ny brukergruppe?

Dette må avklares før implementasjon, fordi noen tilganger kan være mer naturlige å modellere som eksisterende roller eller Custom Metadata.

## 7. Skal dette ligge i samme LWC-komponent eller i flere delte komponenter?

Ja, vi bør begrense antallet nye komponenter. Jeg mener det er bedre å bruke dagens `aareg_home` som dagens organisasjonsbaserte inngang, og så lage en liten ny inngangsside for de nye brukergruppene som skal kunne velge bruker type og organisasjon.

Dette bør fungere som en sammenhengende struktur:

- dagens `aareg_home` beholdes som den eksisterende organisasjonsbaserte siden,
- den nye siden brukes for nye brukergrupper når de må velge bruker type og/eller organisasjonskontekst,
- etter at konteksten er valgt, kan de gå videre inn i den samme eksisterende funksjonaliteten som dagens flyt,
- vi unngår å bygge en helt ny parallelle app fra bunnen av og holder løsningen liten og forståelig.

Kort sagt: jeg vil ikke lage en helt ny "aareg_home" fra scratch som erstatter dagens side, men heller en liten, tydelig ny inngang som peker bakover til dagens `aareg_home`-flyt når det er nødvendig.

## 8. Hvilke funksjoner som er "sinne" og hvilke som er "ikke tillatte"?

Ja, dette bør dokumenteres som en matrise for hver brukergruppe. Her er en fersk, redigerbar matrise som kan brukes som utgangspunkt før implementasjon:

| Brukergruppe                              | Kode / rolle                     | Må ha organisasjonskontekst | Må velge organisasjon                            | Personbasert kontekst     | Tillatte funksjoner                                                                    | Ikke tillatte funksjoner                                |
| ----------------------------------------- | -------------------------------- | --------------------------- | ------------------------------------------------ | ------------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| Virksomhetsrepresentant                   | Eksisterende organisasjonsbruker | Ja                          | Ja, via dagens flyt                              | Nei                       | Alle dagens organisasjonsbaserte funksjoner                                            | Nye personbaserte funksjoner uten organisasjonskontekst |
| Arbeidsgiver                              | Ny brukergruppe                  | Ja                          | Ja, enten via organisasjonsnummer eller homepage | Ja                        | Funksjoner knyttet til valgt arbeidsgiverorganisasjon og egen personlige kontekst      | Flere samtidige organisasjonsvalg i samme flyt          |
| Samarbeidspartner                         | Ny brukergruppe                  | Ja                          | Ja, enten via organisasjonsnummer eller homepage | Ja                        | Funksjoner knyttet til valgt samarbeidspartnerorganisasjon og egen personlige kontekst | Flere samtidige organisasjonsvalg i samme flyt          |
| Privatperson                              | Ny brukergruppe                  | Nei                         | Nei                                              | Ja                        | Personlige oppgaver og personlige meldinger uten organisasjonskrav                     | Obligatorisk organisasjonsvalg                          |
| Brukerstøtte / eksisterende supportbruker | Eksisterende support             | Ja/avhengig av dagens flyt  | Som i dag                                        | Avhengig av dagens modell | Nåværende supportflyt uten endring                                                     | Regresjon i dagens oppførsel                            |

Dette er et godt utgangspunkt for å få ned de viktigste beslutningene i en enkel tabell. Dere kan redigere den etter hva som faktisk er tillatt for hver funksjon i den endelige leveransen.

## 9. Hva er ønsket nivå for audit / tracking i dette første steget?

Dette prosjektet bør holde seg liten og AAREG-spesifikk. Før implementasjon må det bestemmes hvor mye historikk som faktisk trengs i prosessen, uten å bygge et generisk aktivitetsystem.

## 10. Vil dette være en isolert AAREG-løsning eller skal det dele logikk med andre områder?

Det anbefales å holde dette AAREG-spesifikt i første fase, slik at løsningen er enkel å forstå, vedlikeholde og auditere.
