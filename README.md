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
- Windows-flyt med `bin/create-scratch-org.bat` (PowerShell engine, no `sf-project` dependency)
- henting fra scratch-org-pool
- pakkeoppløsning og nødvendige Dev Hub-forutsetninger

For komplett bruk og alle kommandoalternativ:

- [Samla kommandoreferanse](bin/COMMANDS.md) — flagg, eksempel, miljøvariablar,
  konfigurasjon, sideeffektar og legacy-avgrensingar.
- [Funksjons- og plattformmatriser](bin/COMPATIBILITY.md) — Bash, PowerShell,
  CMD/npm, macOS/Linux/Windows og kva som faktisk er verifisert.
- [Alle støtteskript](scripts/README.md) — pre-commit, formatering, P360-smoke,
  Apex-hjelpeskript og testar.

Vanleg pakkeinstallasjon/oppdatering har ein felles Node-basert rekursiv
avhengigheitssjekk før org-oppsettet. Sjekken lagar Markdown med både full og
pakkevis Mermaid-graf, pluss ein sjølvstendig HTML-graf for lokal interaktiv
utforsking. Dette krev Node også ved direkte Bash-/PowerShell-køyring.
Versjonsavvik blir ikkje automatisk tolka som kompatible eller retta ved
nedgradering; sjå [rapport- og sjekkflyten](bin/README.md#complete-package-dependency-preflight).

En typisk CLI-flyt starter med at du logger inn mot en Dev Hub med `sf org login web`, og deretter bruker den dokumenterte scratch-org-flyten. Installasjonsnøkler skal aldri legges i README, kildekode eller shell-historikk.

På Windows er `bin/create-scratch-org.bat` den anbefalte CMD-inngangen.
PowerShell 7 LTS må vere installert og `pwsh.exe` må vere på PATH; Windows
PowerShell 5.1 er ikkje lenger støtta, og launcherane fell ikkje tilbake til han.
Sjå [migrering og lokale PowerShell-testar](bin/README.md#migrating-from-windows-powershell-51).

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
utelatt fra Jest sitt testsøk. Begge runnerne må lykkes for at `npm test` skal lykkes,
og den eksisterende PR-valideringen kjører begge uten endringer i workflowen.
Apex-kompilering og Apex-tester er org-avhengige og må kjøres mot en autentisert Salesforce-org.

### Pre-commit på Windows, Linux og macOS

Husky installeres av `prepare`-scriptet ved `npm install` eller `npm ci`.
Bruk Git (Git for Windows på Windows), Node.js som støttes av avhengighetene
(`lint-staged` 17.6.0 krever Node.js >=22.22.1), og npm. Git og Node må være
tilgjengelige i PATH også når commit startes fra VS Code.

[Hooken](.husky/pre-commit) starter [Node-scriptet](scripts/pre-commit.cjs),
som kontrollerer staged filer mot pakkemappene i `sfdx-project.json` og deretter
kjører lokalt installert `lint-staged`. Verken `jq`, `grep`, `npx` eller WSL
er nødvendig. Husky bruker fortsatt Git sin shell; LF-linjeskift for hooken
er sikret i `.gitattributes`.

Endringer i andre pakkemapper enn `force-app` blokkeres. Eksisterende unntak
med miljøvariabelen `ALLOW_PACKAGE_DIR_COMMIT=1` krever eksplisitt godkjenning
og hopper bare over pakkekontrollen, ikke formateringen. Feil i konfigurasjon,
Git eller formatering stopper commit.

Kjør isolerte hook-tester uten å endre repoets Git-indeks:

```bash
node --test scripts/tests/pre-commit.test.cjs
```

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
- [bin/COMMANDS.md](bin/COMMANDS.md) — total kommandoreferanse for lokale skript
- [bin/COMPATIBILITY.md](bin/COMPATIBILITY.md) — funksjons-, system- og testmatriser
- [scripts/README.md](scripts/README.md) — full oversikt over støtteskript

Testtilgang, testbrukere, tokens, credentials og miljøspesifikke URL-er skal håndteres i godkjent, ikke-offentlig dokumentasjon.
