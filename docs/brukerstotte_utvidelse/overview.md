# Oversikt over AAREG-ekstern brukerflateutvidelse

## Formål

Dette dokumentet beskriver analyse og spesifikasjon for utvidelse av dagens eksterne brukerflate i crm-arbeidsforhold. Målet er å støtte nye brukergrupper uten å endre dagens oppførsel for eksisterende virksomhetsrepresentanter eller brukerstøttebrukere i større grad enn nødvendig.

## Bakgrunn

Dagens løsning er bygd rundt egen organisasjonskontekst og eksisterende tilgangsmodell for virksomhetsrepresentanter. Hjemmesiden og navigasjonen i AAREG er i stor grad basert på siste valgte organisasjonsnummer, og tilgang til applikasjonsdata og meldinger er i dag knyttet til dette valg.

Den nye løsningen skal utvide dette til også å støtte:

- arbeidsgivere,
- samarbeidspartnere / fullmektiger,
- privatpersoner / arbeidstakere.

## Beslutninger som ligger til grunn

1. Første versjon støtter privatpersoner, arbeidsgivere og samarbeidspartnere.
2. Dagens løsning for virksomhetsrepresentanter og dagens brukerstøtteflyt skal fungere som i dag uten regressjon.
3. `LastUsedOrganization__c` brukes kun for virksomhetsrepresentanter.
4. For arbeidsgiver, samarbeidspartner og privatperson brukes personbasert kontekst som hovedmodell, mens organisasjon brukes som arbeidskontekst eller filter.
5. Privatpersoner trenger ikke organisasjonsnummer eller organisasjonsvalg.
6. Arbeidsgiver og samarbeidspartner må enten ha organisasjonsnummer eller velge organisasjon på homepage før de fortsetter.
7. Vi skal begrense antallet nye komponenter og bygge en liten ny inngangsside på toppen av dagens `aareg_home`-modell.

## Kjerneprinsipp

1. Behold dagens løsning for virksomhetsrepresentanter.
2. Gjenbruk eksisterende LWC-komponenter, Apex-klasser og datamodeller der dette er naturlig.
3. Sørg for tydelig skille mellom brukergruppe, representasjonskontekst og faktisk tilgang.
4. Kontroller alle autorisasjonsavhengigheter på serversiden.
5. Unngå ny og generisk arkitektur uten konkret behov.
6. Bruk én aktiv organisasjonskontekst per bruker i de nye personbaserte flytene, ikke flere samtidige aktive organisasjonsvalg.

## Inngangsvinkler

Løsningen skal støtte to inngangsmåter:

- Eksisterende `aareg_home`-flyt for virksomhetsrepresentanter og dagens brukerstøttebrukere.
- Ny, liten inngangsside for brukergruppevalg for arbeidsgiver, samarbeidspartner og privatperson, der organisasjonsnummer kun er påkrevd når det er relevant.
- Direkte inngang via URL med query parameters for brukergruppe og organisasjonsnummer der dette er relevant.

## Utkast til ønsket oppførsel

- Virksomhetsrepresentant: kan bruke eksisterende løsninger som søknad, mine søknader, mine avtaler, brukerstøtte og mine meldinger.
- Brukerstøtte: har tilgang til brukerstøtte og relevante meldinger, i tråd med dagens modell.
- Arbeidsgiver: får tilgang til brukerstøtte og personlige meldinger i personbasert kontekst, men ikke til organisasjonsbaserte søknads- og avtalefunksjoner uten egen kontekst.
- Samarbeidspartner / fullmektig: får tilgang til brukerstøtte og egne meldinger i personbasert kontekst, men ikke til organisasjonsbaserte søknads- og avtalefunksjoner uten egen kontekst.
- Privatperson: får tilgang til egne meldinger og personlige funksjoner uten organisasjonsnummer, men ikke til virksomhetsbaserte funksjoner.

## Dokumentasjonsstruktur

Dette dokumentet er det overordnede rammeverket. De mer detaljerte analysene finnes i de øvrige dokumentene i denne katalogen:

- current-implementation.md
- proposed-changes.md
- acr-email-handling.md
- implementation-plan.md
- risks-and-testing.md
- open-questions.md

## Avgrensning

Dette er en analyse- og spesifikasjonsfase. Det skal ikke implementeres kode i denne fasen. Endringene dokumenteres kun som plan for senere utvikling.
