# Verktøy i `scripts/`

Dette dokumentet dekkjer alle filer under `scripts/`, inkludert anonyme Apex-filer
og testane for verktøya. Kommandoane er meinte køyrde frå prosjektrota med mindre
anna er sagt. Les åtvaringane før du køyrer Salesforce-kommandoar: to av Apex-filene
endrar org-data eller innstillingar, og røykprøva brukar eit fast org-alias.

## Oversikt

| Fil                                                                | Føremål                                                                                                               | Salesforce-org                       |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| [`pre-commit.cjs`](pre-commit.cjs)                                 | Kontrollerer staged filer mot pakkemappene i `sfdx-project.json`, og køyrer deretter lokalt installert `lint-staged`. | Nei                                  |
| [`prettier-staged.cjs`](prettier-staged.cjs)                       | Formaterer filer frå `lint-staged`, eller kontrollerer dei med `--check`.                                             | Nei                                  |
| [`ci-changes.cjs`](ci-changes.cjs)                                 | Klassifiserer Git-diffen for behovsstyrt Salesforce-/LWC-validering og skriv GitHub Actions-output.                   | Nei                                  |
| [`tests/ci-changes.test.cjs`](tests/ci-changes.test.cjs)           | Testar endringsfilter, base-konfigurasjon, filnamn, slettingar og omdøypingar.                                        | Nei                                  |
| [`tests/pre-commit.test.cjs`](tests/pre-commit.test.cjs)           | Node-testar for pre-commit-kontrollen og Husky-hooken.                                                                | Nei                                  |
| [`tests/prettier-staged.test.cjs`](tests/prettier-staged.test.cjs) | Node-testar for `prettier-staged.cjs`; blir hoppa over utan `npm ci`, men køyrer i PR-LWC-workflowen.                 | Nei                                  |
| [`p360-mock-smoke.sh`](p360-mock-smoke.sh)                         | Konfigurerer mock-transport for ein P360-røykprøve og kontrollerer oppretta arkivjobbar.                              | Ja; aliaset er fast                  |
| [`apex/activateMock.apex`](apex/activateMock.apex)                 | Slår på mock-responsar for kvar Salesforce-profil.                                                                    | Ja; endrar innstillingar             |
| [`apex/p360MockArchiveFlow.apex`](apex/p360MockArchiveFlow.apex)   | Opprettar testdata og startar P360-arkivflyten med mock-transport.                                                    | Ja; endrar org-data og innstillingar |

Det finst ikkje eitt felles grensesnitt for alle filene: Node-verktøya tek
kommandolinjeargument, shell-røykprøva har eit fast målorg, medan Apex-filene blir
køyrde som anonym Apex gjennom Salesforce CLI.

## Pre-commit og formatering

### `pre-commit.cjs`

**Bruk**

Hooken [`.husky/pre-commit`](../.husky/pre-commit) startar dette verktøyet:

```sh
node scripts/pre-commit.cjs
```

Køyr frå prosjektrota. Skriptet tek ikkje eigne kommandolinjeflagg.

**Krav og konfigurasjon**

- Node.js, Git, prosjektfila `sfdx-project.json` og installerte npm-avhengigheiter.
- `lint-staged` må vere installert lokalt; skriptet startar det lokale CLI-et
  direkte med den aktive Node-prosessen.
- `sfdx-project.json` må ha `packageDirectories` som ei liste. Kvart element må
  ha ein relativ `path` innanfor repoet.
- `ALLOW_PACKAGE_DIR_COMMIT=1` er det einaste miljøunntaket. Det hoppar over
  kontrollen av pakkemapper, men køyrer framleis `lint-staged`. Bruk det berre
  ved eit eksplisitt godkjent unntak.

**Verknad og resultat**

Skriptet les staged filnamn frå Git-indeksen (tilføya, kopierte, endra og
omdøypte filer) og blokkerer filer i kvar konfigurert pakkemappe utanom
`force-app`. Slettingar åleine er ikkje med i denne blokkeringa. Stiar i
konfigurasjonen får normaliserte skråstrekar og blir behandla som mappenamn, ikkje
regulære uttrykk eller delstrengar. Deretter køyrer skriptet `lint-staged`, som
kan formatere staged filer og dermed endre arbeidskopien.

- Exitkode `0`: pakkekontrollen (eller godkjent unntak) og `lint-staged` lukkast.
- Ikkje-null exitkode: policybrot, ugyldig/manglande konfigurasjon, Git-feil,
  manglande lokal `lint-staged`-installasjon eller formateringsfeil.
- Ved blokkering viser feilmeldinga staged filer og eit døme på å ta dei ut av
  staging. Unntaket er ikkje automatisk og skal ikkje brukast for å omgå
  pakkeeigarskap.

Det er ikkje nødvendig med `jq`, `grep`, `npx`, WSL eller Salesforce CLI.
Husky-hooken er eit `sh`-skript; på Windows blir han køyrd gjennom Git for
Windows si shell-integrering, ikkje direkte som PowerShell.

### `prettier-staged.cjs`

Skriptet blir kalla av `lint-staged` for filtypane som er konfigurerte i
`package.json`. Det kan òg køyrast direkte:

```sh
node scripts/prettier-staged.cjs <fil> [fil ...]
node scripts/prettier-staged.cjs --check <fil> [fil ...]
```

Eksempel på eksisterande dokument, først berre kontroll og deretter eksplisitt
formatering av arbeidskopien:

```sh
node scripts/prettier-staged.cjs --check README.md bin/README.md
node scripts/prettier-staged.cjs README.md bin/README.md
node --test scripts/tests/prettier-staged.test.cjs
```

Køyr frå prosjektrota. `--check` kan stå kvar som eit argument. Utan dette flagget
formatert innhald blir skrive til arbeidskopien; med `--check` blir fila berre
kontrollert. Skriptet leitar etter Prettier-konfigurasjon og brukar
`.gitignore` og `.prettierignore` når det vurderer om fila skal handsamast.
Ignorerte filer og filer utan ein utleidd Prettier-parser blir hoppa over.

Berre skilnaden i avsluttande linjeskift blir godteken utan skriving. Med `--check`
gir andre formateringsskilnader exitkode `1` og ei melding om fila ville blitt
formatert. Feil ved lesing, konfigurasjon eller formatering blir rapporterte per
fil og gir samla exitkode `1`. Ingen filer å handsame gir ingen endring.
Avhengigheitene `prettier` og `@prettier/plugin-xml` er del av prosjektet sine
npm-avhengigheiter.

### `tests/pre-commit.test.cjs`

Køyr berre denne testsamlinga:

```sh
node --test scripts/tests/pre-commit.test.cjs
```

Eller køyr alle Node-testane frå `package.json`:

```sh
npm run test:node
```

Testane nyttar `node:test` og lagar eit isolert, mellombels Git-repo for kvar
fixture. Dei testar tillatne hovudpakke-/dokumentasjonsfiler, blokkering av
pakke-/referansefiler, filnamn med mellomrom og linjeskift (linjeskift-tilfellet
er hoppa over på Windows), mappenamn med liknande prefiks, det eksplisitte
miljøunntaket, vidareføring av `lint-staged` sin exitkode og handtering av
konfigurasjons-, Git- og installasjonsfeil. Ein test kontrollerer òg at Husky-hooken
har LF-linjeskift og kallar Node-skriptet utan `jq`, `grep` eller `npx`.

Testane kallar ikkje Salesforce. Dei brukar lokale fixture-filer og Git-kommandoar;
testmiljøet må tillate oppretting og sletting av mellombelse mapper. Kommandoane
over er testinstruksjonar, ikkje dokumentasjon på at testane er køyrde i alle
operativsystem.

## Behovsstyrte CI-sjekkar

### `ci-changes.cjs`

Dette er ein lokal Git-/Node-CLI for workflow-output, ikkje ein Salesforce-CLI:

```sh
node scripts/ci-changes.cjs <base-ref> <head-ref>
```

Begge Git-referansane må finnast lokalt. Miljøvariabelen `GITHUB_OUTPUT` må peike
på ei skrivbar fil. Programmet les trepunktsdiffen `<base>...<head>`, med
slettingar og begge sider av omdøypingar, og les `sfdx-project.json` frå
**base-revisjonen**. Han skriv `salesforce=true|false` og `lwc=true|false` til
outputfila med append og viser resultatet i terminalen. Han endrar ikkje Git-indeks,
kjeldekode eller org; ein ugyldig referanse, manglande base-konfigurasjon eller
manglande outputfil-innstilling gir feil i staden for eit trygt-liknande resultat.

Lokalt Bash-eksempel med ein mellombels outputfil:

```bash
output_file="$(mktemp)"
GITHUB_OUTPUT="$output_file" node scripts/ci-changes.cjs origin/main HEAD
cat "$output_file"
rm "$output_file"
```

I PowerShell 7:

```powershell
$outputFile = [IO.Path]::GetTempFileName()
$previousOutput = $env:GITHUB_OUTPUT
try {
  $env:GITHUB_OUTPUT = $outputFile
  node scripts/ci-changes.cjs origin/main HEAD
  if ($LASTEXITCODE -ne 0) { throw 'Endringsfilteret feila.' }
  Get-Content -LiteralPath $outputFile
} finally {
  $env:GITHUB_OUTPUT = $previousOutput
  Remove-Item -LiteralPath $outputFile
}
```

`origin/main` er eit eksempel på ein lokal base-ref, ikkje ein kommando som
oppdaterer referansen. Eit likt base-/head-tre gir ingen relevante endringar.
I ein PR skal workflowen velje og køyre den godkjende baseversjonen av filteret;
ikkje la ugodkjend PR-kode bestemme kva kontrollar som blir hoppa over.

| Endring                                                      | Salesforce                                        | LWC                                        |
| ------------------------------------------------------------ | ------------------------------------------------- | ------------------------------------------ |
| Berre dokumentasjon eller `bin/`                             | false                                             | false                                      |
| Konfigurert pakkemappe, npm-manifest/låsfil eller workflow   | true                                              | true                                       |
| Filteret sjølv eller testane for det                         | true                                              | true                                       |
| `config/`, `manifest/`, `scripts/apex/` eller `.forceignore` | true                                              | false, med mindre andre filer utløyser LWC |
| Jest-konfigurasjon                                           | false, med mindre andre filer utløyser Salesforce | true                                       |

`false` tyder berre at dette filteret ikkje krev den aktuelle tunge sjekken.
Det hoppar ikkje over Node-testar, formatering, review eller andre nødvendige
gates. Workflow-wrapperane bevarer dei påkravde sjekknamna også når ei tung
validering ikkje er nødvendig. Manglande filter i ei eldre basegrein gir full
validering i wrapperen, ikkje automatisk skip.

Køyr isolerte testar utan Salesforce eller workflow-endringar:

```sh
node --test scripts/tests/ci-changes.test.cjs
```

Testane lagar isolerte Git-fixtures og dekkjer klassifisering, base-konfigurasjon,
filnamn med mellomrom/linjeskift, slettingar, omdøypingar og feilhandtering.
Ein lokal test er ikkje dokumentasjon på at GitHub faktisk har rapportert dei
forventa branch-protection-statusane; det krev ei reell PR-køyring.

## P360-mock-røykprøve

### `p360-mock-smoke.sh`

**Køyring**

```sh
npm run test:p360:mock
```

Ekvivalent direkte kommando:

```sh
bash scripts/p360-mock-smoke.sh
```

Skriptet tek ikkje argument eller miljøvariablar for å endre org-alias. Det brukar
alltid `crm-arbeidsforhold`. Direktekøyring krev Bash; skriptet er ikkje eit
PowerShell- eller CMD-skript.

**Krav**

- Bash, Salesforce CLI (`sf`) med innlogging/tilgang til org-aliaset
  `crm-arbeidsforhold`, og `jq`.
- Org-en må ha P360-metadata, nødvendige felt, aktivert
  `P360_Archive_Processing`-feature flag og ein brukar med
  `P360_Archive_Job_Processing`.
- Salesforce CLI-tilgang må vere konfigurert på førehand. Skriptet loggar ikkje
  inn eller opprettar org.

**Viktig: dette er ei muterande røykprøve**

Skriptet køyrer `p360MockArchiveFlow.apex`, opprettar Access Request,
Application, ContentVersion og arkivjobbar, og startar asynkron behandling.
Anonymous Apex-fila set `Use_Mock_Transport__c` på org-standardinnstillinga til
`true`. Ho har ingen opprydding eller automatisk tilbakestilling; mock-transport
kan difor bli ståande aktiv etter både vellukka og mislukka køyring. Røykprøva
hevdar at ingen live P360-callout blir utført, men ho endrar framleis org-en.
Bruk berre etter godkjenning, i rett ikkje-produksjonsorg, og følg lokal
framgangsmåte for kontroll/tilbakestilling av mock-innstillinga. Ikkje køyr dette
som del av vanleg lokal validering.

Skriptet lagrar CLI-resultat i mellombelse filer og slettar dei ved normal
avslutting eller feilhandtering gjennom shell-trap. Det viser ID-ar for
Application, ContentVersion, dokumentjobb og worker. Det kontrollerer at det
finst to jobbar med dei forventa eventtypane, begge har status `Succeeded` og
eitt forsøk, at det ikkje finst dupliserte idempotensnøklar, og at ein worker har
status `Completed` og null feil. Skriptet skriv også ut ei melding om at
mock-transport er brukt. Den meldinga er ikkje ei uavhengig verifisering av
nettverkstrafikk eller av kva transport som faktisk tok imot kall.

Exitkode `0` og `Result: PASS` tyder at kontrollane bestod. Feil i CLI, Apex,
SOQL, manglande debug-payload eller ein kontroll som ikkje består gir
`Result: FAIL`/ikkje-null exitkode. Ved kontrollfeil står mock-transport framleis
aktiv. Worker-status blir kontrollert gjennom høgst fem påfølgjande spørringar;
skriptet har ikkje ei synleg venting mellom dei. Dermed er ikkje resultatet ei
garanti for at ein langsam async-worker rekk å fullføre før kontrollen gir opp.

Røykprøva skriv ut Salesforce-record-ID-ar. Del ikkje slik terminalutskrift
ukritisk, sjølv om testdata blir brukte.

## Anonyme Apex-filer

Apex-filene er ikkje sjølvstendige CLI-program. Dei skal køyrast som anonym Apex
med Salesforce CLI mot ein uttrykkeleg vald, godkjend ikkje-produksjonsorg.
Det finst ingen kommando eller test i denne dokumentasjonen som autoriserer
Salesforce-køyring.

### `apex/activateMock.apex`

Køyring med ein eksplisitt godkjend org-alias:

```sh
sf apex run --target-org <godkjent-ikkje-produksjonsalias> \
  --file scripts/apex/activateMock.apex
```

Fila går gjennom alle Salesforce-profilar, hentar profilens
`API_Controller_Mock_Settings__c` og set `Status__c = 'OK'`,
`Status_Code__c = '200'` og `Use_Mock__c = true`, før ho gjer `upsert` av
innstillingane. Ho har ingen parametrar, outputrapport, valideringsmodus eller
tilbakestillingssteg. Ho kan feile dersom metadata, rettar eller DML-krav ikkje
stemmer med org-en.

Dette er ei brei, varig endring av profilspesifikke mock-innstillingar, ikkje berre
ein tørrkøyring. Kontroller påverknaden og avtalt tilbakeføringsmåte før bruk.
Fila må ikkje køyrast mot produksjon eller ein delt org utan særskild godkjenning.

### `apex/p360MockArchiveFlow.apex`

Fila blir normalt kalla av `p360-mock-smoke.sh`. Manuell køyring:

```sh
sf apex run --target-org <godkjent-ikkje-produksjonsalias> \
  --file scripts/apex/p360MockArchiveFlow.apex
```

Først kontrollerer ho at `P360_Archive_Job__c`, eit sett påkravde felt og
`P360_ArchiveProcessingGate.isEnabled()` er tilgjengelege. Deretter set ho
`P360_Integration_Setting__c.Use_Mock_Transport__c = true` på
org-standardinnstillinga, opprettar ein `Access_Request__c`, ein `Application__c`,
eit `ContentVersion`-vedlegg og ein ApplicationDocument-jobb, og startar
`P360_ArchiveJobScheduler`. Resultat-ID-ar blir skrivne med `System.debug` som
`P360_SMOKE_RESULT=...`; jobben frå vedlegget og async-resultatet kjem frå
etterfølgjande Salesforce-behandling.

Vanlege feil før dataskaping er manglande P360-objekt/felt eller deaktivert
feature flag; Apex unntak, manglande tilgang, valideringsreglar eller feil i async
behandling kan òg stoppe eller påverke køyringa. Køyrekommandoen har ikkje
opprydding. Oppretta data og mock-innstilling kan bli ståande sjølv om seinare
steg feilar. Bruk same org- og godkjenningsåtvaring som for shell-røykprøva.

## Plattformar og verifikasjon

| Verktøy                                 | Kva kjelda/konfigurasjonen viser                                                                        | Avgrensing                                                                                                                             |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `pre-commit.cjs`, `prettier-staged.cjs` | Node.js-program som nyttar Node sine fil-/prosess-API. Node-testane blir kalla frå `npm run test:node`. | `pre-commit.cjs` krev Git, lokal `lint-staged` og køyring frå repo-rota. Husky sin `sh`-hook må kunne køyrast av Git-klienten.         |
| `tests/pre-commit.test.cjs`             | Node `node:test`; den tilhøyrande offline-workflowen køyrer `npm run test:node` på Windows og Ubuntu.   | Ein test med linjeskift i filnamn er uttrykkeleg hoppa over på Windows. Dette er ikkje i seg sjølv dokumentasjon på macOS-testkøyring. |
| `p360-mock-smoke.sh`                    | Bash med `sf`, `jq` og vanlege Unix-verktøy; sjølve fila er eit Bash-skript.                            | Ikkje native PowerShell/CMD. Ingen Windows-paritets- eller Salesforce-org-køyring blir hevda her.                                      |
| `apex/*.apex`                           | Anonymous Apex sendt gjennom Salesforce CLI.                                                            | Org-, metadata-, tilgangs- og Salesforce-runtime-avhengig; ikkje ei lokal, offline validering.                                         |

Kontroller som ikkje krev org og ikkje endrar kjelde kan køyrast slik:

```sh
node --test scripts/tests/pre-commit.test.cjs
npm run test:node
node scripts/prettier-staged.cjs --check scripts/README.md
```

`npm run test:node` køyrer også Node-testar frå `bin/tests/`. Den fulle
formateringskontrollen for repoet er:

```sh
npm run prettier:check
```

Ikkje bruk `npm run test:p360:mock` eller `sf apex run` som dokumentasjons- eller
lokal formatvalidering; dei krev org-tilgang og kan endre org-data/innstillingar.
Salesforce-køyring og Apex-validering må godkjennast og planleggjast separat.

## Relatert dokumentasjon

- [Pre-commit og lokal validering i rot-README-en](../README.md#pre-commit-på-windows-linux-og-macos)
- [P360-brukartestguide](../docs/integrations/p360/user-testing-guide.md)
- [Offline arbeidsflyt for lokale skript](../.github/workflows/scratch-org-offline.yml)
