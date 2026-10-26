# crm-arbeidsforhold

Denne pakken inneholder Salesforce metadata som støtter arbeidet NAV gjør rundt Aa-registeret. Løsningen omfatter blant annet Experience Cloud, dialog, support, saksbehandling, søknader og avtaler.

## Avhengigheter

Pakken har flere avhengigheter. Se [sfdx-project.json](https://github.com/navikt/crm-arbeidsforhold/blob/main/sfdx-project.json) for oversikten over pakker og versjoner.

## Komme i gang

Installer følgende verktøy:

- [Salesforce CLI (`sf`)](https://developer.salesforce.com/tools/sfdxcli)
- [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
- [Visual Studio Code](https://code.visualstudio.com)
- [Eclipse Temurin JDK 11](https://adoptium.net/temurin/releases/), som er repoets dokumenterte Java-anbefaling for Salesforce-utvikling

Klon repoet og kjør kommandoene fra prosjektroten.

## Scratch org

Oppsett, pool, avhengigheter, preflight, autofiks og feilsøking er samlet i
[scratch-org-guiden](bin/README.md). Se [kommandoreferansen](bin/COMMANDS.md)
for alle flagg og eksempler og [plattformmatrisen](bin/COMPATIBILITY.md) for
forskjeller mellom macOS, Linux og Windows. Org-endringer krever godkjenning.

## Lokal validering

```bash
npm install
npm test
npm run prettier:check
```

`npm test` kjører først Node-testene for lokale utviklerverktøy og deretter LWC Jest-testene.
Bruk `npm run test:node` for bare Node-testene og `npm run test:unit` for bare LWC-testene.
`npm run test:dependency-report` køyrer dei isolerte Jest/jsdom-testane for
interaktiv HTML (hover/fokus, retning, låsing, tastatur og zoom). Denne separate
kommandoen er ikkje inkludert i `npm test` eller den avhengigheitsfrie offline-CI.
Han krev prosjektets installerte devDependencies, men ingen Salesforce-org.
Med PowerShell 7 LTS installert kan `npm run test:scratch-org:powershell` køyre
den portable offline-harnessen på Mac og Windows, utan Salesforce-tilgang.
Mac-testane verifiserer ikkje Windows-entrypoints; desse krev eiga Windows-køyring.
Node-testene under `bin/tests/` og `scripts/tests/` bruker `node:test` og er derfor
utelatt fra Jest sitt testsøk. Begge runnerne må lykkes for at `npm test` skal lykkes.
Apex-kompilering og Apex-tester er org-avhengige og må kjøres mot en autentisert Salesforce-org.

### Behovsstyrte PR-sjekkar

PR-workflowene bevarer påkrevde sjekknavn og velger Salesforce-/LWC-validering
ut fra endringene. Rene dokumentasjons- og verktøyendringer trenger normalt
ikke org-validering; lokale tester og formatering gjelder fortsatt.
Se [endringsfilteret og eksemplene](scripts/README.md#behovsstyrte-ci-sjekkar)
for regler, sikkerhetsgrenser og lokal kontroll. Endringer i workflows krever
særskilt menneskelig gjennomgang.

### Workflowar og merge til main

| Workflow                        | Utløysar og ansvar                                                                                                                                                                              |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `[PUSH] Create Package`         | Push til `main` som endrar `force-app/**`, `sfdx-project.json` eller `.forceignore`, og manuell start. Opprettar pakke, validerer installasjon i SIT og lagar release via den delte workflowen. |
| `[PUSH] Deploy to Dev`          | Berre manuell kjeldedeploy til dev, med oppdatering av avhengigheiter og `RunLocalTests`. Namnet er bevart for eksisterande referansar.                                                         |
| `[PR] Validate`                 | Ikkje-utkast-PR-ar til alle branchar, også namn med `/`. Brukar behovsstyrt Salesforce-validering.                                                                                              |
| `[PR] LWC tests and formatting` | Alle PR-ar. Køyrer Node-/rapporttestar, relevante LWC-testar og formateringskontroll av endra filer.                                                                                            |
| `Salesforce validation`         | Lokal gjenbrukbar workflow kalla av PR-valideringa. Bevarer påkrevde sjekknamn og krev at den delte valideringa lukkast når ho er relevant.                                                     |
| `Scratch org offline`           | Relevante PR-ar og push til `main`, eller manuell start. Testar lokale skript på Windows, Linux og macOS utan Salesforce-org. Inkluderer workflow-kontraktane.                                  |
| `Copilot Setup Steps`           | Copilot-oppsett, manuell start og endringar i sjølve workflowfila. Installerer Node og npm-avhengigheiter.                                                                                      |
| `[HELPER] Create Scratch Org`   | Manuell, men blokkert av feil i den delte implementasjonen; sjå nedanfor.                                                                                                                       |
| `[HELPER] Quick Package Create` | Manuell rask pakkeoppretting via delt workflow.                                                                                                                                                 |
| `[HELPER] Promote Package`      | Manuell promotering, versjonsoppdatering og release via delt workflow.                                                                                                                          |
| `[HELPER] Deployment`           | Manuell pakkeinstallasjon i valt sandboxmiljø via delt workflow.                                                                                                                                |
| `[HELPER] Deploy to Production` | Manuell pakkeinstallasjon i produksjon via delt workflow.                                                                                                                                       |

Push-utløysaren gjeld òg direkte push, ikkje berre PR-merge. Rene dokumentasjonsendringar
lagar ikkje pakke. Direkte dev-deploy køyrer ikkje parallelt automatisk ved merge.
Workflowane er ikkje køyrde mot Salesforce som del av lokal validering.

**Ekstern eigar og avgrensingar:** `navikt/crm-workflows-base` eig Salesforce-workflowane,
og er festa til commit `aad6b4f48e419d71490db436da697cd7581a2c6a`.
Eigaren har ansvar for org-oppsett, Apex-/dekningsvalidering, pakkeoperasjonar og opprydding.
Lokal SHA-pinning låser ikkje transitive action-referansar: den delte implementasjonen
brukar framleis fleire muterbare tags og `@master`/`@main`. Desse er eksterne referansar,
ikkje lokale branch-utløysarar, og må rettast hos eigaren.

Gjennomgangen fann desse oppfølgingspunkta før org-operasjonar:

- Den delte `createScratchOrg.yml` brukar utgåtte `actions/upload-artifact@v2` og
  `actions/download-artifact@v2`, og skriv til `GITHUB_OUTPUT` utan `$`.
  Ikkje bruk helperen før eigaren har retta dette. Bruk den dokumenterte lokale
  [scratch-org-flyten](bin/README.md) med eksplisitt godkjenning i mellomtida.
- Berre GitHub-miljøet `copilot` fanst ved gjennomgangen; det hadde ingen godkjenningsreglar.
  Dei delte org-jobbane brukar ikkje beskytta GitHub environments. Manuell start er
  ikkje eit separat godkjenningssteg. Miljøvern og godkjennarar må avklarast og koplast
  til dei faktiske org-jobbane hos eigaren før deploy-/releaseflyten kan reknast som godkjenningsverna.
- Pakkeoppretting installerer òg i SIT. Dette er eksisterande delt åtferd som blir
  aktivert att av `main`-utløysaren; det er ikkje berre ein lokal byggjobb.

Lokale regresjonstestar: `node --test scripts/tests/ci-workflows.test.cjs`
(inngår òg i `npm run test:node`). Dei sjekkar triggarar, CLI-kontrakt, eksplisitte
tokenrettar, direkte shell-interpolering og lokale SHA-referansar, utan nye avhengigheiter.
Dei verifiserer ikkje eksterne workflowar, secrets, GitHub-miljøvern eller org-tilstand.

### Pre-commit på Windows, Linux og macOS

Husky installeres ved `npm install` eller `npm ci`. Git og Node må være i PATH,
og Node må oppfylle npm-avhengighetenes krav (`lint-staged` 17.6.0 krever >=22.22.1).
Hooken beskytter pakkeeide mapper og formaterer staged filer. Se
[hook- og formateringsguiden](scripts/README.md#pre-commit-og-formatering) for
oppsett, godkjente unntak, eksempler og isolerte tester.

## Salesforce Project CLI

Den valgfrie [Salesforce Project CLI-en](tools/salesforce-project-cli/README.md)
er en separat lokal pakke med egen installasjon, kommandoreferanse og webflate.
Den kreves ikke av scratch-org-skriptene og startes ikke automatisk fra rotprosjektet.
Se [verktøyets dokumentasjon](tools/salesforce-project-cli/docs/README.md) for bruk
og forskjeller fra skriptene. Nøkler og credentials skal ikke lagres i kildekode
eller konfigurasjonsfiler.

## Dokumentasjon og agentregler

- [AGENTS.md](AGENTS.md) — repositoryregler og kildegrenser
- [CONTEXT.md](CONTEXT.md) — domeneord, arkitekturgrenser og verifikasjonsvokabular
- [.github/copilot-instructions.md](.github/copilot-instructions.md) — Copilot-arbeidsflyt og sikkerhetsregler
- [docs/adr/](docs/adr/) — Architecture Decision Records
- [docs/architecture/](docs/architecture/) — tverrgående arkitektur og kildeoppdeling
- [docs/domain/](docs/domain/) — domenedokumentasjon
- [docs/surfaces/](docs/surfaces/) — brukerflate-dokumentasjon
- [docs/integrations/](docs/integrations/) — integrasjonsspesifikk teknisk dokumentasjon
- [docs/utviklingsstandarder.md](docs/utviklingsstandarder.md) — speilet oversikt over utviklingsstandarder
- [bin/COMMANDS.md](bin/COMMANDS.md) — total kommandoreferanse for lokale skript
- [bin/COMPATIBILITY.md](bin/COMPATIBILITY.md) — funksjons-, system- og testmatriser
- [scripts/README.md](scripts/README.md) — full oversikt over støtteskript

Testtilgang, testbrukere, tokens, credentials og miljøspesifikke URL-er skal håndteres i godkjent, ikke-offentlig dokumentasjon.
