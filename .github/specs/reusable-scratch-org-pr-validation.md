---
slug: reusable-scratch-org-pr-validation
status: planned
github-epic: https://github.com/navikt/crm-arbeidsforhold/issues/1267
---

# PR-validering på gjenbrukbar scratch-org

## Problem

`[PR] Validate` lagar ein ny scratch-org for kvar PR som endrar Salesforce-kjelde,
installerer alle 19 pakkeavhengigheiter og køyrer valideringa. Det tek om lag
30 minutt per køyring, sjølv når berre éi Apex-klasse er endra.

Den parallelle piloten viste at:

- gjenbruk av ein ferdig oppsett org fungerer og vel rett rute
  (`reuse validation: CI scratch org matches the package plan.`);
- fallback til ny org fungerer (`fresh validation: Scratch configuration changed.`);
- gjenbruksruta brukte om lag 22,5 minutt mot 31 minutt for vanleg validering,
  og då inkluderte ho alle repo-testane;
- `RunSpecifiedTests` krev minst 75 % dekning **per klasse og trigger**.
  `AAREG_AdminMonitorController` feila på 72 % og vart retta i #1263;
- piloten laga mange unødvendige køyringar fordi han starta på
  `workflow_run: in_progress`, og han kravde manuell miljøgodkjenning per PR.

Piloten blir avslutta. Vi byggjer den endelege workflowen direkte.

## Ønskt resultat

Ein utviklar opnar ein PR og får **éin** Salesforce-validering som:

1. brukar den gjenbrukbare CI-orgen når han er klar, og elles lagar ny org automatisk;
2. aldri krev manuell godkjenning per PR;
3. viser i GitHub kva rute som vart valt og kvifor, kor lang tid kvart steg tok,
   og kva som eventuelt feila, utan at nokon må lese rå CLI-loggar;
4. beheld dei tre påkravde sjekknamna, slik at branch protection ikkje må endrast.

Ingen må manuelt opprette eller oppdatere CI-orgen. Ein planlagd workflow held
han frisk og på rett pakkeversjon.

## Oversikt

```mermaid
flowchart LR
    PR[PR opna eller oppdatert] --> V["[PR] Validate"]
    V --> C{Salesforce-endringar?}
    C -- nei --> SKIP[Sjekkane blir grøne utan org]
    C -- ja --> R{Vel rute}
    R -- CI-org klar --> REUSE[Gjenbruk CI-org]
    R -- ikkje klar --> FRESH[Ny eingongsorg]
    REUSE --> RES[Resultat: kompilering, testar, dekning]
    FRESH --> RES
    RES --> SUM[Lesbar oppsummering i PR og Actions]

    N["[CI] Maintain CI scratch org<br/>(dagleg + manuell)"] -.-> ORG[(CI scratch-org)]
    REUSE -.-> ORG
```

## Flyt i `[PR] Validate`

```mermaid
flowchart TD
    A[1. Finn endringar] -->|ingen Salesforce| Z[Grønt: ingen org trengst]
    A -->|Salesforce| B[2. Vel rute]
    B --> B1{Secret registrert?}
    B1 -- nei --> F
    B1 -- ja --> B2{Innlogging OK?}
    B2 -- nei --> F
    B2 -- ja --> B3{Går ut om meir enn 1 døgn?}
    B3 -- nei --> F
    B3 -- ja --> B4{Pakkeversjonar = pakkeplan?}
    B4 -- nei --> F
    B4 -- ja --> B5{Scratch-definisjon uendra?}
    B5 -- nei --> F
    B5 -- ja --> B6{"Færre enn 2 andre PR-ar ventar i kø?"}
    B6 -- nei --> F
    B6 -- ja --> RU

    RU[3a. Gjenbruk: check-only deploy<br/>+ repo-testar + dekning] --> G
    F[3b. Fallback: ny org, installer pakkeplan,<br/>deploy, repo-testar, dekning, slett org] --> G

    G[4. Lag resultatfil] --> H1[Compile Metadata]
    G --> H2[Run Apex Tests]
    G --> H3[Validate 85% Code Coverage]
```

Rutevalet skjer **før** nokon Salesforce-feil kan oppstå i sjølve valideringa.
Kompilerings-, test- og dekningsfeil gir aldri automatisk fallback, fordi dei
er feil i PR-en og ikkje i orgen.

## Køyring og kø

```mermaid
sequenceDiagram
    participant A as PR A
    participant B as PR B
    participant C as PR C
    participant D as PR D
    participant Q as Kø (concurrency)
    participant ORG as CI-org
    A->>Q: 0 andre PR-ar ventar, vel reuse
    Q->>ORG: Validering A køyrer (tel ikkje som ventande)
    B->>Q: 0 andre PR-ar ventar, vel reuse og ventar
    B->>Q: Ny commit i PR B
    Note over B,Q: Eigne køyringar tel ikkje, B ventar framleis
    C->>Q: 1 annan PR ventar (B), vel reuse og ventar
    D->>Q: 2 andre PR-ar ventar (B og C)
    Note over D: D går til fallback med ny org
    ORG-->>A: Resultat A
    Q->>ORG: Validering B
```

Valideringa er check-only og endrar ikkje kjelda i orgen. Køen er ein felles
lås for CI-orgen. Han hindrar at to deployar konkurrerer i same org, og at
vedlikehaldet oppgraderer pakkar eller slettar orgen medan ein PR validerer.
Fallback-ruta brukar ikkje låsen.

Når ei gjenbruksvalidering har fått låsen, kontrollerer ho tilstanden til orgen
på nytt: registrering, utløp, pakkeversjonar og fingeravtrykk. Har noko endra
seg medan ho venta, går ho til fallback før deployen startar.

Når to eller fleire **andre** PR-ar har ei køyring som **ventar** på CI-orgen,
vel nye køyringar fallback. Elles ville ventetida i køen ete opp tidsvinsten.
Køyringa som er i gang mot orgen, tel ikkje. Kvar PR tel éin gong, sjølv om han
har fleire ventande commitar, og køyringar frå same PR tel ikkje.

## Vedlikehald av CI-orgen

```mermaid
flowchart TD
    start["[CI] Maintain CI scratch org: dagleg kl. 05 og manuelt"] --> lock["Ta den felles låsen for CI-orgen"]
    lock --> fresh{"Finst orgen, varer han meir enn 7 døgn til og stemmer fingeravtrykket med main?"}
    fresh -->|nei| pending{"Finst det ein kandidat som ventar på registrering?"}
    pending -->|ja, gyldig| notify
    pending -->|ja, ugyldig| discard["Slett den forkasta kandidaten"]
    discard --> create
    pending -->|nei| create["Lag ny kandidat-org"]
    create --> install["Installer pakkeplan"]
    install --> smoke["Røyktest: validering av main"]
    smoke -->|bestått| notify["Oppsummering og varsel: registrer ny org manuelt"]
    notify --> secret["Person køyrer éin kommando: dekrypter artefakt og registrer alle fire samla"]
    secret --> remove["Neste vedlikehald slettar gammal org når alle fire peikar på den nye"]
    smoke -->|feila| keep["Slett kandidaten, behald gammal org og vis feilen i oppsummeringa"]
    fresh -->|ja| plan{"Pakkeversjonar lik pakkeplan?"}
    plan -->|ja| unchanged["Ingen endring"]
    plan -->|nei| upgrade["Installer manglande eller nyare versjonar i same org"]
    upgrade --> unchanged
```

Registreringa består av secreten `CI_SCRATCH_ORG_AUTH_URL` og variablane
`CI_SCRATCH_ORG_ID`, `CI_SCRATCH_ORG_EXPIRATION` og
`CI_SCRATCH_ORG_CONFIG_SHA256`. Ho blir oppdatert manuelt inntil vidare. Medan
ho er halvferdig, går PR-ane til fallback. Ein GitHub App med skrivetilgang
til miljø-secrets kan valfritt takast i bruk seinare for å automatisere dette
steget. Fram til alle fire verdiane er oppdaterte, held PR-ane fram på den gamle orgen
eller fallback.

Medan ein røyktesta kandidat ventar på registrering, lagar vedlikehaldet ingen
nye orgar. Det minner om registreringa i kvar køyring. Slik er det aldri meir
enn éin kandidat i tillegg til den registrerte orgen, og kvoten for scratch-orgar
blir verande ledig for fallback.

Ein feil i vedlikehaldet stoppar ikkje PR-ar. Dei går til fallback til orgen er
frisk igjen.

## Krav

### Ruting og fallback

- **REQ-100:** `[PR] Validate` startar éi Salesforce-validering per PR-oppdatering. Draft-PR-ar og PR-ar utan Salesforce-endringar køyrer ikkje mot org.
- **REQ-101:** Gjenbruk blir valt berre når secret finst, innlogging lukkast, orgen går ut om meir enn eitt døgn, alle 19 pakkeversjonar er nøyaktig lik pakkeplanen og fingeravtrykket til scratch-definisjonen er uendra.
- **REQ-102:** Elles blir det laga ein eingongsorg som blir sletta etter køyringa, også ved feil.
- **REQ-103:** Kompilerings-, test- og dekningsfeil gir aldri fallback.
- **REQ-104:** Gjenbruksruta brukar check-only deploy og endrar ikkje kjelda i CI-orgen.
- **REQ-106:** Gjenbruksvalideringa og muterande vedlikehald (pakkeoppgradering, sletting og byte av org) brukar den same eksklusive låsen. Etter at låsen er teken, blir tilstanden i REQ-101 kontrollert på nytt før deploy. Avvik gir fallback.
- **REQ-107:** Når secreten og dei tre variablane ikkje peikar på same org, vel ruta fallback med grunnen «registreringa er ikkje komplett». Valideringa blir ikkje avbroten.
- **REQ-105:** Når to eller fleire andre PR-ar har ei køyring som ventar på CI-orgen, vel ei ny køyring fallback. Køyringa som er i gang, tel ikkje. Kvar annan PR tel éin gong, og køyringar frå same PR tel ikkje mot grensa. Grunnen og talet på ventande PR-ar blir vist i oppsummeringa.

### Testpolicy

- **REQ-110:** Begge rutene køyrer dei same repo-testklassane, funne med `ci-scratch-plan.cjs tests`.
- **REQ-111:** Samla repo-dekning må vere minst 85 %.
- **REQ-112:** Fordi gjenbruksruta brukar `RunSpecifiedTests`, krev Salesforce minst 75 % per deploya klasse og trigger. Brot blir vist som ein eigen tabell med klasse, dekning og manglande prosentpoeng.
- **REQ-113:** Klassar og triggarar som er lagde til eller endra i PR-en og manglar dekningsdata, blir rekna som 0 % i grunnlaget for 85 %-kravet i staden for å bli utelatne. Testklassar (`@IsTest`), interface og filer i `.forceignore` blir hoppa over. Filene blir lista i oppsummeringa som «⚠️ ingen dekningsdata». Dei gir ikkje eigen stoppfeil. Åtferda blir stadfesta når workflowen blir teken i bruk; det trengst ikkje eiga verifisering i org på førehand.

### Godkjenning og tryggleik

- **REQ-120:** Ingen manuell miljøgodkjenning per PR. Miljøet `ci-scratch-org` blir behalde for secrets, utan required reviewers.
- **REQ-121:** Fork-PR-ar får ikkje tilgang til secrets og køyrer ikkje Salesforce-validering.
- **REQ-122:** Skript som tek avgjerder blir henta frå base-commiten, ikkje frå PR-en.
- **REQ-123:** Ingen secrets, auth-URL-ar, brukarnamn, org-ID-ar eller testdata med persondata blir skrivne til oppsummering, annotasjonar eller artefakt.

### Lesbar output

- **REQ-130:** Kvar køyring skriv ei oppsummering øvst med rute, grunngjeving, org-utløp, tid per steg og samla resultat.
- **REQ-131:** `Compile Metadata` viser kompileringsfeil som tabell: komponent, type, linje og melding.
- **REQ-132:** `Run Apex Tests` viser tal på testar, beståtte, feila og tid, og ein tabell over feila testar med klasse, metode og første linje av feilmeldinga.
- **REQ-133:** `Validate 85% Code Coverage` viser samla dekning mot krav og dei ti klassane med lågast dekning, og eventuelle klassar under 75 %.
- **REQ-134:** Feil blir òg sende som GitHub-annotasjonar (`::error file=…,line=…::`), slik at dei synest i PR-diffen.
- **REQ-135:** Status blir vist med både ikon og tekst (`✅ Bestått`, `❌ Feila`, `⏭️ Hoppa over`), slik at han ikkje er avhengig av farge.
- **REQ-136:** Rå CLI-JSON blir ikkje skriven til loggen. Han blir lagra som artefakt med 7 dagars levetid, utan identitetsfelt.

### Vedlikehald

- **REQ-140:** `[CI] Maintain CI scratch org` køyrer dagleg og manuelt.
- **REQ-141:** Orgen blir fornya når han manglar, går ut om sju døgn eller mindre, eller når fingeravtrykket for scratch-definisjonen og `sourceApiVersion` på `main` ikkje stemmer med registreringa.
- **REQ-142:** Ny org blir teken i bruk berre etter at røyktesten mot `main` er grøn.
- **REQ-143:** Avvik i pakkeversjonar blir retta i same org når det er mogleg. Elles blir orgen fornya.
- **REQ-144:** Vedlikehaldet viser same type oppsummering: tilstand før og etter, pakkar endra og utløpsdato.
- **REQ-145:** Ny org blir registrert manuelt etter ein grøn røyktest. Secreten og dei tre variablane blir oppdaterte samla, og oppsummeringa listar namna på dei fire som må endrast, utløpsdatoen og fingeravtrykket. Org-ID og auth-URL blir ikkje viste (REQ-123). Auth-URL-en blir overlevert som kryptert artefakt etter REQ-147. Den gamle orgen blir ikkje sletta før alle fire peikar på den nye. Automatisering med GitHub App er valfri og kan komme seinare.
- **REQ-146:** Det finst høgst éin kandidat-org om gongen. Kandidaten blir merkt i Dev Hub, til dømes med `Description` på `ScratchOrgInfo`, slik at tilstanden «ventar på registrering» overlever mellom køyringar utan å skrive til repoet. Ein gyldig kandidat (røyktesta, går ut om meir enn sju døgn og fingeravtrykket stemmer med `main`) blir gjenbrukt. Ein ugyldig kandidat blir sletta før ein ny blir oppretta. Ein kandidat som feilar røyktesten, blir sletta med ein gong.
- **REQ-147:** Etter grøn røyktest krypterer vedlikehaldet auth-URL-en til kandidaten med ein offentleg nøkkel lagra som repo-variabel (`CI_SCRATCH_ORG_HANDOFF_PUBLIC_KEY`), og lastar han opp som artefakt med eitt døgns levetid. Klartekst blir aldri skriven til logg, oppsummering eller artefakt. Den private nøkkelen finst berre hos operatøren. Ein lokal kommando lastar ned artefaktet, dekrypterer, set secreten og dei tre variablane samla med `gh`, og slettar artefaktet. Har artefaktet gått ut, lagar neste vedlikehald eit nytt for same kandidat.

### Opprydding

- **REQ-150:** `ci-reusable-pr-pilot.yml`, pilotdelane av `ci-pr-pilot.cjs` og pilotartefakta blir fjerna.
- **REQ-151:** Avhengigheita til `navikt/crm-workflows-base/.github/workflows/validate.yml` i `salesforce-validation.yml` blir fjerna.
- **REQ-152:** `docs/operations/workflows.md` og `docs/operations/reusable-scratch-org-validation.md` blir oppdaterte. Pilotsteg 8–10 blir arkiverte.

## Eksempel på oppsummering

```text
## Salesforce-validering for PR #1234

| Steg                    | Status       | Tid    |
|-------------------------|--------------|--------|
| Rute                    | ♻️ Gjenbruk  | 0:12   |
| Kompilering             | ✅ Bestått   | 6:40   |
| Apex-testar (480)       | ❌ 2 feila   | 14:05  |
| Dekning                 | ⏭️ Ikkje vurdert | –  |

Rute: gjenbruk – CI-org samsvarar med pakkeplanen (19/19), går ut 2026-12-07.

### Feila testar
| Klasse                     | Metode                         | Feil                          |
|----------------------------|--------------------------------|-------------------------------|
| AAREG_ApplicationControllerTest | submitsApplicationWithAttachments | System.AssertException: Expected 2, actual 1 |
```

## Testseam

- Ruting, testutval, dekningsvurdering og oppsummeringsformat: Node-testar i `scripts/tests/` med fiktive CLI-resultat. Køyrast med `npm run test:node`.
- Workflow-kontraktar (sjekknamn, rekkjefølgje, permissions, ingen `secrets: inherit` til tredjepart): eksisterande `ci-workflows.test.cjs`.
- Faktisk org-åtferd: éin forkastbar test-PR per rute etter merge. Dei er ikkje ein del av lokal validering.

## Avgjerder

| Avgjerd | Val | Grunn |
|---|---|---|
| Pilot | Blir avslutta | Rutene er demonstrerte. Vidare pilot gir støy og ventetid. |
| Sjekknamn | Uendra | Branch protection treng ikkje endrast. |
| Testnivå | Repo-testar (`RunSpecifiedTests`) | Pakketestar blir ikkje køyrde på nytt. 75 %-kravet per klasse er akseptert. |
| Godkjenning | Ingen per PR | Dagens påkravde validering har allereie Dev Hub-secret utan godkjenning. Gjenbruks-secreten gir tilgang berre til ein scratch-org. |
| Fornying av secret | Manuell registrering no; GitHub App valfritt seinare | Vi tek ikkje i bruk GitHub App no. Vedlikehaldet gjer resten automatisk og seier frå når secreten må oppdaterast. |
| Kø-grense | Fallback ved 2 eller fleire andre PR-ar i kø | Lang kø et opp tidsvinsten. Commitar i same PR tel ikkje. |
| Dekning for endra filer utan data | Tel som 0 %, ingen eigen stoppfeil | Tettar holet for utesta nye klassar utan falske positive for interface og liknande. |

## Tryggleik og data

- Dev Hub-secreten `CRM_PROD_SFDX_URL` gir tilgang til ein produksjonstilknytt Dev Hub. Han blir brukt berre til å lage og slette scratch-orgar, slik som i dag. Agentar køyrer ikkje desse stega.
- CI-orgen inneheld berre syntetiske testdata.
- Endringa rører CI og auth og krev menneskeleg review og security-review før merge.

## Utanfor scope

- Snapshots og scratch-org-pool.
- Endring av LWC-, dokumentasjons- og pakkeworkflowar.
- Parallell bruk av fleire CI-orgar.

## Avklarte spørsmål

1. GitHub App for automatisk oppdatering av secreten blir ikkje teken i bruk no. Det er eit valfritt steg seinare (REQ-145).
2. Køyringa går til fallback når to eller fleire andre PR-ar ventar i kø for CI-orgen. Køyringa som er i gang, og fleire køyringar i same PR tel ikkje (REQ-105).
3. Auth-URL-en til ein ny kandidat blir overlevert som kryptert artefakt som operatøren dekrypterer og registrerer med éin lokal kommando (REQ-147). JWT-innlogging er forkasta fordi det krev Dev Hub-sertifikatet lokalt.
