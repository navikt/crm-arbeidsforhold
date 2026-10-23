---
slug: scratch-org-powershell-verification
status: draft
---

# Feature Specification: Verifiserbar PowerShell-støtte utan lokal Windows-maskin

**Oppretta:** 2026-10-23  
**Status:** Krav avklarte med brukar; implementasjon og CI-endring er ikkje godkjende gjennom denne specen.  
**Styring:** [AGENTS.md](../../AGENTS.md), [agentarbeidsflyt](../instructions/agentic-development.instructions.md) og Nav sine verktøyreglar.  
**Relatert kontrakt:** [Cross-platform standalone scripts](cross-platform-scratch-org-scripts.md), særleg REQ-300–306.

## Scope Baseline

- Oppdagingsmetode: direkte lesing av standalone-skript, launcherar, PowerShell-testharness, dokumentasjon og opne GitHub-issues i begge repo.
- To repo er omfatta: `navikt/crm-arbeidsforhold` og `navikt/crm-platform-integration`.
- Fire produktflater per repo: PowerShell-skriptet, CMD-launcheren, npm-launcheren og prosjektkonfigurasjonen.
- Testflater: lokal PowerShell-harness, Node-launchertestar, Bash-regresjon og ny Windows offline-CI.
- Eksisterande issue #1069 eig den opphavlege Windows-funksjonaliteten; denne specen kompletterer, ikkje erstattar, den kontrakten.
- Skripta i integrasjonsrepoet er førebels lokale, ucommitta kopiar. Eit CI-jobbresultat frå det andre repoet verifiserer ikkje desse automatisk.

### Vedtekne avgjerder

1. PowerShell 7 LTS blir einaste støtta runtime. Windows PowerShell 5.1 skal ikkje veljast som fallback.
2. PowerShell 7 direkte på Mac er primær lokal testløysing. Docker, VM og Windows-lisens er ikkje krav.
3. GitHub-hosted Windows-runner kan planleggjast. Faktisk CI-endring krev eiga godkjenning.
4. Grøn Windows offline-matrise er akseptansegate for offline-støtte. Ekte Salesforce-flyt skal framleis merkast uverifisert.
5. Det skal ikkje installerast noko, endrast CI/auth eller aksesserast Salesforce som del av spec- og issue-arbeidet.

### Kvifor ikkje Windows PowerShell 5.1?

5.1 er ein del av Windows og følgjer støttelivsløpet til operativsystemet; det er ikkje rett å kalle han generelt utgått eller utrygg.
Støtte er viktig dersom målbrukarane er låste til innebygd PowerShell og ikkje får installere 7, eller treng gamle Windows-modular.
Det er ikkje påvist eit slikt behov for desse skripta, som hovudsakleg køyrer ekstern Salesforce CLI.

To runtime-generasjonar aukar testmatrisa og gir ulike reglar for encoding, JSON og native argument.
Brukaren har valt å krevje PowerShell 7 LTS. Dette er ei tilsikta endring frå dokumentert 5.1-støtte, med krav om migreringsrettleiing og tydeleg feil ved manglande runtime.
Om organisasjonen seinare nektar installasjon av 7, må kontrakten vurderast på nytt; stille 5.1-fallback er ikkje ei løysing.

### Ut av scope

- Faktisk scratch-org-oppretting/sletting, pooltilgang, pakkeinstallasjon, metadata-retrieval og deploy under offline-test.
- Salesforce-auth, Dev Hub-konfigurasjon, secrets i CI eller endringar i pakkeversjonar.
- Windows 5.1-støtte, Windows ARM64 og påstand om at alle Windows-utgåver er testa.
- Ende-til-ende-verifikasjon mot Salesforce; dette krev eiga oppgåve og godkjenning av eksakt mål og handling.
- Ny felles distribusjonspakke eller automatisk synkronisering mellom repo.

## User Scenarios & Testing

### Brukarhistorie 1 – Lokal raud–grøn-loop på Mac (P1)

Som utviklar på Mac vil eg køyre dei faktiske PowerShell-åtferdstestane utan Salesforce, slik at eg kan reprodusere og rette feil lokalt.

**Kvifor:** Ein Node-test som berre vel ein scriptsti, beviser ikkje at PowerShell-logikken fungerer.

**Uavhengig test:** Køyr den portable harnessen med PowerShell 7 og falske CLI-program.

**Akseptansescenario:**

1. Gitt PowerShell 7 på Mac og ingen Salesforce-auth, når felles testsett blir køyrt, så blir skriptet faktisk køyrt og resultat/exitkodar kontrollerte.
2. Gitt eit uventa CLI-kall, når testen køyrer, så feilar han med kommando og årsak, utan å falle tilbake til eit ekte program på PATH.
3. Gitt Windows-only CMD-testar, når lokal Mac-test køyrer, så er desse eksplisitt hoppa over og ikkje rapporterte som bestått.

### Brukarhistorie 2 – Ekte Windows-prosessgrenser utan eiga Windows-maskin (P1)

Som vedlikehaldar vil eg sjå Windows offline-resultat før eg lovar Windows-støtte.

**Uavhengig test:** Køyr Windows-CI med PowerShell 7, CMD og npm mot fake CLI utan secrets.

**Akseptansescenario:**

1. Gitt ei endring i skript eller konfigurasjon, når godkjend CI køyrer, så blir PowerShell, CMD og npm faktisk starta på Windows.
2. Gitt både `powershell.exe` og `pwsh.exe`, når ein launcher startar, så blir den støtta PowerShell 7-runtime brukt.
3. Gitt manglande `pwsh`, når CMD/npm startar, så feilar han før Salesforce-kall med ei handlingsretta installasjonsmelding.
4. Gitt ein feil frå fake Salesforce CLI, når skript/launcher avsluttar, så ser brukaren ikkje-suksess og relevante feildetaljar.

### Brukarhistorie 3 – Ærleg status i begge repo (P2)

Som Windows-brukar vil eg vite kva som er testa, kva eg må installere, og kva som ikkje er bevist.

**Uavhengig test:** Kontroller dokumenterte kommandoar og resultatreferansar for eksakte revisjonar i begge repo.

**Akseptansescenario:**

1. Gitt grøn Windows offline-CI, når støtte blir omtalt, så står ekte Salesforce-integrasjon framleis som uverifisert.
2. Gitt grøn test i arbeidsforhold-repoet, når integrasjonsrepoet blir vurdert, så krevst eigne resultat for det repoet sin konfigurasjon og sine kopiar.

### Kanttilfelle

- Mellomrom og norske teikn i prosjektsti, tomme argument, sitatteikn og fleire argument.
- CLI installert som `.cmd` på Windows kontra køyrbart program på Mac.
- CLI skriv advarsel før JSON, ugyldig JSON, tom stdout, stderr eller ikkje-null exitkode.
- Manglande/tom pool; feil frå fetch/install/deploy; ingen automatisk suksess etter feil.
- Konfigurasjonsfeil, CLI/env/config-presedens og manglande prosjektfil.
- Windows-only testar blir ikkje køyrde på Mac; manglande Windows-runtime i CI skal feile, ikkje gi skip.
- Feil i harness må ikkje maskere at produksjonsskriptet aldri blei starta.

## Requirements

### Funksjonelle krav

- **REQ-001:** Alle støtta Windows-entrypoints skal velje PowerShell 7 LTS og aldri Windows PowerShell 5.1. Direkte oppstart på ein ikkje-støtta runtime skal avvisast tydeleg før sideeffektar.
- **REQ-002:** Ved manglande PowerShell 7 skal CMD/npm gi ikkje-null exitkode og installasjonsrettleiing; eksisterande Bash-val på Mac/Linux skal bevarast.
- **REQ-003:** Felles PowerShell-harness skal køyre på Mac og Windows, finne korrekt host og bruke plattformrett PATH og tempområde.
- **REQ-004:** Parserkontroll skal omfatte både produksjonsskript og harness, men skal ikkje erstatte åtferdstestar.
- **REQ-005:** Offline-testane skal ikkje kunne bruke ekte `sf`/`sfp` ved ein feil. Fake kommandoar skal avvise alle uventa kall og registrere program, argument og exitkode utan secrets.
- **REQ-006:** Testsettet skal kontrollere config-presedens/validering, poolflyt med feil, install/update/plan, deploy/post-steps-only, init-config og vidareformidling av CLI-feil.
- **REQ-007:** Testsettet skal kontrollere argumentgrenser, prosjektstiar med mellomrom/Unicode og CLI-outputvariantane i kanttilfella. Test med eit falskt installasjonsnøkkelmerke skal bevise at verdien ikkje kjem i loggen.
- **REQ-008:** Windows-testar skal faktisk starte PowerShell-skript, CMD- og npm-launcher, verifisere argv/exitkodar og bevise manglande-runtime-feilen utan 5.1-fallback.
- **REQ-009:** Windows-CI skal bruke eksplisitt vald Windows-runner-generasjon og PowerShell 7 LTS-baseline, logge faktisk OS/runtime og køyre utan Salesforce-secrets/auth. CI-endring må godkjennast før implementasjon.
- **REQ-010:** Nye testjobbar skal ikkje få skrive- eller deployment-tilgang som ikkje trengst. Actions skal følgje repoets reglar for rettar og versjonsfesting; ubetrodd PR-kode skal ikkje få secrets.
- **REQ-011:** Same testkontrakt skal brukast i begge repo, med prosjektspesifikke assertions. Integrasjon krev `dev`-pool utan automatisk create-fallback; arbeidsforhold bevarer sin konfigurerte flyt.
- **REQ-012:** Resultat skal skilje bestått, feila, hoppa over og ikkje køyrt; kvar køyring skal knytast til repo, revisjon, kommando, runtime og OS.
- **REQ-013:** Dokumentasjonen skal forklare Mac-installasjon, ingen krav om Docker/.NET SDK/Windows-lisens, og migrering frå 5.1 til 7 på Windows.
- **REQ-014:** Påstand om Windows offline-støtte krev grøne felles- og Windows-only testar i kvart repo. Full Salesforce-flyt skal ikkje kallast verifisert på grunnlag av mocks.
- **REQ-015:** Feil funne under implementasjon skal først reproduserast i ein fokusert raud test, deretter rettast og verifiserast grønt. Bash- og Node-regresjon skal bevarast.

### Krav til tryggleik og pålitelegheit

- **REQ-016:** Ingen offline-test skal kontakte Salesforce, lese lokal Salesforce-auth eller skrive til ekte prosjektmetadata. Fixtures skal vere syntetiske og tempområde ryddast målretta.
- **REQ-017:** Implementasjonen skal ikkje svekkje lokal sandbox, execution policy eller macOS-sikkerheit for å få testane til å køyre.
- **REQ-018:** Kjende feil skal dokumenterast med reproduksjon, ikkje antaking om at alle Windows-feil er identiske med Mac-feil.

## Success Criteria

- **SC-001:** Utviklar på Mac kan køyre heile felles testsettet utan Windows, Docker eller Salesforce-konto etter godkjend runtime-installasjon.
- **SC-002:** Alle obligatoriske scenario bestått i kvart repo på Mac og Windows; null obligatoriske Windows-scenario er hoppa over i Windows-jobben.
- **SC-003:** Null ekte Salesforce-kall i offline-køyring; uventa kall gir deterministisk testfeil.
- **SC-004:** Feil i underprosess, manglande runtime og ugyldig konfigurasjon gir ikkje-null resultat gjennom direkte script, CMD og npm der entrypointen er støtta.
- **SC-005:** Ein annan utviklar kan skilje «Mac felles-test bestått», «Windows offline bestått» og «Salesforce ende til ende ikkje køyrt» frå rapporten utan å lese implementasjonen.

## Kva krevst på Mac-maskina?

### Observert 2026-10-23

Maskina rapporterte Apple Silicon (`arm64`), macOS `26.7.1` og Node.js `22.20.0`.
Homebrew og Docker-klient finst. PowerShell (`pwsh`) blei ikkje funne på PATH.
Docker-motor og Salesforce-auth er ikkje kontrollerte og er ikkje nødvendige for den planlagde offline-loopen.
Dette er ei lokal observasjon, ikkje ein organisasjonsstandard eller ein støttegaranti frå Microsoft.

### Nødvendig

1. Godkjend PowerShell 7 LTS for macOS ARM64. Bruk Microsoft si signerte/notariserte installasjonspakke gjennom godkjend programvarekanal; ikkje preview eller x64/Rosetta når native ARM64 finst.
2. Dersom maskinpolicy krev administrert installasjon, få installasjonen utført gjennom godkjend kanal. Ikkje slå av Gatekeeper, fjern quarantine eller prøv å omgå sandbox.
3. Ny terminal etter installasjon, med `pwsh` på PATH. Installeraren har .NET-runtime som del av distribusjonen; separat .NET SDK er ikkje nødvendig.
4. Lokal repo-checkout med skript og den framtidige portable harnessen. Node/npm trengst for npm-entrypoint og Node-testane, ikkje for direkte PowerShell-køyring.
5. Skrivetilgang til operativsystemet sitt tempområde for syntetiske prosjekt og fake CLI. I agent-sandbox skal scratch-filer bruke det tillatne `$TMPDIR`.
6. Nettverk til godkjend nedlastingsstad for installasjon og GitHub for CI-resultat. Sjølve felles-testsettet skal ikkje krevje nettverk.

Etter installasjon kan runtime sjekkast utan Salesforce:

```bash
pwsh -NoLogo -NoProfile -Command '$PSVersionTable'
```

Etter at den portable harnessen er implementert, er planlagd lokal kommando frå kvar repo-rot:

```bash
pwsh -NoLogo -NoProfile -File ./bin/tests/create-scratch-org.Tests.ps1
```

**Denne testkommandoen er eit framtidig akseptansemål. Dagens harness er Windows-bunden og er ikkje verifisert på Mac.**
Han byggjer `pwsh.exe`, brukar `;` i PATH, lagar `sf.cmd` og startar `ComSpec`. Dette må rettast før kommandoen kan forventast å bli grøn.
Ingen PowerShell-installasjon eller testkøyring er utført som del av denne specen.

Eksakt LTS-patch og støtta OS-versjon skal kontrollerast ved installasjon og registrerast i resultatet, ikkje kopierast ukritisk frå dette dokumentet.
Ein global installasjon kan krevje ekstra godkjenning etter lokal maskinpolicy; det er ikkje løyve til å skrive utanfor sandbox.

### Ikkje nødvendig for offline-test

Salesforce CLI, `sfp`, Dev Hub, scratch-org, installasjonsnøklar, Windows-installasjon, VM, Windows-lisens, Docker eller Pester er ikkje krav.
Testane brukar eigne fake program. Eksisterande faktiske installasjonar skal ikkje bli brukte.
Pester eller annan ny testavhengigheit skal berre innførast dersom den eksisterande harnessen ikkje er tilstrekkeleg, med eiga grunngiving.
`--dry-run` i eit produktskript er ikkje det same som offline-test: særleg Bash-poolflyten les poolstatus og pakkeversjonar.

## Verifikasjonsnivå og restrisiko på Windows

| Nivå | Beviser | Beviser ikkje |
| --- | --- | --- |
| Parser på Mac | Gyldig syntaks i installert PowerShell 7 | At nokon arbeidsflyt fungerer |
| Felles åtferdstest på Mac | PowerShell-logikk og kontrakt med fake CLI på Mac | Windows-prosessgrenser, CMD, Windows-stiar |
| Windows offline-CI | Testa PowerShell/CMD/npm-kontrakt på den konkrete runneren | Faktisk Salesforce CLI/sfp, brukar-PC eller org |
| Seinare godkjend ende-til-ende-test | Den prøvde flyten med konkrete verktøy og scratch-org | Alle Windows-PC-ar, alle org-tilstandar eller alle framtidige CLI-versjonar |

| Restrisiko etter grøn Windows offline-CI | Konsekvens | Tiltak / kva står att |
| --- | --- | --- |
| Fake CLI avvik frå ekte `sf`/`sfp` | JSON, exitkode eller argument kan fungere i mock og feile mot ekte CLI | Dokumenter kontrakten; registrer faktiske verktøyversjonar ved eventuell seinare E2E. Ikkje lov org-integrasjon no. |
| Reell Windows-installasjon bruker `.cmd` og andre quoting-reglar | Install/deploy kan få feil argument | Bruk ein faktisk `.cmd`-fake i Windows, assert argv, inkludert tomme argument og mellomrom. Ekte CLI står framleis att. |
| Administrert PC, AppLocker/WDAC, antivirus, execution policy eller manglande installasjonsrett | Programmet kan bli blokkert før testlogikken startar | Dokumenter krav og feil; ikkje instruer om tryggleiksomgåing. Organisasjons-PC er ikkje simulert av hosted runner. |
| Proxy, sertifikat, VPN og TLS | Auth/nedlasting/callout feilar berre hos brukaren | Utanfor offline-bevis; krev miljødiagnose og godkjend måloperasjon seinare. |
| OS/runtime/Node/CLI-drift, Windows ARM64 og andre locale | Ei anna maskin kan feile sjølv om runneren er grøn | Avgrens dokumentert baseline og logg versjonar. Utvid matrisa berre ved uttrykkeleg behov. |
| Reelt org, pooltomheit, pakkekrav og tilgangar | Delvis installasjon/deploy eller feil etter tidlegare steg | Test feilbaner med mocks; verifiser eksakt org separat før bruk. Grøn offline-test er ikkje deploy-godkjenning. |
| Kopiar i to repo divergerer | Eitt repo mistar ei retting eller testar feil konfigurasjon | Eigne resultat og testkontrakt i begge repo; vurder felles distribusjon seinare, ikkje i denne oppgåva. |

Sannsyn kan ikkje talfestast forsvarleg utan faktiske Windows-resultat. Risikoen blir redusert av Windows offline-CI, men ikkje eliminert.
Eit feilande muterande steg kan la eit delvis klargjort org stå att; gjenkøyring eller opprydding må ikkje skje automatisk utan å kjenne faktisk tilstand.
Brukaren har uttrykkeleg akseptert denne avgrensinga: støtte skal omtalast som **Windows offline-verifisert; Salesforce ende til ende uverifisert** når og berre når offline-gaten er grøn.

## Implementasjonsrekkjefølgje og evidens

1. Lag ein portabel testseam, legg til feilreproduksjonar og innfør 7-only-kontrakten i arbeidsforhold-repoet.
2. Etter separat CI-godkjenning: legg til offline Windows-jobbar som utøver PowerShell 7 LTS, CMD og npm; bevar Bash-/Node-regresjon.
3. Overfør same kontrakt og rettingar til integrasjonsrepoet, med eigne prosjektassertions og eigen Windows-køyring.
4. Registrer eksakte kommandoar, resultat, skip, OS/runtime, repo og revisjon. Ingen test er bestått berre fordi testfila finst.

Ingen nye påstandar om PowerShell-funksjon er verifiserte gjennom denne dokumentasjonsoppgåva.
Den tidlegare Bash-/Node-valideringa er ikkje PowerShell-evidens.

## GitHub-arbeid

| Oppgåve | Krav og avhengigheiter |
| --- | --- |
| [navikt/crm-arbeidsforhold#1147](https://github.com/navikt/crm-arbeidsforhold/issues/1147) – lokal testseam og PowerShell 7-kontrakt | REQ-001–008, REQ-012–013, REQ-015–018. Første implementasjonsskive. |
| [navikt/crm-arbeidsforhold#1148](https://github.com/navikt/crm-arbeidsforhold/issues/1148) – Windows offline-CI | REQ-008–010, REQ-012, REQ-014, REQ-016–018. Avhengig av #1147 og separat CI-godkjenning. |
| [navikt/crm-platform-integration#467](https://github.com/navikt/crm-platform-integration/issues/467) – integrasjonsrepo | Alle krava for eigne kopiar; særleg REQ-011. Avhengig av dei to oppgåvene over. |

Oppgåvene kompletterer [#1069](https://github.com/navikt/crm-arbeidsforhold/issues/1069), som framleis eig opphavleg Windows-funksjonalitet.
Specen er lokal fram til ho blir committa og publisert gjennom godkjend flyt. Issuane gjengir krav og brukaravgjerder utan å føresetje at ei upublisert fil er tilgjengeleg på GitHub.

## Kjelder

- [Microsoft: installere PowerShell på macOS](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-macos) – ARM64-distribusjon, installasjonsmetodar og plattformkrav.
- [Microsoft: PowerShell support lifecycle](https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-support-lifecycle) – LTS og skiljet mellom PowerShell 7 og Windows PowerShell.
- [GitHub: workflow syntax og shell-val](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) – Windows-jobbar og eksplisitt shell.

Kjeldene blei lesne 2026-10-23. Versjonsnummer og runnerinnhald må kontrollerast på nytt ved implementasjon.
