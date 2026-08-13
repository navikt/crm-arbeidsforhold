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

## Neste steg

- [ ] Teamet må verifisere at Nav si interne agentiske utviklingspolicy er rett tolka for dette repoet, særleg krav til datahandtering, logging, modellbruk og godkjenning.
- [ ] Køyre Nav agent-readiness via `mcp-onboarding.nav.no` eller `nav-pilot` når verktøyet er tilgjengeleg og brukaren er autentisert.
- [ ] Vurdere periodisk gjennomgang mot nye versjonar av Matt Pocock sine skills utan å kopiere inn språk- eller rammeverkspesifikke antakingar.
- [ ] Avklare om Nav user-scope-filene skal forvaltast gjennom ein registrert collection, eller om teamet skal vedlikehalde repo-tilpassingane manuelt med Nav som referansekjelde.
- [ ] Avklare issue tracker og lagringsstad for specs, ADR-ar og tickets før `to-spec`/`to-tickets`-flyt blir innført.
- [x] Lage ein liten, reell LWC-endring gjennom TDD-flyten: `aareg_applicationInternal` viser Apex-feil utan å krasje når `error.body` manglar; regresjonstest og brei Jest-validering er grøne.
- [x] TDD-pilot: fokuserte testar og brei Jest-validering er grøne; 3 suites og 4 testar passerer gjennom `npm test`.
- [ ] Vurdere automatisk CI-handheving av PR-malen og relevante review-/testkrav gjennom eksisterande Nav-workflow; malen støttar prosessen, men handhevar ikkje krava åleine.
- [ ] Vurdere lokal secret scanning med Gitleaks dersom teamet godkjenner verktøyet og CI ikkje allereie dekkjer behovet.
- [ ] Vurdere `.github/agents/` med ein Salesforce-spesialist berre dersom ein konkret arbeidsflyt ikkje kan dekkast av instruksjonar og skills.
- [ ] Vurdere cplt-agentval (`sandbox.agent=copilot`) og ein repo-lokal `.cplt.toml`; cplt vel sjølve klienten, medan Nav Pilot si klientkonfigurasjon er separat. Dette krev teamavklaring om sandbox-policy og separat `cplt trust`, og skal ikkje innførast automatisk.
- [ ] Ta ein separat naming-/ApexDoc-gjennomgang av eksisterande kode og lag ei prioritert oppryddingsliste; ikkje masse-rename deployed metadata utan migreringsplan.

### Første kartleggingsfunn

- Hovudpakkja har legacy-testmetodar med `test...`-prefiks i `AAREG_HomeControllerTest` og `AAREG_ApplicationControllerTest`. Dette er eit eigna første naming-oppryddingstiltak, men krev eiga TDD-/review-skive.
- Repo-søket viser ApexDoc på fleire sentrale klasser, men dette er ikkje nok til å konkludere om komplett ApexDoc-dekning for alle offentlege kontraktar.
- `force-app/unpackagable/` og dei eksterne pakke-eigde mappene skal ikkje takast med i denne oppryddinga utan eksplisitt godkjenning.
- Repoet har ingen lokal Salesforce Code Analyzer-konfigurasjon eller npm-script; PR-valideringa brukar `navikt/crm-workflows-base`. Vurder Code Analyzer gjennom eksisterande Nav-workflow før ny lokal dependency eller CI blir introdusert.
- Read-only review fann at fleire workflows brukar mutable `@master`-referansar. Dette er eit Trusted-/supply-chain-funn, men pinning til immutable commit-SHA krev eksplisitt godkjenning fordi det endrar CI/auth-konfigurasjon.
- Read-only review fann at `force-app/main/default/AGENTS.md` har eldre eller motstridande døme i prosjektstruktur og selector-naming. Dette bør ryddast i ei separat dokumentasjonsskive før naming-opprydding i Apex.
- Spec-axis i code review er avgrensa så lenge issue tracker og lagringsstad for specs/tickets ikkje er valt.

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
