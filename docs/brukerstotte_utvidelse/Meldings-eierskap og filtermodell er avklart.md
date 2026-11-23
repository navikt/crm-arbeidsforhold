# Meldings-eierskap og filtermodell er avklart

**Status:** For avklaring — ikke godkjent før eierskap, filtermodeller og multi-role-scenarier er fylt ut

Dette dokumentet skal avgjøre hvem som eier og administrerer meldinger i Salesforce, og hvilke tråder brukeren får se eller skrive i for hver rolle.

## Beslutningsmodell

Meldingsmodell og tilgang må behandles som separate beslutninger:

- `Inquiry` eller støttehenvendelsen representerer opprettelsen og eierforholdet.
- `Thread` og svar representerer samtalen.
- `Attachment` representerer vedlegg og må arves eller isoleres fra den samme tilgangen som tråden.
- Serverfilter bestemmer hvilke meldinger brukeren får se og skrive i.
- Rollekontekst bestemmer hvilken modell og hvilket filter som brukes, men gir ikke tilgang alene.

UI-skjuling er ikke tilgangskontroll.

## Dagens modell

Eksisterende virksomhetsrepresentantflyt skal beholdes under overgang:

- Meldinger er i dag organisasjonsbaserte.
- Tråder hentes via `User.LastUsedOrganization__c` og tilknyttet arbeidsgiverkonto.
- Kommunen eller Salesforce-organisasjonen må ikke bli brukt som generell tilgangskilde for nye roller.
- Dagens modell må vurderes som en separat fallback for eksisterende brukerstøttebrukere.

**Bekreftet baseline:**

- [ ] Virksomhetsrepresentant beholder dagens organisasjonsbaserte modell.
- [ ] Nye roller får en tydelig person-/rollebasert modell der organisasjonen er kontekst eller filter.
- [ ] Serverlogikken revaliderer tilgang uavhengig av hidden navigation eller Experience Cloud visibility.

## Eiendomsmodell

### Inquiry

Avklar hvilke data som eier og identifiserer en støttehenvendelse:

- Hvilken bruker opprettet Inquiry.
- Hvilken rolle brukeren valgte da Inquiry ble opprettet.
- Hvilken kontekst ble brukt: organisasjon, person eller estate.
- Hvilket organisasjonsnummer eller personidentifikator skal lagres.
- Hvem som kan lese, endre eller lukke Inquiry.
- Om Inquiry eies av Account, Contact, User, Person Account eller en annen record.
- Om redigering eller sletting er tillatt etter opprettelse.

| Spørsmål                                      | Beslutning |
| --------------------------------------------- | ---------- |
| Logisk eier av Inquiry                        | Fyll ut    |
| Eies av organisasjon eller person             | Fyll ut    |
| Opprettende bruker                            | Fyll ut    |
| Kan brukeren endre Inquiry                    | Fyll ut    |
| Kan brukeren slette Inquiry                   | Fyll ut    |
| Kan brukerstøtte korrigere eier-/kontekstfelt | Fyll ut    |

### Thread

- Hvilken Inquiry eier tråden.
- Hvilken rolle og kontekst tråden opprettes under.
- Hvem som kan lese tråden.
- Hvem som kan svare i tråden.
- Om en tråd kan flyttes mellom organisasjons-, rolle- eller personkontekst.
- Om en tråd kan være synlig for flere roller for samme person.
- Om en tråd kan være synlig for flere brukere i samme organisasjon.

| Spørsmål                                   | Beslutning |
| ------------------------------------------ | ---------- |
| Logisk eier av Thread                      | Fyll ut    |
| Eies av Inquiry, organisasjon eller person | Fyll ut    |
| Hvem kan lese                              | Fyll ut    |
| Hvem kan svare                             | Fyll ut    |
| Kan tråden flyttes                         | Fyll ut    |
| Er tråden synlig på tvers av roller        | Fyll ut    |

### Attachment

- Hvem kan laste opp vedlegg.
- Hvem kan lese vedlegget.
- Om tilgang følger Inquiry, Thread eller en egen ownership-record.
- Begrensninger på filtype og størrelse.
- Lagringssted, retention og sletting.
- Om vedlegg kan lastes ned direkte ved kjent URL eller Salesforce-ID.
- Om virus-/malwarekontroll eller annen validering er påkrevd.

| Spørsmål                     | Beslutning |
| ---------------------------- | ---------- |
| Eiere av Attachment          | Fyll ut    |
| Tilgang arves fra            | Fyll ut    |
| Kan ekstern bruker laste opp | Fyll ut    |
| Kan ekstern bruker lese      | Fyll ut    |
| Retention/sletting           | Fyll ut    |

### Svar

- Hvem kan opprette svar.
- Om svar eies av innsenderen eller tråden.
- Om brukeren kan sende svar i en lukket tråd.
- Om bruker, case handler og automatiske svar håndteres forskjellig.
- Om rolle og kontekst skal lagres på selve svaret eller bare arves fra tråden.
- Om redigering eller sletting av sendte svar er tillatt.

| Spørsmål                        | Beslutning |
| ------------------------------- | ---------- |
| Eier av svar                    | Fyll ut    |
| Ekstern bruker kan svare        | Fyll ut    |
| Lukket tråd kan besvares        | Fyll ut    |
| Rolle/kontekst lagres på svaret | Fyll ut    |
| Redigering/sletting tillatt     | Fyll ut    |

## Filtermodell per rolle

| Rolle                           | Modell                                   | Påkrevd filter                                        | Ekstra tilgangskrav                         | Beslutning |
| ------------------------------- | ---------------------------------------- | ----------------------------------------------------- | ------------------------------------------- | ---------- |
| Virksomhetsrepresentant         | Organisasjonsbasert                      | Organisasjonsnummer og godkjent organisasjonskontekst | Dagens access-regler                        | Fyll ut    |
| Arbeidsgiver                    | Personbasert eller person + organisasjon | Person-ID og godkjent organisasjonskonstekt           | Servergodkjent capability                   | Fyll ut    |
| Samarbeidspartner/fullmektig    | Person + organisasjon eller rollebasert  | Person-ID, representasjon og valgt organisasjon       | Servergodkjent representasjon og capability | Fyll ut    |
| Privatperson/arbeidstaker       | Personbasert                             | Person-ID eller godkjent personbinding                | Ingen organisasjon kreves                   | Fyll ut    |
| Eksisterende brukerstøttebruker | Dagens modell                            | Eksisterende filter/kontekst                          | Dagens access-regler                        | Fyll ut    |

### Virksomhetsrepresentant

- Beholdes som organisasjonsbasert.
- Hver tråd skal fortsatt kunne filtreres på den valgte organisasjonen.
- Stored context får ikke alene gi tilgang.
- Serveren revaliderer den valgte organisasjonen ved lesing og skriving.

**Beslutning:**

### Arbeidsgiver

- `organizationNumber` kan brukes som organisasjonsfilter og arbeidskontekst.
- Personens rolle og identity må også vurderes når trådene filtreres.
- Avklar om arbeidsgiver ser alle organisasjonens tråder eller bare egne/personrelaterte tråder.
- Avklar om to brukere i samme organisasjon kan se hverandres meldinger.

**Beslutning:**

### Samarbeidspartner/fullmektig

- Avklar om meldinger følger representasjonen eller personen.
- Avklar om tråder opprettet under én representasjon blir synlige for andre fullmakter.
- Avklar om tilgang skal begrenses til valgt organisasjon.
- Avklar om en tilbakekalt representasjon straks mister lesing og svaring.

**Beslutning:**

### Privatperson/arbeidstaker

- Meldinger filtreres først på person, ikke organisasjon.
- Ingen organisasjonsnummer skal være påkrevd.
- Serveren må koble pålogget bruker til personmaster eller godkjent personbinding.
- Personen må ikke kunne lese organisasjonsbaserte meldinger eller andres meldinger bare ved å manipulere en ID.

**Beslutning:**

## Synlighet på tvers av roller

Avklar hvert tilfelle separat:

- [ ] Samme person ser meldinger opprettet som virksomhetsrepresentant.
- [ ] Samme person ser meldinger opprettet som arbeidsgiver.
- [ ] Samme person ser meldinger opprettet som partner/fullmektig.
- [ ] Samme person ser meldinger opprettet som privatperson.
- [ ] Meldinger fra en rolle kan bare ses i den rollen.
- [ ] Meldinger fra samme person samles på tvers av roller.
- [ ] Meldinger fra en organisasjon deles med alle authorized representanter i organisasjonen.
- [ ] Meldinger fra en organisasjon er begrenset til personen som opprettet dem.

**Beslutning om kryssrolle-synlighet:**

**Krav for å unngå feil eksponering:**

## Rollekontekst på meldingene

Avklar hvilke felter som må lagres på Inquiry, Thread og eventuell svarhistorikk:

- `SubmittedRole__c` eller tilsvarende rollefelt.
- Konteksttype: organisasjon eller person.
- Organisasjonsnummer der det er relevant.
- Personbinding eller person-ID der det er relevant.
- Representasjons-ID eller godkjent fullmaktsreferanse der det er relevant.
- Opprettelsesdato og tidspunkt.
- Hvem som opprettet recorden.

Serveren, ikke klienten, skal skrive autoritativ rolle- og kontekstinformasjon.

**Beslutning:**

## Server-side filter

For hvert serverkall skal filtermodellen eksplisitt definere:

- Pålogget bruker-ID, hentet fra `UserInfo.getUserId()`.
- Rollevalget og den validerte konteksten.
- Godkjent capability.
- Tillatte record-IDer eller record owner.
- Organisasjons- eller personfilter.
- Lese- og skriverettigheter.
- Svar på tomt resultat.
- Svar på manglende tilgang.
- Svar på teknisk kildefeil.

| Operasjon            | Krav til serverfilter                 | `GRANTED` | `DENIED` | `TECHNICAL_ERROR` |
| -------------------- | ------------------------------------- | --------- | -------- | ----------------- |
| Opprette Inquiry     | Rolle + context + `SUPPORT`           | Fyll ut   | Fyll ut  | Fyll ut           |
| Liste tråder         | Rolle + context + `MESSAGES`          | Fyll ut   | Fyll ut  | Fyll ut           |
| Åpne en bestemt tråd | Rolle + context + eid/scope           | Fyll ut   | Fyll ut  | Fyll ut           |
| Sende svar           | Rolle + context + aktiv tråd          | Fyll ut   | Fyll ut  | Fyll ut           |
| Laste opp vedlegg    | Rolle + context + tråd-/Inquiry-scope | Fyll ut   | Fyll ut  | Fyll ut           |
| Laste ned vedlegg    | Rolle + context + tråd-/Inquiry-scope | Fyll ut   | Fyll ut  | Fyll ut           |

Direkte Apex-kall må kontrollere samme beslutning som UI og endepunkt fra Experience Cloud.

## Vedlegg og personvern

- [ ] Vedlegg behandles som rødsone data.
- [ ] Unødvendig persondata skal ikke logges.
- [ ] Nedlasting uten tråd- eller Inquiry-scope skal nektes.
- [ ] Record sharing og CRUD/FLS er avklart for Inquiry, Thread, Attachment og svar.
- [ ] Minimum-access external user brukes i relevante tester.
- [ ] E-postadresser og personopplysninger i meldinger er beskyttet.
- [ ] Retention og sletting er avklart.

**Beslutning:**

## Feil og kanttilfeller

| Situasjon                                     | Forventet resultat                              |
| --------------------------------------------- | ----------------------------------------------- |
| Tomt resultat                                 | Tøm liste eller tom tilstand, ikke teknisk feil |
| Mangler rolle eller kontekst                  | `DENIED` eller avvist input                     |
| Mangler capability `SUPPORT` eller `MESSAGES` | `DENIED`                                        |
| Tråden finnes, men brukeren er utenfor scope  | `DENIED` uten å eksponere trådinnhold           |
| Manipulert tråd-ID eller vedlegg-ID           | `DENIED`                                        |
| Tilbakekalt representasjon eller rolle        | `DENIED`; revoker tidligere listede resultater  |
| Tilgangskilden svarer teknisk                 | `TECHNICAL_ERROR` med retry                     |
| Tråden er lukket                              | Svartilgang avklart som tillatt eller avvist    |

## Testing

- [ ] Virksomhetsrepresentantens organisasjonsbaserte tråder har regresjonsdekning.
- [ ] Arbeidsgiver kan bare se servergodkjente tråder.
- [ ] Partner/fullmektig kan bare se tråder innen godkjent representasjon og organisasjon.
- [ ] Privatperson ser bare personbaserte tråder.
- [ ] Samme person med flere roller tester alle representative multi-role-scenarier.
- [ ] Manipulerte tråd-, vedlegg-, Inquiry- og organisasjons-IDer nektes.
- [ ] Tomt resultat skiller seg fra teknisk feil.
- [ ] Minimum-access external user dekker lesing og skriving der relevant.
- [ ] Direkte Apex-kall testes separat fra portal-/LWC-kall.
- [ ] Vedlegg krever samme tilgang som den tilhørende tråden.

## Godkjenning

| Rolle                                              | Godkjent av | Dato | Referanse |
| -------------------------------------------------- | ----------- | ---- | --------- |
| Produkt-/domeneansvarlig for meldingsmodell        |             |      |           |
| Teknisk ansvarlig for serverfilter og dataeierskap |             |      |           |
| Security/personvernansvarlig                       |             |      |           |
| Ansvarlig for Salesforce sharing/CRUD/FLS          |             |      |           |
| Ansvarlig for Email-to-Case/svar-/trådkorrelasjon  |             |      |           |

## Endelig beslutning

- [ ] Inquiry-eierskap er bestemt.
- [ ] Thread-eierskap er bestemt.
- [ ] Attachment-eierskap er bestemt.
- [ ] Svareierskap er bestemt.
- [ ] Filtermodell per rolle er bestemt.
- [ ] Kryssrolle-synlighet er bestemt.
- [ ] Serverfilteret er uavhengig av skjult UI og Experience Cloud visibility.
- [ ] Tomt resultat og teknisk feil er skilt.
- [ ] Minimum-access og direct-call-scenarioer er planlagt.
- [ ] Ingen kode startes før gate er oppfylt.

**Referanse til godkjenning/issue/PR:**

**Godkjent dato:**
