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

Scratch-org-flyten og avhengighetsinstallasjon er dokumentert i [bin/README.md](bin/README.md). Der finner du blant annet:

- opprettelse med `bin/create-scratch-org.sh`
- Windows-flyt med `bin/newScratchOrg.bat`
- henting fra scratch-org-pool
- pakkeoppløsning og nødvendige Dev Hub-forutsetninger

En typisk CLI-flyt starter med at du logger inn mot en Dev Hub med `sf org login web`, og deretter bruker den dokumenterte scratch-org-flyten. Installasjonsnøkler skal aldri legges i README, kildekode eller shell-historikk.

## Lokal validering

```bash
npm install
npm test
npm run prettier:check
```

`npm test` kjører LWC Jest-testene. Apex-kompilering og Apex-tester er org-avhengige og må kjøres mot en autentisert Salesforce-org.

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

Testtilgang, testbrukere, tokens, credentials og miljøspesifikke URL-er skal håndteres i godkjent, ikke-offentlig dokumentasjon.
