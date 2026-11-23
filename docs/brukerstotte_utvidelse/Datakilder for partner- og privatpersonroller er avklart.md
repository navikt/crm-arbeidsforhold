# Datakilder for partner- og privatpersonroller er avklart

**Status:** For avklaring — ikke godkjent før kildene, eierne og håndtering av feil/konflikt er fylt ut

Dette dokumentet skal avgjøre hvilke datakilder som styrer representasjon og tilgang for partner-/fullmektigroller og privatpersonroller.

## Beslutningsregel

Det må skilles mellom fire beslutninger:

1. **Identitet:** hvem er brukeren?
2. **Representasjon:** hvem har brukeren rett til å opptre for?
3. **Rettighet/tilgang:** hvilke handlinger får brukeren?
4. **Data-/record-tilgang:** hvilke Salesforce-records og felter får brukeren lese eller skrive?

ACR og Altinn er ikke samme type beslutning, og én kilde må ikke automatisk brukes som bevis for alle fire beslutningene.

## Kildekart

| Rolle                     | Beslutning                      | Autoritativ kilde | Fallback-kilde | Oppdateringsfrekvens | Eier    | Status   |
| ------------------------- | ------------------------------- | ----------------- | -------------- | -------------------- | ------- | -------- |
| Partner/fullmektig        | Identitet                       | Fyll ut           | Fyll ut        | Fyll ut              | Fyll ut | Uavklart |
| Partner/fullmektig        | Representasjon                  | Fyll ut           | Fyll ut        | Fyll ut              | Fyll ut | Uavklart |
| Partner/fullmektig        | Organisasjonsrettighet          | Fyll ut           | Fyll ut        | Fyll ut              | Fyll ut | Uavklart |
| Partner/fullmektig        | Salesforce data-/record-tilgang | Fyll ut           | Fyll ut        | Fyll ut              | Fyll ut | Uavklart |
| Privatperson/arbeidstaker | Identitet                       | Fyll ut           | Fyll ut        | Fyll ut              | Fyll ut | Uavklart |
| Privatperson/arbeidstaker | Person-/selvkontekst            | Fyll ut           | Fyll ut        | Fyll ut              | Fyll ut | Uavklart |
| Privatperson/arbeidstaker | Rettighet til egne data         | Fyll ut           | Fyll ut        | Fyll ut              | Fyll ut | Uavklart |
| Privatperson/arbeidstaker | Salesforce data-/record-tilgang | Fyll ut           | Fyll ut        | Fyll ut              | Fyll ut | Uavklart |

## Partner/fullmektig

### Representasjonskilde

Avklar hvor representasjonen finnes:

- [ ] Altinn
- [ ] `AccountContactRelation.Roles` / ACR
- [ ] Register over andre fullmakter
- [ ] Salesforce-/AAREG-data
- [ ] Kombinasjon av flere kilder
- [ ] Annen godkjent kilde:

**Beslutning:**

**Begrunnelse:**

### Hvorfor kilden er autoritativ

Beskriv hvem som oppretter og endrer representasjonen, hvilke oppdateringer som er autoritative, og hvilke konflikter kilden løser:

**Beslutning:**

### Rolle og status i representasjonen

- [ ] Rolleverdier er eksplisitt definert.
- [ ] Aktiv/inaktiv status er avklart.
- [ ] `StartDate` og `EndDate` er avklart.
- [ ] Tilbakekalling er avklart.
- [ ] Utløpte relasjoner oppdateres eller ignoreres.
- [ ] Flere aktive relasjoner for samme person støttes.
- [ ] Flere samtidige roller støttes.
- [ ] Samme person kan representere flere organisasjoner.

**Beslutning:**

### Kapabilities

| Partnerhandling   | Representasjonskilde | Tilgangskilde | Lesing  | Skriving | Beslutning |
| ----------------- | -------------------- | ------------- | ------- | -------- | ---------- |
| `APPLICATION`     | Fyll ut              | Fyll ut       | Fyll ut | Fyll ut  | Uavklart   |
| `MY_APPLICATIONS` | Fyll ut              | Fyll ut       | Fyll ut | Fyll ut  | Uavklart   |
| `AGREEMENTS`      | Fyll ut              | Fyll ut       | Fyll ut | Fyll ut  | Uavklart   |
| `SUPPORT`         | Fyll ut              | Fyll ut       | Fyll ut | Fyll ut  | Uavklart   |
| `MESSAGES`        | Fyll ut              | Fyll ut       | Fyll ut | Fyll ut  | Uavklart   |

### Organisasjonskontekst

- [ ] Partneren må velge eller få levert organisasjonsnummer.
- [ ] Organisasjonsnummer revalideres mot representasjon ved hvert kall.
- [ ] URL-parametere brukes bare som kontekst og ikke som autorisasjonsbevis.
- [ ] Ugyldig, manipulert eller utdatert organisasjonsnummer avvises.
- [ ] Bare én aktiv arbeidskontekst støttes per handling der organisasjon er påkrevd.
- [ ] Kontekstbytte nullstiller eller invalidrerer gammel tilgangsbeslutning.

**Beslutning:**

### Kildekonflikter

Avklar hva som skjer når kildene ikke er enige:

- [ ] ACR eksisterer, men Altinn eller annen tilgangskilde mangler.
- [ ] Altinn eller annen tilgangskilde finnes, men ACR mangler.
- [ ] Relasjonen er aktiv i en kilde og utløpt eller tilbakekalt i en annen.
- [ ] Organisasjonsnummeret finnes i flere konto-/representasjonsrelasjoner.
- [ ] Kilden har tilgengelighetsfeil eller tidsavvik.

**Prioritet ved konflikt:**

**Fail-closed eller fail-open:**

### Vedlikehold og historikk

- [ ] Eierskap for opprettelse av representasjon er bestemt.
- [ ] Eierskap for vedlikehold er bestemt.
- [ ] Migrering fra eksisterende koblingsmodeller er avklart.
- [ ] Historikk eller tidsbegrensning er avklart.
- [ ] Oppdateringsfrekvens eller sanntidskrav er målbart.
- [ ] Audit-/sporingsbehov er avklart.

**Beslutning:**

## Privatperson/arbeidstaker

### Person-/identitetskilde

Avklar hvilken autoritativ kilde som kobler pålogget person til personcontext:

- [ ] Salesforce Person Account eller Personkonto
- [ ] `Contact`
- [ ] Fødselsnummer eller annen påloggingsidentitet
- [ ] KRR
- [ ] AAREG
- [ ] Kombinasjon av kilder
- [ ] Annen godkjent kilde:

**Beslutning:**

**Begrunnelse:**

### Personkontekst

- [ ] Privatperson trenger ikke organisasjonsnummer.
- [ ] Personens identitet hentes på serveren fra pålogget bruker eller godkjent personbinding.
- [ ] Klienten sender ikke person-ID eller fødselsnummer som tilgangsbevis.
- [ ] Personens egne records kobles til personmasteren.
- [ ] Ugyldig eller duplikat personbinding avvises.
- [ ] Personendring eller sammenslåing håndteres på en sikker måte.

**Beslutning:**

### Handlinger for privatpersonen

| Handling          | Lesing tillatt | Skriving tillatt | Datakilde | Begrensning/scope | Beslutning |
| ----------------- | -------------- | ---------------- | --------- | ----------------- | ---------- |
| `APPLICATION`     | Fyll ut        | Fyll ut          | Fyll ut   | Fyll ut           | Uavklart   |
| `MY_APPLICATIONS` | Fyll ut        | Fyll ut          | Fyll ut   | Fyll ut           | Uavklart   |
| `AGREEMENTS`      | Fyll ut        | Fyll ut          | Fyll ut   | Fyll ut           | Uavklart   |
| `SUPPORT`         | Fyll ut        | Fyll ut          | Fyll ut   | Fyll ut           | Uavklart   |
| `MESSAGES`        | Fyll ut        | Fyll ut          | Fyll ut   | Fyll ut           | Uavklart   |

### Personlige data og meldinger

- [ ] Egen-scope er avklart for Inquiry, Thread, Attachment og svar.
- [ ] Personens rett til å se andres meldinger er avklart som ikke tillatt eller begrenset.
- [ ] Samme person med flere roller har avklart melding-scope.
- [ ] Meldinger skal være personbasert, rollebasert eller organisasjonsbasert der relevant.
- [ ] Meldinger skal være synlige på tvers av roller bare hvis beslutningen uttrykkelig godkjenner det.
- [ ] Unødvendig persondata må ikke logges.
- [ ] Kilden for e-post er avklart i separat ADR eller dokument.

**Beslutning:**

### Endring av personopplysninger

- [ ] Privatpersonen kan korrigere e-post.
- [ ] Privatpersonen kan korrigere andre personopplysninger.
- [ ] Autoritativ kilde kan bli overskrevet av brukerstøtte eller bruker.
- [ ] Overstyringer har historikk og kilde-sporing.
- [ ] Oppdateringsfrekvens og personvernhåndtering er avklart.

**Beslutning:**

## Salesforce-tilgang

For begge roller må følgende avklares separat fra representasjon:

- [ ] `CRUD` er avklart for hver objecttype.
- [ ] `FLS` er avklart for hver feltgruppe.
- [ ] Record sharing og ownership er avklart.
- [ ] Metoder i system mode har eksplisitte data- og actiongrenser.
- [ ] Minimum-access external user brukes i relevante Apex-tester.
- [ ] Direkte Apex-kall testes separat fra LWC-kall.
- [ ] Klientinput kan ikke utvide data- eller action-scope.
- [ ] Bruker-ID hentes alltid fra `UserInfo.getUserId()` på serveren.

**Beslutning:**

## Feil og kanttilfeller

| Situasjon                                        | Forventet beslutning                                        | Bruker-/driftutfall                               |
| ------------------------------------------------ | ----------------------------------------------------------- | ------------------------------------------------- |
| Relasjonen finnes ikke                           | `DENIED`                                                    | Ingen representasjons-/data-adgang                |
| Relasjonen er tilbakekalt eller utløpt           | `DENIED`                                                    | Tøm eller avvis gammel kontekst                   |
| Relasjonen finnes i en kilde men ikke i en annen | Fail-closed med mindre eksplisitt godkjent fallback finnes  | Ingen tilgang eller tydelig avklaring av konflikt |
| Datakilden svarer med teknisk feil               | `TECHNICAL_ERROR`                                           | Egen retry-feilmelding; ikke «ingen tilgang»      |
| Flere relasjoner eller roller finnes             | Serveren evaluerer valgt rolle og aktiv kontekst            | Ulik scope for rolle og handling                  |
| Personbinding er ukjent eller duplikat           | `DENIED` eller teknisk feil, avklart av personvernansvarlig | Ikke eksponere andres persondata                  |
| Resultatsett er tomt                             | Ikke lik teknisk feil                                       | Vis tom tilstand                                  |

## Tester som må dekke gate

- [ ] Partner med aktiv representasjon får godkjent scope.
- [ ] Partner uten aktiv representasjon får `DENIED`.
- [ ] Tilbakekalt eller utløpt representasjon nektes.
- [ ] Manipulert eller utdatert organisasjonsnummer nektes.
- [ ] Konflikt mellom kilder får godkjent fail-closed/fail-open-resultat.
- [ ] Tekniske kildefeil gir `TECHNICAL_ERROR`.
- [ ] Privatperson får bare egen person-/melding-scope.
- [ ] Privatperson får ikke organisasjonsdata uten godkjent representasjon.
- [ ] Flere roller og relasjoner er testet som representative multi-role scenarios.
- [ ] Minimum-access user dekker positivt og negativt scenario der relevant.
- [ ] Direkte Apex-kall testes separat fra portal-/LWC-kall.

## Godkjenning

| Rolle                                | Godkjent av | Dato | Referanse |
| ------------------------------------ | ----------- | ---- | --------- |
| Kildeeier for partnerrepresentasjon  |             |      |           |
| Kildeeier for privatperson/identitet |             |      |           |
| Teknisk ansvarlig                    |             |      |           |
| Domene-/produktansvarlig             |             |      |           |
| Security/personvernansvarlig         |             |      |           |

## Endelig beslutning

- [ ] Autoritativ kilde for partnerrepresentasjon er godkjent.
- [ ] Autoritativ kilde for partnerens operativ tilgang er godkjent.
- [ ] Autoritativ kilde for privatpersonens personkontekst er godkjent.
- [ ] Representasjon og tilgangen er ikke blandet sammen som én beslutning.
- [ ] ACR og Altinn brukes med eksplisitte roller.
- [ ] Kildekonflikt og feiltilstand er avklart.
- [ ] CRUD/FLS og record sharing er avklart.
- [ ] Testene dekker positive, negative og tekniske feil.
- [ ] Ingen kode startes før gate er oppfylt.

**Referanse til godkjenning/issue/PR:**

**Godkjent dato:**
