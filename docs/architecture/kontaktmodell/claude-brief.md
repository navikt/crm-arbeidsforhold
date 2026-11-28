# Brief til Claude: skisser for kontaktmodellen i Aa-registeret

**Status: Grunnlag for design. Avgjerdene i [spesifikasjonen](../../../.github/specs/aareg-contact-model.md) gjeld føre denne briefen.**

Avgjort 23. november 2026: **rolle først, på forsida**, deretter søkbar organisasjonsveljar på rollesida. Søknaden har ikkje eige rolleval. Sjå [inngangsportal.md](inngangsportal.md). E-post per organisasjon blir lagra på ACR.

Dette dokumentet er laga for å limast inn i Claude, eller ein annan designassistent, i sin heilskap.
Det inneheld alt som trengst for å lage wireframes, diagram og flytskjema for eksterne og interne
Salesforce-sider. Kapittel 7 har òg ei vurdering av korleis profilsida skal oppføre seg før
personen har valt organisasjon.

---

## 1. Oppdrag til Claude

> Du er ein erfaren tenestedesignar og Salesforce-arkitekt. Lag klikkbare, høgoppløyste
> wireframes og diagram for ein ny kontaktmodell i Aa-registeret hos Nav. Løysinga består av ein
> ekstern portal i **Salesforce Experience Cloud** og interne sider i **Salesforce Lightning
> Experience**. Følg prinsippa, datamodellen, skjermlista og flytane i denne briefen nøyaktig.
> Bruk berre plasshaldarar for personar, organisasjonar, organisasjonsnummer og e-postadresser.
> Marker alt som er forslag. Lever i formata i kapittel 12.

## 2. Bakgrunn

Aa-registeret er Nav sitt register over arbeidsforhold. Verksemder søkjer om tilgang til data,
inngår avtalar og kontaktar brukarstøtte gjennom ein portal. Privatpersonar kan bruke portalen
for å sjå og spørje om eigne forhold.

I dag finst det problem i løysinga:

- Ein kontakt blir slått opp på organisasjon og e-post. Ny e-post eller ny organisasjon gir ein
  ny kontakt for same person.
- To personar med same felles e-post kan bli slått saman.
- Andre kontaktpersonar på ein søknad er lagra som fritekst utan kopling til ein kontakt eller
  ei eksplisitt rolle.
- Personen har ingen profilside der dei kan halde eigne kontaktopplysningar oppdaterte.

Målet er éin varig kontakt per person, ein tydeleg modell for organisasjonstilknyting og
søknadsroller, og eigne e-postadresser per kontekst.

## 3. Låste prinsipp

Desse prinsippa skal ikkje endrast eller tolkast vekk i skissene.

1. **Éin kontakt per person** i Aa-register-domenet. Ny e-post eller ny organisasjon gir aldri
   ny kontakt.
2. **Organisasjonstilknyting ligg i standardobjektet `AccountContactRelation` (ACR).** ACR er
   ein relasjon, ikkje fullmakt. Tilgang kjem alltid frå Altinn.
3. **Søknadsroller ligg i eit junction-objekt** mellom kontakt og søknad eller avtale, med
   eksplisitt rolle. Forslaget er å vidareutvikle `RelatedContact__c`.
4. **Éi privat e-postadresse** for eigen regi, og **éi separat adresse per
   organisasjonstilknyting**, uavhengig av kor mange roller personen har der.
5. **Konteksten vel adressa.** Det finst ingen automatisk fallback til privatadressa eller til
   adressa hos ein annan organisasjon. Manglar adressa, må personen oppgi ho.
6. **Endringar er isolerte.** Endring av éi adresse endrar ikkje dei andre adressene eller
   historikk som allereie er sendt inn.
7. **Innsynet er avgrensa.** Ein organisasjon ser ikkje privatadressa til personen eller adressa
   hos ein annan organisasjon.
8. **Ingen representant kan endre profilen til ein annan person.** Representanten kan berre
   leggje til eller fjerne roller i eigen organisasjon.
9. **Skjerming** av eigne tilsette og personar med kode 6 eller 7, det vil seie strengt fortrolig
   eller fortrolig adresse, gjeld kontakt, ACR, søk, rapportar, filer, meldingar og arkiv.
10. **Kontekst blir avgjord på serveren.** Klienten kan aldri bestemme kven brukaren er eller
    kva organisasjon brukaren representerer.

## 4. Brukarar

| Persona                | Flate             | Mål                                                              |
| ---------------------- | ----------------- | ---------------------------------------------------------------- |
| Privatperson           | Experience Cloud  | Sjå eigne forhold og sende spørsmål i eigen regi                 |
| Verksemdsrepresentant  | Experience Cloud  | Søkje, følgje søknad, administrere kontaktpersonar i søknaden    |
| Brukarstøtteperson     | Experience Cloud  | Sende meldingar på vegner av ei verksemd utan søknadsrett        |
| Person i fleire roller | Experience Cloud  | Arbeide for fleire verksemder og i eigen regi utan samanblanding |
| Saksbehandlar          | Lightning         | Behandle søknader og sjå rett kontakt og adresse                 |
| Brukarstøtte hos Nav   | Lightning Console | Svare på meldingar til rett adresse                              |
| Forvaltar              | Lightning         | Rydde i uavklarte kontaktar utan automatisk samanslåing          |

Bruk desse plasshaldarane i alle skisser:

- personar: «Person A», «Person B», «Person C»;
- organisasjonar: «Organisasjon A» med org.nr. «123 456 789» og «Organisasjon B» med org.nr.
  «987 654 321»;
- adresser: «privat@eksempel.no», «person@org-a.eksempel.no» og liknande.

## 5. Datamodell

Teikn dette som eit entitetsdiagram. Merk standardobjekt, eksisterande objekt som må endrast og
nye felt.

| Objekt                   | Type                  | Viktige felt                                                                                                                                                    |
| ------------------------ | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `User`                   | Standard, uendra      | `ContactId` peikar til eksisterande innloggingskontakt. Skal ikkje endrast.                                                                                     |
| `Contact`                | Standard              | Primærkonto er ein teknisk domenekonto. Namn frå verifisert identitet. **Nytt:** privat e-post, privat telefon, kopling til innlogging, skjermingsstatus.       |
| `AccountContactRelation` | Standard              | `AccountId`, `ContactId`, `IsActive`, `StartDate`, `EndDate`, `Roles`. **Nytt:** e-post og telefon hos organisasjonen, domene = AAREG, sist stadfesta i Altinn. |
| `Account`                | Standard              | Organisasjon med org.nr. I tillegg finst éin teknisk domenekonto.                                                                                               |
| `RelatedContact__c`      | Eksisterande, endrast | Kopling til søknad eller avtale. **Nytt:** `Contact__c`, rolle, ACR-referanse, gyldig frå/til. Eksisterande namn, e-post og telefon blir snapshot.              |
| `Application__c`         | Eksisterande          | Organisasjon og status. `Email__c` er adressa som vart brukt ved innsending.                                                                                    |
| `Inquiry__c` / tråd      | Eksisterande, endrast | `ContactId__c`. **Nytt:** kontekst (person/organisasjon), «sendt som»-rolle. `Email__c` er adressa som vart brukt.                                              |
| `EmailQueue__c`          | Eksisterande          | Mottakaren blir bunden ved kølegging og kontrollert på nytt ved utsending.                                                                                      |

Relasjonar:

- `User` til `Contact`: kontrollert mapping, ikkje direkte endring av `User.ContactId`;
- `Contact` 1:n `AccountContactRelation` n:1 `Account`;
- `Contact` 1:n `RelatedContact__c` n:1 `Application__c` eller avtale;
- `RelatedContact__c` peikar til ACR-raden som gir adressa for organisasjonen;
- `Contact` 1:n `Inquiry__c` og `EmailQueue__c`.

Lagring av adressa per organisasjon er ikkje avgjord. Skissene skal vise ACR-alternativet. I
notatfeltet skal det stå at alternativet er eit eige kontaktpunktobjekt.

## 6. Altinn i dag

Den eksisterande portalen hentar organisasjonslista frå Altinn via
`AAREG_HomeController.getOrganizationsWithRoles` og kan oppdatere ho med
`refreshOrganizationsWithRoles`. Rettar for ein bestemt organisasjon og teneste blir henta med
`AAREG_CommunityUtils.getUserRights`. Skissene skal byggje på denne mekanismen og ikkje på ACR.

## 7. Vurdering: vise organisasjonsdata før organisasjonsval?

### Spørsmålet

Skal profilsida vise adresser, roller eller anna informasjon for organisasjonar før personen har
valt organisasjonen i ein veljar? Formålet er å unngå forvirring og å kontrollere at personen
framleis har tilgang i Altinn.

### Alternativ

| Alternativ                                                    | Fordel                                                | Ulempe                                                                                                                               |
| ------------------------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| A. Vis alle organisasjonar med adresse og roller              | Full oversikt på éin stad                             | Byggjer på ACR, som kan vere utdatert. Viser data for organisasjonar personen ikkje lenger representerer. Lett å endre feil adresse. |
| B. Vel organisasjon først, vis berre data for den             | Éin kontekst om gongen, alltid kontrollert mot Altinn | Personen ser ikkje alle eigne adresser samla                                                                                         |
| C. Som B, pluss ei avgrensa liste over tidlegare tilknytingar | Personen kan sjå og fjerne eigne opplysningar         | Krev eit ekstra, enkelt element                                                                                                      |

### Tilråding: alternativ C

Profilsida skal vere kontekststyrt:

1. **Før val** viser profilen berre «Meg sjølv»: namn, privat e-post og telefon. Øvst står ein
   organisasjonsveljar.
2. **Veljaren blir fylt frå eit ferskt Altinn-oppslag**, ikkje frå ACR. Ein organisasjon utan
   gjeldande Altinn-rett blir ikkje vist i veljaren.
3. **Etter val** kontrollerer serveren retten i Altinn for den valde organisasjonen. Først då blir
   adressa hos organisasjonen, rollene og søknadene vist. ACR blir oppretta eller oppdatert, og
   tidspunktet for stadfestinga blir lagra.
4. **Ny kontroll** blir gjort ved handlingar med konsekvens: innsending, endring av adresse,
   endring av roller og opning av ein søknad. Ein kort mellomlagring i økta kan vurderast, men
   tida må avklarast.
5. **Tidlegare tilknytingar** blir viste i ein lukka seksjon nedst. Seksjonen viser berre namnet
   på organisasjonen og teksten «Du har ikkje lenger tilgang via Altinn». Personen kan fjerne si
   eiga adresse der. Roller, søknader og adressa sjølv blir ikkje viste.
6. **Om Altinn ikkje svarar**, blir ingen organisasjonsdata viste. Det skal vere tydeleg at dette
   er ein teknisk feil og ikkje mangel på tilgang. «Meg sjølv» fungerer framleis.
7. **ACR blir ikkje deaktivert automatisk** etter eitt mislukka oppslag. Statusen «ikkje
   stadfesta sidan [dato]» blir vist internt. Deaktivering skjer etter ein avtalt regel.

**Grunngiving:** Brukaren ser éin kontekst om gongen og kan ikkje endre adressa hos feil
organisasjon ved ein feil. Tilgang kjem alltid frå Altinn, i samsvar med prinsipp 2 og 10. Data
blir ikkje viste til personar som har mista retten. Personen har likevel innsyn i at det finst
lagra opplysningar, og kan fjerne dei.

**Tradeoff:** Personen må byte kontekst for å sjå adresser hos fleire organisasjonar. Det
reduserer oversikta, men gir tryggare og meir forståeleg bruk. Saksbehandlaren ser framleis alle
kontekstar internt.

**Må avklarast:** mellomlagringstid, regel for deaktivering av ACR, kva Altinn-rett som gjeld for
kvar handling, og om fjerning av adresse skal vere sjølvbetent eller gå via Nav.

### Krav til organisasjonsveljaren

Ein person kan representere mange organisasjonar, til dømes som rekneskapsførar eller i eit
konsern. Kort og vanleg `Select` er derfor ikkje godt nok. Veljaren skal vere:

1. **Éin søkbar nedtrekksliste i sidehovudet** med teksten «Du opptrer som». Profilen og andre
   sider viser valet, men har ikkje ein eigen veljar.
2. **Søk på namn og organisasjonsnummer** i lista som allereie er henta frå Altinn for personen.
   Søket skal ikkje skilje mellom store og små bokstavar, skal ignorere mellomrom i
   organisasjonsnummeret og skal gi treff midt i namnet.
3. **«Meg selv» står alltid øvst** i ei eiga gruppe, også når søket ikkje gir treff.
4. **Kvart alternativ** viser namn, organisasjonsnummer med mellomrom og type, til dømes
   «Hovedenhet» eller «Underenhet», på éi linje.
5. **Sortering:** sist brukte organisasjon først, deretter alfabetisk. «Sist brukt» blir lagra på
   serveren.
6. **Tal på treff** blir lese opp for skjermlesarar.
7. **Tilstandar:** lastar, ingen organisasjonar, ingen treff, Altinn-feil med «Prøv igjen», og
   «Oppdater fra Altinn». Éin organisasjon blir **ikkje** vald automatisk.
8. **Valet blir kontrollert på serveren** før data blir viste.
9. **Mobil:** veljaren opnar ein dialog i full skjerm med søkjefeltet øvst.

Aksel tilrår `UNSAFE_Combobox` for lange lister. Portalen er bygd med LWC, så komponenten må
lagast som LWC etter
[ARIA-mønsteret for combobox](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/), med Aksel-stil.
Teikn han som Aksel Combobox og merk han «Nytt (LWC)». Sjå òg
[arkiv/samla-vurdering.md](arkiv/samla-vurdering.md), kapittel 4.

## 8. Eksterne skjermar (Experience Cloud)

**Designkrav:** Bruk Nav sitt designsystem Aksel med komponentar frå `@navikt/ds-react`, til dømes
`Select`, `TextField`, `RadioGroup`, `Alert`, `Table`, `Modal`, `Tag`, `FormProgress` og
`ExpansionCard`. Bruk Aksel-tokens og ikkje eigne fargar. Design for mobil først med breidder
på 360, 768 og 1280 px. UI-tekst skal vere på bokmål med mindre teamet bestemmer noko anna. Følg
WCAG 2.1 AA.

Sidehovudet skal alltid ha Nav-logo, «Aa-registeret», ein **søkbar kontekstveljar** med teksten
«Du opptrer som: …», «Min profil» og «Logg ut». Sjå krava i kapittel 7.

| ID  | Skjerm                         | Innhald og tilstandar                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| --- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| E1  | Vel rolle og kontekst          | **Rolle først, på forsida (inngangsportalen).** Steg 1: «Hvordan vil du bruke tjenesten?» med radioknappane «Som arbeidsgiver», «Som samarbeidspartner» og «Som privatperson». Steg 2 for dei to første: søkbar veljar (kapittel 7) med organisasjonane frå Altinn der personen har rett for den valde rolla. «Som privatperson» går rett til «Meg selv». Søk på namn og org.nr. Vis døme med 40 organisasjonar og eit søk. Tilstandar: lastar, ingen organisasjonar, ingen treff og Altinn-feil med «Prøv igjen». Éin organisasjon blir ikkje vald automatisk. Infotekst: tilknyting i Aa-registeret gir ikkje tilgang. |
| E2  | Min profil – før val           | Berre «Meg selv»: namn frå innlogging (ikkje redigerbart), privat e-post og telefon med «Endre». Hjelpetekst «Velg organisasjon i «Du opptrer som» for å se kontaktopplysninger og roller der». Ingen eigen veljar på sida. Lukka seksjon «Tidligere tilknytninger».                                                                                                                                                                                                                                                                                                                                                     |
| E3  | Min profil – etter val         | Banner «Kontrollert i Altinn [tid]». Kort for «E-post hos Organisasjon A» med verdi, status «Bekreftet» og «Endre». Liste over rollene mine hos A, til dømes «Innsender, 2 søknader» og «Faglig kontakt, 1 avtale». Tilstand utan adresse: åtvaring og «Legg til». Tilstand der Altinn-retten er borte: feilmelding, og ingen data blir viste.                                                                                                                                                                                                                                                                           |
| E4  | Endre adresse (modal)          | Tittel med kontekst: «Endre e-post hos Organisasjon A» eller «Endre privat e-post». Noverande adresse, felt for ny adresse, boksen «Dette endres / Dette endres ikke», kode sendt til ny adresse, felt for kode, feil kode, utgått kode og konflikt med anna økt.                                                                                                                                                                                                                                                                                                                                                        |
| E5  | Tidlegare tilknytingar         | Ekspandert seksjon med organisasjonsnamn, «Ingen tilgang via Altinn lenger» og «Fjern e-postadressen min». Stadfestingsdialog. Ingen roller eller søknader.                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| E6  | Søknad – kontaktpersonar       | Steg 3 av 5. «Deg som innsender» med adressa hos organisasjonen. Tabell med rolle, person, e-post hos organisasjonen, varsel og «Fjern». Same person kan ha fleire roller. Status: «Kjent kontakt», «Invitert» eller «Uavklart». Knapp: «Legg til kontaktperson».                                                                                                                                                                                                                                                                                                                                                        |
| E7  | Legg til kontaktperson (modal) | Vel rolle. Søk berre blant personar med aktiv tilknyting til den valde organisasjonen. Viss personen ikkje finst: namn og e-post hos organisasjonen, med teksten «Lagres som uavklart til personen logger inn. Vi slår ikke sammen personer på e-post.»                                                                                                                                                                                                                                                                                                                                                                  |
| E8  | Ny melding til brukarstøtte    | Boks «Du sender som: brukerstøtte for Organisasjon B». Tema, melding og felt for e-post hos Organisasjon B. Når adressa manglar, er feltet **tomt og påkravd** og har feilmelding. Radioknappar: «Lagre som min adresse hos Organisasjon B» eller «Bruk bare for denne meldingen».                                                                                                                                                                                                                                                                                                                                       |
| E9  | Mine meldingar                 | Berre meldingar i aktiv kontekst. Kolonnar: emne, sendt som, svar går til og status. Merknad når adressa er endra etter innsending.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| E10 | Kvittering                     | Stadfesting med adressa som faktisk vart brukt, og kontekst.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| E11 | Privatperson – eigen regi      | Kontekst «Meg selv». Oversikt over eigne forhold og ny melding med privat adresse. Ingen organisasjonsdata.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| E12 | Ingen tilgang                  | Ein person som opnar ei side utan gjeldande Altinn-rett, blir send tilbake til E1 med melding. Ingen data frå sida blir viste.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |

Lag mobilversjonar av E1, E2, E3 og E8.

## 9. Interne skjermar (Lightning Experience)

**Designkrav:** Følg Salesforce Lightning Design System (SLDS). Bruk standard record pages med
highlights panel, path, related lists og tabs, laga i Lightning App Builder. Eigne
LWC-komponentar skal berre brukast der standardkomponentar ikkje held, og skal merkast «LWC –
ny». Appen heiter «AAREG – Arbeidsforhold».

| ID  | Skjerm                                | Innhald og tilstandar                                                                                                                                                                                                                                                                                        |
| --- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| I1  | Contact – domenekontakt               | Highlights: namn, domene, identitetsstatus, primærkonto og skjerming. Fanen «Kontekster og adresser» (LWC – ny) viser éi rad for privat og éi rad per ACR, med e-post, telefon, stadfesta, sist kontrollert i Altinn og status. Related lists: Related Accounts (ACR), Deltakelser, Meldinger og Innlogging. |
| I2  | Contact – skjerma                     | Banner for skjerma kontakt. Namn, adresser og organisasjonar er maskerte. Knapp «Be om innsyn» med logging. Svar via systemet er mogleg utan at adressa blir vist.                                                                                                                                           |
| I3  | Account – organisasjon                | Related list «Related Contacts – AAREG» viser berre adressa hos denne organisasjonen. Skjerma personar er maskerte. Status «ikke bekreftet i Altinn siden [dato]».                                                                                                                                           |
| I4  | ACR – redigering                      | Standard edit-modal med nye felt: domene (låst), e-post og telefon hos organisasjonen, og sist stadfesta i Altinn. Banner om at endringa berre gjeld denne organisasjonen.                                                                                                                                   |
| I5  | Søknad                                | Path for status. Related list «Deltakere» med rolle, kontakt, adresse ved innsending (snapshot), gjeldande adresse hos organisasjonen (merkt «endret» om ho er ulik) og varsel. Kort for innsendt grunnlag og «Neste varsel går til».                                                                        |
| I6  | Service Console – brukarstøttemelding | Tre kolonnar: kø, meldingstråd og avsendarpanel. Avsendarpanelet viser kontakt, kontekst, sendt som og adresse ved innsending. Panelet «Mottakerkontroll» viser om tilknytinga er aktiv, om adressa er uendra og om personen er skjerma. «Svar sendes til» blir sett av systemet og kan ikkje veljast fritt. |
| I7  | Uavklarte kontaktar                   | Listevising (Lightning-fane) over uavklarte deltakarar. Modal for kopling med forslag, grunngiving, «Behold uavklart», «Marker som funksjonsadresse» og «Koble». Tekst: «Lik e-post er ikke bevis på samme person».                                                                                          |

## 10. Flytskjema som skal teiknast

Teikn flytane som swimlane-diagram med banene Person, Experience Cloud, Apex-grense, Altinn og
Data. Bruk standardsymbol for start, handling, avgjerd, lagring og stopp.

1. **Innlogging og kontekstval:** innlogging, finn domenekontakt frå innlogga brukar (opprett om
   han manglar, aldri på e-post), hent organisasjonar frå Altinn, vel kontekst, kontroller retten,
   opprett eller oppdater ACR og vis «Du opptrer som».
2. **Profil før og etter val:** sjå kapittel 7. Ta med greina for Altinn-feil og for tapt rett.
3. **Adresseval ved innsending:** kontekst, adresse for konteksten, manglande adresse som gir
   påkravd felt utan forslag, lagre eller bruk éin gong, snapshot og kvittering.
4. **Endre adresse:** vel kontekst, kontroller eigarskap og Altinn-rett, send kode, stadfest,
   oppdater éin rad og vis kva som ikkje er endra.
5. **Utsending av varsel:** hending, finn deltakarar, vel adresse per kontekst, kø, kontroller på
   nytt ved utsending og stopp om noko er endra.
6. **Intern kopling av uavklart kontakt:** opne, sjekk skjerming, vurder treff, kople eller
   behald som uavklart, og logg.

Lag òg eit **arkitekturdiagram** med fem lag: Experience Cloud, Apex-grense (`with sharing`,
user mode), skjerming og identitet, data og Lightning.

## 11. Synlegheitsmatrise

| Kven                                | Privat adresse | Adresse hos A           | Adresse hos B           | Innsendt snapshot |
| ----------------------------------- | -------------- | ----------------------- | ----------------------- | ----------------- |
| Personen sjølv, kontekst «Meg selv» | Ja, kan endre  | Nei, vel A først        | Nei, vel B først        | Eigne             |
| Personen sjølv, kontekst A          | Nei            | Ja, kan endre           | Nei                     | Eigne for A       |
| Representant for A                  | Nei            | Ja, i deltakingar for A | Nei                     | Søknader for A    |
| Representant for B                  | Nei            | Nei                     | Ja, i deltakingar for B | Søknader for B    |
| Saksbehandlar                       | Ved behov      | Ja                      | Ja                      | Ja                |
| Saksbehandlar, skjerma person       | Maskert        | Maskert                 | Maskert                 | Krev løyve        |
| Andre Salesforce-appar via ACR      | Nei            | Nei                     | Nei                     | Nei               |

## 12. Leveranse

Lever dette:

1. eitt entitetsdiagram for datamodellen;
2. eitt arkitekturdiagram;
3. seks swimlane-flytskjema;
4. wireframes for E1–E12 med tilstandane som er nemnde, og mobilversjonar av E1, E2, E3 og E8;
5. wireframes for I1–I7;
6. synlegheitsmatrisa som figur;
7. ein klikkbar prototype som byter mellom «Meg selv», Organisasjon A og Organisasjon B og viser
   prinsippa i praksis;
8. ei liste over antakingar og opne spørsmål.

Bruk éin HTML-fil per leveranse eller eit samla designdokument. Merk kvart element som
«Standard», «Endret», «Nytt» eller «Senere».

## 13. Kva Claude ikkje skal gjere

- Ikkje bruk ekte namn, fødselsnummer, organisasjonsnummer, e-postadresser eller miljø-URL-ar.
- Ikkje beskriv sårbarheiter eller tryggleiksfunn i dagens løysing.
- Ikkje foreslå automatisk samanslåing av personar på e-post.
- Ikkje la ACR gi tilgang.
- Ikkje vis adresser eller roller for ein organisasjon før han er valt og kontrollert i Altinn.
- Ikkje foreslå fallback mellom adresser.
- Ikkje endre `User.ContactId`, `User.Email` eller Person Account.
- Ikkje framstill forslag som vedtekne.

## 14. Opne spørsmål

| Spørsmål                                                           | Eigar                     |
| ------------------------------------------------------------------ | ------------------------- |
| Kan domenefelt på ACR skjulast for andre appar?                    | Team Platforce            |
| Teknisk domenekonto som primærkonto                                | Team Platforce            |
| Mellomlagringstid for Altinn-svar og regel for deaktivering av ACR | Produkteigar og tryggleik |
| Kva Altinn-rett krevst for kvar handling (rollekatalog)?           | Produkteigar              |
| Kontrollert mapping mellom innlogging og domenekontakt             | Team Platforce            |
| Kan `EmailQueue__c` binde og revalidere mottakar ved utsending?    | Eigar av e-postpakken     |
| Mekanisme for å stadfeste ny e-postadresse                         | Team Platforce            |
| Kan brukarstøtteløyvet endre roller i avtalar?                     | Produkteigar              |
| Maskering i søk, rapportar og lookup for skjerma personar          | Tryggleiksansvarleg       |
| Målform i UI-tekst                                                 | Produkteigar              |
| Grense for tal på viste treff i organisasjonsveljaren              | Produkteigar og UX        |
| Kvar går svaret når adressa er endra etter innsending?             | Produkteigar              |
| Blir ACR tømd eller deaktivert når personen fjernar ei adresse?    | Produkteigar              |
| Kan saksbehandlaren endre adressa til personen hos organisasjonen? | Produkteigar              |
| Blir saksbehandlaren sitt oppslag av privat adresse logga?         | Tryggleiksansvarleg       |
| Krev søk etter kontaktpersonar fersk stadfesting i Altinn?         | Produkteigar og tryggleik |
| Duplikat- og valideringsreglar på Contact frå andre team           | Team Platforce            |

Funn frå SIT2 som påverkar skissene: portalbrukarar er knytte til ein personkonto, og Contact og
ACR blir delte med andre team. Sjå [arkiv/samla-vurdering.md](arkiv/samla-vurdering.md), kapittel 5.
