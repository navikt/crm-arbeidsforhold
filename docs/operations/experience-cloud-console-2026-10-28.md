# Experience Cloud: console-feil og oppfølging

- **Dato:** 2026-10-28
- **Miljø:** SIT2
- **Flater:** Framsida og Ny søknad
- **Status:** Diagnose og tiltak; ingen rettingar eller deploy er utførte som del av denne kartlegginga.

## Grunnlag og avgrensing

Oversikta samlar unike meldingstypar frå den delte nettlesaren og tidlegare
observasjonar i same undersøking. Lokal kjeldekode er lesen for
søknadskomponenten. Dekoratøren si øktvarsling og Skyra-lasting er kontrollerte
mot kjeldekoden til dekoratørversjonen som sida rapporterte.

Dette er ikkje ein full gjennomgang av alle sider, organisasjonstypar eller
innsendingsløp. Fråvær av ei melding i siste logg er ikkje bevis på retting.
Ingen autentiseringsdata, persondata eller miljøspesifikke nettstadadresser
er tekne med.

Gjentekne meldingar og stacktraces er grupperte. GitHub Issues er systemet for
vidare oppfølging; denne fila dokumenterer observasjonane på kartleggingsdatoen.

## Prioritert oversikt

| ID    | Prioritet                        | Funn                                                    | Evidens/status                                                     |
| ----- | -------------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------ |
| EC-01 | Høg                              | Ugyldige iterasjonslister og picklist-nøklar i søknaden | Observert i nettlesar og stadfesta i lokal kode                    |
| EC-02 | Middels                          | CORS-avvising ved henting av Nav-økt                    | Observert; øktoppslaget kjem frå dekoratøren si utloggingsvarsling |
| EC-03 | Middels                          | Skyra-script blokkert av CSP                            | Tidlegare observert; retting ikkje endeleg verifisert              |
| EC-04 | Middels, uavklart                | Aura registrerer handler mot ukjend komponent           | Observert; kallar og funksjonskonsekvens ikkje identifiserte       |
| EC-05 | Låg, dersom ingen funksjonssvikt | CryptoAdapter klarer ikkje dekryptere lokal cache       | Tidlegare observert; årsak uavklart                                |
| EC-06 | Låg                              | Preloada font blir ikkje brukt raskt                    | Tidlegare observert; ytelsesvarsel utan dokumentert funksjonssvikt |

Prioritetane er tilrådingar, ikkje stadfesta konsekvensklassifisering.

## EC-01: Rett lister og picklist-bindingar i søknadskomponenten

### Behov og evidens

Som søkjar treng eg fungerande val av heimel og føremål, slik at rett verdi
blir vist og send vidare i skjemaet.

Observerte meldingar:

```text
Invalid template iteration for value `undefined` ... Aareg_applicationBasis
It must be an array-like object.
Invalid "key" attribute value ... Set a unique "key" value on all iterated child elements.
```

I [JavaScript-komponenten](../../force-app/externalApplication/lwc/aareg_applicationBasis/aareg_applicationBasis.js)
er `legalBasisOptions` og `purposeOptions` ikkje initialiserte som lister.
Den avhengige føremålslista blir berre sett når heimel har ein verdi.
[Templaten](../../force-app/externalApplication/lwc/aareg_applicationBasis/aareg_applicationBasis.html)
itererer over listene og brukar `option.key` som både nøkkel og HTML-verdi.
Picklist-dataa som koden fører vidare, har `value` og `label`, ikkje `key`.
Feilen kan påverke valde skjemaverdiar; lagring/innsending er ikkje verifisert.

### Tiltak og avgrensing

- Initialiser listene som `[]` og handter lasting og feil eksplisitt.
- Bruk `option.value` som nøkkel og verdi, og `option.label` som synleg tekst.
- Bevar avhengig filtrering, eksisterande verdiar og read-only-åtferd.
- Ikkje endre picklist-metadata, tilgangar eller dekoratøren som del av rettinga.

### Akseptansekriterium

- [ ] Før metadata er lasta, blir komponenten rendra utan ugyldig iterasjon.
- [ ] Når metadata kjem, har alternativa gyldige, unike nøklar og korrekte etikettar/verdiar.
- [ ] Val av heimel filtrerer føremål korrekt og sender korrekte API-verdiar vidare.
- [ ] Ny søknad, eksisterande verdiar, tomme val og read-only blir dekte av regresjonstestar.
- [ ] Metadatafeil blir synlege for brukaren, ikkje skjulte som ei vellukka tom liste.

### Risiko og verifisering

Skjemadata kan vere påverka. Bruk syntetiske fixtures og red-green-refactor
med fokusert LWC Jest-test. Kontroller deretter organisasjonstypane som
komponenten støttar i godkjent testmiljø. Org-kontroll krev eiga godkjenning.

## EC-02: Avklar støtta Nav-øktvarsling frå Salesforce

### Behov og evidens

Som ekstern brukar treng eg korrekt øktvarsling utan mislukka øktoppslag.

```text
Access to fetch ... /oauth2/session ... blocked by CORS policy
No 'Access-Control-Allow-Origin' header is present
Failed to load resource: net::ERR_FAILED
[ERROR] Failed to fetch session
TypeError: Failed to fetch
```

Dette er fleire meldingar frå same feilkjede. Dekoratøren har
`logoutWarning=true` og hentar Nav-økta med `credentials: 'include'`.
Responsen tillèt ikkje lesing frå Salesforce-origin i den observerte køyringa.
Nav-økta og Salesforce-økta er separate. Nye sidelastingar og synleggjering
av fana kan gi nye kall og gjentekne meldingar.

### Tiltak og avgrensing

- Avklar med dekoratør-/innloggingseigar om Salesforce-origin er støtta,
  inkludert credentialed CORS, cookies og eventuell øktfornying.
- Dersom Nav-øktvarsling ikkje skal brukast i test, vurder eksplisitt
  `logoutWarning=false` før initialisering, med avklart alternativ for øktvarsling.
- Bevar eksisterande standardåtferd og produksjonsoppsett.
- Ikkje bruk `no-cors`, nettlesar med avslått sikkerheit eller ein improvisert credential-proxy.

### Akseptansekriterium

- [ ] Eigar og støtta løysing er avklarte for SIT2 og scratch-orgar.
- [ ] Vald løysing er testa utan dei observerte mislukka øktoppslaga.
- [ ] Øktutløp, eventuell fornying og utlogging er avklarte separat for Nav og Salesforce.
- [ ] Dersom funksjonen blir slått av, er testavgrensinga og alternativ øktvarsling dokumenterte.
- [ ] Ingen brei CORS-/CSP-opning eller utilsikta produksjonsendring er innført.

### Risiko og verifisering

Auth og øktvarsling er raud sone og krev menneskeleg gjennomgang.
Trusted Sites for Scripts og Salesforce si eiga CORS-liste rettar ikkje
denne utgåande CORS-avvisinga. Credentialed CORS kan ikkje bruke wildcard-origin.
Den lokale [decoratorHeader](../../crm-community-base/main/default/lwc/decoratorHeader/decoratorHeader.js)
eksponerer berre miljø og kontekst. Endring der krev godkjenning frå pakkeeigar.
Verifiser første sidelasting og synleggjering av fana i godkjent miljø,
utan å registrere cookies, token eller persondata i evidensen.

## EC-03: Verifiser Skyra og avgrensa script-CSP

### Behov og evidens

Som nettstadeigar treng eg at eventuell godkjend undersøking fungerer innanfor
samtykke og nettstaden sin sikkerheitspolicy.

```text
Loading the script 'https://survey.skyra.no/skyra-survey.js'
violates ... "script-src ..."
```

Salesforce blokkerte scriptet. Dekoratøren startar Skyra ved analytics-samtykke.
Meldinga var ikkje med i den seinaste loggen, men rettinga er ikkje endeleg
verifisert med relevant samtykketilstand.

### Tiltak og avgrensing

- Avklar om Skyra skal vere aktiv på nettstaden.
- Dersom ja: tillat `https://survey.skyra.no` under Experience Builder sine
  Trusted Sites for Scripts etter godkjend endringsrutine.
- Vurder eventuelle vidare ressurskall kvar for seg; ikkje opne breie wildcard-domene.
- Ikkje omgå samtykkestyring eller bruke dette som tiltak mot Nav-session-CORS.

### Akseptansekriterium

- [ ] Ønskt Skyra-bruk og ansvar er avklarte.
- [ ] Med relevant samtykke fungerer vald løysing utan den observerte script-CSP-feilen.
- [ ] Avslag/tilbaketrekking av samtykke blir respektert.
- [ ] Eventuelle nye CSP-avvisingar blir dokumenterte og vurderte per direktiv.

### Risiko og verifisering

Tredjepartsscript, samtykke og CSP krev menneskeleg gjennomgang.
Kontroller Console og Network med godkjende samtykketilstandar.
Publisering og org-endringar krev særskild godkjenning. Ikkje bruk fråvær
av feil utan aktivt samtykke som bevis på at scriptet fungerer.

## EC-04: Spor Aura-handler mot ukjend komponent

### Behov og evidens

```text
WARNING: $A.eventService.addHandler:
Unknown component with globalId 'undefined'. Does this component exist?
```

Meldinga er observert fleire gonger. Kallaren er ikkje identifisert.
Det er ikkje dokumentert om ei brukarhandling feilar, og meldinga kan ikkje
tilskrivast dekoratøren på noverande grunnlag.

### Tiltak og avgrensing

- Fang relevant stacktrace og identifiser registrerande komponent.
- Kontroller komponentreferanse, livssyklus og opprydding ved navigasjon.
- Rett berre identifisert årsak; ikkje skjul varselet eller endre Aura globalt.

### Akseptansekriterium

- [ ] Kallar og ei minimal reproduksjon er dokumenterte.
- [ ] Eventuell funksjonskonsekvens er avklart.
- [ ] Identifisert feil er retta og testa, eller plattformårsak er dokumentert med vidare eigar.
- [ ] Navigasjon fram/tilbake fungerer utan tapte eller dupliserte handlers.

### Risiko og verifisering

Bruk syntetisk testflyt og godkjend nettlesarundersøking. Ikkje gjett eigar
ut frå meldinga åleine. Legg til fokusert regresjonstest dersom årsaka ligg i eigen kode.

## EC-05: Undersøk CryptoAdapter-varsel for lokal Salesforce-cache

### Behov og evidens

```text
WARNING: CryptoAdapter[...]decrypt(): decryption failed for key cryptoadapter
```

Tidlegare observert for `actions`, `ldsObjectInfo`, `ldsLayout`,
`ldsLayoutUserState`, `ldsCSRFToken`, `ldsDurableCache` og `actionsManagerCache`.
Dette viser mislukka dekryptering av lokale Salesforce-cacheoppføringar,
men årsaka og eventuell funksjonskonsekvens er ikkje fastslått.

### Tiltak og avgrensing

- Samanlikn med ei rein nettlesarøkt utan å slette brukarens arbeid eller øktdata.
- Avklar om meldinga kjem att og om data eller funksjonar sviktar.
- Ved vedvarande plattformfeil: dokumenter minimal reproduksjon for plattformeigar.
- Ikkje endre applikasjonskryptering eller slå av sikkerheitsmekanismar.

### Akseptansekriterium

- [ ] Resultat frå eksisterande og rein økt er samanlikna.
- [ ] Funksjonskonsekvens og reproduksjonsvilkår er dokumenterte.
- [ ] Behov for retting eller plattformeskalering er avgjort med evidens.

### Risiko og verifisering

Cache og øktdata kan innehalde sensitiv informasjon. Ikkje eksporter
lagringsinnhald, token eller kryptografiske nøklar. Prioriteten må aukast
dersom undersøkinga avdekkjer funksjonssvikt.

## EC-06: Vurder ubrukt preload av Source Sans 3

### Behov og evidens

```text
SourceSans3-normal.woff2 was preloaded using link preload
but not used within a few seconds from the window's load event.
```

Tidlegare observert ytelsesvarsel, utan dokumentert funksjonssvikt.
Eigar av preload og kvifor fonten ikkje blir brukt raskt er ikkje fastslått.

### Tiltak og avgrensing

- Identifiser eigar av preload og faktisk brukt font.
- Kontroller URL, `as`, fonttype, CORS-attributt og samsvar med fontdeklarasjonen.
- Bevar visuell utforming; fjern eller juster berre dokumentert unødvendig preload.

### Akseptansekriterium

- [ ] Eigar og bruk av fonten er identifiserte.
- [ ] Eventuell retting bevarer typografi og unngår unødvendig fontlasting.
- [ ] Resultat før/etter er dokumentert, eller varselet er grunngitt som akseptabelt.

### Risiko og verifisering

Kontroller Network, rendra font og visuell utforming ved første sidelasting.
Endringar i dekoratør eller pakkeeigd innhald må handterast av rett eigar.

## Informasjonsmelding utan eige issue

```text
ComponentProfiler: Component-level profiling has not been enabled.
```

Salesforce-profilering er ikkje aktivert. Meldinga åleine krev ingen
produktretting og er ikkje bevis på funksjonsfeil.

## Tidlegare løyst feil og diagnostisk gjeld

Organisasjonsoppslaget gav tidlegare HTTP 500 med ei generisk feilmelding.
Nettlesarfangst av første oppslag avdekte `System.CalloutException`:
Salesforce fekk ikkje tilgang til external credential
`Maskinporten_Test_Access_Token`, eller credentialen mangla.

Brukaren retta oppsettet. Etterpå vart organisasjonsveljaren fylt ved
sidelasting. Oppdateringsknappen vart ikkje retesta. Dette er ikkje bevis
på at alle organisasjons- og tilgangsflytar er verifiserte.

[AAREG_HomeController](../../force-app/externalAccess/classes/AAREG_HomeController.cls)
loggar berre ei statisk melding ved mislukka eksplisitt oppdatering.
Trygg diagnostisk kontekst bør vurderast ved framtidig arbeid med denne
feilgrensa, utan rå exception-data som kan eksponere token eller persondata.
Ingen ny credential-feil er påvist, og det blir ikkje oppretta eit nytt
feilissue for den løyste hendinga.

## Verifisering av vidare arbeid

1. Rett og regresjonstest søknadskomponenten først.
2. Avklar og test støtta Nav-/Salesforce-øktåtferd.
3. Verifiser Skyra med relevant samtykke.
4. Spor Aura-handleren.
5. Prioriter cache og font etter faktisk funksjons- og ytelseskonsekvens.

For lokale kodeendringar skal fokusert Jest og relevant formatering køyrast.
Org-lesing, testar, publisering og deploy krev eigne mål-/handlingsgodkjenningar.
Ingen av dei føreslåtte rettingane er testa eller erklærte grøne i denne rapporten.

## GitHub-oppfølging

| Funn                           | Issue                                                             |
| ------------------------------ | ----------------------------------------------------------------- |
| EC-01: Søknadskomponenten      | [#1165](https://github.com/navikt/crm-arbeidsforhold/issues/1165) |
| EC-02: Nav-øktvarsling og CORS | [#1166](https://github.com/navikt/crm-arbeidsforhold/issues/1166) |
| EC-03: Skyra og CSP            | [#1167](https://github.com/navikt/crm-arbeidsforhold/issues/1167) |
| EC-04: Aura-handler            | [#1168](https://github.com/navikt/crm-arbeidsforhold/issues/1168) |
| EC-05: CryptoAdapter-cache     | [#1169](https://github.com/navikt/crm-arbeidsforhold/issues/1169) |
| EC-06: Font-preload            | [#1170](https://github.com/navikt/crm-arbeidsforhold/issues/1170) |
