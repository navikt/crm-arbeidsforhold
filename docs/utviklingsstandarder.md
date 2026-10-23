---
tittel: Utviklingsstandarder (SF)
kilde: Repoet — crm-arbeidsforhold
oppdatert: 2026-10-22
speilkopi: nei
---

# Utviklingsstandarder (SF)

Denne siden samler utviklingsstandarder for Aa-registeret Salesforce-løsningen.

Siden er repo-eid fra 2026-10-22 og er ikke lenger en speilkopi fra Confluence.
Confluence må oppdateres til å beskrive kildeansvaret og lenke til denne siden.
Inntil den oppfølgingen er utført, kan Confluence ha en eldre beskrivelse.
Oppfølging: [GitHub Issue #1142](https://github.com/navikt/crm-arbeidsforhold/issues/1142).

Formålet er å gjøre det lettere å utvikle konsistent, testbart og vedlikeholdbart på tvers av teammedlemmer og funksjonsområder.

Standardene her skal være praktiske og konkrete. De skal hjelpe utviklere å ta gode valg i hverdagen, ikke være pyntedokumentasjon som ingen bruker.

## Hva hører hjemme her?

- Namnestandard for Apex, LWC, metadata og testklasser
- Teststruktur og testprinsipper
- Apex-testassertions og `Test`-livssyklus må bruke den fullt kvalifiserte Salesforce-namneplassen: `System.Assert.*` og `System.Test.*`. Ikke bruk bare `Assert` eller ukvalifisert `Test` i Apex-kode.
- README-struktur
- Retningslinjer for package og deploy
- Regler for plassering av kode og metadata
- Bruk av fakes, mocks og builders
- Dokumentasjonsstandarder

## Hva hører ikke hjemme her?

- Arkitekturbegrunnelser som bør være ADR
- P360-spesifikke mappingregler
- Driftshåndbøker
- Saksbehandlerdokumentasjon

## Merknad om overlapp i dette repoet

Repoet har allerede maskinlesbare utviklingsstandarder som dekker mye av det denne siden lister opp:

| Område                                    | Hvor det ligger i repoet                                                                                                |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Apex-standarder                           | [.github/instructions/salesforce-apex.instructions.md](../.github/instructions/salesforce-apex.instructions.md)         |
| LWC-standarder                            | [.github/instructions/salesforce-lwc.instructions.md](../.github/instructions/salesforce-lwc.instructions.md)           |
| Metadata-standarder                       | [.github/instructions/salesforce-metadata.instructions.md](../.github/instructions/salesforce-metadata.instructions.md) |
| Teststruktur og testprinsipper            | [.github/instructions/salesforce-testing.instructions.md](../.github/instructions/salesforce-testing.instructions.md)   |
| Navngiving, Apex-regler, Well-Architected | [force-app/main/default/AGENTS.md](../force-app/main/default/AGENTS.md)                                                 |
| Kildegrenser og lokal validering          | [AGENTS.md](../AGENTS.md)                                                                                               |

Instruksjonsfilene er operativ fasit for agenter og styrer daglig utvikling.
Denne repo-eide siden samler oversikten og forklarer arbeidsflyten; den skal
ikke duplisere eller overstyre detaljreglene i instruksjonsfilene.

## Skills og arbeidsflyt

Repoet vedlikeholder små Salesforce-tilpassede skills inspirert av
[Matt Pocock](https://github.com/mattpocock/skills). Upstream er referanse,
ikke en runtime-avhengighet. Vi installerer ikke hele samlingen parallelt med
lokale tilpasninger.

| Arbeid                        | Skill                                                                   | Bruk                                                                       |
| ----------------------------- | ----------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Avklare behov og beslutninger | [grill-with-docs](../.github/skills/grill-with-docs/SKILL.md)           | Brukerstartet; spørsmål i avhengighetsrekkefølge og eksplisitt bekreftelse |
| Vurdere grensesnitt og ansvar | [codebase-design](../.github/skills/codebase-design/SKILL.md)           | Ved relevant designarbeid; små kontrakter og testbar offentlig atferd      |
| Skrive avtalt spesifikasjon   | [to-spec](../.github/skills/to-spec/SKILL.md)                           | Brukerstartet etter avklaring                                              |
| Dele opp leveransen           | [to-tickets](../.github/skills/to-tickets/SKILL.md)                     | Brukerstartet; vertikale skiver og eksplisitte avhengigheter               |
| Implementere godkjent arbeid  | [implement](../.github/skills/implement/SKILL.md)                       | Brukerstartet; ingen implisitt deploy eller pakkeutgivelse                 |
| Test-first                    | [tdd-salesforce](../.github/skills/tdd-salesforce/SKILL.md)             | Red–green–refactor med lokal/org-avhengig evidens skilt                    |
| Diagnostisere feil            | [diagnosing-bugs](../.github/skills/diagnosing-bugs/SKILL.md)           | Etabler en reproduserbar feil før produksjonskode endres                   |
| Gjennomgå endringer           | [code-review-two-axis](../.github/skills/code-review-two-axis/SKILL.md) | Standarder og spesifikasjon vurderes separat                               |
| Forbedre agentarbeidsflyten   | [retro](../.github/skills/retro/SKILL.md)                               | Brukerstartet; konkrete funn og forslag før endring                        |

`disable-model-invocation: true` betyr at en skill er ment å startes eksplisitt
av brukeren. De øvrige kan velges av agenten når beskrivelsen passer.
En gyldig fil er ikke bevis på at verten har oppdaget den: kontroller
slash-kommandoen i VS Code før en skill erklæres tilgjengelig eller manglende.

Avklaringsrunden skal skille fakta, godkjente beslutninger, forslag og åpne
spørsmål. Et spørsmål med uavklarte forutsetninger venter til neste runde.
Brukeren bekrefter utfallet før det behandles som avtalt.

Designarbeid skal begrunne nye abstraksjoner, identifisere testseam og vise
relevante Trusted/Easy/Adaptable-tradeoffs. Retrospektiv skal forbedre
verktøybruk og feedback, ikke automatisk legge til flere instruksjoner.

Stabile domenebegreper hører hjemme i [CONTEXT.md](../CONTEXT.md), og viktige
arkitekturvalg i [ADR-er](adr/README.md). Vi oppretter ikke en konkurrerende
glossary som del av disse skillene.

Se [kildeoppdelingen](architecture/README.md) for forholdet mellom repoet og Confluence.
