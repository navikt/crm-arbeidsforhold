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
