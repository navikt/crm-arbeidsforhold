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

## Salesforce Project CLI

CLI-en er ein sjølvstendig lokal pakke i [tools/salesforce-project-cli](tools/salesforce-project-cli). Root-prosjektet har ingen npm-script eller dependency som startar verktøyet automatisk.

Installer verktøyet frå tool-mappa. Denne eine kommandoen installerer avhengigheiter, byggjer CLI-en, opprettar prosjektkonfigurasjonen og lenkjer `sf-project` lokalt:

```bash
cd tools/salesforce-project-cli
npm run setup
```

Setup opprettar eller gjennomgår `sf-project.config.json` ved sida av `sfdx-project.json`. Kvar innstilling viser eksisterande verdi og defaultverdi. Trykk Enter for å bevare eksisterande verdi; dersom innstillinga manglar, brukar Enter defaultverdien.

Gå så tilbake til repo-rota:

```bash
cd ../..
```

Køyr deretter kommandoane frå repo-rota:

```bash
sf-project doctor
sf-project org list
sf-project packages plan
sf-project web start
```

Utan global lenking kan du køyre CLI-en direkte frå tool-mappa:

```bash
cd tools/salesforce-project-cli
npx sf-project doctor --project-dir ../..
```

Konfigurasjonen inneheld ikkje installasjonsnøklar. Nøkkelen må ligge i miljøvariabelen som står i `packageInstallKeyEnvironmentVariable`. På macOS kan ein lagre ein nøkkel i Keychain og berre eksportere han for éi køyring:

```bash
security add-generic-password -a "$USER" -s PACKAGE_INSTALL_KEY -w
PACKAGE_INSTALL_KEY="$(security find-generic-password -a "$USER" -s PACKAGE_INSTALL_KEY -w)" sf-project packages install --target-org my-org
```

Nøklar, tokens og credentials skal ikkje skrivast til `sf-project.config.json`, shell-script eller README.

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
