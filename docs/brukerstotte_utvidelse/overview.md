# Oversikt over AAREG-ekstern brukerflateutvidelse

## Formål

Dette dokumentet beskriver analyse og spesifikasjon for utvidelse av dagens eksterne brukerflate i crm-arbeidsforhold. Målet er å støtte nye brukergrupper uten å endre dagens oppførsel for eksisterende virksomhetsrepresentanter eller brukerstøttebrukere i større grad enn nødvendig.

## Bakgrunn

Dagens løsning er bygd rundt egen organisasjonskontekst og eksisterende tilgangsmodell for virksomhetsrepresentanter. Hjemmesiden og navigasjonen i AAREG er i stor grad basert på siste valgte organisasjonsnummer, og tilgang til applikasjonsdata og meldinger er i dag knyttet til dette valg.

Den nye løsningen skal utvide dette til også å støtte:

- arbeidsgivere,
- samarbeidspartnere / fullmektiger,
- privatpersoner / arbeidstakere.

## Kjerneprinsipp

1. Behold dagens løsning for virksomhetsrepresentanter.
2. Gjenbruk eksisterende LWC-komponenter, Apex-klasser og datamodeller der dette er naturlig.
3. Sørg for tydelig skille mellom brukergruppe, representasjonskontekst og faktisk tilgang.
4. Kontroller alle autorisasjonsavhengigheter på serversiden.
5. Unngå ny og generisk arkitektur uten konkret behov.

## Inngangsvinkler

Løsningen skal støtte to inngangsmåter:

- Felles startside for valg av brukergruppe og, når relevant, organisasjonsnummer.
- Direkte inngang via URL med query parameters for brukergruppe og organisasjonsnummer.

## Utkast til ønsket oppførsel

- Virksomhetsrepresentant: kan bruke eksisterende løsninger som søknad, mine søknader, mine avtaler, brukerstøtte og mine meldinger.
- Brukerstøtte: har tilgang til brukerstøtte og relevante meldinger, i tråd med dagens modell.
- Arbeidsgiver: får tilgang til brukerstøtte og personlige meldinger, men ikke til søknads- og avtalefunksjoner.
- Samarbeidspartner / fullmektig: får tilgang til brukerstøtte og egne meldinger, men ikke til søknads- og avtalefunksjoner.
- Privatperson: får tilgang til egne meldinger og eventuelle personlige funksjoner, men ikke til virksomhetsbaserte funksjoner.

## Dokumentasjonsstruktur

Dette dokumentet er det overordnede rammeverket. De mer detaljerte analysene finnes i de øvrige dokumentene i denne katalogen:

- current-implementation.md
- proposed-changes.md
- implementation-plan.md
- risks-and-testing.md
- open-questions.md

## Avgrensning

Dette er en analyse- og spesifikasjonsfase. Det skal ikke implementeres kode i denne fasen. Endringene dokumenteres kun som plan for senere utvikling.
