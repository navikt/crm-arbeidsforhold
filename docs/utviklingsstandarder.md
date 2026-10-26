---
tittel: Utviklingsstandarder (SF)
kilde: Repoet — crm-arbeidsforhold
oppdatert: 2026-10-26
speilkopi: nei
---

# Utviklingsstandarder

Denne siden er utviklerens inngang til standardene for Aa-registerets
Salesforce-løsning. Start med [kom i gang](kom-i-gang.md) for lokalt oppsett.

## Kortversjonen

- Finn nærmeste kode og tester før du velger mønster.
- Gjør små endringer innenfor riktig pakkegrense.
- Test observerbar atferd, også relevante feil og tilgangsgrenser.
- Skill lokale kontroller fra org-avhengig verifisering.
- Bevar offentlige kontrakter; planlegg omdøping og sletting som egne endringer.
- Oppgi faktisk utførte kontroller og gjenstående arbeid i PR-en.

## Kilder og prioritet

Konkrete, gjeldende føringer fra [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f) og relevante Nav-standarder
skal inngå i vurderingen sammen med Platforce-dokumentasjonen. Følg alle
relevante krav som ikke er i konflikt; prioriteringslisten er ikke et valg
mellom kilder.

Følg repoets [standardhierarki](../AGENTS.md#standards-hierarchy):

1. Nav-reglene i [hovedpakkens instruksjon](../force-app/main/default/AGENTS.md)
   og [Platforce Documentation](https://navikt.github.io/platforce-doc/),
   blant annet [navngiving](https://navikt.github.io/platforce-doc/reference/naming-conventions/).
2. [Salesforce Architecture Center](https://architect.salesforce.com/) og
   [Well-Architected Framework](https://architect.salesforce.com/docs/architect/well-architected/guide/overview).
3. Gjeldende [offisiell Salesforce-dokumentasjon](https://developer.salesforce.com/docs/)
   for aktuell API-versjon.
4. Etablerte repomønstre når de ikke strider mot føringene over eller en
   uttrykkelig godkjent bevaring av en eksisterende kontrakt.

### Ansvar for å holde seg oppdatert

Hver utvikler har selv ansvar for å holde seg oppdatert på gjeldende Nav-,
Platforce- og Salesforce-retningslinjer og bruke dem i arbeidet.
Kontroller nettversjonene ved planlegging og review; denne siden er ikke
en frosset kopi av eksterne standarder.
Les den relevante kilden når en endring berører et område du ikke kjenner godt.
Ved uklare eller motstridende krav: avklar med riktig fagmiljø, bevar den
deployede kontrakten og dokumenter avviket for menneskelig vurdering.
Ikke masseendre eldre metadata bare for å normalisere navn.

## Eierskap og ansvar

| Ansvar                                                                        | Team                                                                                        | Lenker                                                                                                  |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Produkt og repository                                                         | [Team Arbeidsforhold](https://teamkatalog.nav.no/team/29d44f3f-ff09-477c-b26a-83cd0aa66116) | [NAIS Console](https://console.nav.cloud.nais.io/team/crm-arbeidsforhold)                               |
| GitHub-tilgang, bidrag og kodegjennomgang                                     | `@navikt/crm-arbeidsforhold`                                                                | [CODEOWNERS](../CODEOWNERS) · [NAIS Console](https://console.nav.cloud.nais.io/team/crm-arbeidsforhold) |
| Plattformføringer og godkjenning av menneskelige produksjonsmetadataendringer | [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f)      | [NAIS Console](https://console.nav.cloud.nais.io/team/platforce)                                        |
| Verifikasjon og sletting i produksjon                                         | [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f)      | [NAIS Console](https://console.nav.cloud.nais.io/team/platforce)                                        |

[Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f) er ikke produkteier for dette repoet. [Team Arbeidsforhold](https://teamkatalog.nav.no/team/29d44f3f-ff09-477c-b26a-83cd0aa66116) har
ansvar for at endringer er forstått, testet, dokumentert og klare for review.
Plattformhandlinger avtales med [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f) når de krever deres utføring eller godkjenning.

## Finn detaljreglene

Bruk reglene som gjelder filen og området du endrer:

| Område                                    | Hvor det ligger i repoet                                                                                                |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Apex-standarder                           | [.github/instructions/salesforce-apex.instructions.md](../.github/instructions/salesforce-apex.instructions.md)         |
| LWC-standarder                            | [.github/instructions/salesforce-lwc.instructions.md](../.github/instructions/salesforce-lwc.instructions.md)           |
| Metadata-standarder                       | [.github/instructions/salesforce-metadata.instructions.md](../.github/instructions/salesforce-metadata.instructions.md) |
| Teststruktur og testprinsipper            | [.github/instructions/salesforce-testing.instructions.md](../.github/instructions/salesforce-testing.instructions.md)   |
| Navngiving, Apex-regler, Well-Architected | [force-app/main/default/AGENTS.md](../force-app/main/default/AGENTS.md)                                                 |
| Kildegrenser og lokal validering          | [AGENTS.md](../AGENTS.md)                                                                                               |

Denne siden forklarer arbeidsflyten. Detaljreglene vedlikeholdes i kildene
over, ikke som konkurrerende kopier her.

## Kode, navn og pakkegrenser

- Produktkode og metadata hører hjemme i `force-app/`, i riktig feature- eller
  integrasjonsområde. Følg [repositorystrukturen](architecture/repositorystruktur.md).
- Apex-tester og gjenbrukbare testverktøy legges i
  `force-app/tests/classes/<matching-area>/`, ikke sammen med produksjonsklassene.
- Pakkeeide avhengigheter leses som referanse. Endringer krever eksplisitt
  godkjenning; [pakkemanifestet](../sfdx-project.json) er kilde til pakker og versjoner.
- Bruk forklarende engelske navn for API-er, Apex og metadata.
  Bruk Translation Workbench for brukerrettede norske oversettelser.
  Bevar eksisterende offentlige navn med mindre en godkjent migrering dekker endringen.
- Hold triggere tynne, bulkifiser SOQL/DML og bruk `with sharing` som standard.
  SOQL/DML skal ikke kjøres inne i løkker. Gjør delings- og sikkerhetsvalg eksplisitte.
  Gjenbruk logging, konfigurasjon, testdatafabrikker og pakkekomponenter før nye
  abstraksjoner eller hardkodede verdier innføres.
- Bevar Salesforce source format og valider data ved tillitsgrenser.
  Håndter feil tydelig; ikke skjul dem med stille standardverdier eller brede catches.
- Nye eller vesentlig endrede offentlige Apex-kontrakter dokumenteres med
  ApexDoc etter [Apex-reglene](../.github/instructions/salesforce-apex.instructions.md).

### Navngiving

Følg [Platforce Naming Conventions](https://navikt.github.io/platforce-doc/reference/naming-conventions/).
Velg spesifikke, forklarende navn som samsvarer med forretnings- og integrasjonsspråket
i [CONTEXT.md](../CONTEXT.md). Unngå generiske navn og nye lokale prefikser uten
forankring i feature- eller integrasjonsområdet.

De konkrete mønstrene for klasser, testklasser, metoder og ApexDoc står i
[Apex-instruksjonen](../.github/instructions/salesforce-apex.instructions.md)
og [hovedpakkens instruksjon](../force-app/main/default/AGENTS.md).
Eksisterende offentlige API-navn skal ikke endres bare for å følge en nyere
navnestandard. Dokumenter avviket og behandle omdøping som en egen godkjent migrering.

### Design og risiko

Ved designendringer vurderer vi relevante Well-Architected-dimensjoner:

| Dimensjon     | Spørsmål i review                                           |
| ------------- | ----------------------------------------------------------- |
| **Trusted**   | Er tilgang, personvern, feil og gjenoppretting håndtert?    |
| **Easy**      | Er omfang, kode og brukerflyt forståelig og vedlikeholdbar? |
| **Adaptable** | Er ansvar, pakkegrenser og integrasjonskontrakter tydelige? |

Forklar den viktigste avveiningen og grunnlaget for valget. Kjernelogikk,
autentisering, tilgang, persondata, callouts, metadata-synlighet og pakkekontrakter
krever særlig grundig menneskelig review.

## Test og verifisering

Ved ny atferd eller feilretting bruker vi red–green–refactor i vertikale skiver:
skriv en fokusert atferdstest, observer feil, implementer minste endring,
observer grønt og refaktorer deretter. Kjør relevant bredere kontroll til slutt.

- Test offentlige utfall fremfor privat tilstand eller om kode bare unngår å kaste feil.
- Dekk relevante feiltilfeller, tomme data og tilgangsgrenser. Bruk mocks for callouts,
  ikke ekte nettverkskall.
- Bruk `System.Assert.*` og `System.Test.*` i Apex-tester. Test med minimumstilgang
  når scenariet ikke krever høyere rettigheter; følg
  [testreglene](../.github/instructions/salesforce-testing.instructions.md).
- Kjør minste relevante lokale kontroll først. Kommandoene er samlet i
  [README](../README.md#lokal-validering) og
  [plattformguiden](kom-i-gang.md#5-hvis-noe-stopper).
- Oppgi eksakt kommando, resultat og begrensninger. En lokal grønn test beviser
  ikke Apex-kompilering, pakkeinstallasjon, deploy eller støtte på et annet operativsystem.

Hvis en Apex-test er blokkert av manglende autentisert org, oppgi kommandoen som
gjenstår og forutsetningen for å kjøre den. Ikke rapporter den som bestått.

## Org, pakker og leveranse

### Org- og miljøsikkerhet

- Før **hver** agentkommando som aksesserer Salesforce, skal brukeren bekrefte
  eksakt ikke-produksjonsmål og handling på nytt. Det gjelder også
  standard-scratch-orget `crm-arbeidsforhold`, Dev Hub, innlogging, lesing,
  Apex-tester, deploy preview, retrieval, deploy og skript som kontakter org.
- Forklar den tekniske grunnen før et annet ikke-produksjonsorg enn
  standard-scratch-orget brukes. Autentisering, standardalias, tidligere
  godkjenning eller et eksisterende skript er ikke tillatelse til neste operasjon.
- **Agenter skal aldri aksessere produksjon**, heller ikke etter forespørsel
  eller godkjenning. Forbudet omfatter innlogging, spørringer, metadatahenting,
  tester, deploy og tilgang via en produksjonstilknyttet Dev Hub.
  Avtal menneskelig utføring i stedet.
- Menneskelige endringer i produksjonsmetadata krever eksplisitt godkjenning
  fra [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f). [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f) utfører produksjonsverifikasjon og sletting.
  Godkjenning av en menneskelig handling gir ikke agenten produksjonstilgang.
- Org-oppretting, pakkeinstallasjon, deploy, pakkeoppretting og promotering
  krever fortsatt eksplisitt godkjenning av handlingene.
- Følg godkjente rutiner og registrer handlinger og resultater slik at de kan
  spores i Issue/PR og operasjonssak og kontrolleres mot auditlogger.

Se de fullstendige [org-reglene](../AGENTS.md#org-safety).

Ikke legg inn credentials, installasjonsnøkler, personopplysninger,
hardkodede Salesforce-ID-er eller miljøspesifikke URL-er i kode, tester,
dokumentasjon eller logger.
Se [workflowoversikten](operations/workflows.md) for automatikk og kjente
godkjenningsbegrensninger. Manuell workflowstart er ikke et separat miljøgodkjenningssteg.

### Runbooks, metadataopprydding og skript

Lag eller oppdater en runbook for alle endringer som krever manuelle steg
eller handlinger fra [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f). Runbooken skal angi:

- formål, omfang, Issue/PR og kildekoderevisjon;
- forutsetninger, eksakt målmiljø, ansvarlig utfører og nødvendige godkjenninger;
- lenker til innskjekkede skript og trinnvis fremgangsmåte;
- forventet resultat, verifisering, stoppkriterier og rollback;
- faktisk resultat og evidens per miljø, uten tilgangsdetaljer eller personopplysninger.

Alle skript som [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f) skal kjøre, må være sjekket inn, gjennomgått,
testet, verifisert og godkjent før kjøring. En innskjekket fil alene er ikke
bevis på at skriptet er klart. Oppgi hva som er testet, av hvem og på hvilken
revisjon, samt eventuelle gjenstående godkjenninger.

Ved sletting eller omdøping skal runbooken liste alle relevante metadata-API-navn,
inkludert gammelt og nytt navn. Beskriv avhengigheter og oppryddingssteg.
En sletting i Git eller vanlig source deploy beviser ikke sletting i org.
**Sletting skal verifiseres i SIT2**, etter godkjenning av mål og handling.
**[Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f) skal utføre produksjonsverifikasjon og sletting**; runbooken
skal vise til deres godkjenning og evidens.

Bruk [runbooken for metadataopprydding](operations/salesforce-metadata-cleanup-runbook.md)
som teknisk sjekkliste for opprydding. Registrer aldri et steg som fullført
uten dokumentert resultat. Operative godkjenninger, utførere og endringsvinduer
dokumenteres i riktig Confluence-/operasjonssak og lenkes fra Issue/PR.

## Dokumentasjon som er enkel å bruke

README er inngangsdøren, ikke hele håndboken:

| Dokument                                                                   | Innhold                                                           |
| -------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| [README](../README.md)                                                     | Hva løsningen gjør, kort lokal start, validering og lenker videre |
| [Kom i gang](kom-i-gang.md)                                                | Stegvis oppsett med plattformvalg og tydelige sideeffekter        |
| [Skriptguide](../bin/README.md) og [kommandoreferanse](../bin/COMMANDS.md) | Detaljer, flagg, konfigurasjon og feilsøking                      |
| [Arkitektur og ADR-er](architecture/README.md)                             | Ansvarsdeling, alternativer og begrunnede tekniske valg           |
| [Arbeidsflyt og dokumentasjon](arbeidsflyt-og-dokumentasjon.md)            | Forholdet mellom krav, kode, tester, repo og Confluence           |

Bruk oppgaveorienterte overskrifter og relative lenker. Skill fakta, planlagt
arbeid og verifisert atferd. Oppdater direkte berørt dokumentasjon i samme endring.
Varige eller tverrgående arkitekturvalg registreres som ADR med
[det obligatoriske ADR-formatet](adr/README.md#format). Ikke presenter forslag eller uverifisert
atferd som vedtatt standard.

For plattformvalg bruker vi GitHub-støttet `<details>`/`<summary>` med tydelige
navn: **Mac (macOS)**, **Linux**, **Windows – PowerShell 7** og **Windows – CMD**.
Vanlig GitHub Markdown har ikke innebygde faner. Hold sikkerhetsadvarsler og felles
forutsetninger synlige utenfor de utbrettbare seksjonene, og merk kodeblokker med
`bash`, `powershell` eller `cmd`. Bruk `text` for plattformuavhengige kommandoer.
Ikke bland Bash-flagg og PowerShell-parametere i samme eksempel.

Kildene og plasseringen i `crm-platform-integration` har vært referanse for denne
strukturen, ikke en avhengighet. Vi kopierer ikke det repoets Node-krav,
pakkeversjoner eller testplassering hit. Org- og produksjonsreglene over
er uttrykkelig avklart for dette repoet.

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

## Eierskap til denne siden

Siden er repo-eid fra 2026-10-22, ikke en speilkopi fra Confluence.
Confluence må lenke hit og beskrive kildeansvaret. Inntil oppfølgingen i
[#1142](https://github.com/navikt/crm-arbeidsforhold/issues/1142) er utført,
kan Confluence ha en eldre beskrivelse.
