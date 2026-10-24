# Funksjonsparitet, plattformstøtte og verifisering

Dette er ein kjeldebasert kontrakt for skripta, ikkje ein lovnad om at alle
Salesforce-operasjonar er køyrde på kvart operativsystem.
Sjå [kommandoreferansen](COMMANDS.md) for parameter, eksempel, miljøvariablar og
risiko, og [scripts README](../scripts/README.md) for utviklar-/P360-verktøya.

## 1. Inngangane: kva er same implementasjon?

```text
npm run scratch-org / node bin/create-scratch-org.js
  macOS/Linux -> bash -> create-scratch-org.sh
  Windows     -> pwsh -> create-scratch-org.ps1

Windows CMD -> create-scratch-org.bat -> pwsh -> create-scratch-org.ps1
Direkte pwsh på Mac/Linux/Windows -> create-scratch-org.ps1

Bash og PowerShell install/update
  -> Node package-dependencies.js
     -> sf metadata reads
     -> Markdown/Mermaid + package-dependency-report.js -> offline HTML/SVG
     -> kontrollert midlertidig versjonsplan
```

CMD og npm er launcherar, ikkje eigne kopiar av oppsettlogikken.
Node-helperen er delt; Bash- og PowerShell-motoren er framleis separate
implementasjonar. Dei liknar funksjonelt, men ikkje alle miljøvariablar,
CLI-argument, feiltilfelle eller fallbackar er identiske.

## 2. Plattformmatrise

**Ja** = kjelda har denne inngangen/funksjonen. **Vilkår** = krev ekstra runtime.
Ingen av delane betyr at siste endring har grøn CI på den plattforma.

| Inngang / funksjon          | macOS       | Linux                | Windows               | Føresetnad / avgrensing                                                   |
| --------------------------- | ----------- | -------------------- | --------------------- | ------------------------------------------------------------------------- |
| Bash-motor                  | Ja          | Ja                   | Ikkje native kontrakt | WSL/Git Bash er ikkje testa/støtta som Windows-løysinga her               |
| PowerShell-motor            | Vilkår      | Vilkår               | Ja                    | PowerShell 7; Mac-harness finst, Linux-PS er ikkje dokumentert køyrd      |
| CMD-launcher                | Nei         | Nei                  | Ja                    | `cmd.exe` + `pwsh.exe`; ingen fallback til PowerShell 5.1                 |
| npm/Node-launcher           | Bash        | Bash                 | PowerShell            | Node + valt runtime; flaggdialekt følgjer OS, ikkje terminal              |
| Dependency-helper direkte   | Ja          | Ja                   | Vilkår                | Node 22+, `sf`; Windows krev òg `pwsh.exe` som native CLI-bru             |
| MD/Mermaid-rapport          | Ja          | Ja                   | Ja                    | Mermaid-kompatibel visar for graf-rendering                               |
| Lokal interaktiv HTML       | Tiltenkt    | Tiltenkt             | Tiltenkt              | Moderne nettlesar + JS; DOM-testar er ikkje full visuell plattformtest    |
| Automatisk Keychain-oppslag | Bash berre  | Nei                  | Nei                   | `security` på macOS + eksplisitt teneste/ev. konto                        |
| Nøkkel via miljøvariabel    | Ja          | Ja                   | Ja                    | Ikkje logg eller skriv nøkkelen til fil                                   |
| Bash offline-harness        | Ja          | Ja                   | Ikkje native          | Bash, jq og Node for preflight                                            |
| PowerShell offline-harness  | Ja          | Ikkje verifisert her | Ja                    | pwsh + Node; Windows-only CMD/npm-grupper krev Windows                    |
| Node offline-tests          | Ja          | Ja                   | Ja                    | Windows hoppar over éin eksisterande newline-filnamn-fixture              |
| Interaksjonstestar for HTML | Ja lokalt   | Tiltenkt             | Tiltenkt              | `npm run test:dependency-report`, eksisterande Jest/jsdom-devDependencies |
| Legacy versjonsskript       | Delvis      | Delvis               | Windows-retry         | Timeout-retry er Windows-spesifikk; ikkje ein gate                        |
| Legacy coverage-script      | pwsh mogleg | pwsh mogleg          | PowerShell            | Ingen dokumentert portabilitetsgate; secrets kan lekke i kommandologg     |
| Hooks/formatering           | Sjå scripts | Sjå scripts          | Sjå scripts           | [Eigen matrise og kommandoar](../scripts/README.md)                       |
| P360 smoke/Apex             | Sjå scripts | Sjå scripts          | Sjå scripts           | Org-/mock-avhengig, ikkje offline OS-verifikasjon                         |

## 3. Funksjonsmatrise for motorane

| Funksjon                                    | Bash            | PowerShell      | CMD/npm     | Paritet og vesentleg tradeoff                                                       |
| ------------------------------------------- | --------------- | --------------- | ----------- | ----------------------------------------------------------------------------------- |
| Shared config, manifest, generiske defaults | Ja              | Ja              | Delegerer   | CLI/config er tryggare felles kontrakt enn alle miljøbrytarar                       |
| Org-oppretting/sletting                     | Ja              | Ja              | Delegerer   | Kan erstatte eksisterande scratch; inga generell rollback                           |
| Pool + fallback                             | Ja              | Ja              | Delegerer   | Sfp-outputparser og CLI-default må verke i ekte miljø                               |
| Ikkje fallback ved tom pool                 | Miljø           | Parameter/miljø | Delegerer   | Bash har ikkje `--no-fallback-to-create`                                            |
| Manifestinstall/update                      | Ja              | Ja              | Delegerer   | Same preflight; installasjonsargument er ikkje byte-identiske                       |
| Nøkkelkrav frå packageKeyConfig             | Ja              | Ja              | Delegerer   | Manglande oppføring betyr normalt nøkkel påkravd                                    |
| Install-retry ved transient feil            | Ja              | Ja              | Delegerer   | Ikkje retry av alle feil; npm/metadata-lesing er ikkje same retry-løkke             |
| Nyaste release / versjonsvarsel             | Ja              | Ja              | Delegerer   | `skip-version-check` hoppar ikkje over grafkontrollen                               |
| Package-plan                                | Ja              | Ja              | Delegerer   | Ikkje komplettheitskontroll; ikkje det same som preflight                           |
| Self-check                                  | Ja              | Ja              | Delegerer   | Omfang varierer; PS sjekkar ikkje rekursiv graf/pakkeoppløysing som eigen preflight |
| Dependency check/apply                      | Felles Node     | Felles Node     | Delegerer   | Eksakte ID-ar; konfliktar krev menneskeleg avklaring                                |
| Rapport MD + HTML                           | Felles Node     | Felles Node     | Delegerer   | Begge skriv lokale filer, òg i dry-run                                              |
| Deploy/permsets/data/community              | Ja              | Ja              | Delegerer   | Reell metadata-/dataendring og publisering                                          |
| Custom-steg                                 | Ja              | Ja              | Delegerer   | Frå prosjektrot; executable må vere tilgjengeleg på valt OS                         |
| Dummybrukarar/profilmapping                 | Ja              | Ja              | Delegerer   | Gjeld nye brukarar; ikkje generell migrering av eksisterande brukarar               |
| Full-deploy/redeploy                        | Ja              | Ja              | Delegerer   | Lokal tracking blir sletta før deploy; ikkje org-datareset                          |
| Manifestversjon check/apply                 | Ja              | Ja              | Delegerer   | Eiga vedlikehaldsflyt, ikkje dependency-kompatibilitetsløysing                      |
| Coverage                                    | Ja              | Ja              | Delegerer   | Eiga flyt utan manifestpreflight; kan installere/deploye                            |
| Dependency-kjelde cleanup/retrieve          | Ja              | Ja              | Delegerer   | Referansemapper er normalt read-only; eksplisitt godkjenning                        |
| Framdrift/heartbeat/fargar                  | Ja              | Ja              | Delegerer   | CLI-JSON blir ikkje framstilt som framdriftsprosent                                 |
| Dry-run via miljø                           | `DRY_RUN=true`  | Nei             | OS-avhengig | Bruk alltid `--dry-run` / `-DryRun`                                                 |
| Keychain                                    | macOS           | Nei             | OS-avhengig | PS treng nøkkel via miljø, også på Mac                                              |
| Timeout frå commandTimeouts                 | Validert skjema | Validert skjema | Delegerer   | Ikkje implementert som generell prosesstimeout                                      |

### Konkrete avvik som ikkje må skjulast

1. `COVERAGE_CLASS_PATTERN` er Bash-namnet; PS brukar
   `COVERAGE_CLASS_NAME_PATTERN`, eller parameteret `-CoverageClassNamePattern`.
2. `FULL_DEPLOY`, `DRY_RUN` og fleire andre Bash-modusvariablar blir ikkje
   lesne som PS-brytarar. Bruk eksplisitte parameter.
3. Bash krev jq ved konfigurasjonslesing. PS brukar native JSON for òg
   dependency-rydding; den gamle PS-helpteksten nemner jq, men implementasjonen
   brukar ikkje jq der.
4. PowerShell legg til `--publish-wait` på vanleg pakkeinstallasjon; Bash brukar
   `-w`/CLI-installargumenta sine. Begge prøver å installere same kontrollerte ID.
5. PS har `-NoFallbackToCreate`; Bash brukar miljøvariabel eller konfig.
6. Motstridande modus blir ikkje likt avviste i alle kodevegar. Kombiner ikkje
   fleire eksklusive hovudmodus berre fordi parseren tek imot flagga.
7. `package-plan`, self-check og coverage er ikkje bevis på komplett manifestgraf.
8. Dependency-helperen gir berre grafen han faktisk fekk undersøkt.
   Greiner som stoppar ved ulik versjon er uttrykkeleg uundersøkte vidare.

## 4. Kva endrar kva?

| Modus                           | Kontaktar Salesforce                | Org-/dataendring                                                 | Lokal manifest/config-endring                                   | Rapportar                |
| ------------------------------- | ----------------------------------- | ---------------------------------------------------------------- | --------------------------------------------------------------- | ------------------------ |
| Help                            | Nei                                 | Nei                                                              | Nei                                                             | Nei                      |
| Offline-testar                  | Nei, fake CLI                       | Nei                                                              | Berre isolerte testfixtures                                     | Isolerte testfiler       |
| Init config                     | Nei                                 | Nei                                                              | Config, med force ved erstatning                                | Nei                      |
| Dependency check                | Ja                                  | Nei                                                              | Nei                                                             | MD + HTML                |
| Dependency apply                | Ja                                  | Nei                                                              | Manifest + eksklusiv backup                                     | MD + HTML, før retting   |
| Normal install/update preflight | Ja                                  | Nei i preflight                                                  | Midlertidig versjonsplan                                        | MD + HTML                |
| Fullt oppsett                   | Ja                                  | Kan slette/opprette/hente/installere/deploye/importere/publisere | Tracking, ev. kjeldefiler                                       | Ja når pakkephase        |
| Package-plan                    | Ja                                  | Nei                                                              | Ikkje manifest                                                  | Ikkje dependency-rapport |
| Version check                   | Ja                                  | Nei                                                              | Nei                                                             | Terminal                 |
| Version apply                   | Ja                                  | Nei                                                              | Manifest + `.backup`                                            | Terminal                 |
| Self-check                      | Ja                                  | Nei                                                              | Ikkje produktfiler                                              | Terminal                 |
| Coverage                        | Ja                                  | Kan installere/deploye; køyrer Apex                              | Tracking kan påverke lokale filer via CLI                       | Terminal/query           |
| Post-steps-only                 | Ja                                  | Ja, valde steg                                                   | Tracking ved deploy                                             | Ikkje dependency-rapport |
| Clear dependency sources        | Treng ikkje org for sjølve ryddinga | Nei                                                              | Slettar referanseinnhald                                        | Terminal                 |
| Refresh dependency sources      | Ja                                  | Oppsett kan endre org, retrieve les                              | Ryddar/hentar referansekjelder, flyttar .forceignore mellombels | Terminal/ev. preflight   |
| Dry-run                         | Kan lese                            | Planlagde mutasjonar blir ikkje køyrde                           | Rapportar kan bli skrivne                                       | Ja når preflight køyrer  |

Ikkje bruk denne tabellen til å gi agentar lov til å bruke andre orgar.
Ein read-only kommando kan framleis lese persondata/privilegerte metadata.

## 5. Verifikasjonsmatrise og vedlikehald

| Lag                       | Kva testen beviser                                                             | Kva han ikkje beviser                                                       |
| ------------------------- | ------------------------------------------------------------------------------ | --------------------------------------------------------------------------- |
| Node `test:node`          | CLI-val, rekursiv graf, feil/backup/rapportkontraktar og hooks                 | Levande Salesforce API eller installasjonskompatibilitet                    |
| Bash-harness              | Reelle Bash-script mot falsk CLI, ingen mutasjon etter preflightfeil           | `sf`/`sfp`-versjonar, auth og pool i ekte miljø                             |
| PS-harness                | Reell PS-script mot falsk CLI; live output, native argument, feil og rapportar | Mac-køyring er ikkje Windows CMD/native CLI-verifikasjon                    |
| PS `-RequireWindows`      | Køyrer på Windows og ingen obligatoriske Windows-grupper blir hoppa over       | Ekte Salesforce install/deploy                                              |
| Jest/jsdom HTML           | Hover/fokus, retning, låsing, tastatur, zoom og inert tekst                    | SVG-layout, browser-CSP-handheving, peikar-drag og faktisk visuell kvalitet |
| Menneskeleg browser-sjekk | Piler, layout, hover og panorering i faktisk nettlesar                         | Ekte metadatafullstendigheit eller org-kompatibilitet                       |
| Godkjend live preflight   | Tilgjengeleg pakkemetadata og observerte krav for køyringa                     | Uundersøkte konfliktgreiner eller at høgare versjonar er kompatible         |

### Dokumentert Windows-evidens

[Offline-køyring 40043090089](https://github.com/navikt/crm-arbeidsforhold/actions/runs/40043090089)
var grøn på feature-SHA `1979ef2c15529652cdd26cdff8ccd80f8155935b`:

- Windows 2025 / PowerShell 7.6.6: 210 assertions, 0 feil, 0 hoppa-over-grupper.
- Windows Node: 45 bestått, 1 eksisterande newline-filnamn-test hoppa over.
- Ubuntu Node: 46 bestått.
- Ubuntu Bash: 234 assertions; valfritt separat CLI-verktøy var ikkje installert.

Dette er **historisk evidens**, ikkje verifikasjon av dei seinare lokale
farge-, rapport-, HTML- og dokumentasjonsendringane. Siste lokale køyringstal
skal lesast frå testresultata, ikkje reknast ut frå eldre Windows-tal.
På Mac kan Bash-harnessen køyre fleire assertions dersom det valfrie
`sf-project`-verktøyet er installert; ulike tal er ikkje nødvendigvis regressjon.

[Offline-workflowen](../.github/workflows/scratch-org-offline.yml) køyrer Node
og shell-harness utan Salesforce-secrets. Han installerer ikkje heile root
devDependencies og køyrer derfor **ikkje** `test:dependency-report`.
DOM-testkommandoen må køyrast separat etter utviklarinstallasjon. Vi har ikkje
endra CI som del av dokumentasjonsarbeidet.

### Lokal avslutningskontroll

Dei enno ikkje publiserte rapport-/dokumentasjonsendringane er kontrollerte
på macOS med følgjande resultat:

| Kommando                                      | Resultat                                                  |
| --------------------------------------------- | --------------------------------------------------------- |
| `npm run test:node`                           | 51 bestått, 0 feil, 0 hoppa over                          |
| `npm run test:dependency-report`              | 8 bestått                                                 |
| `npm run test:scratch-org:powershell`         | 213 assertions, 0 feil; éi Windows-only-gruppe hoppa over |
| `bash bin/tests/create-scratch-org.test.sh`   | 305 assertions, 0 feil                                    |
| Målretta Prettier, Bash-syntaks og whitespace | Bestått                                                   |

Dokumentasjonskontrollen fann ingen manglande bin-filer i referansen eller
brotne lokale lenkjemål; alle oppdaga eigendefinerte Bash-/PowerShell-flagg er
omtalte. Dette er lokal arbeidskopi-evidens, ikkje ein ny Windows-CI-køyring.
Browser-rendering og live Salesforce-integrasjon er framleis ikkje sertifisert.

### Reproduser lokal gate

```bash
npm run test:node
npm run test:dependency-report
npm run test:scratch-org:powershell
bash bin/tests/create-scratch-org.test.sh
npm run prettier:check
```

Den siste kommandoen er repository-brei og kan finne uvedkomande gamle feil.
Ved avgrensa dokumentasjonsendring kan du fyrst køyre Prettier berre på endra
MD-/JS-/JSON-filer. Apex/live metadata/deploy krev eiga eksplisitt org-godkjenning.
Visuell testing av HTML var blokkert i agent-sandboxen; lokal preview-server
og opning av tempfil blei avviste. Brukaren har valt å gjere visuell sjekk sjølv.

## 6. Når skript eller parameter blir endra

1. Oppdater både parser/help og radene i [COMMANDS.md](COMMANDS.md).
2. Legg til/fjern inventarrada for kvar ny/fjerna fil, også tests og fixtures.
3. Oppdater paritetsmatrisa dersom berre éin motor får funksjonen.
4. Endre ikkje «tiltenkt» til «verifisert» utan faktisk køyringsevidens.
5. Test minste relevante lag, deretter dei andre motorane dersom shared helper
   eller offentleg kontrakt endrar seg.
6. Ta vare på red/green-resultat og eksakt SHA ved ekstern Windows-verifikasjon.
7. Ikkje dokumenter ein planlagt CLI som om han allereie finst.
