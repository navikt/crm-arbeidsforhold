# crm-arbeidsforhold

Salesforce-løsningen for søknader, avtaler og tilgang til Aa-registerets arbeidsforholdsdata.

Løsningen bruker Apex, Lightning Web Components og Experience Cloud for eksterne
virksomheter og interne saksbehandlere. Den leveres som en Salesforce Unlocked Package.

## Kom i gang

**Ny i prosjektet?** Følg [utviklerguiden](docs/kom-i-gang.md) fra installasjon av
verktøy til første endring. Den har separate valg for **Mac, Linux og Windows**.

Har du Git, Node.js og npm på plass, kan du starte lokalt:

```text
git clone https://github.com/navikt/crm-arbeidsforhold.git
cd crm-arbeidsforhold
npm ci
npm run test:node
```

Bruk Node.js 22 LTS, minst **22.22.1**, for prosjektets npm-avhengigheter.
`npm ci` installerer utviklerverktøy og pre-commit-hooken, ikke Salesforce-pakker
eller et utviklingsorg. Kommandoene over krever ikke Salesforce-tilgang.

## Utviklingsstandarder

Les **[Utviklingsstandarder](docs/utviklingsstandarder.md)** før du begynner å
endre løsningen. Dokumentet samler gjeldende Nav-/Platforce-føringer, kode- og
testprinsipper, teamansvar og krav til dokumentasjon, runbooks og org-sikkerhet.
Det lenker videre til detaljreglene for Apex, LWC og metadata.

## Scratch-org

Bruk `npm run scratch-org` fra prosjektroten for å hente eller opprette et
scratch-org, installere pakkeavhengigheter og kjøre konfigurerte post-steg.
Du trenger Salesforce CLI, godkjent Dev Hub-tilgang og sikker tilgang til
installasjonsnøkkelen. Mac/Linux krever Bash og `jq`; Windows krever PowerShell 7 LTS.
Repoet har pool aktivert, som også krever `sfp`.

**Start med hjelp.** Avhengighetskontroll og dry-run kan kontakte Salesforce.
Fullt oppsett kan erstatte eksisterende scratch-org og endre metadata, data og
tilgang. Avklar mål og få godkjenning før disse operasjonene.

| Plattform / terminal   | Hjelp (offline)                  | Avhengighetskontroll (etter godkjenning)      |
| ---------------------- | -------------------------------- | --------------------------------------------- |
| Mac (macOS) – Bash     | `npm run scratch-org -- --help`  | `npm run scratch-org -- --check-dependencies` |
| Linux – Bash           | `npm run scratch-org -- --help`  | `npm run scratch-org -- --check-dependencies` |
| Windows – PowerShell 7 | `npm run scratch-org '--' -Help` | `npm run scratch-org '--' -CheckDependencies` |
| Windows – CMD          | `npm run scratch-org -- -Help`   | `npm run scratch-org -- -CheckDependencies`   |

Etter godkjenning starter **`npm run scratch-org`** fullt oppsett på alle tre
operativsystemene. npm velger Bash på Mac/Linux og PowerShell på Windows;
flaggene følger derfor plattformen.

Se **[scratch-org-guiden](bin/README.md)** for første oppsett, konfigurasjon,
pool, nøkler og feilsøking. Alle flagg og flere eksempler finnes i
[kommandoreferansen](bin/COMMANDS.md).

## Finn frem

| Jeg vil …                                                     | Start her                                                                                                                 |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Sette opp PC/Mac og gjøre min første endring                  | [Kom i gang](docs/kom-i-gang.md)                                                                                          |
| Forstå løsningen og hvor koden ligger                         | [Arkitekturoversikt](docs/architecture/hele-loysinga.md) og [repositorystruktur](docs/architecture/repositorystruktur.md) |
| Sette opp scratch-org eller oppdatere pakker                  | [Skriptguide](bin/README.md), [kommandoer](bin/COMMANDS.md) og [plattformstøtte](bin/COMPATIBILITY.md)                    |
| Følge utviklings- og teststandardene                          | [Utviklingsstandarder](docs/utviklingsstandarder.md)                                                                      |
| Forstå PR-sjekker, pakkeoppretting og deploy                  | [Workflowoversikt og kjente begrensninger](docs/operations/workflows.md)                                                  |
| Finne dokumentasjon om P360, Altinn eller andre integrasjoner | [Integrasjoner](docs/integrations/README.md)                                                                              |
| Finne domene, brukerflater og tekniske beslutninger           | [Dokumentasjonskart](docs/README.md) og [ADR-er](docs/adr/README.md)                                                      |

## Lokal validering

Kjør fra prosjektroten etter `npm ci`. Velg den minste kontrollen som dekker endringen:

| Kommando                           | Hva den kontrollerer                                                                     |
| ---------------------------------- | ---------------------------------------------------------------------------------------- |
| `npm run test:node`                | Lokale utviklerverktøy, hooks, endringsfilter og workflowkontrakter                      |
| `npm run test:unit -- --runInBand` | LWC Jest-tester                                                                          |
| `npm test -- --runInBand`          | Node-testene, deretter LWC Jest-testene                                                  |
| `npm run test:dependency-report`   | Egne Jest/jsdom-tester for den interaktive avhengighetsrapporten; ikke del av `npm test` |
| `npm run prettier:check`           | Formatering av filer som dekkes av prosjektets Prettier-oppsett                          |

Dette er lokale kontroller. Apex-kompilering, Apex-tester og metadata mot
org-tilstand krever Salesforce-tilgang. Se [plattformspesifikke tester og feilsøking](docs/kom-i-gang.md#5-hvis-noe-stopper).

### Behovsstyrte PR-sjekkar

PR-sjekkene velger Salesforce-/LWC-validering ut fra endringene. Rene
dokumentasjons- og verktøyendringer trenger normalt ikke org-validering.
Se [reglene for endringsfilteret](scripts/README.md#behovsstyrte-ci-sjekkar).

### Workflowar og merge til main

Relevante push til `main` starter pakkeoppretting **og installasjonsvalidering i SIT**.
Direkte kildedeploy til dev er bare manuell.
Den delte scratch-org-helperen er blokkert av kjente feil; bruk den dokumenterte
lokale flyten etter godkjenning. Se [hele workflowoversikten](docs/operations/workflows.md)
for triggere, ansvar og manglende godkjenningsvern.

## Kode, avhengigheter og bidrag

- Produktkoden ligger i [force-app/](force-app/). Apex-tester og testverktøy ligger
  i [force-app/tests/classes/](force-app/tests/classes/).
- [sfdx-project.json](sfdx-project.json) beskriver pakker og versjoner.
  Pakkeeide referansemapper er ikke vanlige produktmapper.
- Lag en egen branch, gjør en avgrenset endring og oppgi kontroller og resultater
  i PR-en. Se [arbeidsflyten](docs/arbeidsflyt-og-dokumentasjon.md).
- Pre-commit beskytter pakkeeide mapper og formaterer staged filer.
  Se [hook-guiden](scripts/README.md#pre-commit-og-formatering).
- [AGENTS.md](AGENTS.md) og [CONTEXT.md](CONTEXT.md) beskriver repoets grenser
  og kontekst for agentassistert arbeid.

Org-oppretting, pakkeinstallasjon og deploy krever eksplisitt godkjenning.
Autentisering eller et eksisterende alias er ikke i seg selv en tillatelse.
Agentassistert org-tilgang krever ny bekreftelse av mål og handling før hver
kommando. Agenter skal aldri aksessere produksjon, heller ikke via Dev Hub.
Se [miljøreglene](docs/utviklingsstandarder.md#org--og-miljøsikkerhet).
Testtilgang, innloggingsdetaljer, nøkler og personopplysninger hører ikke hjemme i repoet.

Den valgfrie [Salesforce Project CLI-en](tools/salesforce-project-cli/README.md)
har egen installasjon og webflate. Den kreves ikke for vanlig utvikling eller scratch-org-skriptene.

## Eierskap og ansvar

| Ansvar                                                                        | Team                                                                                        | Lenker                                                                                               |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Produkt og repository                                                         | [Team Arbeidsforhold](https://teamkatalog.nav.no/team/29d44f3f-ff09-477c-b26a-83cd0aa66116) | [NAIS Console](https://console.nav.cloud.nais.io/team/crm-arbeidsforhold)                            |
| Tilgang, bidrag og kodegjennomgang                                            | `@navikt/crm-arbeidsforhold`                                                                | [CODEOWNERS](CODEOWNERS) · [NAIS Console](https://console.nav.cloud.nais.io/team/crm-arbeidsforhold) |
| Plattformføringer og godkjenning av menneskelige produksjonsmetadataendringer | [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f)      | [NAIS Console](https://console.nav.cloud.nais.io/team/platforce)                                     |
| Verifikasjon og sletting i produksjon                                         | [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f)      | [NAIS Console](https://console.nav.cloud.nais.io/team/platforce)                                     |

Se [utviklingsstandardene](docs/utviklingsstandarder.md#eierskap-og-ansvar) for detaljer om ansvarsdelingen.

Lisens: [MIT](LICENSE).
