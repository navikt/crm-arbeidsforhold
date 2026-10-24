# Samla kommandoreferanse for bin og scripts

Denne referansen dekkjer dei støtta inngangane, alle eigendefinerte kommandoflagg,
vanlege kombinasjonar og hjelpeprogramma i [bin](./) og [scripts](../scripts/).
Det finst ikkje ei nyttig liste over alle matematiske flaggkombinasjonar: fleire
modus er gjensidig utelukkande. Vel **éin hovudmodus**, og legg til innstillingar
for akkurat den modusen.

## Finn rett dokument

| Behov                                            | Dokument                                                                         |
| ------------------------------------------------ | -------------------------------------------------------------------------------- |
| Første oppsett, framdrift og rapportar           | [bin README](README.md)                                                          |
| Alle kommandoar og parameter                     | Denne sida                                                                       |
| Funksjonsparitet, operativsystem og verifisering | [Kompatibilitetsmatriser](COMPATIBILITY.md)                                      |
| Hooks, formatering, P360 og Apex-hjelpeskript    | [scripts README](../scripts/README.md)                                           |
| Konfigurasjonsskjema                             | [Konfigurasjonsreferanse](../tools/salesforce-project-cli/docs/configuration.md) |
| Separat, valfri `sf-project` CLI                 | [CLI README](../tools/salesforce-project-cli/README.md)                          |

## 1. Køyring, tryggleik og føresetnader

Køyr frå repository-rota med mindre noko anna er sagt. Filnamn med mellomrom
skal siterast. Bruk forward slash i PowerShell-eksempel som skal fungere på Mac.
CMD nyttar backslash. Alle `sf`-kommandoar treng rett autentisering **og** lov til
å bruke det aktuelle miljøet; autentisering er ikkje godkjenning.

- Standard scratch-org i dette repoet er `crm-arbeidsforhold`.
- Brukaren må godkjenne org-oppretting, installasjon, deploy, henting og sletting.
  Eksempela nedanfor er ikkje løyve til å utføre dei.
- `--dry-run` / `-DryRun` er **ikkje offline**. Lesing av pakkar, org og pool
  kan kontakte Salesforce. Avhengigheitssjekken skriv lokale rapportar.
- Standard oppsett kan **slette/erstatte eksisterande scratch-org**, hente frå
  pool, installere pakkar og køyre alle konfigurerte ettersteg.
- Ikkje send installasjonsnøklar som argument. Bruk godkjend løysing for secrets
  som set den konfigurerte miljøvariabelen for éi køyring, og fjern han etterpå.
- Node 22+ trengst for avhengigheitssjekken. For full npm-utviklarinstallasjon
  må Node òg oppfylle avhengigheitskrava; `lint-staged` 17.6.0 krev >=22.22.1.
- Bash-flyten krev Bash, `jq` og vanlege Unix-verktøy. PowerShell-flyten krev
  PowerShell 7 og den medfølgjande ThreadJob-modulen, ikkje Windows PowerShell 5.1.
  `sf` trengst for org/pakkelesing. `sfp` trengst berre for pool.
- Linux/macOS/Windows er ikkje identiske: les [matrisane](COMPATIBILITY.md)
  før du flyttar miljøvariablar eller legacy-kommandoar mellom system.

## 2. Vel inngang

| Terminal/system                 | Hjelp                                                              | Argumentdialekt                  |
| ------------------------------- | ------------------------------------------------------------------ | -------------------------------- |
| Bash på macOS/Linux             | `bash bin/create-scratch-org.sh --help`                            | Bash-flagg                       |
| PowerShell 7 på alle tre system | `pwsh -NoLogo -NoProfile -File ./bin/create-scratch-org.ps1 -Help` | PowerShell-parameter             |
| Windows CMD                     | `bin\create-scratch-org.bat -Help`                                 | PowerShell-parameter             |
| npm på macOS/Linux              | `npm run scratch-org -- --help`                                    | Bash-flagg                       |
| npm i Windows CMD               | `npm run scratch-org -- -Help`                                     | PowerShell-parameter             |
| npm i PowerShell 7              | `npm run scratch-org '--' -Help`                                   | PowerShell-parameter             |
| Direkte Node-launcher           | `node bin/create-scratch-org.js --help`                            | Vel dialekt etter operativsystem |

Launcherane normaliserer berre hjelpeflagga `-h`, `--help`, `-Help`, `--Help`
(og store/små bokstavar). Dei omset **ikkje** andre flagg. CMD vidaresender
argument og exitkode til PowerShell. npm/Node vel Bash på Mac/Linux og `pwsh.exe`
på Windows; at du startar npm frå PowerShell på Mac endrar ikkje det valet.
Den gamle inngangen `newScratchOrg.bat` finst ikkje i denne checkouten.

I PowerShell er `npm` ofte `npm.ps1`. PowerShell fjernar då ein usitert `--`
før npm får argumenta, slik at npm tolkar `-Help` og andre flagg som eigne
innstillingar. Siter skiljet (`'--'`), bruk `npm.cmd`, eller køyr
`.\bin\create-scratch-org.ps1` direkte.

## 3. Alle flagg i scratch-org-motorane

`<verdi>` er ein verdi du skal byte ut; parameteret er ikkje bokstavleg tekst
med vinkelparentesar. Tabellen dekkjer Bash-parseren og dei eigendefinerte
PowerShell-parametera, ikkje alle innebygde PowerShell common parameters.

### Mål, konfigurasjon og pool

| Bash                                                          | PowerShell / CMD                    | Verknad, default og eksempel                                                                                |
| ------------------------------------------------------------- | ----------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `-h`, `--help`                                                | `-Help`                             | Hjelp; ingen org-handlingar                                                                                 |
| `-a`, `--alias <alias>`                                       | `-OrgAlias <alias>`; alias `-Alias` | CLI > `ORG_ALIAS` > `defaultOrgAlias`; elles prosjektnamn ved fullt oppsett, CLI-default ved delvis køyring |
| `-d`, `--duration-days <1..30>`                               | `-DurationDays <1..30>`             | `scratchDurationDays`; generisk 14 dagar                                                                    |
| `-f`, `--definition-file <fil>`                               | `-DefinitionFile <fil>`             | `scratchDefinition`; generisk `config/project-scratch-def.json`                                             |
| `-p`, `--project-file <fil>`                                  | `-ProjectFile <fil>`                | `PROJECT_FILE`; elles `sfdx-project.json`                                                                   |
| `--config <fil>`                                              | `-ConfigFile <fil>`                 | `SF_PROJECT_CONFIG`; elles `sf-project.config.json` ved prosjektfila                                        |
| `--no-config`                                                 | `-NoConfig`                         | Ignorer prosjektkonfigurasjonen, ikkje prosjektmanifestet eller alle miljøvariablar                         |
| `--init-config`                                               | `-InitConfig`                       | Skriv effektiv konfigurasjon lokalt og avslutt; ikkje org-oppsett                                           |
| `--force`                                                     | `-Force`                            | Tillat erstatning av eksisterande konfig ved init; ikkje generell «ignorer feil»                            |
| `--use-pool`                                                  | `-UsePool`                          | `pool.use`; generisk false, repoet set true                                                                 |
| `--pool-tag <tag>`                                            | `-PoolTag <tag>`                    | `pool.tag`; generisk `dev`                                                                                  |
| `--pool-devhub <alias>`                                       | `-PoolDevHub <alias>`               | `pool.devHub` / `POOL_DEVHUB_USERNAME`; elles CLI target-dev-hub                                            |
| Ingen flagg; `FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY=false` | `-NoFallbackToCreate`               | Stopp ved tom pool i staden for direkte oppretting                                                          |

Relativ konfigurasjonsfil og konfigurerte stiar blir løyste ut frå prosjektroten.
Bruk alltid repository-rota som arbeidsmappe for eksempla; vilkårleg arbeidsmappe
er ikkje ein lovnad om full paritet for alle CLI-stiar.

### Hovudmodus og ettersteg

| Bash                            | PowerShell / CMD          | Kva skjer                                                                                         |
| ------------------------------- | ------------------------- | ------------------------------------------------------------------------------------------------- |
| Ingen modusflagg                | Ingen modusparameter      | Fullt oppsett; kan erstatte org og installere/deploye                                             |
| `--post-steps-only`             | `-PostStepsOnly`          | Bruk eksisterande org; ikkje org-oppretting eller manifestpakkeinstallasjon                       |
| `-s`, `--post-steps <liste>`    | `-PostSteps <liste>`      | Vel `deploy,permsets,data,community`, konfigurerte custom-steg, `all` eller `none`                |
| `--skip-org`                    | `-SkipOrg`                | Ikkje slett/opprett/hent org; pakkar og ettersteg kan framleis køyre                              |
| `--skip-packages`               | `-SkipPackages`           | Ikkje vanleg manifestpakkeinstallasjon; andre steg køyrer framleis                                |
| `--delete-org-only`             | `-DeleteOrgOnly`          | Forsøk å slette scratch-org og avslutt                                                            |
| `--update-packages`             | `-UpdatePackages`         | Eksisterande org; installer manglande/lågare avhengigheiter; ingen vanlege ettersteg              |
| `--package-plan`                | `-PackagePlan`            | Les installeringsstatus og versjonar; ingen pakkeinstallasjon eller fullstendigheitssertifisering |
| `--self-check`                  | `-SelfCheck`              | Diagnostikk; kan lese Salesforce. Omfanget er ikkje identisk mellom motorane                      |
| `--dry-run`                     | `-DryRun`                 | Planlegg endrande kommandoar; metadata-lesing og rapportskriving kan skje                         |
| `--full-deploy`                 | `-FullDeploy`             | Slett lokal source tracking før deploy; sender all lokal kjelde, ikkje berre spora endringar      |
| `--redeploy`                    | `-Redeploy`               | Snarveg: post-steps-only + deploy + full-deploy                                                   |
| `--permission-sets <liste>`     | `-PermissionSets <liste>` | Overstyr `permissionSets`; krev at dei namngitte setta finst                                      |
| `--dummy-data-plan <fil>`       | `-DummyDataPlan <fil>`    | Overstyr `dummyDataPlan`; dataimport og eventuelt konfigurerte dummybrukarar                      |
| `-c`, `--community-name <namn>` | `-CommunityName <namn>`   | Overstyr `communityName` ved publisering                                                          |

Stega følgjer den kanoniske rekkjefølgja **deploy → permsets → data → community →
custom-steg i konfigurasjonsrekkjefølgje**, ikkje rekkjefølgja på kommandolinja.
Manglande valfri innstilling gir varsel og hoppa-over-status, ikkje ein
påstand om at steget er utført. Eit custom-steg køyrer `executable` med
`arguments` frå prosjektroten; det er kodekøyring du må gjennomgå.

I PowerShell-terminalen kan du bruke `-PostSteps deploy,data`. Ved
`pwsh -File`/CMD er éin sitert kommaseparert streng robust:
`-PostSteps 'deploy,data'`. For Bash: `--post-steps deploy,data`.

### Pakkar, avhengigheiter og kjeldefiler

| Bash                              | PowerShell / CMD              | Kva skjer                                                                                                          |
| --------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `--install-latest`                | `-InstallLatest`              | Vel nyaste publiserte versjon, ikkje berre manifestets versjonsserie                                               |
| `--skip-version-check`            | `-SkipVersionCheck`           | Slå av varsel om nyare release; **ikkje** slå av dependency-preflight                                              |
| `--check-dependencies`            | `-CheckDependencies`          | Les rekursiv graf, skriv MD/HTML, ikkje endre manifest/org                                                         |
| `--apply-dependencies`            | `-ApplyDependencies`          | Rett manglande deklarasjonar/rekkjefølgje med backup; avslutt utan oppsett; konfliktar blir ikkje retta automatisk |
| `--dependency-report <fil.md>`    | `-DependencyReport <fil.md>`  | Vel MD-fil; HTML får same basename                                                                                 |
| `--check-versions`                | `-CheckVersions`              | Sjå nyare manifestversjonar; ikkje ein dependency-sjekk                                                            |
| `--apply-project-versions`        | `-ApplyProjectVersions`       | Skriv nyare versjonar i manifestet, med `.backup`; ikkje installer noko                                            |
| `--refresh-dependency-sources`    | `-RefreshDependencySources`   | Kan rydde lokale referansemapper og hente pakkekjelder; krev eksplisitt løyve                                      |
| `--clear-dependency-sources-only` | `-ClearDependencySourcesOnly` | Slett innhald i avhengigheitsmapper utan org-oppsett; bevar konfigurerte rotfiler                                  |
| `--keychain-service <teneste>`    | Ikkje støtta                  | macOS Bash: hent nøkkel frå denne Keychain-tenesta                                                                 |
| `--keychain-account <konto>`      | Ikkje støtta                  | macOS Bash: avgrens Keychain-oppslag til konto                                                                     |

Versjonssjekk, dependency-sjekk og installasjonsplan er tre ulike produkt:
«nyaste release» er ikkje bevis på komplett graf eller kompatibilitet.
Vanleg installasjon/oppdatering krev preflight og frys kontrollerte root-ID-ar
for den køyringa. Coverage-only, package-plan, self-check og ettersteg-only
er ikkje sertifiserte av manifestpreflight.

### Coverage

| Bash                              | PowerShell / CMD                   | Verknad                                                                         |
| --------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------- |
| `--coverage-check`                | `-CoverageCheck`                   | Eksisterande org: eventuell installasjon, deploy, Apex-testar og coverage-query |
| `--coverage-package-id <04t>`     | `-CoveragePackageId <04t>`         | Faktisk godkjend subscriber-version-ID; ingen oppdikta ID-ar                    |
| `--coverage-minimum <0..100>`     | `-MinimumCoverage <0..100>`        | `coverage.minimumPercent`; generisk 75                                          |
| `--coverage-test-class <namn>`    | `-CoverageTestClass <namn>`        | `coverage.testClass`; tom/null → alle testar                                    |
| `--coverage-class-pattern <LIKE>` | `-CoverageClassNamePattern <LIKE>` | `coverage.classNamePattern`; generisk `%`                                       |
| `--coverage-run-all`              | `-CoverageRunAll`                  | Køyr alle testar sjølv om éin klasse er konfigurert                             |
| `--coverage-skip-install`         | `-CoverageSkipInstall`             | Ikkje coverage-pakkeinstallasjon                                                |
| `--coverage-skip-deploy`          | `-CoverageSkipDeploy`              | Ikkje coverage-deploy; testar/query kontaktar framleis org                      |

Coverage er ikkje offline, og er ikkje avgrensa til «berre lesing» med mindre
du har valt bort installasjon/deploy. Coverage-aggregatet er orgdata filtrert
med LIKE-mønsteret, ikkje ein lokal coverage-rapport for Node/LWC.

### Utskrift

| Bash         | PowerShell / CMD | Verknad                                                            |
| ------------ | ---------------- | ------------------------------------------------------------------ |
| `--verbose`  | `-Verbose`       | Vis fleire vellykka CLI-detaljar; ikkje ein debugmodus for secrets |
| `--color`    | `-Color`         | Tving fargar, også ved omdirigering                                |
| `--no-color` | `-NoColor`       | Rein tekst                                                         |

Ikkje kombiner begge fargeflagga. PowerShell og Node avviser det; Bash brukar
sist sette flagg. Eksplisitt val går føre `NO_COLOR`, deretter `FORCE_COLOR`,
deretter terminaldeteksjon. `NO_COLOR` må vere ikkje-tom; `FORCE_COLOR=0`
er ikkje «tving på». Framdrift og femsekunds-heartbeat er status, ikkje ein
estimert Salesforce-prosent.

## 4. Eksempelbibliotek

### Lokalt utan autentisering

```bash
bash bin/create-scratch-org.sh --help
node bin/create-scratch-org.js --help
npm run test:node
npm run test:dependency-report
bash bin/tests/create-scratch-org.test.sh
```

```powershell
pwsh -NoLogo -NoProfile -File ./bin/create-scratch-org.ps1 -Help
npm run test:scratch-org:powershell
```

Offline-testane nyttar falske `sf`/`sfp`, ikkje dine autentiserte CLI-ar.
Ikkje start test-fixturen manuelt.

### Konfigurasjon utan org-oppsett

```bash
bash bin/create-scratch-org.sh --init-config --dry-run
# Skriv først etter gjennomgang:
bash bin/create-scratch-org.sh --init-config --force
```

```powershell
pwsh -NoProfile -File ./bin/create-scratch-org.ps1 -InitConfig -DryRun
pwsh -NoProfile -File ./bin/create-scratch-org.ps1 -InitConfig -Force
```

Generiske defaults er ikkje repository-defaults: dette repoet konfigurerer
pool og fleire ettersteg. `--no-config` endrar dermed flyten vesentleg.

### Les pakkemetadata og lag rapport

Etter godkjenning av det konkrete Dev Hub-målet:

```bash
node bin/package-dependencies.js --dev-hub '<godkjend-devhub-alias>'
node bin/package-dependencies.js --dev-hub '<godkjend-devhub-alias>' --report dependency-review.md --no-color
```

Wrapperane les `SF_TARGET_DEV_HUB` eller CLI packaging-default:

```bash
bash bin/create-scratch-org.sh --check-dependencies --dependency-report dependency-review.md
bash bin/create-scratch-org.sh --check-dependencies --install-latest
```

```powershell
pwsh -NoProfile -File ./bin/create-scratch-org.ps1 -CheckDependencies -DependencyReport dependency-review.md
pwsh -NoProfile -File ./bin/create-scratch-org.ps1 -CheckDependencies -InstallLatest
```

Same reportvalg via CMD: `bin\create-scratch-org.bat -CheckDependencies`.
Via npm: `npm run scratch-org -- --check-dependencies` på Mac/Linux,
`npm run scratch-org -- -CheckDependencies` i Windows CMD og
`npm run scratch-org '--' -CheckDependencies` i PowerShell.

Opne HTML-fila i nettlesaren, ikkje berre som ei tekstfil:

| System                     | Kommando frå rett mappe                  |
| -------------------------- | ---------------------------------------- |
| macOS, også frå PowerShell | `open ./dependency-review.html`          |
| Linux med skrivebord       | `xdg-open ./dependency-review.html`      |
| Windows PowerShell         | `Start-Process ./dependency-review.html` |
| Windows CMD                | `start "" "dependency-review.html"`      |

GitHub rendrar Mermaid i MD, men ikkje den interaktive JavaScript-fila som ei
applikasjonsside. Last ned/opne HTML lokalt. Ingen server er nødvendig.

### Rett deklarasjonar eksplisitt

Etter gjennomgang av rapporten:

```bash
bash bin/create-scratch-org.sh --apply-dependencies
git diff -- sfdx-project.json
bash bin/create-scratch-org.sh --check-dependencies
```

```powershell
pwsh -NoProfile -File ./bin/create-scratch-org.ps1 -ApplyDependencies
git diff -- sfdx-project.json
pwsh -NoProfile -File ./bin/create-scratch-org.ps1 -CheckDependencies
```

Backupen er `sfdx-project.json.dependencies.backup`. Eksisterande backup blir
ikkje overskriven. Bevar han før du ryddar. Rapporten frå apply viser funna
**før** retting; køyr sjekken igjen. Apply og dry-run kan ikkje kombinerast.

### Planlegg og utfør oppsett

Berre etter org-/pakke-/deploy-godkjenning og secrets-oppsett:

```bash
bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --dry-run
bash bin/create-scratch-org.sh --alias crm-arbeidsforhold
bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --use-pool --pool-tag dev
bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --skip-org --skip-packages --post-steps deploy
```

```powershell
pwsh -NoProfile -File ./bin/create-scratch-org.ps1 -OrgAlias crm-arbeidsforhold -DryRun
pwsh -NoProfile -File ./bin/create-scratch-org.ps1 -OrgAlias crm-arbeidsforhold
pwsh -NoProfile -File ./bin/create-scratch-org.ps1 -OrgAlias crm-arbeidsforhold -UsePool -PoolTag dev -NoFallbackToCreate
```

Bash-ekvivalenten til siste kommando brukar
`FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY=false` i miljøet. Pool Dev Hub og
packaging Dev Hub er ulike innstillingar. `--pool-devhub` vel ikkje hub for
dependency-preflight.

### Delvise køyringar og vedlikehald

| Oppgåve                                    | Bash-eksempel                                                                                                                                     | PowerShell-parametera etter `-File ./bin/create-scratch-org.ps1`                                           |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Planlegg pakkeoppdatering                  | `bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --package-plan`                                                                        | `-OrgAlias crm-arbeidsforhold -PackagePlan`                                                                |
| Oppdater til manifestversjonar             | `bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --update-packages`                                                                     | `-OrgAlias crm-arbeidsforhold -UpdatePackages`                                                             |
| Oppdater til nyaste releases               | `bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --update-packages --install-latest`                                                    | `-OrgAlias crm-arbeidsforhold -UpdatePackages -InstallLatest`                                              |
| Ettersteg utan reinstallasjon              | `bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --post-steps-only --post-steps permsets,data`                                          | `-OrgAlias crm-arbeidsforhold -PostStepsOnly -PostSteps 'permsets,data'`                                   |
| Full deploy av kjelde                      | `bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --redeploy`                                                                            | `-OrgAlias crm-arbeidsforhold -Redeploy`                                                                   |
| Versjonsforslag                            | `bash bin/create-scratch-org.sh --check-versions`                                                                                                 | `-CheckVersions`                                                                                           |
| Skriv nyare manifestversjonar              | `bash bin/create-scratch-org.sh --apply-project-versions`                                                                                         | `-ApplyProjectVersions`                                                                                    |
| Coverage utan install/deploy               | `bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --coverage-check --coverage-skip-install --coverage-skip-deploy --coverage-minimum 75` | `-OrgAlias crm-arbeidsforhold -CoverageCheck -CoverageSkipInstall -CoverageSkipDeploy -MinimumCoverage 75` |
| Coverage med alle testar                   | `bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --coverage-check --coverage-run-all --coverage-skip-install --coverage-skip-deploy`    | `-OrgAlias crm-arbeidsforhold -CoverageCheck -CoverageRunAll -CoverageSkipInstall -CoverageSkipDeploy`     |
| Slett scratch-org                          | `bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --delete-org-only`                                                                     | `-OrgAlias crm-arbeidsforhold -DeleteOrgOnly`                                                              |
| Førehandsvis lokal dependency-rydding      | `bash bin/create-scratch-org.sh --clear-dependency-sources-only --dry-run`                                                                        | `-ClearDependencySourcesOnly -DryRun`                                                                      |
| Rydd/hent dependency-kjelder under oppsett | `bash bin/create-scratch-org.sh --refresh-dependency-sources --dry-run`                                                                           | `-RefreshDependencySources -DryRun`                                                                        |

Ta bort dry-run i dei to siste radene berre etter godkjenning av
pakkeeigde mapper og eventuelle org-operasjonar. Bevaringslista er ikkje backup
av alt innhaldet. `.forceignore` blir mellombels flytta ved henting.
Ikkje køyr fleire vedlikehalds-/apply-prosessar mot same manifest samtidig.

## 5. Direkte dependency-helper

[package-dependencies.js](package-dependencies.js) er ein sjølvstendig Node-CLI.

| Flagg                   | Default / åtferd                                                                      |
| ----------------------- | ------------------------------------------------------------------------------------- |
| `--project-file <fil>`  | `sfdx-project.json` relativt til arbeidsmappe                                         |
| `--dev-hub <alias>`     | `SF_TARGET_DEV_HUB`, elles CLI packaging-default                                      |
| `--latest`              | Vel nyaste publiserte root-versjon; elles manifestets eksakte/build-symbolske versjon |
| `--dry-run`             | Metadata og rapportar blir framleis lesne/skrive; ikkje manifestendring               |
| `--apply`               | Rett manglande deklarasjonar og rekkjefølgje; aldri automatisk konfliktløysing        |
| `--report <fil.md>`     | `package-dependencies-report.md` ved prosjektfila; HTML same basename                 |
| `--plan-file <fil>`     | Intern eksklusiv JSON-versjonsplan ved gyldig graf; må ikkje finnast frå før          |
| `--color`, `--no-color` | Fargepolicy som over; begge samtidig er feil                                          |

Helperen har **ikkje** `--help`; denne tabellen er kommandoreferansen.
Ukjende eller ufullstendige flagg feilar. Metadata-lesing er
`sf package version list --released`, `report --verbose` og ved behov
`sf package list`, alle med JSON. Windows-CLI-broen krev `pwsh.exe`.
Ingen `sfp`, `jq`, installasjonsnøkkel eller fungerande scratch-org trengst for
denne reine metadata-sjekken, men Dev Hub må sjå alle nødvendige metadata.

Exit `0` betyr gyldig graf eller fullført eksplisitt apply; `1` betyr funn,
lesefeil, ugyldig input eller rapportfeil. Detaljen i utskrifta skil desse.
Forskjellig subscriber-version-ID blir handsama konservativt som konflikt,
også når den valde versjonen er høgare. Slike greiner blir ikkje ekspanderte.
Ein nullteljar for manglande pakkar er då **ikkje** komplettheitsbevis.

Rapportfilene blir oppdaterte etter fullført grafkontroll, ikkje etter kvar
metadata-lesing. Ved lesefeil blir førre rapport liggjande: sjekk tidsstempelet.
Ved feil medan dei to rapportane blir skrivne kan éi vere nyare enn den andre.
Sjekken feilar då før installasjon/oppsett held fram. Rapportskriving er ikkje
ein atomisk transaksjon over begge filer.

## 6. Legacy og interne modular

| Fil                                                                | Bruk og avgrensing                                                                                                                                                                                                                               |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [check-sfdx-versions.js](check-sfdx-versions.js)                   | Legacy: `node bin/check-sfdx-versions.js`; les alltid manifestet ved repo-rota, ikkje `--project-file`. Spør interaktivt om `YES` før oppdatering og lagar/erstattar `.backup`. Ingen eigne CLI-flagg. Bruk heller motorens check/apply-versions |
| [post-package-coverage-check.ps1](post-package-coverage-check.ps1) | Legacy coverage; full parameterreferanse nedanfor. Bruk heller `-CoverageCheck`                                                                                                                                                                  |
| [package-dependency-report.js](package-dependency-report.js)       | Intern rein HTML-generator, importert av checker; ingen direkte CLI, ingen Salesforce-tilgang. Native SVG + lokal JS, ikkje CDN                                                                                                                  |
| [create-scratch-org.js](create-scratch-org.js)                     | Plattform-launcher og eksportert `getLauncher`; ingen ekstra oppsettlogikk                                                                                                                                                                       |

### Viktige legacy-avvik

Legacy-versjonsskriptet ventar portabelt mellom timeout-retry på alle system.
Per-pakke-feil blir
skrivne ut, men kan likevel ende i «all packages up to date» og exit 0.
Det er **ikkje** ein påliteleg valideringsgate. Det samanliknar tre versjonsledd,
vel siste release etter `CreatedDate` og skriv `.LATEST`; det sjekkar ikkje grafen.
Ikkje stol på siste suksesslinje utan å lese alle pakkeresultata.

Legacy-coverage-scriptet sender kvar parameter som eitt native argument til `sf`
og maskerer `-InstallationKey` i kommandoutskrifta. Det er dekt av
[post-package-coverage-check.Tests.ps1](tests/post-package-coverage-check.Tests.ps1).

| Legacy-parameter   | Default og funksjon                                  |
| ------------------ | ---------------------------------------------------- |
| `-TargetOrg`       | `crm-arbeidsforhold`                                 |
| `-PackageId`       | Ingen; installer berre når sett og ikkje SkipInstall |
| `-InstallationKey` | Ingen; utrygg logging i legacy, ikkje tilrådd        |
| `-MinCoverage`     | 75                                                   |
| `-SkipInstall`     | Ikkje installer                                      |
| `-SkipDeploy`      | Ikkje deploy `force-app`                             |
| `-TestRunAll`      | Alle Apex-testar, med async-fallback ved feil        |
| `-TestClass`       | `AAREG_ApplicationDecisionControllerTest`            |

Avgrensa legacy-eksempel, berre etter godkjenning av Apex-køyringa:

```powershell
pwsh -NoProfile -File ./bin/post-package-coverage-check.ps1 -TargetOrg crm-arbeidsforhold -SkipInstall -SkipDeploy -MinCoverage 75
```

Coverage under terskel gir legacy exit `2`. Async-fallback kan fortsetje etter
testresultatfeil og bruke tidlegare coverage-data; ei grøn terskelutskrift er
ikkje åleine bevis på vellykka ny testkøyring.

## 7. Miljø- og konfigurasjonsreferanse

Ikkje gå ut frå at alle Bash-miljøvariablar er PowerShell-parameter. Denne lista
er medvite delt. Bruk CLI og konfigurasjonsfila for mest mogleg paritet.

### Felles innstillingar med faktisk miljølesing

| Miljøvariabel                              | Verknad / konfigurasjonsfelt                                                       |
| ------------------------------------------ | ---------------------------------------------------------------------------------- |
| `ORG_ALIAS`                                | `defaultOrgAlias`                                                                  |
| `PROJECT_FILE`                             | Manifestfil                                                                        |
| `SF_PROJECT_CONFIG`                        | Konfigurasjonsfil                                                                  |
| `DURATION_DAYS`                            | `scratchDurationDays`                                                              |
| `SCRATCH_DEF_FILE`                         | `scratchDefinition`                                                                |
| `COMMUNITY_NAME`                           | `communityName`                                                                    |
| `DUMMY_DATA_PLAN`                          | `dummyDataPlan`                                                                    |
| `PERMISSION_SETS`                          | `permissionSets`; kommaseparert                                                    |
| `POST_STEPS`                               | `postSteps`; kommaseparert                                                         |
| `USE_POOL`                                 | `pool.use`; `true` / `false`                                                       |
| `POOL_TAG`                                 | `pool.tag`                                                                         |
| `POOL_DEVHUB_USERNAME`                     | `pool.devHub`                                                                      |
| `FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY` | `pool.fallbackToCreate`; PowerShell har òg `-NoFallbackToCreate`                   |
| `PACKAGE_INSTALL_KEY_ENV_VAR`              | Namnet på nøkkelvariabelen; `packageInstallKeyEnvironmentVariable`                 |
| `PACKAGE_INSTALL_KEY`                      | Nøkkel/fallback; ikkje logg innhaldet                                              |
| `PACKAGES_NOT_REQUIRING_INSTALL_KEY`       | Namneliste som overstyrer behov for nøkkel; sjå òg `packageKeyConfig` i manifestet |
| `PACKAGE_WAIT_MINUTES`                     | CLI-venting på installasjon; generisk 10                                           |
| `PACKAGE_INSTALL_MAX_ATTEMPTS`             | Maks forsøk ved kjende transiente installasjonsfeil; generisk 3                    |
| `PACKAGE_INSTALL_RETRY_DELAY_SECONDS`      | Pause mellom forsøk; generisk 5                                                    |
| `INSTALL_LATEST_PACKAGES`                  | Vel nyaste release når `true`                                                      |
| `VERIFY_PACKAGE_VERSIONS`                  | `false` slår av nyare-release-varsel, ikkje preflight                              |
| `DUMMY_USER_FILE`                          | `dummyUsers.file`; PowerShell overstyrer berre eksisterande dummyUsers-blokk       |
| `DUMMY_USER_PROFILE_NAME`                  | `dummyUsers.profileName`; same PowerShell-avgrensing                               |
| `DUMMY_USER_PERMSET_ASSIGNMENTS`           | `PermA,PermB:user1,user2;PermC:user3`; ikkje bruk ekte persondata i eksempel       |
| `COVERAGE_MINIMUM`                         | `coverage.minimumPercent`                                                          |
| `COVERAGE_TEST_CLASS`                      | `coverage.testClass`                                                               |
| `VERBOSE`                                  | `true` aktiverer detaljar                                                          |
| `NO_COLOR`, `FORCE_COLOR`                  | Fargepolicy                                                                        |
| `SF_TARGET_DEV_HUB`                        | Node-checkerens packaging-hub; vel ikkje nødvendigvis pool-hub                     |

`SF_*`-innstillingar som CLI-en sjølv les kan påverke kommandokøyringa.
`CI`, `TERM`, `LANG`, `LC_ALL` og `LC_CTYPE` påverkar interaktivitet/fargar/ikon;
`TMPDIR` påverkar midlertidige filer. Desse er ikkje produktkonfigurasjon.

### Bash-spesifikke miljøvariablar

| Variabel                                                                                                          | Verknad                                                                                     |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `PACKAGE_INSTALL_KEYCHAIN_SERVICE`, `PACKAGE_INSTALL_KEYCHAIN_ACCOUNT`                                            | macOS Keychain-oppslag                                                                      |
| `PRESERVE_ROOT_FILES`                                                                                             | Rootfiler som blir bevarte ved lokal dependency-rydding                                     |
| `RUN_ORG_CREATE`, `RUN_PACKAGES`                                                                                  | Interne/eldre brytarar; bruk heller `--skip-org` / `--skip-packages`                        |
| `DELETE_ORG_ONLY`, `UPDATE_PACKAGES_ONLY`, `POST_STEPS_ONLY_MODE`                                                 | Modus; bruk heller CLI                                                                      |
| `SELF_CHECK_ONLY`, `DRY_RUN`, `PACKAGE_PLAN_ONLY`                                                                 | Modus; PowerShell les ikkje desse som modusbrytarar                                         |
| `FULL_DEPLOY`                                                                                                     | Full tracking-reset før deploy                                                              |
| `CHECK_PROJECT_VERSIONS_ONLY`, `APPLY_PROJECT_VERSIONS`                                                           | Manifestversjonsmodus                                                                       |
| `COVERAGE_CHECK_ONLY`, `COVERAGE_PACKAGE_ID`, `COVERAGE_RUN_ALL`, `COVERAGE_SKIP_INSTALL`, `COVERAGE_SKIP_DEPLOY` | Coverage-modus og brytarar                                                                  |
| `COVERAGE_CLASS_PATTERN`                                                                                          | Bash LIKE-filter; PowerShell les i staden `COVERAGE_CLASS_NAME_PATTERN`                     |
| `REFRESH_DEPENDENCY_SOURCES`, `CLEAR_DEPENDENCY_SOURCES_ONLY`                                                     | Lokal rydding/henting                                                                       |
| `ORG_AVAILABLE_FOR_READ`                                                                                          | Intern kontroll av lesing under planlagt org-oppretting; ikkje ein normal brukarinnstilling |

PowerShell krev eigne parameter for dry-run/full-deploy/coverage-brytarar.
Til dømes betyr **ikkje** `DRY_RUN=true` at PowerShell er trygg å køyre utan
`-DryRun`. Ikkje bruk miljøoppsett frå Bash ukritisk.

### Konfigurasjonsskjema og defaultar

| Felt                                                                               | Generisk default / meining                                                    |
| ---------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `schemaVersion`                                                                    | 1                                                                             |
| `defaultOrgAlias`                                                                  | Mappenamn ved fullt oppsett når ikkje sett                                    |
| `scratchDefinition`, `scratchDurationDays`                                         | `config/project-scratch-def.json`, 14                                         |
| `postSteps`                                                                        | `["deploy"]`; tom liste betyr ingen                                           |
| `permissionSets`                                                                   | Tom liste                                                                     |
| `dummyDataPlan`, `communityName`                                                   | Ingen; steg kan bli hoppa over                                                |
| `customPostSteps`                                                                  | Tom liste; unike namn, executable og argument-array                           |
| `pool.use`, `pool.tag`, `pool.devHub`, `pool.fallbackToCreate`                     | false, `dev`, CLI-default, true                                               |
| `packageInstallKeyEnvironmentVariable`                                             | `PACKAGE_INSTALL_KEY`                                                         |
| `coverage.minimumPercent`, `coverage.testClass`, `coverage.classNamePattern`       | 75, ingen/alle testar, `%`                                                    |
| `dummyUsers.file`, `profileName`, `profileAssignments`, `permissionSetAssignments` | Valfri brukarimport; Standard User fallback, valfrie mappings                 |
| `dependencySourcePolicy.preserveRootFiles`                                         | `["README.md"]`; tom liste betyr bevar ingenting                              |
| `dependencySourcePolicy.requireLocalDirectories`                                   | true; manglande lokal dependency-mappe feilar                                 |
| `commandTimeouts.readMs`, `commandTimeouts.mutationMs`                             | Skjema blir validert; motorane brukar ikkje desse til generell prosesstimeout |

Repoets konkrete verdiar ligg i [sf-project.config.json](../sf-project.config.json).
Ikkje kopier brukarnamn, secrets eller miljødata derfrå til eksempel eller loggar.
`packageAliases`, `packageDirectories[].dependencies` og `packageKeyConfig`
ligg i [sfdx-project.json](../sfdx-project.json), ikkje i configfila.

## 8. Inventar for tests og støttefiler

| Fil                                                                                          | Køyring / ansvar                                                                                                                                |
| -------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| [create-scratch-org.test.sh](tests/create-scratch-org.test.sh)                               | `bash bin/tests/create-scratch-org.test.sh`; falsk CLI, prosjekt-/modus-/pakke-/rapportkontraktar; brukar `jq`                                  |
| [create-scratch-org.Tests.ps1](tests/create-scratch-org.Tests.ps1)                           | `pwsh -NoProfile -File ./bin/tests/create-scratch-org.Tests.ps1`; Node + pwsh; `-RequireWindows` krev ekte Windows og ingen obligatoriske skips |
| [create-scratch-org-launcher.test.js](tests/create-scratch-org-launcher.test.js)             | `node --test bin/tests/create-scratch-org-launcher.test.js`; launcher-val, argument, spawn-feil og exitkode                                     |
| [check-sfdx-versions.test.js](tests/check-sfdx-versions.test.js)                             | `node --test bin/tests/check-sfdx-versions.test.js`; versjonssamanlikning, retry, YES/NO og backup med falsk CLI                                |
| [post-package-coverage-check.Tests.ps1](tests/post-package-coverage-check.Tests.ps1)         | `pwsh -NoProfile -File ./bin/tests/post-package-coverage-check.Tests.ps1`; legacy-coverage, quoting, nøkkelmaskering og exitkodar               |
| [post-package-coverage-cli.ps1](tests/fixtures/post-package-coverage-cli.ps1)                | Intern fake `sf` for legacy-coverage-testen; styrt av `COVERAGE_TEST_*`                                                                         |
| [package-dependencies.test.js](tests/package-dependencies.test.js)                           | `node --test bin/tests/package-dependencies.test.js`; graf, CLI, rapportskriving og feil                                                        |
| [package-dependency-report.dom.test.cjs](tests/package-dependency-report.dom.test.cjs)       | `npm run test:dependency-report`; faktisk generert JS køyrer i Jest/jsdom                                                                       |
| [package-dependency-report.jest.config.cjs](tests/package-dependency-report.jest.config.cjs) | Isolert Jest-oppsett for DOM-testane; ikkje ein brukar-CLI                                                                                      |
| [scratch-cli.ps1](tests/fixtures/scratch-cli.ps1)                                            | Intern fake sf/sfp; krev `SCRATCH_TEST_RULES`, `SCRATCH_TEST_LOG`; uventa kall gir exit 97                                                      |
| [README.md](README.md), denne sida og [COMPATIBILITY.md](COMPATIBILITY.md)                   | Inngang, kommandoreferanse og matriser; ikkje executable                                                                                        |

Alle filer under `scripts/`, inkludert Apex og tests, er inventarførte med eigne
kommandoar i [scripts README](../scripts/README.md). Root npm-scriptet
`test:p360:mock` viser dit, ikkje til ei ikkje-eksisterande bin/tests-fil.

## 9. Feilsøking og exitstatus

| Symptom                                      | Tiltak / avgrensing                                                                                        |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| «Still running»                              | Sjå aktivt pakkenamn/metadata-ID og ventetid; ikkje ein garantert tidsgrense                               |
| Ingen Dev Hub-autorisering                   | Bruk godkjend autentisert terminal for det konkrete målet; ikkje bytt automatisk til anna org              |
| Manglande metadatarettar                     | Kontrollen kan ikkje sertifisere grafen; lesetilgang til alle versjonar er nødvendig                       |
| VERSION DIFF                                 | Sjå krav/vald versjon og innkomande piler; ikkje nedgrader for å få grøn farge                             |
| Rapport frå førre køyring                    | Sjekk tidsstempelet; lesefeil oppdaterer ikkje rapporten                                                   |
| HTML som tekst i VS Code/GitHub              | Opne den lokale fila i ein nettlesar                                                                       |
| Blank Mermaid-vising                         | Visaren må støtte Mermaid; HTML har ingen slik ekstern runtime-føresetnad                                  |
| Rapportskriving feilar                       | Sjekk mappe/skrivetilgang; inga automatisk oppretting av foreldremapper; ikkje bruk symlink som rapportmål |
| Backup finst frå før                         | Bevar/flytt backup etter gjennomgang før ny dependency-apply; ikkje overskriv automatisk                   |
| Manglande PowerShell                         | Installer godkjend PowerShell 7 og gjer `pwsh.exe` tilgjengeleg på Windows PATH                            |
| «No changes to deploy», men metadata manglar | Vurder godkjend `--redeploy` / `-Redeploy`; vanleg deploy brukar tracking                                  |
| Jest/jsdom manglar                           | Installer prosjektets devDependencies med vanleg npm-flyt; ikkje legg til ein ny renderer                  |

PowerShell-motoren returnerer 0 ved fullført modus og 1 ved fanga feil.
Bash returnerer ikkje alltid same numeriske kode (til dømes fleire inputfeil
brukar 2); sjekk **0 mot ikkje-0**, og les resultatet. Sletteforsøk kan vere
tolererte; ein exit 0 er ikkje universelt bevis på at orgen faktisk blei sletta.
Testane feilar ved mislukka assertions; Windows-skip på Mac er ikkje
Windows-verifisering. HTML DOM-testar er ikkje ein ekte browser-layouttest.
