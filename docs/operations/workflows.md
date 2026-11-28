# Workflower og leveranse

Denne siden beskriver workflowene i `crm-arbeidsforhold` og begrensningene som
ble funnet ved gjennomgangen 2026-10-26. Org-operasjoner er ikke kjørt som del
av den lokale valideringen.

## Triggere og ansvar

| Workflow                        | Utløser og ansvar                                                                                                                                                                                                                           |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `[PUSH] Create Package`         | Push til `main` som endrer `force-app/**`, `sfdx-project.json` eller `.forceignore`, og manuell start. Oppretter pakke, validerer installasjon i SIT og lager release via delt workflow.                                                    |
| `[PUSH] Deploy to Dev`          | Bare manuell kildedeploy fra `main` til dev, med oppdatering av avhengigheter og `RunLocalTests`. Andre brancher hopper over deployjobben før checkout og autentisering.                                                                    |
| `[PR] Validate`                 | Ikke-utkast-PR-er til alle brancher, også navn med `/`. Bruker behovsstyrt Salesforce-validering.                                                                                                                                           |
| `[CI] Maintain CI scratch org`  | Dagleg og manuelt frå `main`. Oppgraderer pakkeversjonar trygt i den registrerte CI-orgen, røyketestar endringar og opprettar/oppdaterer ei issue til repo-eigarteamet når manuell utskifting trengst. Opprettar eller slettar ikkje orgar. |
| `[PR] LWC tests and formatting` | Alle PR-er. Kjører Node-/rapporttester, relevante LWC-tester og formateringskontroll av endrede filer.                                                                                                                                      |
| `Salesforce validation`         | Lokal gjenbrukbar workflow kalt av PR-valideringen. Bevarer påkrevde sjekknavn og krever vellykket delt validering når den er relevant.                                                                                                     |
| `Scratch org offline`           | Relevante PR-er og push til `main`, eller manuell start. Tester lokale skript på Windows, Linux og Mac uten Salesforce-org, inkludert workflowkontraktene.                                                                                  |
| `Copilot Setup Steps`           | Copilot-oppsett, manuell start og endringer i selve workflowfilen. Installerer Node og npm-avhengigheter.                                                                                                                                   |
| `Dokumentasjon og GitHub Pages` | PR-er bygger og kontrollerer dokumentasjonen med leserettigheter. Push til `main` eller manuell start fra `main` kan publisere etter godkjenning i `github-pages`-miljøet.                                                                  |
| `[HELPER] Create Scratch Org`   | Manuell, men blokkert av feil i den delte implementasjonen; se nedenfor.                                                                                                                                                                    |
| `[HELPER] Quick Package Create` | Manuell rask pakkeoppretting via delt workflow.                                                                                                                                                                                             |
| `[HELPER] Promote Package`      | Manuell promotering, versjonsoppdatering og release via lokal workflow; PREPROD/UAT-installasjon bruker delt workflow.                                                                                                                      |
| `[HELPER] Deployment`           | Manuell pakkeinstallasjon i valgt sandboxmiljø via delt workflow.                                                                                                                                                                           |
| `[HELPER] Deploy to Production` | Manuell pakkeinstallasjon i produksjon via delt workflow.                                                                                                                                                                                   |

På PR-er kjører en lett endringskontroll alltid. Dokumentasjonsbygget kjøres
bare når Markdown, Mermaid-diagrammer, `docs/`, `docs-site/`, `mkdocs.yml`,
`requirements-docs.in`, `requirements-docs.txt` eller dokumentasjonsworkflowen er endret. Push til
`main` og manuell start bygger fortsatt uavhengig av endrede filer.

Push-utløseren gjelder også direkte push, ikke bare PR-merge.
Rene dokumentasjonsendringer lager ikke pakke. Direkte dev-deploy kjører ikke
automatisk parallelt ved merge.

Pages-bygg har bare lesetilgang. Publiseringsjobben trenger `pages: write` for
selve deployen, `id-token: write` for GitHub Pages sin identitetskontroll og
`contents: read` for å kontrollere at committen fortsatt er siste `main`.
Før deploy avvises en eldre kjøring hvis en nyere `main`-commit er synlig.
Publiseringsjobben kjører én om gangen. GitHub køer opptil 100 ventende
deployjobber og kansellerer nye deployjobber hvis køen er full. Pågående
deploy kanselleres ikke, og PR-bygg og validering kjører uavhengig av køen.
Teamet må godkjenne deploy i `github-pages`.

Workflowfilene ligger i [.github/workflows/](../../.github/workflows/).
Se også [reglene for behovsstyrt PR-validering](../../scripts/README.md#behovsstyrte-ci-sjekkar).

## Ekstern eier og valideringsansvar

`navikt/crm-workflows-base` eier de delte Salesforce-workflowene. Den lokale
pakke-promoteringsworkflowen kaller den delte `deployPackage.yml`-workflowen
for installasjon i PREPROD og UAT. Referansen er festet til commit
`aad6b4f48e419d71490db436da697cd7581a2c6a`. Eieren har ansvar for
implementasjonen av installasjonsworkflowen og dens org-oppsett.

Selve promoteringa, opprettinga av versjons-PR, auto-merge etter kravde
kontrollar og GitHub Release ligg lokalt i
`.github/workflows/package-promotion.yml`. Produksjonsautentisering og
Salesforce-pakkeoperasjonar skjer framleis berre når workflowen blir starta
manuelt med godkjende repository-secrets.

Lokal SHA-pinning låser ikke transitive action-referanser: den delte
implementasjonen bruker fortsatt flere muterbare tags og `@master`/`@main`.
Dette er eksterne referanser, ikke lokale branch-utløsere. Endringer må gjøres
og verifiseres hos eieren før den lokale SHA-referansen oppdateres.

## Kjente begrensninger

- Den delte `createScratchOrg.yml` bruker utgåtte `actions/upload-artifact@v2`
  og `actions/download-artifact@v2`, og skriver til `GITHUB_OUTPUT` uten `$`.
  Ikke bruk helperen før eieren har rettet dette. Bruk den dokumenterte
  [lokale scratch-org-flyten](../../bin/README.md) med eksplisitt godkjenning i mellomtiden.
- Bare GitHub-miljøet `copilot` fantes ved gjennomgangen; det hadde ingen
  godkjenningsregler. De delte org-jobbene bruker ikke beskyttede GitHub
  environments. Manuell start er ikke et separat godkjenningssteg.
  Miljøvern og godkjennere må avklares og kobles til de faktiske org-jobbene
  hos eieren før deploy-/releaseflyten kan regnes som godkjenningsvernet.
- Pakkeoppretting installerer også i SIT. Dette er eksisterende delt atferd
  som aktiveres igjen av `main`-utløseren, ikke bare en lokal byggejobb.

## Lokal kontroll

```text
node --test scripts/tests/ci-workflows.test.cjs
```

Testene inngår også i `npm run test:node`. De sjekker triggere, CLI-kontrakt,
eksplisitte tokenrettigheter, direkte shell-interpolering og lokale SHA-referanser,
uten nye avhengigheter.
De verifiserer ikke eksterne workflower, secrets, GitHub-miljøvern eller org-tilstand.

Detaljer om eksisterende hjelpeworkflower finnes i
[workflowdokumentasjonen](../../.github/workflows/documentation/).
