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
- [x] Verifisert at dei nye Markdown-filene har gyldig struktur og passerer isolert Prettier-sjekk.

## Neste steg

- [ ] Teamet må verifisere at Nav si interne agentiske utviklingspolicy er rett tolka for dette repoet, særleg krav til datahandtering, logging, modellbruk og godkjenning.
- [ ] Køyre Nav agent-readiness via `mcp-onboarding.nav.no` eller `nav-pilot` når verktøyet er tilgjengeleg og brukaren er autentisert.
- [ ] Vurdere periodisk gjennomgang mot nye versjonar av Matt Pocock sine skills utan å kopiere inn språk- eller rammeverkspesifikke antakingar.
- [ ] Avklare issue tracker og lagringsstad for specs, ADR-ar og tickets før `to-spec`/`to-tickets`-flyt blir innført.
- [ ] Lage ein liten, reell Apex- eller LWC-endring gjennom TDD-flyten og dokumentere raud test, grøn test og breiare validering.
- [ ] Legge til ein PR-review-sjekk som krev relevant test og review av kjeldegrenser for endringar i `force-app/`.
- [ ] Vurdere lokal secret scanning med Gitleaks dersom teamet godkjenner verktøyet og CI ikkje allereie dekkjer behovet.
- [ ] Vurdere `.github/agents/` med ein Salesforce-spesialist berre dersom ein konkret arbeidsflyt ikkje kan dekkast av instruksjonar og skills.
- [ ] Ta ein separat naming-/ApexDoc-gjennomgang av eksisterande kode og lag ei prioritert oppryddingsliste; ikkje masse-rename deployed metadata utan migreringsplan.

### Første kartleggingsfunn

- Hovudpakkja har legacy-testmetodar med `test...`-prefiks i `AAREG_HomeControllerTest` og `AAREG_ApplicationControllerTest`. Dette er eit eigna første naming-oppryddingstiltak, men krev eiga TDD-/review-skive.
- Repo-søket viser ApexDoc på fleire sentrale klasser, men dette er ikkje nok til å konkludere om komplett ApexDoc-dekning for alle offentlege kontraktar.
- `force-app/unpackagable/` og dei eksterne pakke-eigde mappene skal ikkje takast med i denne oppryddinga utan eksplisitt godkjenning.

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
