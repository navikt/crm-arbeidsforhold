# AI-oppsett TODO

Dette er arbeidslista for agentisk utvikling i `crm-arbeidsforhold`. Status betyr berre at artefakten er lagt inn eller kontrollert lokalt; han betyr ikkje at ein ekstern Nav-teneste eller Salesforce-org er verifisert.

## Ferdig

- [x] Rot-`AGENTS.md` med Salesforce-kontekst, kjeldegrenser og menneskeleg godkjenning.
- [x] `.github/copilot-instructions.md` som peikar til repo- og pakkespesifikke reglar.
- [x] `.github/instructions/agentic-development.instructions.md` med Nav-prinsipp, grøn/raud sone og TDD-gate.
- [x] `.github/skills/tdd-salesforce/SKILL.md` med Salesforce-tilpassa red-green-refactor.
- [x] `.github/skills/code-review-two-axis/SKILL.md` med separat standard- og spec-review.
- [x] Valgt lokale Salesforce-tilpassingar som vedlikehaldt fasit for Matt Pocock-praksis; originalane blir referansekjelder.
- [x] Lagt inn Platforce naming conventions, Salesforce Well-Architected og ApexDoc som standardhierarki for nye og endra Salesforce-kontraktar.
- [x] Lagt til mønstertilpassa Apex-instruks for `.cls`-filer i `.github/instructions/salesforce-apex.instructions.md`.
- [x] Lagt til mønstertilpassa LWC-instruks for `.js`, `.html` og `.css` i `.github/instructions/salesforce-lwc.instructions.md`.
- [x] Lagt til mønstertilpassa metadata-instruks for Salesforce XML, Flow og objekt-/feltmetadata i `.github/instructions/salesforce-metadata.instructions.md`.
- [x] Lagt til mønstertilpassa testinstruks for Apex `*Test.cls` og LWC `__tests__` i `.github/instructions/salesforce-testing.instructions.md`.
- [x] Korrigert selector-eksempelet i `force-app/main/default/AGENTS.md` slik at det følgjer PascalCase-regelen.
- [x] Presisert `@AuraEnabled`-feilhandtering i `force-app/main/default/AGENTS.md` slik at blanket-catch ikkje blir anbefalt.
- [x] Lagt til mønstertilpassa GitHub Actions-instruks for `.github/workflows/**/*.yml` i `.github/instructions/github-actions.instructions.md`.
- [x] Køyrt `nav-pilot doctor`: user-scope Nav-tilpassingar er installerte, `rtk` og Git er OK, og repo-scope er medvite ikkje installert fordi repoet har Salesforce-spesifikke tilpassingar.
- [x] Verifisert at `cplt` støttar repo-scope policy via `config init --repo`, review og separat `cplt trust` før aktivering.
- [x] Køyrt `nav-pilot sync --dry-run`: ingen registrert syncbar collection blei funnen; user-scope-filene er likevel validerte av `nav-pilot doctor`.
- [x] Stadfesta med `nav-pilot list --installed` at ingen collection er registrert; repoet behandlast derfor som manuelt vedlikehaldt inntil teamet vel ein collection-strategi.
- [x] Dokumentert lokal verktøybaseline: Nav Pilot `2026.07.26-074941-46bcf6b`, cplt `2026.07.14-084701-5cac7d9` og Node `v22.20.0`.
- [x] Lagt til `CONTEXT.md` med Aa-registeret-domene, arkitekturgrenser, red-zone og verifikasjonsvokabular.
- [x] Lagt til `.github/PULL_REQUEST_TEMPLATE.md` med TDD-, scope-, to-aksa review- og human-approval-sjekkliste.
- [x] Strukturvalidert lokale instructions og skills: frontmatter, `applyTo`, `name` og `description` er til stades for dei relevante filene.
- [x] Lagt til user-invokable `.github/prompts/tdd-salesforce-slice.prompt.md` for ein konkret Salesforce red-green-refactor-skive.
- [x] Lagt til user-invokable `.github/prompts/review-salesforce-change.prompt.md` for separat Standards-/Specification-review.
- [x] Starta første TDD-skive med ein isolert `linkPanel`-test for unread-badge åtferd.
- [x] Verifisert `linkPanel`-skiva grøn: 2 fokuserte Jest-testar passerer etter installasjon av `@salesforce/sfdx-lwc-jest`, `jest-canvas-mock` og `@sa11y/jest`, og lokale mocks for navigation og Community base path.
- [x] Fjerna Jest-rendercrash i `aareg_applicationInternal` ved å gjere feilmeldinga null-safe for både Apex-feil med `body.message` og enklare feilobjekt.
- [x] Verifisert at dei nye Markdown-filene har gyldig struktur og passerer isolert Prettier-sjekk.
- [x] Repoet si lokale tolking av Nav-prinsippa er kontrollert mot `AGENTS.md`, `CONTEXT.md` og agentinstruksen: små endringar, lokal validering, TDD, raud sone, human control og eksplisitt verifikasjonsstatus er dekte.
- [x] Vurdert Matt Pocock sine skills og anbefalingar: repoet brukar prinsippa gjennom Salesforce-tilpassa TDD- og review-skills, utan å kopiere inn språk- eller rammeverkspesifikke antakingar.
- [x] Lagt inn ein lokal, Salesforce-tilpassa kjerne av Matt Pocock-inspirerte skills: `setup-matt-pocock-skills`, `grill-with-docs`, `to-spec`, `to-tickets`, `implement` og `diagnosing-bugs`, i tillegg til `tdd-salesforce` og `code-review-two-axis`.
- [x] Lage ein liten, reell LWC-endring gjennom TDD-flyten: `aareg_applicationInternal` viser Apex-feil utan å krasje når `error.body` manglar; regresjonstest og brei Jest-validering er grøne.
- [x] TDD-pilot: fokuserte testar og brei Jest-validering er grøne; 3 suites og 4 testar passerer gjennom `npm test`.
- [x] Vurdert behovet for `.github/agents/`: ikkje nødvendig no, fordi repoet har Salesforce-spesifikke instruksar, skills og prompts som dekkjer den dokumenterte arbeidsflyten.
- [x] Vedtatt hybrid forvaltning av AI-oppsettet: Nav sine generelle reglar kan forvaltast i user-scope/collection, medan Salesforce-, Aa-registeret- og repo-spesifikke reglar skal liggje i repoet. Bygg og test skal ikkje vere avhengig av ekstern collection.
- [x] Vedtatt dokumentasjonsstruktur: GitHub Issues for arbeidsoppgåver, `.github/specs/` for korte feature-spesifikasjonar, `docs/adr/` for arkitekturvedtak og `CONTEXT.md` for stabil domene- og arkitekturkontekst.
- [x] Human-approved Nav AI-policy gate: Copilot Business gjennom Nav-organisasjonen, isolerte agentar med `cplt` eller tilsvarande, godkjende MCP-serverar, avgrensa coding-agent-oppgåver med menneskeleg PR-godkjenning, og utviklaransvar for forståing, testing, review og sikkerheit.
- [x] Aktivert og verifisert cplt-sandbox i user-scope med `sandbox.agent = "copilot"`: configen validerer, standard restrictive sandbox-defaults er aktive, og repoet har ingen ekstra trust-permisjonar.
- [x] Vedtatt at repoet ikkje treng ein repo-lokal `.cplt.toml`: einaste kandidaten (`sandbox.allow_lifecycle_scripts` for husky sitt `prepare`-script) er ein supply-chain-risiko som ikkje er nødvendig for agentens vanlege arbeid (Jest, Prettier, filendringar i `force-app/`). Salesforce-autentisering, deploy og scratch-org er alt klassifisert som menneskelege handlingar i `AGENTS.md` og køyrer ikkje inni sandboxen.
- [x] Vurdert `nav-pilot doctor`-varselet «Agent not pinned to nav-pilot» (`cplt config set copilot.agent_name nav-pilot`): stadfesta på nytt etter at cplt auto-oppdaterte til `2026.08.17-062831-1008a92` — `copilot.agent_name` finst framleis ikkje som gyldig nøkkel. Dette er ein feil i `nav-pilot doctor`, ikkje eit repo-problem. Vi forfølgjer det ikkje vidare; varselet blokkerer ikkje agent-readiness.

- [x] Korrigert tidlegare 404-funn: rett domene for `mcp-onboarding` er `https://mcp-onboarding.intern.nav.no`, ikkje `mcp-onboarding.nav.no`. `GET /health` svarer `{"status":"healthy"}`. Dette var eit domenenamn-avvik, ikkje eit tilgangs- eller driftsproblem.
- [x] Køyrt `check_agent_readiness` for `navikt/crm-arbeidsforhold` via MCP-serveren `io.github.navikt/mcp-onboarding`. Resultat: **Basic (2/14)**, 0/8 customizations funne (ingen `AGENTS.md`, `copilot-instructions.md`, `.github/instructions/`, `.github/skills/`, `.github/prompts/`, `.github/workflows/copilot-setup-steps.yml`). Årsak stadfesta: verktøyet les GitHub sin default branch (`main`), som er 32 commits bak. Alt arbeidet i denne oppsett-økta ligg berre på `origin/KlargjørForAgentiskKoding` og er ikkje merga. Dette er forventa, ikkje ein feil i repo-oppsettet.
- [x] `KlargjørForAgentiskKoding` merga til `main` (PR #964). `check_agent_readiness` køyrd på nytt mot `main`: **Intermediate (7/14)**, 5/8 customizations (`copilot-instructions.md`, `.github/instructions/`, `.github/prompts/`, `.github/skills/`, `AGENTS.md`). Verktøyet rapporterer framleis manglande «Test configuration» og «Linter configuration»; dette ser ut som falske negativ sidan repoet har `jest.config.js` og Prettier-oppsett — truleg gjenkjenner ikkje verktøyet `sfdx-lwc-jest`/Prettier-mønsteret. Attståande reelle gap: `.github/agents/`, `.github/workflows/copilot-setup-steps.yml`, `.github/hooks/copilot-hooks.json`, `.github/dependabot.yml`.
- [x] Lagt til `.github/workflows/copilot-setup-steps.yml` for Copilot coding agent. Forslaget frå `generate_setup_steps`-verktøyet hadde feil jobbnamn (`setup`); korrigert til påkravd `copilot-setup-steps` og lagt til `push`/`pull_request`-triggerar per GitHub sin dokumentasjon, slik at oppsettet blir validert i PR før det blir teke i bruk av agenten.
- [x] Lagt til `.github/dependabot.yml` med `npm`- og `github-actions`-økosystem, veke-intervall og `open-pull-requests-limit: 5`. Dekkjer ikkje Salesforce Unlocked Package-avhengigheiter (`sfdx-project.json`), sidan Dependabot ikkje støttar det økosystemet.
- [x] Vedtatt: TDD-/reviewkrav skal handhevast lokalt i dette repoet (ikkje i den delte `navikt/crm-workflows-base`-workflowen). Lagt til `.github/workflows/pull_request-lwc-validation.yml` som køyrer `npm ci`, `npm test` og `npm run prettier:check` på alle PR-ar, som eit uavhengig sjekkpunkt ved sidan av `Validate PR`-sjekken. Dette handhevar at testar passerer og formattering er korrekt, ikkje at TDD-prosessen (raud→grøn) faktisk blei følgd — det er framleis eit menneskeleg review-punkt. «Required status check» i branch protection må aktiverast separat på GitHub for at sjekken skal blokkere merge.

## Neste steg

- [ ] Vurdere pinning til immutable commit-SHA for `navikt/crm-workflows-base/...@master`, `actions/checkout@v4` og `actions/setup-node@v4` (brukt i `copilot-setup-steps.yml` og `pull_request-lwc-validation.yml`). Utsett: `crm-workflows-base@master` bør avklarast med det eigande plattformteamet før pinning, sidan det er ein ekstern workflow utan semantiske tag-versjonar. `actions/checkout`/`actions/setup-node` kan pinnast lågrisiko når som helst, sidan Dependabot (github-actions-økosystemet) held SHA-en oppdatert automatisk.
- [ ] Vurdere lokal secret scanning med Gitleaks dersom teamet godkjenner verktøyet og CI ikkje allereie dekkjer behovet.
- [ ] Ta ein separat naming-/ApexDoc-gjennomgang av eksisterande kode og lag ei prioritert oppryddingsliste; ikkje masse-rename deployed metadata utan migreringsplan.

### Første kartleggingsfunn

- Hovudpakkja har legacy-testmetodar med `test...`-prefiks i `AAREG_HomeControllerTest` og `AAREG_ApplicationControllerTest`. Dette er eit eigna første naming-oppryddingstiltak, men krev eiga TDD-/review-skive.
- Repo-søket viser ApexDoc på fleire sentrale klasser, men dette er ikkje nok til å konkludere om komplett ApexDoc-dekning for alle offentlege kontraktar.
- `force-app/unpackagable/` og dei eksterne pakke-eigde mappene skal ikkje takast med i denne oppryddinga utan eksplisitt godkjenning.
- Repoet har ingen lokal Salesforce Code Analyzer-konfigurasjon eller npm-script; PR-valideringa brukar `navikt/crm-workflows-base`. Vurder Code Analyzer gjennom eksisterande Nav-workflow før ny lokal dependency eller CI blir introdusert.
- Read-only review fann at fleire workflows brukar mutable `@master`-referansar. Dette er eit Trusted-/supply-chain-funn, men pinning til immutable commit-SHA krev eksplisitt godkjenning fordi det endrar CI/auth-konfigurasjon.
- Read-only review fann at `force-app/main/default/AGENTS.md` har eldre eller motstridande døme i prosjektstruktur og selector-naming. Dette bør ryddast i ei separat dokumentasjonsskive før naming-opprydding i Apex.
- Spec-axis i code review er avgrensa så lenge issue tracker og lagringsstad for specs/tickets ikkje er valt.
- Upstream-kjelde for dei tilpassa engineering-skillsa: https://github.com/mattpocock/skills. Repoet held ved like Salesforce-adapterar lokalt i staden for å vere avhengig av upstream-filer eller ekstern collection.

## Vedtak

Vi kopierer ikkje inn heile Matt Pocock-biblioteket. `tdd-salesforce` og
`code-review-two-axis` er repo-spesifikke tilpassingar basert på prinsippa i
originalane. Det reduserer vedlikehald, unngår TypeScript/Vitest-antakingar i
Apex/LWC, og gjer Salesforce-org-avhengige testgrenser eksplisitte.

Nav sine krav har prioritet over generelle agentpraksisar. Ved konflikt skal
teamet stoppe og avklare kva som er gjeldande Nav-policy før reglane blir endra.

## Kjelder

- Nav Copilot: https://github.com/navikt/copilot
- Nav agent-readiness: https://mcp-onboarding.nav.no/
- Matt Pocock sine skills: https://github.com/mattpocock/skills
- AI Hero skills: https://www.aihero.dev/skills
- TDD-prinsippet: https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md
- To-aksa code review: https://github.com/mattpocock/skills/blob/main/skills/engineering/code-review/SKILL.md
- Bevisst AI-bruk frå Nav: https://github.com/navikt/copilot/blob/main/instructions/deliberate-ai-use.instructions.md
- Nav Platforce naming conventions: https://navikt.github.io/platforce-doc/reference/naming-conventions/
- Nav Salesforce Code Analyzer: https://navikt.github.io/platforce-doc/reference/linting/salesforce-code-analyzer/
- Salesforce Architecture Center: https://architect.salesforce.com/
- Salesforce Well-Architected Framework: https://architect.salesforce.com/docs/architect/well-architected/guide/overview
- Salesforce ApexDoc: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_doc_intro.htm
