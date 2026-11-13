# P360 testlogg

Dette er den vedvarande loggen for P360-validering i `crm-arbeidsforhold`. Legg til nye køyringar under ein ny dato; ikkje overskriv tidlegare resultat.

## Statusar

- **PASS:** Utført, samsvar med akseptansekriteriet og evidens er registrert.
- **FAIL:** Utført, men resultatet avvik.
- **BLOCKED:** Kan ikkje utførast fordi ein føresetnad manglar.
- **IKKJE IMPLEMENTERT:** Nødvendig funksjon eller kopling finst ikkje i dagens løysing.
- **IKKJE KØYRD:** Ingen utføring eller verifisert evidens.
- **PASS MED MERKNAD:** Funksjonen er verifisert, men verktøy eller prosess gav eit avvik som må følgjast opp.

## Runde 2026-11-05 — automatisk preflight og mock-smoke

**Miljø:** Default scratch-org `crm-arbeidsforhold`  
**Gjennomføringsmåte:** Assistent-køyrde org-operasjonar etter stegvis godkjenning. Dette var ikkje ei menneskestyrt UI-gjennomgang.  
**Avgrensing:** Ingen live P360-kall. Ingen manuelle Salesforce UI-scenario vart køyrde.

### Automatiserte testar

| Testområde                       | Resultat         | Evidens / merknad                                   |
| -------------------------------- | ---------------- | --------------------------------------------------- |
| Fokusert P360 Apex-gruppe        | PASS             | 35/35 testar                                        |
| Full P360 Apex-suite             | PASS             | 94/94 testar; test-run `707Pw00001njwzn`            |
| Mapping, orkestrering og logging | PASS             | 15/15 testar                                        |
| Altinn-mocking Apex              | PASS             | 72/72 testar                                        |
| Lokal LWC-suite                  | PASS MED MERKNAD | 25/25 testar; åtvaringar i `aareg_applicationBasis` |

Eksakte CLI-kommandoar for desse fem testgruppene vart ikkje tekne vare på i denne loggen; tala over er rapporterte resultat frå same testrunde, ikkje ny køyring.

### P360 mock-smoke og preflight

| Steg                                  | Resultat         | Evidens / merknad                                                                                                                                                                                                                                 |
| ------------------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Felt-tilgang før permission set       | BLOCKED          | Describe viste ikkje dei relevante felta for CLI-brukaren.                                                                                                                                                                                        |
| Permission set-føresetnad             | PASS             | `AAREG_Arbeidsforhold_Saksbehandling` og `P360_Archive_Job_Processing` fanst, men var ikkje tilordna.                                                                                                                                             |
| Godkjend mellombels tilordning        | PASS             | Begge permission set-ane vart tilordna CLI-brukaren. Dette er framleis ei aktiv tilgangsendring og er ikkje rydda opp.                                                                                                                            |
| Felt-tilgang etter tilordning         | PASS             | `Application__c.Access_Request__c` og dei tre undersøkte P360-jobbfelta vart synlege og skrivbare.                                                                                                                                                |
| P360 feature-flag før smoke           | PASS             | `P360_Archive_Processing=false`; `Required_Custom_Permission__c` var ikkje sett.                                                                                                                                                                  |
| Mellombels aktivering og deaktivering | PASS             | Éin Custom Metadata-record vart først deploya med flagget på, så deploya tilbake til `false`. Sluttverdien vart lesen tilbake og stadfesta som `false`.                                                                                           |
| Smoke-runner `npm run test:p360:mock` | PASS MED MERKNAD | Runneren returnerte exit-kode 1 fordi han gjorde fem raske statusoppslag medan worker framleis var `Queued`.                                                                                                                                      |
| Etterkontroll av smoke                | PASS             | Worker enda `Completed` med 0 feil. `ApplicationDocument` og `ApplicationAttachment` enda begge `Succeeded` med eitt forsøk kvar; ingen duplikatnøklar vart rapporterte. Dette stadfestar mock-flyten, men ikkje runneren sin pålitelege venting. |
| Live P360-transport                   | IKKJE KØYRD      | Live endpoint, OAuth, Named Credential, wire-format og ekte arkivering er utanfor mock-smoke.                                                                                                                                                     |
| Manuell UI-regresjon og P360-scenario | IKKJE KØYRD      | Skal gjennomførast saman steg for steg; brukaren utfører handlingane og rapporterer resultat.                                                                                                                                                     |

### Tilstand etter smoke

- `P360_Archive_Processing=false` vart kontrollert i orgen.
- Smoke-scriptet sette `Use_Mock_Transport__c=true`; verdien vart ikkje lesen tilbake etter testen.
- Syntetiske Application-/vedleggsdata og to arkivjobbar vart oppretta. Dei vart ikkje sletta eller etterkontrollerte for opprydding.
- Dei to mellombelse permission set-tilordningane vart ikkje fjerna.
- Ingen fleire smoke-data skal opprettast før ein ny, uttrykkeleg godkjend testhandling.

## Mal for neste menneskestyrte steg

Kopier ei rad per utført steg. Ta berre med syntetiske data og evidensreferansar utan secrets eller personopplysningar.

| Dato/tid | Steg-ID | Miljø / rolle | Forventa resultat | Faktisk resultat | Status      | Evidens / avvik | Opprydding |
| -------- | ------- | ------------- | ----------------- | ---------------- | ----------- | --------------- | ---------- |
|          |         |               |                   |                  | IKKJE KØYRD |                 |            |

## Menneskestyrt gjennomgang — 2026-11-09

| Steg-ID | Miljø / rolle                                                           | Forventa resultat                                                                                             | Faktisk resultat                                                                                                                                                                                                 | Status      | Evidens / avvik                                                                                                                                                                                                                   | Opprydding                                                 |
| ------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| P0.1    | `crm-arbeidsforhold` scratch-org / brukar stadfestar                    | Rett ikkje-produksjonsmiljø identifisert før vidare kontroll.                                                 | Brukaren stadfestar at dette er scratch-orgen dei sjølv oppretta, og kjenner han att på scratch Lightning-hostnamnet. Company Information blei ikkje brukt som avgjerande prov. Ingen org-URL eller ID er lagra. | PASS        | Brukarstadfesting i samtalen 2026-11-09.                                                                                                                                                                                          | Ikkje aktuelt.                                             |
| P1.1    | `crm-arbeidsforhold` scratch-org / lesing i Setup                       | Berre lese prosesseringsflagget; ingen endring.                                                               | `P360_Archive_Processing.Is_Enabled__c = false`.                                                                                                                                                                 | PASS        | Brukarstadfesting frå Custom Metadata Types, 2026-11-09.                                                                                                                                                                          | Ikkje aktuelt.                                             |
| P1.2    | `crm-arbeidsforhold` scratch-org / lesing i Setup                       | Berre lese org-default mock-innstilling; ingen endring.                                                       | `Use_Mock_Transport__c = true`. Feature flagget er framleis `false`, så automatisk P360-behandling er av sjølv om mock-adapter er vald for worker-køyring.                                                       | PASS        | Brukarstadfesting frå Custom Settings, 2026-11-09.                                                                                                                                                                                | Ikkje aktuelt.                                             |
| P1.3    | `crm-arbeidsforhold` scratch-org / App Launcher eller navigasjonsfane   | Finne `P360 Archive Jobs`-lista og berre lese dei to tidlegare smoke-jobbane.                                 | Lista/fana vart ikkje funnen; jobbpostar er ikkje undersøkte.                                                                                                                                                    | BLOCKED     | Brukarstadfesting i samtalen, 2026-11-09. Repoet har objektmetadata med plural label `P360 Archive Jobs`, men inga eiga `CustomTab`-metadatafil; dette forklarer mogleg navigasjonsmangel, men org-tilstanden er ikkje stadfesta. | Ikkje aktuelt.                                             |
| P1.3a   | `crm-arbeidsforhold` scratch-org / Setup → Object Manager               | Stadfeste at P360-jobbobjektet finst i org.                                                                   | `P360 Archive Job` kjem opp i Object Manager.                                                                                                                                                                    | PASS        | Brukarstadfesting i samtalen, 2026-11-09. Dette stadfestar objektet, ikkje fane-/posttilgang.                                                                                                                                     | Ikkje aktuelt.                                             |
| P1.3b   | `crm-arbeidsforhold` scratch-org / standard object list route           | Lese eksisterande smoke-jobbar utan å endre data.                                                             | Standardobjektruta opna, men berre `Recently Viewed` var tilgjengeleg og ingen jobbpostar vart funne/viste. Årsaka til manglande visningar eller postar er ikkje stadfesta.                                      | BLOCKED     | Brukarstadfesting i samtalen, 2026-11-09. Hypotese om skjult fane/tomme list views er ikkje verifisert.                                                                                                                           | Ikkje aktuelt.                                             |
| P1.3c   | `crm-arbeidsforhold` scratch-org / listevisingsveljar                   | Sjå om ei `All`-visning finst og eventuelt berre lesa jobbpostar.                                             | Veljaren eller tilgang til han vart ikkje funnen; det er ikkje mogleg å stadfeste om `All`-visning finst.                                                                                                        | BLOCKED     | Brukarstadfesting i samtalen, 2026-11-09.                                                                                                                                                                                         | Ikkje aktuelt.                                             |
| P1.4    | `crm-arbeidsforhold` scratch-org / innlogga brukar sine permission sets | Lese om brukaren har P360-jobbtilgang, utan å endre tilordningar.                                             | `P360_Archive_Job_Processing` er tilordna innlogga brukar.                                                                                                                                                       | PASS        | Brukarstadfesting i samtalen, 2026-11-09. Dette løyser ikkje kvifor inga `All`-listevising er synleg.                                                                                                                             | Ikkje aktuelt.                                             |
| P1.5    | Arbeidskopi / metadata og tilgangsdesign                                | Gjere P360 Archive Job-fana synleg for godkjende menneskelege lesarar utan å endre processing-rettar.         | Custom Tab og eige read-only Viewer permission set er no deploya til scratch-org; Viewer-set-et er ikkje tildelt og UI-synlegheita er ikkje kontrollert.                                                         | IKKJE KØYRD | Deploystatus er loggført i P1.11.                                                                                                                                                                                                 | Permission-set-tildeling og UI-kontroll står att.          |
| P1.6    | `crm-arbeidsforhold` scratch-org / read-only deploy preview             | Stadfeste at Custom Tab og Viewer permission set kan deployast utan konflikt; ikkje endre org.                | Preview fann ingen konflikt eller sletting og viste nøyaktig to komponentar for deploy.                                                                                                                          | PASS        | `sf project deploy preview` køyrd etter eksplisitt godkjenning, 2026-11-09. Dette er ikkje ein deploy eller verifikasjon av faktisk synlegheit.                                                                                   | Ingen org-endring utført.                                  |
| P1.7    | `crm-arbeidsforhold` scratch-org / metadata-deploy                      | Deploye Custom Tab og Viewer permission set etter eksplisitt godkjenning.                                     | Deployen feila: Salesforce avviste feltløyveoppføringa for det påkravde feltet `P360_Archive_Job__c.Archive_Event_Type__c`.                                                                                      | FAIL        | `sf project deploy start` køyrd etter eksplisitt godkjenning, 2026-11-09. Org-status etter feilen er ikkje kontrollert.                                                                                                           | Ikkje køyr ny deploy eller org-lesing utan ny godkjenning. |
| P1.8    | `crm-arbeidsforhold` scratch-org / korrigert read-only deploy preview   | Kontrollere metadata etter at ugyldig feltløyveoppføring for påkravd felt vart fjerna.                        | Oppdatert preview fann ingen konflikt eller sletting og viste dei same to komponentane.                                                                                                                          | PASS        | `sf project deploy preview` køyrd etter ny eksplisitt godkjenning, 2026-11-09. Dette stadfestar ikkje deploy eller UI-synlegheit.                                                                                                 | Ingen org-endring utført.                                  |
| P1.9    | `crm-arbeidsforhold` scratch-org / korrigert metadata-deploy            | Deploye Custom Tab og Viewer permission set etter ny eksplisitt godkjenning.                                  | Deployen feila igjen: Salesforce avviste feltløyveoppføringa for det påkravde feltet `P360_Archive_Job__c.Attempt_Count__c`.                                                                                     | FAIL        | `sf project deploy start` køyrd etter eksplisitt godkjenning, 2026-11-09. `Status__c` er òg definert som påkravd i kjelda og må handterast før eit nytt forsøk. Org-status er ikkje kontrollert etter feilen.                     | Ikkje køyr ny deploy eller org-lesing utan ny godkjenning. |
| P1.10   | `crm-arbeidsforhold` scratch-org / korrigert read-only deploy preview   | Kontrollere metadata etter at alle påkravde felt vart tekne ut av feltløyveoppføringane.                      | Preview fann ingen konflikt eller sletting og viste dei to komponentane.                                                                                                                                         | PASS        | `sf project deploy preview` køyrd etter eksplisitt godkjenning, 2026-11-09. Dette stadfestar ikkje deploy eller UI-synlegheit.                                                                                                    | Ingen org-endring utført.                                  |
| P1.11   | `crm-arbeidsforhold` scratch-org / metadata-deploy                      | Deploye korrigert Custom Tab og Viewer permission set.                                                        | Deploy fullført med `Succeeded`; begge komponentane vart oppretta. Salesforce hoppa over testkøyring.                                                                                                            | PASS        | `sf project deploy start` køyrd etter eksplisitt godkjenning, 2026-11-09. Ingen brukar vart tildelt Viewer-set-et; fana er ikkje testa i UI.                                                                                      | Permission-set-tildeling er ei separat org-handling.       |
| P1.12   | `crm-arbeidsforhold` scratch-org / listevisings-preview                 | Kontrollere dei sju delte visingane utan å endre org.                                                         | Preview fann ingen konflikt eller sletting og viste sju `ListView`-komponentar. Ikkje deploya.                                                                                                                   | PASS        | `sf project deploy preview --source-dir force-app/integration/p360/objects/P360_Archive_Job__c/listViews --target-org crm-arbeidsforhold` køyrd etter eksplisitt godkjenning.                                                     | Deploy krev eiga, konkret godkjenning.                     |
| P1.13   | `crm-arbeidsforhold` scratch-org / metadata-deploy                      | Deploye dei sju P360 Archive Job-listevisingane etter godkjenning.                                            | Deploy feila: Salesforce avviste `sortColumn` i ListView-metadataen.                                                                                                                                             | FAIL        | `sf project deploy start --source-dir force-app/integration/p360/objects/P360_Archive_Job__c/listViews --target-org crm-arbeidsforhold` køyrd etter eksplisitt godkjenning. Sortinnstillingane vart fjerna før nytt forsøk.       | Ingen vidare org-handling utan fersk godkjenning.          |
| P1.14   | `crm-arbeidsforhold` scratch-org / korrigert metadata-deploy            | Deploye dei sju P360 Archive Job-listevisingane etter ny godkjenning.                                         | Deploy fullført med `Succeeded`; alle sju listevisingane vart oppretta. Salesforce hoppa over testkøyring.                                                                                                       | PASS        | `sf project deploy start --source-dir force-app/integration/p360/objects/P360_Archive_Job__c/listViews --target-org crm-arbeidsforhold` køyrd etter ny eksplisitt godkjenning.                                                    | UI-synlegheit og listeinnhald står att å stadfeste.        |
| P1.15   | `crm-arbeidsforhold` scratch-org / testoperatør i Salesforce UI         | Tildele `P360_Archive_Job_Viewer` til den valde testoperatøren.                                               | Brukaren rapporterte at tildelinga er lagra. `P360_Archive_Job_Processing` er framleis tilordna, så Create/Edit-rettane står ved lag.                                                                            | PASS        | Stadfesting frå brukaren i samtalen; tildelinga er ikkje kontrollert med org-kommando.                                                                                                                                            | Ingen.                                                     |
| P1.16   | `crm-arbeidsforhold` scratch-org / P360 Archive Jobs UI                 | Finne fana og stadfeste at dei sju delte listevisingane er valbare.                                           | Brukaren stadfestar at alle sju visingane er synlege, og at All Archive Jobs viser postar.                                                                                                                       | PASS        | Stadfesting frå brukaren i samtalen; postar vart berre lesne.                                                                                                                                                                     | Ingen.                                                     |
| P1.17   | `crm-arbeidsforhold` scratch-org / All Archive Jobs UI                  | Stadfeste at Application Document og Application Attachment mock-jobbane enda Succeeded med eitt forsøk kvar. | Brukaren stadfestar at begge eventtypane finst, har status `Succeeded` og `Attempt Count = 1`.                                                                                                                   | PASS        | Stadfesting frå brukaren i samtalen; ingen record-ID-ar eller personopplysningar vart delte.                                                                                                                                      | Ingen.                                                     |
| P1.18   | `crm-arbeidsforhold` scratch-org / Needs Attention UI                   | Visinga skal berre ta med Failed- og Manual Review-jobbar; tom liste er gyldig.                               | Brukaren stadfestar at lista er tom.                                                                                                                                                                             | PASS        | Stadfesting frå brukaren i samtalen.                                                                                                                                                                                              | Ingen.                                                     |
| P1.19   | `crm-arbeidsforhold` scratch-org / Failed Archive Jobs UI               | Visinga skal berre ta med Failed-jobbar; tom liste er gyldig.                                                 | Brukaren stadfestar at lista er tom.                                                                                                                                                                             | PASS        | Stadfesting frå brukaren i samtalen.                                                                                                                                                                                              | Ingen.                                                     |
| P1.20   | `crm-arbeidsforhold` scratch-org / Manual Review Archive Jobs UI        | Visinga skal berre ta med Manual Review-jobbar; tom liste er gyldig.                                          | Brukaren stadfestar at lista er tom.                                                                                                                                                                             | PASS        | Stadfesting frå brukaren i samtalen.                                                                                                                                                                                              | Ingen.                                                     |
| P1.21   | `crm-arbeidsforhold` scratch-org / Succeeded Archive Jobs UI            | Begge mock-jobbtypane skal visast, og alle postar skal ha status Succeeded.                                   | Brukaren stadfestar at begge mock-jobbtypane er med, og at statusane er Succeeded.                                                                                                                               | PASS        | Stadfesting frå brukaren i samtalen.                                                                                                                                                                                              | Ingen.                                                     |
| P1.22   | `crm-arbeidsforhold` scratch-org / Pending Archive Jobs UI              | Visinga skal berre ta med Pending-jobbar; tom liste er gyldig.                                                | Brukaren stadfestar at lista er tom.                                                                                                                                                                             | PASS        | Stadfesting frå brukaren i samtalen.                                                                                                                                                                                              | Ingen.                                                     |
| P1.23   | `crm-arbeidsforhold` scratch-org / In Progress Archive Jobs UI          | Visinga skal berre ta med In Progress-jobbar; tom liste er gyldig.                                            | Brukaren stadfestar at lista er tom.                                                                                                                                                                             | PASS        | Stadfesting frå brukaren i samtalen.                                                                                                                                                                                              | Ingen.                                                     |

### P1.24 — Record-detaljar, 2026-11-09 kl. 22:19

- **Miljø:** Same scratch-org og testoperatør som i P1.23; menneskestyrt UI-lesing.
- **Forventa:** Record-sida opnar og viser Archive Event Type, Status, Attempt Count og tidsfelt for kø/behandling.
- **Faktisk:** Brukaren viste ei open detaljside for Application Attachment med `Status = Succeeded` og `Attempt Count = 1`. Correlation ID og Idempotency Key er synlege. Berre Created By/Last Modified By med tidspunkt er med i den rapporterte oversikta; eigne tidsfelt for kø/behandling er ikkje stadfesta.
- **Status:** PASS MED MERKNAD — record-opning og sluttstatus er stadfesta; synlegheit for tidsfelta står att.
- **Evidens:** Brukarrapport i samtalen. Record-ID-ar, nøkkelverdiar og saksreferansar er ikkje kopierte til loggen. Dette er ikkje bevis på ekte P360-arkivering.
- **Neste steg:** Kontroller om tidsfelta er synlege på same detaljside. Ingen redigering eller org-kommando er utført av assistenten.

### P1.25 — Manglande tidsfelt, 2026-11-09

- **Forventa:** Queued Date, Started Date, Last Attempt Date, Lease Expires Date og Next Attempt Date er synlege på detaljsida, også når verdiar er tomme.
- **Faktisk:** Brukaren stadfestar at ingen av dei fem felta er synlege og ber om prioritert retting.
- **Status:** FAIL — record-detaljane gir ikkje det nødvendige statusinnsynet.
- **Lokal undersøking:** Viewer-settet gir lesetilgang til alle fem felta. Repoet har ingen P360 Archive Job-sidelayout eller eiga Lightning record-side. Aktivt sidelayout og eventuell org-spesifikk sidekonfigurasjon er ikkje undersøkte i orgen.
- **Neste steg:** Identifiser eksisterande org-layout før endring, slik at rettinga bevarer eksisterande felt og treff sida testoperatøren faktisk brukar. Org-lesing og deploy krev kvar si ferske godkjenning.

### P1.25a — Lokal retting av sidelayout, 2026-11-09

- **Undersøking:** Godkjend `sf org list metadata --metadata-type Layout --target-org crm-arbeidsforhold --json` fann eitt layout for objektet. Etter ny godkjenning vart `Layout:P360_Archive_Job__c-P360 Archive Job Layout` henta til ein separat originalkopi i sesjonsmappa.
- **Raud kontroll:** XML-kontroll av den henta originalen feila for alle fem tidsfelta; dei manglar i layoutet, ikkje berre i brukaren sin rapport.
- **Retting:** Same layoutnamn er lagt til under P360-kjelda med ein ny `Processing Timeline`-seksjon. Alle fem tidsfelt er `Readonly` i layoutet. Eksisterande seksjonar, felt og innstillingar er bevarte; ingen permission sets eller profilar er endra.
- **Status:** IKKJE KØYRD — korrigert metadata er ikkje deploya og UI-retesten står att.

### P1.25b — Verifikasjon og deploy av sidelayout, 2026-11-09

- **Lokal kontroll:** XML-kontrollen bestod for alle fem skriveverna tidsfelt. Strukturell samanlikning mot originalkopien stadfesta at resten av layoutet er uendra, og Viewer-settet dekker lesetilgangen. Fokusert Prettier-kontroll og `git diff --check` bestod.
- **Preview:** `sf project deploy preview --source-dir "force-app/integration/p360/layouts/P360_Archive_Job__c-P360 Archive Job Layout.layout-meta.xml" --target-org crm-arbeidsforhold` bestod etter fersk godkjenning: eitt layout, ingen konflikt eller sletting.
- **Deploy:** `sf project deploy start --source-dir "force-app/integration/p360/layouts/P360_Archive_Job__c-P360 Archive Job Layout.layout-meta.xml" --target-org crm-arbeidsforhold --json` fullførte med `Succeeded` etter eiga godkjenning. Eitt eksisterande layout vart oppdatert, ingen komponentfeil. Salesforce køyrde ingen Apex-testar.
- **Status:** PASS for metadata-deploy; UI-retest av P1.25 står att. Ingen jobbdata, profilar eller permission sets er endra.

### P1.25c — UI-retest etter deploy, 2026-11-09

- **Forventa:** Processing Timeline viser alle fem tidsfelt på same jobb etter oppdatering av nettlesarsida.
- **Faktisk:** Brukaren stadfestar at alle fem felta er synlege.
- **Status:** PASS — synlegheitsavviket frå P1.25 er retta og stadfesta i UI. Feltverdiar og kronologi er ikkje kontrollerte i dette steget.
- **Evidens:** Brukarstadfesting i samtalen; ingen identifikatorar eller feltverdiar er kopierte.

### P1.26 — Tidslinjeinnhald, 2026-11-09

- **Faktisk:** Brukaren stadfestar at Queued Date, Started Date og Lease Expires Date har verdi. Last Attempt Date og Next Attempt Date er tomme på den undersøkte Succeeded-jobben.
- **Status:** PASS MED MERKNAD — observasjonen samsvarer med undersøkt service-/claim-/worker-kode. Last Attempt Date blir ikkje sett av desse kodestiane og gir dermed ikkje operatøren tidspunktet for siste forsøk.
- **Avgrensing:** Lease blir ståande etter suksess i dagens worker; verdien betyr ikkje at jobben framleis er aktiv. Ingen nøyaktige tidspunkt eller kronologisk rekkjefølgje er verifiserte. Tom Next Attempt Date samsvarer med første-forsøk-suksess utan planlagt retry.
- **Oppfølging:** Registrer manglande oppdatering av Last Attempt Date som eit funksjonelt observabilitetsgap; synlegheitsrettinga fyller ikkje feltet bakover i tid. Ingen jobbdata er endra.

### P1.26a — Lokal undersøking av Last Attempt Date, 2026-11-09

- **Hypotesar:** Manglande skriving i Apex, utfylling via deklarativ automasjon, eller manglande tilgang/vising. Synlegheita er allereie stadfesta i P1.25c.
- **Funn:** Søk etter `Last_Attempt_Date__c` i Apex, triggers og XML under `force-app` fann berre feltdefinisjon, Viewer-tilgang, layout og listekolonnar. Ingen direkte skriving eller testassert for feltet vart funnen. Feltet er eit valfritt DateTime-felt utan standardverdi.
- **Kodegjennomgang:** Claim-service set Started Date, Lease Expires Date og aukar Attempt Count. Worker set sluttstatus eller feil-/retrydata, men ingen av desse kodestiane set Last Attempt Date. Claim-testane kontrollerer start/lease/forsøkstal; ingen Apex-test under `force-app` refererer til Last Attempt Date.
- **Konklusjon:** Manglande utfylling er stadfesta i lokal kjeldekode og samsvarer med UI-observasjonen. Dette er ikkje berre ein visingsfeil. Eventuell automasjon som berre finst i orgen er ikkje undersøkt.
- **Status:** FAIL for utfylling av Last Attempt Date. Ingen produksjonskode, jobbdata eller tilgangar er endra i denne undersøkinga. Ingen org-kommando eller Apex-test er køyrd.

## Etterkontroll av leveransen — 2026-11-09

### Omfang og grunnlag

Etter brukarens krav om etterkontroll er P360-dokumentasjon, specs, git-historikk, relevante GitHub Issues og worker-/claim-/scheduler-kjeda med testar gjennomgått. Branchgrunnlaget er `P360Test`, med merge-base `b8a4909f` mot lokal `origin/main`. Kontrollpunkt for tidlegare UI-arbeid er `80097a50`; `edb6e0d3` inneheld den etterfølgjande undersøkinga av Last Attempt Date. Ingen fetch eller GitHub-endring er utført.

Dette er ein avgrensa etterkontroll av jobbstatus og leveranseevidens, ikkje ein full gjennomgang av alle P360-DTO-ar, mappingar, transportimplementasjonar eller alle historiske samtalar.

### Funn: standardar og implementasjon

1. **Stadfesta feil: Last Attempt Date vart aldri sett.** Feltet fanst frå `bd4fe435`, medan worker-grunnlaget vart lagt til i `49668b16`. Testane kontrollerte sluttstatus, men ikkje tidspunktet. Eit grønt historisk testresultat var derfor ikkje bevis på komplett statusinnsyn.
2. **Stadfesta kopla tilgangsfeil:** Processing-settet mangla Read/Edit for dette feltet. Reelle minimum-access-testar feila på feltlesing/-skriving. Viewer-settet hjelpte den menneskelege operatøren, men var ikkje ei løysing for den tekniske brukaren.
3. **Tidlegare UI-mangel:** Fane, listevisingar og tidsfelt i sidelayout mangla. Desse vart retta og brukarstadfesta i P1.16 og P1.25c; dette er ikkje lenger eit ope synlegheitsavvik.
4. **Evidensavgrensing:** Tomme feil-/kølister i P1.18–P1.23 stadfestar at visingane kan opnast og er tomme med desse dataa. Dei beviser ikkje at alle statusfilter inkluderer riktige postar ved reelle feil eller købehandling. Ingen nye feiljobbar vart oppretta i UI-testen.

### Funn: spesifikasjon og leveransestatus

- [Jobbopprettingsspecen](../../../.github/specs/p360-archive-job-creation.md) krev Pending-jobb, køtid og idempotens, men avgrensar eksplisitt bort worker, lease og retry. Last Attempt Date er ikkje eit eksplisitt akseptansekriterium der. Feilen over er stadfesta som ein implementasjons-/observabilitetsmangel, ikkje som eit sitert brot på eit kriterium som ikkje finst.
- Same spec omtalar application-document-hendinga som fullført, medan [kodegjennomgangen](kodegjennomgang.md) og [datamodelldokumentasjonen](../../architecture/p360-data-model-og-arkiveringsjob.md) seier at automatisk ApplicationDocument-trigger ikkje er avklart. Service-/smoke-oppretting må ikkje presenterast som ferdig automatisk produksjonsflyt. Hendingsval krev produkteigaravklaring, ikkje ein spekulativ ny trigger.
- Live lesing av [mapping-oppgåva](https://github.com/navikt/crm-arbeidsforhold/issues/1016) viser at ho er open og gjeld mapping, ikkje Last Attempt Date eller worker-retry. Ho er ikkje bevis for at jobbruntime er ferdig.
- [Completion-roadmap](../../../.github/specs/p360-completion-roadmap.md) skil runtime-grunnlag frå gjenståande scheduler-/overlapp-, lease-, recovery- og operasjonell validering. Live transport, mapping, filstrategi og ekstern idempotens/recovery er eksplisitte opne grenser, med opne oppgåver [idempotens/recovery](https://github.com/navikt/crm-arbeidsforhold/issues/1015), [mapping](https://github.com/navikt/crm-arbeidsforhold/issues/1016), [integrasjonsavklaring](https://github.com/navikt/crm-arbeidsforhold/issues/1017), [filhandtering](https://github.com/navikt/crm-arbeidsforhold/issues/1018) og [vidare ferdigstilling](https://github.com/navikt/crm-arbeidsforhold/issues/1093). Dei er ikkje rapporterte som nye regresjonar i denne etterkontrollen.
- [Rollout-oppgåva](https://github.com/navikt/crm-arbeidsforhold/issues/1092) er lukka og har oppryddingsevidens frå ein tidlegare oktoberrunde. Det opphevar ikkje uteståande opprydding frå den seinare november-smoken. Historiske køyringar må haldast frå kvarandre.

### Retting og kontrakt for Last Attempt Date

- Worker registrerer no starttidspunktet for kvart faktisk adapterforsøk, og lagrar det saman med utfallet ved Succeeded, Failed eller Manual Review.
- Claim åleine endrar ikkje feltet. Når feature-flagget stoppar worker før adapterkallet, blir eventuell førre verdi bevart og ingen ny forsøksdato oppretta.
- Read/Edit er lagt til berre for Last Attempt Date i det tekniske Processing-settet. Viewer, objektrettar, sharing og permission-set-tildelingar er uendra.
- Tidspunktet blir persistert med worker-transaksjonen. Uventa transaksjonsfeil kan framleis rulle tilbake både status og tidsstempel; dette er ikkje ei separat, garantert callout-auditløysing.
- Ingen historiske tidspunkt blir rekonstruerte. Gamle Succeeded-jobbar kan framleis ha tom Last Attempt Date.

### Raud–grøn-validering

Kvar Salesforce-operasjon under vart godkjend separat for scratch-orgen `crm-arbeidsforhold`. Alle er dry-run utan varig deploy eller live P360-kall.

Første kommando:

```bash
sf project deploy start --dry-run --source-dir force-app/tests/classes/integration/p360/job/P360_ArchiveJobWorkerTest.cls --test-level RunSpecifiedTests --tests P360_ArchiveJobWorkerTest --target-org crm-arbeidsforhold --json
```

Resultat: 11 testar køyrde, seks feila på feltlesing/-skriving. Ingen komponentfeil. Dette avdekte Processing-tilgangen, ikkje ein rein tidsstempelassert.

Andre kommando, etter tilgangsretting og eksplisitt tilgangstest:

```bash
sf project deploy start --dry-run --source-dir force-app/tests/classes/integration/p360/job/P360_ArchiveJobWorkerTest.cls --source-dir force-app/integration/p360/permissionsets/P360_Archive_Job_Processing.permissionset-meta.xml --test-level RunSpecifiedTests --tests P360_ArchiveJobWorkerTest --target-org crm-arbeidsforhold --json
```

Resultat: 12 testar køyrde, fire feila presist på manglande/ikkje oppdatert tidsstempel. Ingen komponentfeil.

Fokusert kommando med rettinga:

```bash
sf project deploy start --dry-run --source-dir force-app/integration/p360/classes/job/P360_ArchiveJobWorker.cls --source-dir force-app/tests/classes/integration/p360/job/P360_ArchiveJobWorkerTest.cls --source-dir force-app/integration/p360/permissionsets/P360_Archive_Job_Processing.permissionset-meta.xml --test-level RunSpecifiedTests --tests P360_ArchiveJobWorkerTest --target-org crm-arbeidsforhold --json
```

Første køyring fylte feltet, men fire tidsvindaugsassertar feila på DateTime-presisjon. Testgrensa vart normalisert til heile sekund, utan å fjerne nullkontroll, øvre grense eller retry-kravet. Ny godkjend køyring bestod: **12/12**, null feil, worker-dekning 77/79 linjer.

Breiare regresjon:

```bash
sf project deploy start --dry-run --source-dir force-app/integration/p360/classes/job/P360_ArchiveJobWorker.cls --source-dir force-app/tests/classes/integration/p360/job/P360_ArchiveJobWorkerTest.cls --source-dir force-app/integration/p360/permissionsets/P360_Archive_Job_Processing.permissionset-meta.xml --test-level RunSpecifiedTests --tests P360_ArchiveJobWorkerTest --tests P360_ArchiveJobClaimServiceTest --tests P360_ArchiveJobSchedulerTest --tests P360_ArchiveJobServiceTest --tests P360_ArchiveJobMetadataTest --target-org crm-arbeidsforhold --json
```

Resultat: **25/25 PASS**, null komponent-/testfeil eller dekningsåtvaringar. Dette verifiserer jobbkjeda som isolerte Apex-testar, ikkje ein ny menneskestyrt ende-til-ende-test eller ekte P360-arkivering.

**Status:** Rett kode og tilgang er lokalt implementerte og org-validerte med dry-run. Varig deploy og UI-observasjon av ein ny jobb står att. Ingen eksisterande jobbpostar er endra.

### Godkjend varig deploy av rettinga — 2026-11-09

Etter eiga godkjenning vart den breiare regresjonskommandoen over køyrd utan `--dry-run`, framleis berre mot `crm-arbeidsforhold` og med dei same tre kjeldefilene og fem testklassane.

- **Deploy:** `Succeeded`, `checkOnly = false`; worker, worker-test og Processing permission set vart oppdaterte. Tre komponentar, null komponentfeil.
- **Testar:** **25/25 PASS**, null testfeil og ingen dekningsåtvaringar.
- **Status:** Last Attempt Date-rettinga er no varig deploya til scratch-orgen. UI-observasjon av ein ny mock-jobb står att; gamle jobbar er ikkje utfylte bakover i tid.
- **Avgrensing:** Ingen ny ende-til-ende-smoke, live P360-kall eller produksjonstilgang er utført. Ingen permission-set-tildelingar eller eksisterande jobbpostar er endra.

## Runde 2026-11-10 — ny mock-jobb etter rettinga

**Miljø:** Scratch-org `crm-arbeidsforhold`; menneskestyrt køyring av godkjend repo-smoke. Berre syntetiske testdata.

| Steg  | Handling / forventa resultat                                                                                                                                                                                      | Faktisk resultat                                                                                                          | Status | Evidens / avgrensing                                                                                                                                                                                  |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| P1.27 | Før aktivering, sjå etter andre kvalifiserte jobbar.                                                                                                                                                              | Brukaren stadfestar Pending Archive Jobs og Needs Attention tomme, og prosesseringsflagget `false`.                       | PASS   | UI-stadfesting frå brukaren; ingen IDs eller feildetaljar loggførte.                                                                                                                                  |
| P1.28 | Køyr `npm run test:p360:mock` med mock-transport og syntetiske testdata. Forventa: worker Completed utan feil; ApplicationDocument og ApplicationAttachment Succeeded med eitt forsøk kvar; ingen duplikatnøklar. | Brukaren rapporterer `Result PASS`, worker `Completed` med 0 feil, og begge eventtypane `Succeeded` med eitt forsøk kvar. | PASS   | Brukaren utførte runneren etter eiga godkjenning. Runneren opprettar syntetisk Access Request, Application, ContentVersion og to jobbpostar; data blir ikkje automatisk sletta. Ingen live P360-kall. |
| P1.29 | Set prosesseringsflagget tilbake til `false` etter smoke.                                                                                                                                                         | Brukaren stadfestar flagget er sett tilbake til `false`.                                                                  | PASS   | Brukarstadfesting; ingen ekstra org-lesing utført.                                                                                                                                                    |
| P1.30 | Kontroller Last Attempt Date på dei to nye jobbane i Salesforce UI. Forventa: begge har verdi.                                                                                                                    | Brukaren stadfestar begge har verdi; jobbstatusane var Succeeded med eitt forsøk kvar.                                    | PASS   | Brukarstadfesting frå UI; tidspunkt og record-ID-ar er ikkje kopierte. Dette stadfestar intern mock-worker, ikkje ekstern P360-arkivering.                                                            |

**Attståande etter denne runden:** Ekstern portalopplasting (`P02`) er ikkje testa. Cleanup av dei syntetiske smoke-postane er ikkje utført; følg godkjend oppryddingsprosedyre før eventuell sletting. Live P360-transport er framleis utanfor denne mock-testen.

## Runde 2026-11-10 — klargjering for P02

**Miljø:** Scratch-org `crm-arbeidsforhold`, valt av brukaren.

| Steg  | Handling / resultat                                                                                                                                                                            | Status      |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| P02.1 | Tidlegare read-only kontroll fann ingen brukarar med det eksakte lisensnamnet Customer Community Plus i denne orgen.                                                                           | BLOCKED     |
| P02.2 | Read-only lisenskontroll: Customer Community Plus har 1 lisens totalt og 0 i bruk; High Volume Customer Portal har 5 totalt og 0 i bruk. Lisensen finst, men dette opprettar ikkje ein brukar. | PASS        |
| P02.3 | Den generiske testbrukaren er dokumentert frå Altinn-testing i `nav-community-dev`. Brukar, community og syntetiske testdata er ikkje stadfesta klare for P02 i `crm-arbeidsforhold`.          | BLOCKED     |
| P02.4 | Ekstern søknadsopplasting er ikkje utført. Føresetnader, mock og kø må kontrollerast før aktivering og test.                                                                                   | IKKJE KØYRD |

Første lisensspørring stoppa på eit ugyldig CLI-utdataformat. Den etterfølgjande
godkjende spørringa med `--result-format human` fullførte. Ingen data eller
innstillingar vart endra.

### Read-only føresetnadskontroll

- **PASS:** Éin publisert Aa-registret-community og Customer Community Plus-profilen finst.
- **PASS:** Permission set-a `AAREG_CommunityPermission` og `AAREG_AltinnScenarioUser` finst. Effektiv tilgang for ein testbrukar er ikkje kontrollert.
- **BLOCKED:** Ingen generiske eller eldre Altinn-seeda brukarar vart funne for dei dokumenterte syntetiske brukarnamnsmønstera.
- **OBSERVERT:** Ingen Altinn-seeda søknader vart funne for det dokumenterte syntetiske e-postmønsteret. Dette seier ikkje at P360-smoke-postane manglar.
- Dei fem spørringane fullførte utan data- eller metadataendringar.

### Read-only kontroll av Altinn-oppsettet

- **PASS:** Dei tre scenarioklassane er aktive, og scenarioressursen finst.
- **OBSERVERT:** Ingen syntetiske identitetskontoar eller kontaktar vart funne for dei dokumenterte mønstera.
- **BLOCKED:** Den dokumenterte testdata-eigaren vart ikkje funnen som aktiv brukar med `Standard User`-profilen. Kontrollen skil ikkje mellom manglande, inaktiv eller annan profil. Det eksisterande seedet krev denne føresetnaden.
- Det vart berre lese teljingar og metadata; oppsettskriptet vart ikkje køyrt.

Ein ny, godkjend kontroll fann ingen brukar med den dokumenterte testdata-eigarens
brukarnamn i denne orgen. Det finst fem roller, men ingen av dei aktive interne
brukarane i kontrollen har rolle. Salesforce-lisensen viser 5 totalt og 0 i bruk.
Ingen brukar, rolle eller tilgang vart endra.

### Lokal kodeobservasjon før P02

Ved lagring av utkast opprettar eller gjenbrukar søknadskontrolleren ein Access
Request, opprettar deretter fila og knyter henne til søknaden. Filopprettinga
set ikkje `FirstPublishLocationId`, medan P360-handleren krev direkte
publisering på søknaden. Dette er ein risiko observert i kjeldekoden, ikkje eit
utført eller bestått UI-scenario.

### Regresjonskontroll for testdata-eigar

- **RED:** Den godkjende read-only kontrollen `bin/verify-altinn-test-owner.apex` feila i `crm-arbeidsforhold` som venta: éin testdata-eigar var forventa, men ingen fanst.
- **IKKJE KØYRD:** Kontroll etter retting og oppretting av eigaren. Lokal kodeendring aleine er ikkje bevis for at oppsettet fungerer i orgen.

### Køyring av eigarsteget

- **FULLFØRT:** Etter brukarens godkjenning vart `bin/seed-altinn-scenario-owner.apex` køyrd i `crm-arbeidsforhold`. Salesforce rapporterte at skriptet kompilerte og fullførte utan feil.
- **VENTAR:** Separat read-only kontroll av eigaren etter køyringa. Community-brukar, søknader, avtalar og scenarioinnstillingar er ikkje oppretta eller endra i dette steget.

### Regresjonskontroll etter eigarsteget

- **GREEN:** Den separat godkjende read-only kontrollen `bin/verify-altinn-test-owner.apex` kompilerte og fullførte i `crm-arbeidsforhold`. Han stadfesta nøyaktig éin aktiv testdata-eigar med `Standard User`-profil og rolle, og kontrollerte eigarskap dersom den syntetiske identitetskontoen fanst.
- **IKKJE KØYRD:** Kontroll av idempotens og alternativa med legacy-, duplikat- eller inaktiv eigar.

### Syntetiske kontoar og testdata

- **FULLFØRT:** Etter brukarens godkjenning vart `bin/seed-altinn-scenario-accounts.apex` køyrd i `crm-arbeidsforhold`. Salesforce rapporterte at skriptet kompilerte og fullførte utan feil.
- **VENTAR:** Separat kontroll av dei oppretta eller gjenbrukte kontoane, søknadene og avtalane. Eventuelle ekstra postar eller varslingar frå automasjon er ikkje kontrollerte.

### Kontroll av syntetiske testdata

- **DELVIS:** Ei godkjend read-only spørring fann fire aktive avtalar kopla til fire ulike syntetiske søknader og fire organisasjonar.
- **AVVIK:** Minst eitt kontrollert felt for søknadsstatus, organisasjonskopling eller avtaletilgang stemte ikkje med forventninga. Det konkrete avviket er ikkje identifisert enno.

### Diagnose av kontrollresultatet

- Den neste godkjende read-only spørringa viste `New` på alle fire søknadene, API- og uttrekkstilgang på og webtilgang av. Kontrolluttrykket for organisasjonskoplinga gav `false` for alle fire.
- **MISTANKE, IKKJE STADFESTA:** Sjølve kontrolluttrykket kan vere feil: metadata oppgir relasjonsfeltet med liten forbokstav, medan uttrykket las med stor forbokstav. Ein ny kontroll er nødvendig før ein kan konkludere om koplingane.

### Korrigert kontroll av testdata

- **PASS:** Ei ny, godkjend read-only spørring stadfesta fire aktive avtalar kopla til fire ulike syntetiske søknader og organisasjonar. Organisasjonskoplingar, søknadsstatus og dei kontrollerte tilgangsfelta stemte.
- Den første kontrollen brukte feil store/små bokstavar i JSON-filteret. Salesforce returnerte `account__r`; dette forklarer det tidlegare falske avviket. Historikken over er bevart.

### Community-brukar

- **FULLFØRT:** Etter brukarens godkjenning vart `bin/seed-altinn-scenario-users.apex` køyrd i `crm-arbeidsforhold`. Salesforce rapporterte at skriptet kompilerte og fullførte utan feil, inkludert skriptets medlemskapskontroll.
- **VENTAR:** Separat verifikasjon av brukar, lisens, permission set og scenarioinnstilling. Innlogging i UI er ikkje testa.

### Altinn-scenario for testbrukaren

- **FULLFØRT:** Etter brukarens godkjenning vart `bin/seed-altinn-scenario-settings.apex` køyrd i `crm-arbeidsforhold`. Salesforce rapporterte at skriptet kompilerte og fullførte utan feil.
- **VENTAR:** Separat read-only verifikasjon av brukar og scenarioinnstilling før P02.

### Verifikasjon av Community-oppsettet

- **PASS:** Den separat godkjende read-only kontrollen `bin/verify-altinn-test-user.apex` fullførte i `crm-arbeidsforhold`. Han kontrollerte aktiv generisk brukar, kontakt, Customer Community Plus-lisens, begge permission set-a og ei eksplisitt aktiv brukarinnstilling med `subject-a` og eit kjent scenario.
- Kontrollen godtek S01–S08 og beviser ikkje åleine at S01 er valt. Innlogging i community og faktisk P02-opplasting er ikkje testa.

### Community-innlogging i UI

- **BLOCKED:** Brukaren rapporterte meldinga «Du må logge på Aa-registret for å få tilgang til denne siden.» Handlinga som førte til meldinga, og årsaka, er ikkje avklarte.
- P02-opplasting er ikkje utført.

Brukaren stadfesta deretter at meldinga kom etter handlinga
**Log in to Experience as User** på kontakten. Årsaka er framleis ikkje
avklart.

Brukaren rapporterte at meldinga kom på ei innloggingsside med knapp eller
innloggingsfelt, utan først å få velje Experience-side.

Ei godkjend read-only spørring mot innloggingshistorikken feila fordi
spørringa brukte ein relasjon Salesforce ikkje støttar på `LoginHistory`.
Ingen innloggingshistorikk vart lesen, og ingen data vart endra.

Eit andre godkjent, read-only forsøk gav ikkje eit lesbart resultat fordi
kommandoutdata ikkje var gyldig JSON. Om kontrollen fann innloggingar, er
derfor ukjent. Det anonyme Apex-uttrykket inneheldt ingen dataskrivande steg.

Ein tredje, separat godkjend read-only kontroll fullførte og fann ingen
innloggingshistorikk for den syntetiske brukaren i dag. Dette avgjer ikkje om
«Log in to Experience as User» oppretta ei økt, fordi slik innlogging kan bli
registrert andre stader.

Brukaren prøvde same kontaktinnlogging i eit privat nettlesarvindauge og
rapporterte den same innloggingssida. Dette utelukkar ikkje ein nettlesar- eller
øktfeil, men P02 er framleis blokkert.

Ei separat godkjend read-only øktspørring fann to øktpostar for den syntetiske
brukaren i dag, av typane `ChatterNetworks` og `TempChatterNetworks`. Dette
stadfestar at Salesforce har registrert økter, men ikkje at nettlesaren fekk
ei fungerande community-økt eller kva for forsøk postane høyrer til.

Brukaren rapporterte at dei trykte **Publish** i Aa-registret sin Experience
Builder og deretter kom inn. Publiseringa vart utført av brukaren; innhaldet
som vart publisert er ikkje gjennomgått i denne kontrollen. Det er ikkje enno
stadfesta kva vising eller brukarkontekst som opna.

**PASS — innlogging:** Brukaren stadfesta deretter den vanlege Aa-registeret-
startsida, ikkje Builder/preview, med **Synthetic Community Test User** som
innlogga brukar. Publiseringa føregjekk det vellukka forsøket; innhaldet i
publiseringa og den eksakte tekniske årsaka til den tidlegare omdirigeringa
er ikkje verifiserte. P02-opplasting er framleis ikkje utført.

### Val av syntetisk organisasjon

- **PASS:** Brukaren stadfesta at syntetisk organisasjon A var vald og at
  panelet **Ny søknad** var synleg på community-startsida.
- Søknaden er ikkje opna eller send som del av dette steget, og P02-vedlegg er
  ikkje lasta opp.

### P02: opning av søknadsskjema

- **PASS:** Brukaren opna **Ny søknad** og stadfesta at syntetisk organisasjon A
  står under **Søker**.
- Dette stadfestar tilgang til skjemaet, ikkje opplasting eller arkivering.
  Skjemaet er ikkje lagra eller sendt som del av steget.

### P02: lesande sikkerheitskontroll før opplasting

- **PASS:** Den separat godkjende kontrollen i `crm-arbeidsforhold` stadfesta
  ei aktiv, eksplisitt scenarioinnstilling for den syntetiske brukaren med
  `S01` og `subject-a`. Kontrollen stadfestar innstillinga, ikkje åleine kva
  provider som faktisk vart brukt av tidlegare UI-kall.
- **PASS:** P360 sin org-default `Use_Mock_Transport__c` var `true`.
- **AVVIK:** `P360_Archive_Processing` var sett til `true`, og den effektive
  prosesseringsgaten var på. Førre smoke-runde hadde loggført flagget som
  `false`; tidspunktet og årsaka til endringa er ikkje kjende.
- **KØ-SNAPSHOT:** Ingen `Pending`, `Failed` eller `In Progress` arkivjobbar,
  aktive P360-workerar eller ikkje-avslutta planlagde Apex-jobbar vart funne.
  Dette er eit augeblikksbilete og utelukkar ikkje seinare aktivitet eller
  andre måtar å starte prosessering på.
- Kontrollen endra ikkje testdata eller innstillingar. Vedlegg er framleis
  ikkje lasta opp, og ingen ny flaggaktivering vart utført som del av steget.

### P02: tilbake til avslått prosesseringsflagg

- **UTFØRT:** Brukaren rapporterte at `P360 Archive Processing` vart slått av
  og lagra i Salesforce UI etter avviket over.
- Det er ikkje gjort ei ny, uavhengig org-lesing etter brukarhandlinga.
  Årsaka til at flagget var på ved førre kontroll, er framleis ukjend.

### P02: syntetisk testvedlegg

- Brukaren hadde ikkje ei eigna testfil. Ei lokal PDF med syntetisk tekst og
  utan personopplysningar vart derfor laga til testen.
- Den lokale kontrollen opna PDF-en, fann éi side og den forventa testteksten.
  Ho er enno ikkje vald i skjemaet eller lagra i Salesforce.

### P02: val av vedlegg i skjemaet

- **PASS:** Brukaren rapporterte at filnamnet for den syntetiske PDF-en vart
  vist under **Opplastet fil** i søknadsskjemaet.
- Dette stadfestar filval i UI, ikkje lagring av vedlegget i Salesforce eller
  oppretting av ein P360-jobb. Brukaren har ikkje lagra eller sendt søknaden.

### P02: ny kontroll før testvindauget

- **PASS:** Ein ny, separat godkjend lesekontroll stadfesta at
  prosesseringsflagget og den effektive gaten var `false`, medan org-default
  P360-mock var `true`.
- **PASS:** Den syntetiske brukaren hadde framleis ei aktiv, eksplisitt
  innstilling for `S01` og `subject-a`.
- **KØ-SNAPSHOT:** Ingen `Pending`, `Failed` eller `In Progress` arkivjobbar,
  aktive P360-workerar eller ikkje-avslutta planlagde Apex-jobbar vart funne.
  Dette er eit augeblikksbilete og ikkje ei garanti mot seinare aktivitet.
- Ingen testdata eller innstillingar vart endra av kontrollen. Utkast og
  vedlegg er framleis ikkje lagra i Salesforce.

### P02: mellombels aktivering

- **UTFØRT:** Brukaren rapporterte at `P360 Archive Processing` vart slått på
  og lagra i Salesforce UI for det avgrensa P02-testvindauget.
- Tilstanden er enno ikkje lese tilbake av assistenten. Flagget skal setjast
  til `false` igjen etter testen; søknaden er ikkje lagra eller sendt enno.

### P02: kontroll etter aktivering

- **PASS:** Ein ny, separat godkjend lesekontroll stadfesta at både metadata-
  flagget og den effektive P360-gaten var `true`, og at org-default mock var
  `true`.
- **KØ-SNAPSHOT:** Ingen `Pending`, `Failed` eller `In Progress` arkivjobbar,
  aktive P360-workerar eller ikkje-avslutta planlagde Apex-jobbar vart funne.
  Dette er eit augeblikksbilete og ikkje ei garanti mot seinare aktivitet.
- `S01` og `subject-a` var framleis valde for den syntetiske testbrukaren.
  Vedlegget er enno ikkje lagra i Salesforce. Prosesseringsflagget skal av
  igjen etter teststeget.

### P02: lagring av utkast og avslutting av testvindauget

- **UTFØRT:** Brukaren rapporterte stadfesting om at søknaden vart lagra, og
  deretter at prosesseringsflagget vart slått av og lagra i Salesforce UI.
  Søknaden vart ikkje sendt inn som del av teststeget.
- Kontrollvindauget for den etterfølgjande org-lesinga starta
  `2026-11-10T22:59:53Z`. Lagring av sjølve vedlegget, koplingane og eventuell
  P360-jobb er ikkje enno uavhengig kontrollerte. Flagget er heller ikkje lese
  tilbake etter brukarhandlinga.

### P02: første resultatkontroll

- **PASS:** Den separat godkjende lesekontrollen stadfesta at både metadata-
  flagget og den effektive P360-gaten var `false` igjen. Org-default mock var
  framleis `true`.
- **UAVKLART:** Kontrollen fann ingen `ContentVersion` som samtidig hadde det
  eksakte testfilnamnet, var oppretta av den syntetiske community-brukaren og
  vart oppretta etter starten på kontrollvindauget. Dette beviser ikkje
  åleine at fila manglar; filnamn, eigar og kopling til utkastet må undersøkjast.
- P360-jobb for filversjonen vart ikkje kontrollert fordi inga eintydig
  filversjon vart funnen.

### P02: UI-kontroll av lagra vedlegg

- **PASS:** Brukaren rapporterte at den syntetiske PDF-en var synleg under
  **Tidligere opplastede vedlegg** på det lagra søknadsutkastet.
- Dette viser at det første filsøket ikkje er tilstrekkeleg som grunnlag for
  å seie at vedlegget manglar. Salesforce-koplingar og eventuell arkivjobb må
  framleis undersøkast.

### P02: kontroll via søknaden sine filkoplingar

- **PASS:** Den separat godkjende lesekontrollen fann eitt søknadsutkast for
  syntetisk organisasjon A, oppretta av testbrukaren. Éi PDF-filversjon var
  kopla til utkastet og til den same tilgangsforespurnaden.
- **FAIL — P360-jobb:** Kontrollen fann ingen `ApplicationAttachment`-jobb
  på søknaden og ingen jobb med nøkkelen for den aktuelle filversjonen.
  Prosesseringsgaten og mock var stadfesta på før lagringa; gaten var stadfesta
  av etterpå.
- **KODEOBSERVASJON:** Fila var først publisert på noko anna enn søknaden.
  Den undersøkte P360-handleren krev direkte publisering på søknaden, medan
  søknadskontrolleren opprettar filversjonen før han opprettar koplingane.
  Dette samsvarer med eit sannsynleg integrasjonsgap; den eksakte runtime-
  årsaka er ikkje isolert gjennom ein regresjonstest.
- **KONTROLLAVVIK:** Det første filsøket gav null treff, sjølv om den seinare
  kontrollen via søknaden fann éi fil med same undersøkte filnamn, opprettar
  og tidsvindauge. Årsaka til skilnaden mellom søkja er ikkje avklart.
- Ekte P360-arkivering er ikkje testa. Flagget er framleis av ved den siste
  lesinga, og testdata er ikkje rydda opp.

### Korrigering: P02 gjeld eit utkast

- **KORREKSJON:** `FAIL`-klassifiseringa over var feil. Den dokumenterte
  [målsemantikken](../../architecture/p360-data-model-og-arkiveringsjob.md#arkiveringsreglar)
  seier at utkast ikkje skal opprette arkiveringsjobb. Dokumentet presiserer
  samtidig at ikkje alle målreglane er implementerte eller godkjende.
- **PASS — utkast:** For denne UI-vegen vart vedlegget lagra og kopla til
  utkastet, utan at det vart oppretta ein `ApplicationAttachment`-jobb. Det
  samsvarer med målregelen for utkast.
- **IKKJE KØYRD:** Innsending av utkastet og kontroll av arkivjobbar for
  søknaden og det allereie lagra vedlegget. P02 er derfor ikkje fullført som
  test av innsending og etterfølgjande arkivering.
- **KODERISIKO, IKKJE TESTA I UI:** Den direkte ContentVersion-inngangen
  sjekkar ikkje søknadsstatus før han opprettar vedleggsjobb. Lokal kode viser
  heller ingen automatisk jobboppretting ved innsending av eksisterande
  vedlegg. Begge forhold krev eigne testar mot godkjende forretningsreglar.
- Den køyrde resultatkontrollen søkte berre etter `ApplicationAttachment`-
  jobbar for utkastet. Andre jobbtypar og andre opplastingsvegar er ikkje
  kontrollerte i dette steget.

### P02: klargjering for innsending

- Brukaren valde å førebu ein trygg innsendingstest. Søknaden er ikkje sendt.
- **LOKAL KODEOBSERVASJON:** Innsending set søknadsstatus til `New`. Den
  lokale flow-metadataen for denne overgangen kan opprette ein kontakt, ein
  `Queued` e-postkøpost, ein tråd og ei melding. Kva som er aktivt og kva som
  faktisk kan sendast i den noverande scratch-orgen, er ikkje kontrollert.
- Ein tidlegare UI-logg for aliaset rapporterte `All email` og ei melding om
  avgrensa utsending. Den historiske observasjonen stadfestar ikkje gjeldande
  innstilling eller om e-post, SMS eller andre varsel er trygt kontrollerte no.
- **NY UI-KONTROLL:** Brukaren rapporterer `Access Level: All email` og teksten
  «Access to send email has been restricted for your organization.» Innstillinga
  vart berre lesen. Meldinga viser ikkje i seg sjølv kva e-post som blir stoppa.
- **GODKJEND LESEKONTROLL:** I `crm-arbeidsforhold` var det ved kontrolltidspunktet
  0 e-postkøpostar med status `Queued`, 0 med status `Instant` og 0 aktive
  `EmailQueueJob`/`EmailQueueScheduler`-køyringar. Kontrollen fann òg 6
  ikkje-pauserte og 0 pauserte planlagde jobbar av alle typar. Identitet og type
  for dei 6 jobbane vart ikkje undersøkte; vi veit derfor ikkje om nokon av
  dei kan starte e-postbehandling. Ingen mottakaradresser vart henta.
- **UI-KONTROLL:** Brukaren fann ingen planlagde jobbar som tydeleg såg ut til
  å gjelde e-post. Dette er ikkje bevis for at e-postkøa ikkje kan bli behandla,
  sidan jobbnamn ikkje nødvendigvis viser klassen som blir køyrd.
- **UI-HENDING:** Brukaren fylte inn den syntetiske e-postadressa og trykte
  deretter `Lagre` utilsikta. Lokal kode koplar denne knappen til lagring av
  utkast, ikkje innsending. Status og eventuelle sideeffektar er ikkje
  kontrollerte etter denne lagringa.
- **GODKJEND LESEKONTROLL ETTER LAGRING:** Éin samsvarande syntetisk søknad
  hadde status `Draft`, tom saksbehandlarstatus og ingen innsendingsdato.
  Ho hadde éi fil og éin filversjon som samsvarte med testvedlegget; fila var
  kopla både til søknaden og tilgangsforespurnaden. Det fanst ingen P360-jobbar
  kopla til søknaden eller tilgangsforespurnaden og ingen e-postkøpostar med
  søknaden som `WhatId`. Dette seier ikkje noko om andre varslingskanalar eller
  e-post som ikkje er registrert på denne måten.
- **UI-KONTROLL:** Brukaren rapporterer at dei tre tekstfelta under
  `Begrunnelse` er fylte med syntetisk testtekst, og at `Web-oppslag` er valt.
  Dette er førebels berre oppgitt i skjemaet; ny lagring er ikkje rapportert.
- **UI-KONTROLL:** Brukaren rapporterer at éin syntetisk kontaktperson er fylt
  inn, og at alle fire varslingstypane er valde. Opplysningane er førebels
  berre oppgitte i skjemaet; ny lagring er ikkje rapportert.
- **LOKAL KODEOBSERVASJON:** Den identifiserte SMS-flowen gjeld bestemte
  supporthenvendingar, ikkje sjølve søknadsinnsendinga. Referansekoden i den
  delte integrasjonspakken viser likevel at ein ny `Pending` SMS kan starte
  ein asynkron callout. Kva SMS-oppsett som er aktivt i scratch-orgen, er
  ikkje verifisert; P360-mock eller syntetisk telefonnummer beviser ikkje at
  SMS-kanalen er sperra.
- **GODKJEND LESEKONTROLL AV SMS:** `SMSTrigger` var `Active`, og
  `SMSHandler`-registreringane for `AFTER_INSERT` og `AFTER_UPDATE` var
  aktive. Det fanst inga API-mockinnstilling på den syntetiske portalbrukaren
  eller profilen hennar. SMS-servicekonfigurasjonen hadde eit mock-responsobjekt,
  men utan vald brukar- eller profilinnstilling er dette ikkje ein aktiv mock
  for brukaren. SMS-gateway og faktisk køyringsidentitet for ulike automasjonar
  er ikkje kontrollerte. Ingen SMS vart oppretta eller send i kontrollen.
- **BLOCKED:** Ikkje send før relevante utgåande kanalar og testmottakarar er
  avklarte, og brukaren har godkjent sjølve testhandlinga.

### P02: vurdering av mellombels SMS-sperre

- Brukaren bad om å undersøkje ei trygg, mellombels sperre. Ingen innstillingar
  er endra.
- Lokal referansekode viser at dei to `SMSHandler`-registreringane styrer
  oppstart av den kjende SMS-køvegen ved innsetting og retry. Å deaktivere dei
  verkar på heile orgen; det stoppar ikkje ein `SMSCalloutQueueable` som alt er
  oppretta. Nye `Pending`-SMS-ar kan bli ståande utan automatisk utsending når
  registreringane blir aktiverte igjen. Sjå
  [SMSHandler](../../../crm-platform-integration/main/default/classes/SMSHandler.cls)
  og
  [SMSCalloutQueueable](../../../crm-platform-integration/main/default/classes/SMSCalloutQueueable.cls).
- API-mock på brukar- eller profilnivå påverkar generelt API-kall som brukar
  [ApiController](../../../crm-platform-base/main/default/classes/ApiController.cls),
  ikkje berre SMS. Koden fangar feil under mockoppsett utan å aktivere mock;
  ei innstilling åleine er derfor ikkje bevis for at all utsending er sperra.
- Ein eventuell mellombels orgbrei sperre krev avklart eksklusiv testbruk,
  kontroll av allereie kølagde/aktive SMS-jobbar, eksplisitt godkjenning,
  kontroll etter endring og ein avtalt tilbakeførings- og oppfølgingsplan.
  Andre SMS-sendarar og faktisk gateway-sperre er ikkje kartlagde i orgen.
- **AVKLARING:** Brukaren seier at scratch-orgen kan reserverast eksklusivt
  under eit kort testvindauge. Det er ikkje stadfesta at vindauget er starta,
  og ingen endring av orgen er godkjend.
- **LESEKONTROLL FEILA:** Ein godkjend kontroll av SMS-kø og -innstillingar
  stoppa med Salesforce-meldinga `Disjunctions not supported`.
  Metadata-spørringa inneheldt eit `OR`. Kontrollen gav inga samanstilling;
  inga innstilling vart endra og ingen SMS vart oppretta eller send.
- **PRESISERING:** Feilmeldinga identifiserte ikkje kva av spørringane som
  feila. Før eit eventuelt nytt forsøk er både `OR` og `IN` fjerna frå
  spørringane. Ny orgtilgang krev ny godkjenning.
- **GODKJEND LESEKONTROLL, NYTT FORSØK:** Ved kontrolltidspunktet var det
  0 `SMSCalloutQueueable`-jobbar med status `Holding`, `Queued`, `Preparing`
  eller `Processing`, og 0 SMS-postar med status `Pending`.
  `SMSHandler`-registreringane for `AFTER_INSERT` og `AFTER_UPDATE` hadde
  begge `Active__c = true`. Dette er eit augneblinksbilete for den kjende
  køvegen, ikkje ei sperre eller ei kontroll av andre SMS-sendarar.
- **UTDATA:** Eit metadatarelasjonsfelt gav ein intern teknisk ID i
  verktøyutdata. Verdien er ikkje teken inn i testloggen; feltet er fjerna frå
  det lokale kontrollskriptet og filteret.

### P02: vurdering av mellombels e-postsperre

- **LOKAL KODEOBSERVASJON:** Innsendingsflowen kan opprette ein `Queued`
  `EmailQueue__c`-post. Den kjende e-postkøvegen brukar Salesforce si
  `Messaging.sendEmail` og oppdaterer køstatusen etter at kallet returnerer.
  Dersom kallet feilar før statusen blir oppdatert, kan posten bli ståande
  `Queued` og bli behandla seinare. Sjå
  [EmailQueueScheduler](../../../crm-platform-email-scheduling/main/default/classes/EmailQueueScheduler.cls)
  og
  [EmailQueueJobHelper](../../../crm-platform-email-scheduling/main/default/classes/EmailQueueJobHelper.cls).
- **IKKJE VERIFISERT:** Salesforce-innstillinga `No access` kan vere eit
  tiltak for Salesforce-e-post i eit avgrensa testvindauge. Ho er orgbrei,
  sperrar ikkje e-post som blir send av eksterne tenester, og handterer ikkje
  ein køpost som framleis er `Queued` når innstillinga blir tilbakeført.
  Tilgjenge, faktisk effekt og trygg oppfølging av testkøposten er ikkje
  kontrollerte. Ingen e-postinnstilling eller køpost er endra.
- **UI-KONTROLL:** Brukaren rapporterer at lista for `Access Level` er låst
  eller ikkje kan opnast. Årsaka og tilgangen til andre verdiar er ikkje
  avklarte; ingen innstilling vart endra.
- **LOKAL MALOBSERVASJON:** Bekreftingsmalen i repository-kjelda inneheld
  mellom anna organisasjonsnamn og søknadsnummer. Han har òg ein
  Salesforce-biletreferanse til ein annan org. Assistenten har ikkje opna
  referansen eller kontrollert kva miljø han peikar til, og malen i
  scratch-orgen er ikkje kontrollert.

### P02: Salesforce-dokumentasjon om scratch-org og e-post

- Salesforce skildrar scratch-orgar som konfigurerbare, mellombelse miljø for
  mellom anna syntetiske testdata, og seier at ein ikkje skal leggje
  persondata inn i dei:
  [Scratch Orgs](https://developer.salesforce.com/docs/platform/sfdx-dev/guide/sfdx-dev-scratch-orgs.html).
  Ei personidentifiserande jobb-e-postadresse skal derfor ikkje leggjast inn
  som søknads- eller kontaktdata i denne testen.
- [Salesforce si Deliverability-rettleiing](https://help.salesforce.com/s/articleView?id=sales.emailadmin_deliverability.htm&type=5)
  seier at `All email` tillèt alle typar utgåande e-post, medan
  `System email only` og `No access` avgrensar utsending. Passordtilbakestillingar blir
  framleis sende med `No access`. Rettleiinga omtalar standardverdiar for
  sandboxar; ho stadfestar ikkje kva den aktuelle scratch-orgen kan levere.
  UI-observasjonen `All email` saman med ei avgrensingsmelding forklarer ikkje
  den faktiske sperra.
- Salesforce si
  [referanse for e-postinnstillingar](https://developer.salesforce.com/docs/platform/api-metadata/references/meta-types/metadata-emailadministrationsettings.html)
  skildrar ein mogleg Compliance BCC-kopi av utgåande e-post. Om dette er
  aktivt i scratch-orgen, er ikkje kontrollert.
- Salesforce skildrar krav om verifisering av avsendardomene i
  [Mandatory Sending-Email Domain Verification Timeline](https://help.salesforce.com/s/articleView?id=005316660&language=en_US&type=1).
  Avsendar og verifiseringsstatus i den aktuelle orgen er ikkje kontrollerte.
- [Test Deliverability](https://help.salesforce.com/s/articleView?id=sales.security_test_email_delivery.htm&language=en_US&type=5)
  sender faktisk testmeldingar til adressa som blir oppgitt. Salesforce seier
  éi melding for Hyperforce og fleire for andre orgar; orgtypen er ikkje
  avklart her. Ein slik test er ikkje køyrd, og han ville ikkje åleine teste
  søknadens e-postkø eller P360-flyten.
- Den lokale
  [scratch-definisjonen](../../../config/project-scratch-def.json) aktiverer
  Enhanced Email, men set ikkje `Access Level` i den viste
  `emailAdministrationSettings`-blokka. Dette dokumenterer ikkje kva
  innstillingar eller avgrensingar den eksisterande orgen faktisk har.

### P02: resultat frå Test Deliverability

- **BRUKARRAPPORT:** Brukaren køyrde Salesforce sin Test Deliverability etter
  dokumentasjonsgjennomgangen. Salesforce rapporterte at ei systemtestmelding
  vart send, medan brukartestmeldinga feila med
  `The FROM address has not been verified`. Opplysninga over om at testen
  ikkje var køyrd, gjeld situasjonen før denne handlinga.
- **IKKJE VERIFISERT:** Faktisk mottak av systemmeldinga, identiteten til
  avsendaren i testen og årsaka til verifiseringsfeilen er ikkje stadfesta.
  Resultatet beviser ikkje at all utgåande e-post er sperra.
- **MOGLEGE FORKLARINGAR, IKKJE STADFESTA:** Brukarens e-postadresse,
  ei anna returadresse, ein org-wide avsendar eller avsendardomenet kan
  krevje verifisering. Det er ikkje avklart kva avsendar testen brukte eller
  kva krav som gav denne feilen. Sjå Salesforce si rettleiing om
  [brukaradresser](https://help.salesforce.com/s/articleView?id=xcloud.security_email_verification_manage.htm&language=en_US&type=5)
  og
  [avsendardomene](https://help.salesforce.com/s/articleView?id=005316660&language=en_US&type=1).
- **LOKAL KODEOBSERVASJON:** Koden for søknaden si e-postkø prøver å velje
  ein org-wide avsendar; han kan vere ein annan enn avsendaren i Test
  Deliverability. Den faktiske avsendaren og verifiseringsstatusen i orgen er
  ikkje kontrollerte.
  Sjå
  [EmailQueueData](../../../crm-platform-email-scheduling/main/default/classes/EmailQueueData.cls)
  og
  [EmailQueueJobHelper](../../../crm-platform-email-scheduling/main/default/classes/EmailQueueJobHelper.cls).
- **BLOCKED:** Testen avklarer ikkje e-postsperre, SMS-sperre eller P360-flyten.
  P02-innsendinga er framleis ikkje utført.
- **MOTTAK STADFESTA ETTERPÅ:** Brukaren rapporterer at systemtestmeldinga kom
  fram. Opplysninga over om at mottak ikkje var stadfesta, gjeld situasjonen før
  denne tilbakemeldinga. Dette viser levering av den konkrete systemmeldinga,
  ikkje av brukartestmeldinga eller søknaden si e-postkø. P02 er framleis
  blokkert.
- **LESANDE UI-KONTROLL:** På `Advanced User Details` såg brukaren `Verify`
  ved e-postfeltet for kontoen som køyrde Test Deliverability. Ifølgje
  [Salesforce](https://help.salesforce.com/s/articleView?id=xcloud.security_email_verification_manage.htm&language=en_US&type=5)
  betyr det at brukaradressa ikkje er verifisert. Noka verifisering er ikkje
  rapportert. Dette er ein mogleg årsak til feilen, men vi har ikkje
  stadfesta kva avsendar testen eller søknaden si e-postkø brukar.
- **LESANDE UI-KONTROLL:** Brukaren rapporterer at lista under
  `Organization-Wide Addresses` ikkje viste nokon adresser. Dette er ikkje
  kontrollert med ei spørring i e-postjobben sin køyringskontekst.
- **LOKAL KODEOBSERVASJON:** Dersom spørringa i
  [EmailQueueData](../../../crm-platform-email-scheduling/main/default/classes/EmailQueueData.cls)
  ikkje finn ein org-wide avsendar, blir avsendar-ID sett til `null` og sendt
  vidare til `setOrgWideEmailAddressId`. Vi har ikkje verifisert kva dette
  fører til i orgen eller kven som køyrer e-postjobben. Ei tom liste er ikkje
  bevis for at søknadsbekreftinga ikkje kan bli send.

### P02: kontroll av e-postkø og planlagde jobbar

- **GODKJEND LESEKONTROLL, RESULTAT IKKJE TILGJENGELEG:** Anonym Apex med
  lesande spørringar vart køyrd i `crm-arbeidsforhold`. Salesforce rapporterte
  vellukka kompilering og køyring, men assistenten sitt lokale filter avviste
  svaret fordi resultatmarkøren fanst i to logglinjer. Ingen teljingar vart
  viste eller lagra, og det kan ikkje trekkjast konklusjonar frå kontrollen.
  Dette er ein lokal filterfeil, ikkje ein stadfesta feil i Salesforce eller
  P360. Ingen forretningsdata eller innstillingar vart endra av skriptet;
  Salesforce genererte ein teknisk debuglogg.
- **GODKJEND LESEKONTROLL, NYTT FORSØK:** Det testa filteret viste ved
  kontrolltidspunktet 0 e-postkøpostar med status `Queued`, 0 med status
  `Instant` og 0 aktive `EmailQueueJob`- eller `EmailQueueScheduler`-køyringar.
  Det fanst 6 planlagde jobbar som ikkje hadde status `COMPLETE` eller
  `DELETED`. Ingen vart identifiserte som `Scheduled Apex` ut frå den lesne
  jobbtypen; alle 6 hadde ein annan eller ukjend type. Den presise typen er
  ikkje kartlagd, og kontrollen dekker ikkje alle moglegheiter for framtidig
  e-postutsending. Søkegrensene vart ikkje nådde.

### P02: val av testmottakar

- Brukaren ønskjer å bruke eiga e-postadresse som mottakar. Adressa er ikkje
  teken inn i testloggen, og vi har ikkje stadfesta om ho er ført inn i
  søknadsskjemaet.
- Ei personidentifiserande adresse kan ikkje brukast som søknads- eller
  kontaktdata i denne scratch-testen: Salesforce seier at scratch-orgar ikkje
  skal innehalde persondata, og testguiden krev syntetiske data. Den lokale
  innsendingsflowen kan lagre søknadsadressa på ein kontakt.
- Den tidlegare Test Deliverability var ein separat systemtest. Vi har ikkje
  undersøkt om Salesforce lagra mottakarinformasjon i tekniske loggar for
  den testen. P02-innsendinga er framleis ikkje utført.
- **BRUKARAVKLARING:** Brukaren stadfestar at eiga e-postadresse ikkje er
  ført inn i søknaden eller kontaktpersonen, og ønskjer å bruke henne som
  testmottakar. Ingen persondata frå eksterne brukarar skal brukast.
- **PRESISERING:** Formuleringa over om at ei personidentifiserande adresse
  «ikkje kan brukast», var for kategorisk som påstand om Nav-regelverk.
  [Salesforce si rettleiing](https://developer.salesforce.com/docs/platform/sfdx-dev/guide/sfdx-dev-scratch-orgs.html)
  seier at persondata ikkje skal leggjast inn i scratch-orgar, og testguiden
  føreset syntetiske data. Bruk av eiga adresse vil avvike frå desse
  testføresetnadene; vi har ikkje stadfesta kva Nav sine reglar seier om
  dette eller om eit eventuelt unntak er godkjent. Adressa er ikkje teken inn
  i loggen. Søknaden er framleis ikkje send.

### P02: reservert testvindauge før innsending

- **BRUKARAVKLARING:** Brukaren stadfestar at scratch-orgen
  `crm-arbeidsforhold` er reservert for dette testvindauget.
- Brukaren godkjende éin lesekontroll av P360-innstillingar og teljingar av
  P360-, e-post- og SMS-køar og kjende aktive jobbar. Godkjenninga omfattar
  ikkje innsendingshandlinga eller endring av flagg og innstillingar.
- **AVBROTE – IKKJE VERIFISERT:** Den godkjende lesekontrollen vart starta,
  men gav ikkje resultat etter fleire minutt og vart stoppa lokalt. Maskina
  hadde høg belastning; årsaka til ventinga er ikkje stadfesta. Vi veit ikkje
  om Salesforce rakk å behandle førespurnaden eller opprette ein debuglogg.
  Skriptet inneheldt berre lesing og inga sending eller endring av
  forretningsdata eller innstillingar. Ingen nye flagg- eller køverdiar kan
  rapporterast, og preflighten er ikkje bestått.

### P02: ny lesekontroll av innstillingar — 2026-11-12

- **BRUKARRAPPORTERT:** I scratch-orgen `crm-arbeidsforhold` var org-default
  `Use Mock Transport` på, `P360 Archive Processing` sitt `Is Enabled` av,
  og `Required Custom Permission` tomt.
- Ingen innstillingar vart endra i denne kontrollen. Køar og aktive jobbar er
  ikkje kontrollerte på nytt; preflighten er derfor ikkje bestått.
- **BRUKARRAPPORTERT:** Listevisingane Pending, Needs Attention og In Progress
  viste ingen arkivjobbar. Dette er eit augeblikksbilete av det brukaren ser,
  ikkje ein kontroll av aktive workerar eller andre køar.
- **BRUKARRAPPORTERT:** I Apex Jobs såg brukaren ingen aktive eller ventande
  `P360_ArchiveJobWorker`, `EmailQueueJob`, `EmailQueueScheduler` eller
  `SMSCalloutQueueable`. Dette er ei UI-observasjon, ikkje ei fullstendig
  kartlegging av alle bakgrunnsjobbar eller framtidige køyringar.
- **BRUKARAVKLARING:** Orgen er reservert for denne testen. Søknaden er open,
  test-PDF-en er synleg, og dei seinare utfylte felta vart ikkje lagra og må
  fyllast inn på nytt. Søknaden er ikkje send i denne runden.
- **BRUKARRAPPORTERT:** Begrunnelse og kontaktperson vart fylte inn på nytt,
  Web-oppslag og dei fire varslingstypane vart valde. Brukaren oppgav å ha
  eit trygt testnummer. Desse nye skjemaverdiane er ikkje stadfesta lagra.
- **BRUKARRAPPORTERT:** Ingen jobbnamn på Scheduled Jobs-sida såg tydeleg ut
  til å gjelde P360, e-postkø eller SMS. Jobbnamn åleine utelukkar ikkje
  relevant planlagt behandling.
- **BRUKARRAPPORTERT:** Brukaren køyrde lesande spørringar i Query Editor og
  fekk 0 `EmailQueue__c`-postar med status `Queued` eller `Instant` og 0
  `SMS__c`-postar med status `Pending`. Dette er augeblikksbilete og hindrar
  ikkje seinare varsling eller behandling.
- **BRUKARAVKLARING:** Brukaren valde å fortsetje utan mellombels SMS-sperre
  med det stadfesta testnummeret. Om innsending kan utløyse SMS, er ikkje
  verifisert; ingen SMS-sperre er etablert.
- **GODKJEND AKTIVERING:** Brukaren slo på `P360 Archive Processing` i
  `crm-arbeidsforhold` og rapporterte at `Is Enabled` var på ved etterfølgjande
  UI-kontroll. Flagget skal slåast av etter testvindauget. Søknaden er ikkje
  send, og effektiv gate og ny mockverdi er ikkje kontrollerte etter aktivering.
- **BRUKARRAPPORTERT:** Søknaden sitt e-postfelt inneheld brukaren si eiga
  testadresse. Brukaren har lese og valt å godta bruksvilkåra for testen og
  kryssa av i skjemaet. Ingen adresse er registrert i denne loggen.
- **BRUKARRAPPORTERT:** Org-default `Use Mock Transport` var framleis på ved
  lesekontroll etter flaggaktivering. Brukaren valde å sende inn og såg
  kvittering om at søknaden er mottatt. Dette stadfestar UI-kvitteringa,
  ikkje arkivjobb, varsel eller faktisk arkivering. Prosesseringsflagget skal
  slåast av etter testen.
- **BRUKARRAPPORTERT:** Etter innsending var listevisingane Pending,
  In Progress og Needs Attention tomme, og All Archive Jobs viste ingen jobb
  rundt innsendingstidspunktet. Dette er ikkje endeleg bevis for at ingen
  tilknytt jobb finst.
- **BRUKARRAPPORTERT:** Brukaren slo prosesseringsflagget av etter testen og
  såg at `Is Enabled` var av ved etterfølgjande UI-kontroll.
- **BRUKARRAPPORTERT:** Brukaren hadde ikkje motteke e-post ved kontrollen.
  Første spørjeresultat for ventande e-post vart rapportert som 0; ei seinare
  gruppert spørring viste 1 `Queued`-post frå i dag, og ein ny gruppert
  køkontroll viste 1 `Queued`-post totalt. Årsaka til skilnaden er ukjend, og
  det er ikkje verifisert at posten høyrer til denne søknaden.
- **BRUKARRAPPORTERT:** Tidspunktet for den kølagde e-posten passa omtrent med
  innsendinga, men samanhengen er ikkje verifisert. Søknadsoversikta viste
  status `New`. Brukaren fann ikkje vedleggsområdet i den innsendte søknaden;
  filkoplinga etter innsending er ikkje kontrollert.
- **BRUKARRAPPORTERT:** Test-PDF-en var synleg under Files på den interne
  søknadsposten. Ei lesande spørring fann ingen P360-jobbar med direkte
  `Application__c`-kopling til søknaden. Ei anna spørring fann éin `Queued`
  e-postpost med søknaden som `WhatId__c`. Jobbar som berre er kopla til
  tilgangsforespurnaden, er ikkje kontrollerte.
- **BRUKARRAPPORTERT:** Søknaden hadde ei tilgangsforespurnad. Spørringa for
  `Access_Request__c` fann ingen tilknytte P360-jobbar, og test-PDF-en var
  synleg under Files på tilgangsforespurnaden. Manglande arkivjobb etter
  innsending er eit mogleg gap; effektiv gate under innsending er ikkje
  uavhengig verifisert.
- **BRUKARRAPPORTERT:** Etter innsending gav lesande spørringar ingen
  `SMS__c`-postar i `Pending` og ingen `SMS__c`-postar oppretta i dag. Dette
  utelukkar ikkje andre SMS-mekanismar.
- **BRUKARRAPPORTERT:** Ei lesande spørring fann ingen `AsyncApexJob`-postar
  for `EmailQueueJob` eller `EmailQueueScheduler` oppretta i dag. Dette
  stadfestar ikkje om ei framtidig køyring er planlagd.
- **LOKAL KODEDIAGNOSE:** Vedlegg som allereie er lagra på utkastet, blir ikkje
  automatisk arkiverte av innsendinga i den undersøkte koden. Controlleren
  opprettar berre ein ny `ContentVersion` når nye fildata blir sende inn, og
  den eksisterande P360-handleren handterer berre nye versjonar med
  `FirstPublishLocationId` sett til søknaden. Controlleren set ikkje dette
  feltet ved ny opplasting, men opprettar filkoplingar etterpå.
  `ApplicationDocument`-service finst, men den undersøkte produksjonskoden
  har ingen automatisk innsendingstilknyting. Dette samsvarer med P02-funnet;
  den eksakte runtime-kjeda og effektiv gate vart ikkje verifiserte under
  innsendinga. Automatisk søknadsarkivering har uavklarte produktkrav.
