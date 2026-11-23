# Samla vurdering av kontaktmodellen

**Status: Forslag til vurdering, ikkje vedteken arkitektur.**
**Dato:** 23. november 2026.

Denne vurderinga samlar alt materialet i denne mappa, Claude-skissene, branch-materialet om
brukarstøtteutvidinga og ei lesing av objektmodellen i to organ: scratch-orgen
`crm-arbeidsforhold` og sandboxen SIT2. Ho svarar på tre spørsmål:

1. Heng dokumenta og skissene saman, og kva må rettast?
2. Korleis skal organisasjonsveljaren fungere når ein person kan representere mange
   organisasjonar?
3. Kva seier dei faktiske objekta i Salesforce om kor gjennomførbar modellen er?

## 1. Konklusjon

Hovudretninga står seg: éin domenekontakt, organisasjonstilknyting i ACR, søknadsroller i
`RelatedContact__c` og éi adresse per kontekst utan fallback. Lesinga av SIT2 endrar likevel
tre ting vesentleg:

- **Innloggingsidentiteten er ein personkonto.** I SIT2 peikar `User.ContactId` for alle aktive
  portalbrukarar på ein kontakt under ein personkonto. Domenekontakten må derfor vere ein eigen
  post, kopla til brukaren på serveren. Dette er no ikkje berre ei tilråding, men eit krav.
- **Contact og ACR er delte med andre team.** Contact har felt, valideringsreglar og
  duplikatreglar frå andre appar, og ACR blir allereie brukt på arbeidsgivarkontoar. AAREG må
  skilje sine data med eit eige domenefelt og må ikkje bruke den felles `Roles`-plukklista.
- **Organisasjonsveljaren må vere ein søkbar nedtrekksliste.** Korta i Claude-skissene og
  `Select` i E2 og E3 held ikkje når ein person har mange organisasjonar. Sjå kapittel 4.

Claude-skissene er det beste materialet som finst no. Dei følgjer briefen tett, men må justerast
på organisasjonsveljaren og på kva komponentar som faktisk finst i ein LWC-portal.

## 2. Kva er vurdert

| Materiale                                                                        | Type              | Vurdering                                                                                                          |
| -------------------------------------------------------------------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------ |
| [README.md](README.md)                                                           | Inngang           | Oppdatert. Må lenkje til denne vurderinga og Claude-skissene.                                                      |
| [analyse-og-malmodell.md](analyse-og-malmodell.md)                               | Analyse           | Står seg. Avsnittet om innlogging bør få funnet om personkonto frå SIT2.                                           |
| [brukarflater-og-flyt.md](brukarflater-og-flyt.md)                               | Tekstskisser      | Erstatta av Claude-skissene. Bør merkast som historisk.                                                            |
| [migrering-og-verifikasjon.md](migrering-og-verifikasjon.md)                     | Migrering og test | Står seg. Treng testscenario for duplikatregel, valideringsreglar og personkonto-innlogging (kapittel 6).          |
| [brukarstoette-og-e-post-analyse.md](brukarstoette-og-e-post-analyse.md)         | Hovudanalyse      | Står seg. Prinsippa er dei same som i briefen.                                                                     |
| [wireframes-brukarstoette-og-kontakt.md](wireframes-brukarstoette-og-kontakt.md) | Vurdering         | Gjeld Claude-artefakten frå branchen. Står seg.                                                                    |
| [claude-brief.md](claude-brief.md)                                               | Brief             | Fullstendig, men E1–E3 må endrast til søkbar veljar (kapittel 4).                                                  |
| `salesforce-skisser.html`, `prototype.html`, `modell.html`, `kontaktmodell.svg`  | Eigne skisser     | Utdaterte. E-nummera avvik frå briefen. Bør flyttast til eit arkiv eller fjernast etter godkjenning.               |
| `Kontaktmodell Aa-registeret – skisser (forslag).html`                           | Claude, prototype | Klikkbar kontekstbyte. Viser prinsippa godt.                                                                       |
| `… (forslag)2.html`                                                              | Claude, diagram   | Entitetsdiagram, fem lag, synlegheitsmatrise og opne spørsmål. Godt. Seks nye spørsmål er verdt å ta vidare.       |
| `… (forslag)3.html`                                                              | Claude, flyt      | Seks swimlanes. Godt. Flyt 2 brukar veljar utan søk.                                                               |
| `… (forslag)4.html`                                                              | Claude, E1–E12    | Fullstendig og konsekvent. E1 med kort og E2/E3 med `Select` skalerer ikkje.                                       |
| `… (forslag)5.html`                                                              | Claude, mobil     | E1 på mobil blir ei lang kortliste med mange organisasjonar. 768 px manglar.                                       |
| `… (forslag)6.html`                                                              | Claude, I1–I7     | God bruk av standard Lightning-sider. I3 må vise korleis andre appar sine kontaktar blir haldne utanfor.           |
| `Wireframes – Brukerstøtteutvidelse Aa-registeret.html`                          | Branch-materiale  | Brukar «vel rolle først, så verksemd». Det er ein annan modell enn «Du opptrer som». Må samordnast (kapittel 3.2). |

Filnamna til Claude-filene har mellomrom, tankestrek og parentesar. Det fungerer lokalt, men
gir dårlege lenkjer i GitHub. Tilrådd namn er til dømes `claude-01-prototype.html` til
`claude-06-interne-sider.html` og `branch-wireframes-brukarstoette.html`. Eg har ikkje endra
namna.

## 3. Vurdering av skissene

### 3.1 Claude-skissene

**Styrkar**

- Alle ti prinsippa i briefen er synlege i skissene og forklarte i merknadene.
- Tilstandane er gjennomførte: lasting, tom liste, Altinn-feil, tapt rett, manglande adresse,
  feil kode og konflikt mellom økter.
- Komponentane er namngitte, og kvart element er merkt «Standard», «Endret», «Nytt» eller
  «Senere».
- Claude har funne seks nye spørsmål. Desse bør inn i lista over opne spørsmål:
    1. Kvar går svaret når adressa er endra etter innsending (E9, I6)?
    2. Blir ACR-rada tømd eller deaktivert når personen fjernar ei tidlegare adresse (E5)?
    3. Kan saksbehandlaren endre adressa til personen hos ein organisasjon (I4)?
    4. Kva betyr «Ved behov» når saksbehandlaren ser privat adresse, og blir oppslaget logga?
    5. Skal søket etter kontaktpersonar (E7) krevje fersk stadfesting i Altinn?
    6. Kva er skiljet mellom «Invitert» og «Uavklart» (E6)?

**Manglar**

| Funn                                                  | Konsekvens                                                                                        | Tiltak                                                                 |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| E1 og E12 viser éitt kort per organisasjon            | Ein rekneskapsførar eller ein konsernperson kan ha mange organisasjonar. Lista blir uoversiktleg. | Søkbar veljar, sjå kapittel 4                                          |
| E2, E3 og mobilversjonane brukar `Select`             | Ingen søk på namn eller organisasjonsnummer                                                       | Same veljar som i sidehovudet                                          |
| «Bytt» i sidehovudet er ikkje skissert                | Det er uklart om kontekstbyte skjer i sidehovudet eller på profilen                               | Éin veljar i sidehovudet. Profilen viser same val, ikkje ein ny veljar |
| Aksel-komponentane er namngitte som React-komponentar | Portalen er bygd med LWC. `@navikt/ds-react` kan ikkje brukast direkte                            | Sjå kapittel 4.4                                                       |
| Ingen skisse for 768 px                               | Nettbrett og smale vindauge er ikkje vurderte                                                     | Ta med i neste runde                                                   |
| I3 viser berre AAREG-kontaktar                        | I SIT2 deler AAREG arbeidsgivarkontoar med andre team                                             | Vis at lista er filtrert på domene, og kva andre team ser              |

### 3.2 Brukarstøtte-wireframes frå branchen

Branch-skissene startar med «Hvordan vil du bruke tjenesten?» med rollene arbeidsgivar,
samarbeidspartnar og privatperson. Deretter vel personen verksemd. Kontaktmodellen startar med
«Hvem opptrer du som?», der personen vel seg sjølv eller ein organisasjon.

Dei to modellane kan kombinerast:

- **Kontekst** er kven personen opptrer for: seg sjølv eller organisasjon X.
- **Rolle** er kva personen gjer for organisasjonen: arbeidsgivar med søknadsrett,
  brukarstøtteperson eller samarbeidspartnar. Rolla kjem frå Altinn-rettane i den valde
  organisasjonen og blir ikkje vald fritt.

Tilrådd rekkjefølgje er derfor kontekst først. Rolla blir avleidd og vist i «Du sender som».
Viss produkteigar vil halde på rolleval først, må veljaren for verksemd i branch-skisse 3 vere
den same søkbare veljaren som i kapittel 4.

Branch-skisse 9 har feltet «Kontakt e-post» som fritekst ved kvar melding. Det bryt ikkje med
prinsippet om ingen fallback, men adressa blir ikkje lagra per organisasjon. Den bør erstattast
av E8 frå Claude-skissene.

## 4. Organisasjonsveljaren

### 4.1 Krav

1. **Éin veljar i sidehovudet** med teksten «Du opptrer som». Han blir brukt overalt. Profilen,
   søknader og meldingar les konteksten frå han.
2. **Nedtrekksliste med søk.** Personen kan skrive delar av namnet eller organisasjonsnummeret.
   Søket skal vere:
    - uavhengig av store og små bokstavar;
    - uavhengig av mellomrom i organisasjonsnummeret, slik at «123456789», «123 456 789» og
      «456 78» gir treff;
    - treff midt i namnet, ikkje berre i starten.
3. **«Meg selv» står alltid øvst** i ei eiga gruppe, også når søket ikkje gir treff blant
   organisasjonane.
4. **Kvart alternativ viser** namn, organisasjonsnummer med mellomrom og kort type, til dømes
   «Hovedenhet» eller «Underenhet». Teksten skal ikkje brytast over fleire linjer. Altinn gir i
   dag `name`, `organizationNumber`, `type` og `unitType`.
5. **Sortering:** sist brukte organisasjon først, deretter alfabetisk. «Sist brukt» blir lagra på
   serveren for den innlogga brukaren og blir aldri sendt frå klienten som sanning.
6. **Lista kjem frå Altinn**, ikkje frå ACR. Ein organisasjon utan gjeldande rett blir ikkje vist.
7. **Når éin organisasjon blir vald**, kontrollerer serveren retten for den organisasjonen før
   noko blir vist. Valet i lista er ikkje ein kontroll.
8. **Tal på treff** blir lese opp for skjermlesarar, til dømes «12 organisasjoner passer med
   søket».
9. **Ved mange organisasjonar**, til dømes over 200, kan lista avgrensast til dei første treffa
   med teksten «Skriv mer for å avgrense». Grensa må avklarast.

### 4.2 Tilstandar

| Tilstand                  | Visning                                                                                                |
| ------------------------- | ------------------------------------------------------------------------------------------------------ |
| Lastar                    | Veljaren viser «Henter organisasjoner fra Altinn …». «Meg selv» kan veljast med ein gong.              |
| Éin organisasjon          | Ikkje vel automatisk. Vis veljaren med «Meg selv» og organisasjonen. Automatisk val gir feil kontekst. |
| Ingen organisasjonar      | Berre «Meg selv», med teksten «Du har ingen organisasjoner i Altinn med rett til Aa-registeret».       |
| Ingen treff på søket      | «Ingen organisasjoner passer med søket.» «Meg selv» står framleis.                                     |
| Altinn svarar ikkje       | Feilmelding i veljaren og knappen «Prøv igjen». «Meg selv» fungerer.                                   |
| Retten forsvinn etter val | Personen blir send til veljaren med melding, og ingen data blir viste (E12).                           |
| Oppdater lista            | Lenkja «Oppdater fra Altinn» brukar `refreshOrganizationsWithRoles`.                                   |

Claude-skissa vel éin organisasjon automatisk. Eg tilrår å la vere. Ein person med éin
organisasjon kan òg ønskje å opptre som seg sjølv, og eit automatisk val kan gi feil
avsendaradresse.

### 4.3 Wireframe

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ [Nav]  Aa-registeret        Du opptrer som: [ Organisasjon A ▾ ]  Min profil │
└──────────────────────────────────────────────────────────────────────────────┘
                              ┌───────────────────────────────────────────────┐
                              │ Søk på navn eller org.nr.                     │
                              │ [ 456 78|                                 ✕ ] │
                              │ 2 organisasjoner passer med søket             │
                              ├───────────────────────────────────────────────┤
                              │ DEG SELV                                      │
                              │   Meg selv · Person A                         │
                              ├───────────────────────────────────────────────┤
                              │ ORGANISASJONER                                │
                              │ ✓ Organisasjon A        123 456 789  Hoved.   │
                              │   Organisasjon A avd.   912 345 678  Under.   │
                              ├───────────────────────────────────────────────┤
                              │ Oppdater fra Altinn                           │
                              └───────────────────────────────────────────────┘
```

På mobil opnar veljaren ein heil-skjerms dialog med søkjefeltet øvst og lista under.

### 4.4 Implementering i Experience Cloud

Aksel har `UNSAFE_Combobox`, som passar til lange lister og har innebygd filtrering. Aksel seier
òg at `Select` passar for få alternativ. Komponenten finst berre for React, men portalen er bygd
med LWC. `crm-community-base` har LWC-utgåver av nokre Aksel-komponentar, til dømes `picklist`,
`dsTextField` og `dsButton`, men ingen combobox. Dagens veljar i `aareg_home` er ein vanleg
`select` utan søk.

| Alternativ                                                       | Fordel                                         | Ulempe                                             |
| ---------------------------------------------------------------- | ---------------------------------------------- | -------------------------------------------------- |
| A. Ny LWC som følgjer ARIA-mønsteret for combobox, med Aksel-CSS | Likt Aksel, full kontroll over søk og tilstand | Må byggjast og testast for tastatur og skjermlesar |
| B. `lightning-combobox`                                          | Ferdig komponent                               | Har ikkje fritekstsøk og ser ikkje ut som Nav      |
| C. Søkjefelt og liste med radioknappar                           | Enkelt å byggje                                | Tek mykje plass og fungerer dårleg i sidehovudet   |

**Tilråding:** Alternativ A. Komponenten bør følgje
[ARIA-mønsteret for combobox](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/), slik Aksel
gjer. Han kan seinare tilbydast til `crm-community-base`, men det krev avtale med eigarteamet,
sidan mappa er skriveverna her.

## 5. Funn frå organa

Lesinga vart gjord 23. november 2026 med Salesforce CLI. Ho omfatta `describe` av objekt,
Tooling-spørjingar om metadata og aggregerte tal. Ingen namn, e-postadresser, ID-ar eller andre
persondata er henta ut. Ingenting er endra. SIT2 vart lese etter eksplisitt godkjenning.

### 5.1 Samanlikning

| Område                          | Scratch-org                      | SIT2                                                                | Konsekvens                                                                                   |
| ------------------------------- | -------------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Portalbrukaren sin kontakt      | Forretningskonto                 | Personkonto for alle aktive portalbrukarar                          | Domenekontakten må vere eigen post. Testdata i scratch-orgen gir feil bilete.                |
| Contact, tal                    | Nokre få                         | Om lag 1,6 millionar, nesten alle personkontoar                     | Søk, lookup og rapportar på Contact må alltid filtrere på domene                             |
| Eigne felt på Contact           | 3                                | 18, mellom anna 12 frå eit anna team for arbeidsgivarkontaktar      | Contact er delt. Nye AAREG-felt må ha prefiks og avgrensa feltrettar                         |
| Valideringsreglar på Contact    | Ingen                            | Tre aktive, mellom anna ein som berre godtek tal i telefonfelt      | Domenekontaktar må passere reglane. Må testast i SIT2.                                       |
| Duplikatreglar på Contact       | Standardregel aktiv              | Standardregel og regel mot leads aktive                             | Ny domenekontakt kan bli stoppa eller varsla som duplikat av ein kontakt frå eit anna team   |
| ACR i bruk                      | Berre direkte relasjonar         | Direkte og indirekte relasjonar på arbeidsgivar- og selskapskontoar | ACR er ikkje AAREG sitt eige. Domenefelt er nødvendig                                        |
| Eigne felt på ACR               | Ingen                            | Eitt felt frå ein annan kjelde, ikkje i bruk                        | Andre kan òg utvide ACR. Avtal namnekonvensjon                                               |
| `Roles` på ACR                  | Salesforce-standardverdiar       | Salesforce-standardverdiar                                          | Ikkje bruk `Roles` for AAREG-roller. Lista er felles for alle appar                          |
| Delingsmodell for ACR           | Styrt av foreldrepostane         | Styrt av foreldrepostane                                            | ACR kan ikkje få eigne delingsreglar. Synlegheit for AAREG-felt må styrast med feltrettar    |
| Delingsmodell for AAREG-objekt  | Som i repoet                     | Fem objekt er opnare internt enn i repoet. Ekstern deling er lik    | Sjå 5.2. Deltakarar og adresse per organisasjon blir synlege for fleire interne enn tiltenkt |
| `RelatedContact__c`             | Ingen kopling til Contact        | Ingen kopling til Contact                                           | Bekreftar at `Contact__c` og rolle må leggjast til                                           |
| Posttypar på `Inquiry__c`       | Ingen                            | To posttypar for organisasjon og person                             | Posttypane finst ikkje i repoet. Avklar kven som eig dei, og om dei kan brukast for kontekst |
| `Thread__c`                     | Tre posttypar                    | Fire posttypar                                                      | Delt med andre team. Kontekst må lagrast på AAREG-objekta, ikkje på tråden                   |
| Account-posttypar               | Forretning, arbeidsgivar, person | Fleire, mellom anna to typar personkonto                            | Den tekniske domenekontoen treng ein avklart posttype                                        |
| Triggerar på Contact og Account | Frå `crm-platform-base`          | Same                                                                | Automatikk frå plattforma køyrer òg på domenekontakten                                       |

### 5.2 Delingsmodell

Delingsmodellen vart lesen frå `EntityDefinition` i begge organa og samanlikna med
`sharingModel` og `externalSharingModel` i repoet.

| Funn                                                                                                                                   | Kjelde                    |
| -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| Scratch-orgen har same delingsmodell som repoet for alle AAREG-objekt.                                                                 | Scratch-org og repo       |
| I SIT2 har fem AAREG-objekt opnare intern standarddeling enn repoet: søknad, deltakarar på søknad, meldingar, avtalar og eit kodeverk. | SIT2 og repo              |
| Ekstern deling, det vil seie for portalbrukarar, er privat for alle fem i alle tre kjeldene.                                           | SIT2, scratch-org og repo |
| Repoet har hatt privat deling for dei fem sidan objekta vart oppretta. Avviket kjem derfor frå orgen og ikkje frå kjeldekoden.         | Git-historikk             |
| `Contact`, `Account` og `Thread__c` er private, og ACR og meldingar er styrte av foreldreposten, likt i begge organa.                  | SIT2 og scratch-org       |
| Standarddelinga for `User` er ulik i dei to organa.                                                                                    | SIT2 og scratch-org       |

Detaljert tabell per objekt ligg i eit internt notat utanfor repoet, sidan repoet er offentleg.
Han kan delast med teamet ved behov.

**Konsekvens for kontaktmodellen:**

1. Prinsippet om at ein organisasjon ikkje ser adressa hos ein annan, gjeld portalen. Der held
   modellen, fordi den eksterne delinga er privat.
2. Internt er det ikkje sikra. Viss `RelatedContact__c` får adresse per organisasjon og SIT2-delinga
   også gjeld i produksjon, kan alle interne brukarar med lesetilgang til objektet sjå alle
   adressene. Det same gjeld kontekst og «sendt som» på meldingar.
3. Skjerming av kode 6, kode 7 og eigne tilsette kan då ikkje byggje på delingsmodellen åleine.
   Ho må handhevast med feltrettar, restriksjonsreglar eller maskering i Apex.
4. Testar i scratch-orgen kan derfor gi grøne resultat på tilgang som ikkje held i SIT2.

**Moglege årsaker, ikkje verifiserte:** manuell endring i SIT2, at SIT2 er kopiert frå produksjon
med open deling, eller at installasjon av pakka ikkje endrar delingsmodellen når orgen har ein
annan verdi.

**Kontroll som må gjerast:** Ein person sjekkar «Setup Audit Trail» og «Sharing Settings» i SIT2
og, etter avtale med Team Platforce, i produksjon. Ønskt delingsmodell må avgjerast før
kontaktmodellen blir bygd. Ei eventuell innstramming krev runbook, sidan ho kan påverke
saksbehandlarar, rapportar og integrasjonar.

### 5.3 Teikn på dagens problem

Tala er aggregerte og gjeld testdata, så dei viser mønster, ikkje omfang.

- I SIT2 har kontaktane med e-post færre unike adresser enn kontaktar. Same adresse finst altså
  på fleire kontaktar.
- I SIT2 har `RelatedContact__c` om lag dobbelt så mange rader som unike e-postadresser. I
  scratch-orgen er forholdet om lag tolv til ein.
- Dei fleste meldingane i SIT2 peikar på kontaktar under arbeidsgivarkontoar. Dagens løysing
  opprettar altså kontaktane direkte på organisasjonen, der andre team òg har kontaktar.

### 5.4 Endringar i tilrådinga

1. **Innlogging:** Domenekontakten blir slått opp med den innlogga brukaren på serveren. Han blir
   aldri lagra som `User.ContactId`, og personkontoen blir ikkje endra.
2. **Domenefelt på ACR:** Alle AAREG-felt på ACR får prefiks og eit obligatorisk domenefelt.
   Lister og spørjingar filtrerer alltid på domenet.
3. **Ikkje bruk `Roles`:** AAREG-roller ligg i `RelatedContact__c` eller i eit eige AAREG-felt.
4. **Duplikat og validering:** Oppretting av domenekontakt må testast mot reglane i SIT2.
   Eventuelle unntak må avtalast med eigarane av reglane, ikkje leggjast inn i AAREG åleine.
5. **Feltrettar:** AAREG-felt på Contact og ACR blir berre gitt via AAREG sine permission sets.
   Brukarar med «View All Data» og Apex i systemmodus ser dei likevel. Det må med i
   personvernvurderinga.
6. **Testdata:** Scratch-orgen må få portalbrukarar med personkonto, slik som i SIT2, før
   modellen blir testa.
7. **Delingsavvik:** Modellen kan ikkje rekne med privat intern deling på søknad, deltakarar og
   meldingar før avviket i 5.2 er avklart. Adresse per organisasjon og skjerming må vernast med
   feltrettar og maskering uavhengig av delingsmodellen. Om avviket finst i produksjon, må ein
   person kontrollere, ikkje ein agent.

## 6. Nye testscenario

Desse bør leggjast til i [migrering-og-verifikasjon.md](migrering-og-verifikasjon.md) etter
godkjenning:

1. Portalbrukar med personkonto opprettar domenekontakt utan at personkontoen eller
   `User.ContactId` blir endra.
2. Ein domenekontakt med same namn og e-post som ein kontakt frå eit anna team blir oppretta utan
   å bli slått saman, og utan at duplikatregelen stoppar innsendinga.
3. Telefonnummer med mellomrom eller landskode blir handtert av valideringsregelen.
4. Ein brukar frå eit anna team ser ikkje AAREG-felta på ACR.
5. Veljaren finn ein organisasjon på delar av namnet og på organisasjonsnummer med og utan
   mellomrom.
6. Veljaren med 500 organisasjonar svarar raskt nok og kan brukast med tastatur og skjermlesar.
7. Ein organisasjon som manglar i Altinn-svaret, kan ikkje veljast via ein gammal lenkje eller
   ei open fane.
8. Ein intern brukar utan saksbehandlarløyve ser ikkje adresse per organisasjon på deltakarar,
   testa i SIT2 og ikkje berre i scratch-orgen.

## 7. Neste steg

| Steg                                                                          | Eigar               |
| ----------------------------------------------------------------------------- | ------------------- |
| Godkjenne søkbar veljar i sidehovudet og oppdatere briefen og Claude-skissene | Produkteigar        |
| Avgjere kontekst først eller rolle først (kapittel 3.2)                       | Produkteigar        |
| Avklare domenefelt, feltrettar og namnekonvensjon på ACR med andre team       | Team Platforce      |
| Avklare duplikat- og valideringsreglar på Contact med eigarane                | Team Platforce      |
| Sjekke Audit Trail for delingsavviket i SIT2 og avgjere ønskt delingsmodell   | Team Arbeidsforhold |
| Få ein person til å kontrollere delingsmodellen i produksjon                  | Team Platforce      |
| Oppdatere testdata i scratch-orgen med personkonto-innlogging                 | Team Arbeidsforhold |
| Arkivere eller fjerne eldre skisser og gi Claude-filene betre namn            | Team Arbeidsforhold |
