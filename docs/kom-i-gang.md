# Kom i gang med utvikling

Denne guiden tar deg fra lokale verktøy til en første endring i
`crm-arbeidsforhold`. Kjør kommandoene fra prosjektroten hvis ikke annet er angitt.

1. [Installer verktøy](#1-installer-verktøy)
2. [Klon og kontroller prosjektet lokalt](#2-klon-og-kontroller-prosjektet-lokalt)
3. [Avklar Salesforce-miljø og scratch-org](#3-avklar-salesforce-miljø-og-scratch-org)
4. [Gjør en endring og opprett PR](#4-gjør-en-endring-og-opprett-pr)
5. [Hvis noe stopper](#5-hvis-noe-stopper)

## 1. Installer verktøy

Bruk Navs godkjente installasjonskanaler. Installer verktøyene for din plattform,
og kontroller at de også finnes i VS Code-terminalens PATH.

| Verktøy                                                                                                         | Bruk                                                                                                                                                                                                   |
| --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [Git](https://git-scm.com/downloads)                                                                            | Versjonskontroll; Git for Windows gir også shellen Husky bruker                                                                                                                                        |
| [Node.js og npm](https://nodejs.org/en/download)                                                                | Bruk Node.js 22 LTS, minst 22.22.1, for rotprosjektets avhengigheter                                                                                                                                   |
| [Visual Studio Code](https://code.visualstudio.com/)                                                            | Åpne repositoryroten, der `sfdx-project.json` ligger                                                                                                                                                   |
| [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode) | Apex- og metadataarbeid i VS Code                                                                                                                                                                      |
| [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli)                                          | `sf` for org-avhengige oppgaver                                                                                                                                                                        |
| Java                                                                                                            | Apex Language Server krever en kompatibel JDK; følg [Salesforces Java-veiledning](https://developer.salesforce.com/docs/platform/sfvscode-extensions/guide/java-setup.html) og Navs godkjente JDK-valg |

<details>
<summary><strong>Mac (macOS): Bash, jq og eventuell Keychain</strong></summary>

Scratch-org-skriptene bruker Bash. Installer `jq` gjennom en godkjent kanal.
Systemets Bash 3.2 har egen offline-regresjon i CI; nyere Bash er ikke et krav.
Installasjonsnøkkelen kan hentes fra macOS Keychain etter konfigurering.
Se [plattformmatrisen](../bin/COMPATIBILITY.md) for begrensninger.

```bash
bash --version
jq --version
```

</details>

<details>
<summary><strong>Linux: Bash og jq</strong></summary>

Scratch-org-skriptene bruker Bash og krever `jq`.
Installasjonsnøkkelen leveres gjennom den konfigurerte miljøvariabelen;
macOS Keychain-oppslaget er ikke tilgjengelig på Linux.

```bash
bash --version
jq --version
```

</details>

<details>
<summary><strong>Windows: PowerShell 7 LTS og Git for Windows</strong></summary>

Bruk PowerShell 7 LTS (`pwsh`), ikke Windows PowerShell 5.1 (`powershell`).
CMD-launcheren krever også `pwsh.exe`; WSL og Git Bash er ikke den native
Windows-flyten. `jq` kreves ikke av PowerShell-motoren.

```powershell
pwsh -NoLogo -NoProfile -Command '$PSVersionTable'
git --version
```

Åpne et nytt terminalvindu etter installasjon. Ikke omgå execution policy,
AppLocker eller WDAC; avklar begrensninger gjennom godkjent kanal.

</details>

Disse versjonskontrollene kontakter ikke Salesforce:

```text
git --version
node --version
npm --version
sf --version
java -version
```

## 2. Klon og kontroller prosjektet lokalt

Kommandoene er like i Bash, PowerShell og CMD:

```text
git clone https://github.com/navikt/crm-arbeidsforhold.git
cd crm-arbeidsforhold
npm ci
npm run test:node
```

Åpne mappen med **File → Open Folder** i VS Code, eller `code .` hvis CLI-en
er installert. `npm ci` bruker lockfila og installerer Husky-hooken.
Det oppretter ikke org eller installerer Salesforce-pakkeavhengigheter.

Du kan nå lese og endre kode, kjøre lokale tester og formatere filer.
Ingen Salesforce-innlogging kreves for [de lokale kontrollene](../README.md#lokal-validering).

## 3. Avklar Salesforce-miljø og scratch-org

Avklar mål, tilgang og handlinger før org-oppsett. Før hver agentkommando som
aksesserer et org, skal brukeren bekrefte eksakt ikke-produksjonsmål og handling
på nytt, også for standard-scratch-orget `crm-arbeidsforhold` og lesekommandoer.
Andre ikke-produksjonsorg krever også en teknisk begrunnelse.
Et autentisert alias eller tidligere godkjenning er ikke tillatelse til neste operasjon.
Agenter skal aldri aksessere produksjon, heller ikke en produksjonstilknyttet
Dev Hub. Avtal menneskelig utføring med [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f) hvis dette er nødvendig.

Før oppsett:

1. Les [sfdx-project.json](../sfdx-project.json) og
   [sf-project.config.json](../sf-project.config.json).
2. Avklar hvilken Dev Hub og hvilke org-operasjoner som er godkjent.
3. Avklar sikker tilgang til installasjonsnøkkelen. Ikke skriv den i kommandoer,
   dokumentasjon eller konfigurasjonsfiler.
4. Avklar pool-bruk. Repoet har pool aktivert; det krever `sfp`.
5. Kontroller valgte post-steg: oppsett kan erstatte eksisterende scratch-org,
   installere pakker, deploye metadata og endre data eller tilgang.

Velg plattform nedenfor. **Hjelp er offline. Avhengighetskontroll og dry-run kan
kontakte Salesforce og skrive lokale rapporter.** Fullt oppsett endrer org-et.
Eksemplene er ikke dokumentasjon på gjennomførte eller godkjente org-operasjoner.
Ved agentkjøring må hver kommando i eksemplene avklares separat før den kjøres.

<details>
<summary><strong>Mac (macOS)</strong></summary>

Offline hjelp:

```bash
npm run scratch-org -- --help
```

Etter godkjenning av mål og handlinger:

```bash
npm run scratch-org -- --check-dependencies
npm run scratch-org -- --dry-run
npm run scratch-org
```

</details>

<details>
<summary><strong>Linux</strong></summary>

Offline hjelp:

```bash
npm run scratch-org -- --help
```

Etter godkjenning av mål og handlinger:

```bash
npm run scratch-org -- --check-dependencies
npm run scratch-org -- --dry-run
npm run scratch-org
```

</details>

<details>
<summary><strong>Windows – PowerShell 7</strong></summary>

Offline hjelp; merk det siterte npm-skilletegnet:

```powershell
npm run scratch-org '--' -Help
```

Etter godkjenning av mål og handlinger:

```powershell
npm run scratch-org '--' -CheckDependencies
npm run scratch-org '--' -DryRun
npm run scratch-org
```

Direkte PowerShell-alternativ for hjelp:

```powershell
pwsh -NoProfile -File .\bin\create-scratch-org.ps1 -Help
```

</details>

<details>
<summary><strong>Windows – CMD</strong></summary>

Offline hjelp:

```cmd
bin\create-scratch-org.bat -Help
```

Etter godkjenning av mål og handlinger:

```cmd
bin\create-scratch-org.bat -CheckDependencies
bin\create-scratch-org.bat -DryRun
bin\create-scratch-org.bat
```

CMD-filen starter PowerShell 7 og viderefører argumenter og exitkode.

</details>

Ikke bruk GitHub-helperen for scratch-org før de kjente feilene i den delte
implementasjonen er løst. Se [workflowbegrensningene](operations/workflows.md#kjente-begrensninger).
Detaljer om flagg, pool, pakker og post-steg ligger i
[skriptguiden](../bin/README.md) og [kommandoreferansen](../bin/COMMANDS.md).
Den valgfrie Salesforce Project CLI-en kreves ikke.

## 4. Gjør en endring og opprett PR

1. Lag en egen branch fra oppdatert `main`.
2. Finn nærmeste implementasjon og tester. Les
   [utviklingsstandardene](utviklingsstandarder.md) før du velger nytt mønster.
3. Endre produktkode i `force-app/`; ikke endre pakkeeide referansemapper uten godkjenning.
4. Ved ny atferd eller feilretting: skriv en fokusert test, observer feil, gjør
   minste retting og kjør testen på nytt.
5. Kjør relevant lokal validering. Apex-kompilering og Apex-tester er egne,
   org-avhengige kontroller; en grønn Jest-test beviser ikke at Apex virker.
6. Oppdater direkte berørt dokumentasjon og opprett PR med omfang, kontroller,
   resultater og eventuelle blokkeringer. Følg repoets PR-mal.

Git- og Node-verktøyene må være tilgjengelige også når commit startes fra VS Code.
Se [pre-commit-guiden](../scripts/README.md#pre-commit-og-formatering) hvis hooken stopper.

## 5. Hvis noe stopper

| Problem                               | Neste steg                                                                                                                                  |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `node`, `sf` eller `pwsh` finnes ikke | Kontroller installasjon og PATH; åpne terminalen og VS Code på nytt                                                                         |
| `npm ci` avviser Node-versjonen       | Bruk Node 22 LTS som oppfyller minsteversjonen; ikke ignorer engine-krav                                                                    |
| PowerShell 5.1 blir brukt             | Start `pwsh` eller en PowerShell 7-terminal; ikke bruk policy-bypass                                                                        |
| Bash-oppsettet finner ikke `jq`       | Installer `jq` via godkjent kanal; Windows-motoren krever det ikke                                                                          |
| Preflight feiler                      | Les rapporten og [forklaringen av PASS/FAIL og autofiks](../bin/README.md#complete-package-dependency-preflight); ikke hopp over kontrollen |
| Scratch-org-/pakkeoppsett feiler      | Se [feilsøking og exitstatus](../bin/COMMANDS.md#9-feilsøking-og-exitstatus); ikke start en ny org-operasjon uten avklart mål               |
| Behov for plattformverifisering       | Bruk [testmatrisen](../bin/COMPATIBILITY.md); tester på Mac beviser ikke Windows-entrypoints                                                |

Offline skripttester, i tillegg til `npm run test:node`:

| Plattform                  | Kommando                                    |
| -------------------------- | ------------------------------------------- |
| Mac/Linux med Bash og `jq` | `bash bin/tests/create-scratch-org.test.sh` |
| PowerShell 7 LTS           | `npm run test:scratch-org:powershell`       |

PowerShell-testene kan kjøres på Mac med `pwsh`, men Windows-only CMD-/npm-tester
krever Windows. Rapportens interaksjonstester kjøres separat med
`npm run test:dependency-report`.
