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
