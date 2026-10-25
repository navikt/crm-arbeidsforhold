---
slug: altinn-consumer-scenarios
status: draft
---

# Feature Specification: Konsumentstyrte Altinn-resultat i Arbeidsforhold

**Dato:** 2026-10-20  
**Status:** Diskusjonsklart utkast. Cache-alternativ er ikkje valt.  
**Føringar:** [AGENTS](../../AGENTS.md), [CONTEXT](../../CONTEXT.md) og lokal TDD-gate.

## Scope Baseline

Vi testar crm-arbeidsforhold si handtering av organisasjonar, rettar og feil, ikkje
Altinn-integrasjonen. To Apex-kallestader og éin community-komponent er identifiserte:
`AAREG_HomeController`, `AAREG_CommunityUtils` og `aareg_home`.

Første leveranse: scenario-køyring, miljø-/brukarvern, Setup-basert tildeling og
dokumenterte testscenario. Ein framtidig Admin-app skal kunne bruke dei same
scenarioa og runtime-reglane. Administrasjonsteneste, scenarioeditor og Admin-UI
blir ikkje bygde no, etter avklaringa 2026-10-20.

Utanfor scope: Altinn HTTP/auth/token-testing, mock-server, v2-utfasing,
automatisk oppretting/sletting av produktdata, automatisk tilbakekalling av
deling og testing med scenario i produksjon.

## User Scenarios & Testing

### US1 - Vanleg drift utan testoppsett (P1)

Som systemeigar vil eg installere løysinga utan å opprette ein scenario-record.

**Sjølvstendig test:** Verifiser provider-val ved manglande, null og avskrudd oppsett.

1. **Given** ingen org- eller brukarrecord, **When** tenesta blir vald, **Then**
   blir ordinær teneste brukt utan feil som skuldast manglande scenario-oppsett.
2. **Given** ingen org-record, men eksplisitt aktivert brukarrecord i tillate
   testmiljø, **When** godkjend testbrukar nyttar løysinga, **Then** blir det
   tildelte scenarioet brukt.
3. **Given** aktivt scenario utan gyldig definisjon, **When** det blir brukt,
   **Then** blir ein tydeleg feil vist og ingen Altinn-callout utført.

### US2 - Gjennomføre kontrollerte brukarreiser (P1)

Som testar vil eg velje namngitte scenario i Setup og bruke communityen som normalt.

**Sjølvstendig test:** Bruk isolerte syntetiske brukarar og data for S01-S08.
Scratch-oppsettet har dedikerte brukarar for S01-S04 og S06; S05/S07/S08 blir
verifiserte som tom-, feil- og stale-selection-scenario i Apex-testane fordi
scratch-org-en har ei avgrensa High Volume Customer Portal-lisenskvote.

1. **Given** S01, **When** brukaren vel organisasjonen, **Then** blir
   søknadstilgang gitt gjennom ordinær applikasjonslogikk.
2. **Given** S02, **When** retten blir sjekka, **Then** blir søknadsrett Deny og
   brukerstøtterett Permit, med `hasAccess=true` og `hasApplicationAccess=false`.
3. **Given** S03 og ingen tidlegare delingar, **When** retten blir sjekka,
   **Then** blir begge tilgangsverdiane false og ingen nye delingar oppretta.
4. **Given** fleire organisasjonar, **When** brukaren byter organisasjon,
   **Then** gjeld rettane for den valde organisasjonen, ikkje den førre.

### US3 - Produksjon og feilbruk (P1)

Som systemeigar vil eg hindre at testfunksjonar gir syntetiske rettar i produksjon.

1. **Given** produksjon og ingen aktiv scenariotildeling, **When** løysinga blir
   brukt, **Then** held ordinær drift fram.
2. **Given** produksjon og eit aktivt scenario-oppsett, **When** runtime-bana blir
   forsøkt brukt, **Then** blir ho avvist før syntetiske resultat eller
   scenarioutløyste produktendringar, utan live-fallback.
3. **Given** ein brukar utan mock-rett eller ein annan målbrukar, **When**
   scenario-bruk blir forsøkt, **Then** blir det avvist før syntetiske svar.

### US4 - Repeterbare testar og framtidig administrasjon (P2)

1. **Given** eit valt og dokumentert cache-alternativ, **When** testprosedyren blir
   følgd, **Then** høyrer organisasjonsliste og rettssvar til same testscenario.
2. **Given** tidlegare Permit, **When** same brukar får Deny, **Then** skal testen
   observere både UI-utfall og eksisterande delingar utan at mocken slettar dei.
3. **Given** framtidig Admin-UI, **When** det blir bygd, **Then** kan det bruke
   scenarioidentitetane og runtime-policyen utan å endre provider-kontrakten.

### Edge Cases

- Org-/profilrecord med `true` skal ikkje aktivere mock for alle brukarar.
- Avslått mock-tilgang skal ikkje skjulast som eit vellukka Deny-scenario.
- Tidlegare valt organisasjon kan mangle i neste scenario eller vere filtrert bort.
- Ukjent ressurs/organisasjon skal aldri få Permit automatisk.
- Ein sandbox-refresh kan kopiere oppsett; mock krev framleis eksplisitt
  brukaraktivering, permission og kontrollert testdatagrunnlag.
- Scenarioendring mellom separate Apex-kall kan gi inkonsistent testøkt;
  scenariobyte skal skje utan pågåande brukarhandlingar.

## Requirements

### Functional Requirements

- **REQ-004:** Manglande scenario-record, null aktivering og eksplisitt false skal
  bety scenario-modus av. Dette skal ikkje krevje org-standard eller ny
  testpermission for vanleg drift.
- **REQ-005:** Berre eksplisitt aktiv brukarspesifikk tildeling skal kunne aktivere
  scenario. Manglande org-record skal ikkje hindre slik tildeling. Org-/profil-arv
  skal ikkje kunne aktivere mock for andre brukarar.
- **REQ-006:** Produksjon og ukjend miljøstatus skal sperre scenario-køyring
  server-side, også ved direkte runtime-bruk utan UI. Ingen produksjonsoverstyring
  skal leverast. Manglande/avskrudd oppsett skal ikkje sperre normal produksjonsdrift.
- **REQ-007:** Scenario-bruk skal krevje særskild testpermission på den innlogga
  brukaren. Målbrukar skal vere den innlogga brukaren, og førespurd identitet skal
  samsvare med den brukarens tilknytte syntetiske testidentitet.
- **REQ-008:** Aktivt, ugyldig eller forbode scenario-oppsett skal gi eksplisitt
  feil utan live-fallback. Infrastruktur-/lesefeil skal ikkje skjulast som
  manglande oppsett eller som eit vellukka testresultat.
- **REQ-009:** Organisasjons- og rettsoppslag skal bruke same tildelingsregel på
  tvers av separate UI-transaksjonar. Scenario-køyring skal gjere null callouts.
- **REQ-010:** Scenario skal ha stabil identitet, versjon og beskriving, og kunne
  lesast uavhengig av Setup eller framtidig Admin-UI.
- **REQ-011:** Scenario skal definere organisasjonar og rettar per syntetisk
  identitet, organisasjon og ressurs. Ukjende kombinasjonar skal avvisast eksplisitt,
  ikkje gi implisitt Permit eller kontakte Altinn.
- **REQ-012:** Provider skal levere dagens responskontrakt, inkludert v3-markering
  for organisasjonar og dagens Action/Decision/Resource-felt. Urealistiske
  feilvariantar skal merkast som robustheitstestar, ikkje live-kontraktevidens.
- **REQ-013:** S01-S08 nedanfor skal vere tilgjengelege som dokumenterte scenario
  med konkrete forventa applikasjonsutfall.
- **REQ-014:** Provider skal ikkje overta UI-filtrering, tilgangsavgjerd,
  organisasjonslagring eller delingslogikk. Desse skal testast i applikasjonen.
- **REQ-015:** Cache-strategien skal sikre ein dokumentert, repeterbar teststart
  utan blanding av gamle organisasjonssvar og nye rettssvar. Begge alternativa
  skal planleggjast; valet skal takast før cache-/UI-implementering.
- **REQ-016:** Dersom dynamisk oppfrisking blir vald, skal ho nullstille gamle
  tilgangsverdiar, hente ferske organisasjonar og sjekke gyldig val på nytt.
  Manglande/filtrert organisasjon og feila oppfrisking skal ikkje behalde tilgangen.
- **REQ-017:** Testprosedyren skal skilje mellom rein Deny-test og Permit-til-Deny.
  Mocken skal ikkje slette delingar. Bortfall av rett skal observerast som eigen
  test, ikkje maskerast med opprydding.
- **REQ-018:** Scenario-oppsett og provider skal ikkje opprette, endre eller slette
  produktdata. Ordinære UI-handlingar kan framleis gi reell DML i testmiljø.
  Andre utgåande kanalar må sikrast separat før slike handlingar.
- **REQ-019:** Berre autorisert administrator skal kunne endre tildelingar gjennom
  Setup. Testbrukaren skal ikkje få administrasjonsrettar. Nye offentlege
  administrasjons-/skriveendepunkt skal ikkje leverast i denne fasen.
- **REQ-020:** Runtime-policy, scenarioidentitet og lesing skal vere uavhengige av
  administrasjonsflata. Framtidig administrasjonsteneste, redigering, UI og
  endringshistorikk skal ha eigen leveranse og ikkje reknast som implementert no.
- **REQ-021:** Teststøtta kan inngå i app-pakken med hard produksjonssperre.
  Manuell fjerning av kjelde før pakkebygging skal ikkje vere ein del av løysinga.
- **REQ-022:** Filer, scenario, feilmeldingar og loggar skal ikkje eksponere
  personidentar, credentials, org-URL-ar eller faktiske responsdata. Scenario
  brukar logiske testidentitetar bunde til syntetiske brukarar i miljøet.
- **REQ-023:** Normal, avskrudd bane skal bevare eksisterande funksjonell åtferd.
  Medvite endra feil-/UI-åtferd skal spesifiserast og testast, ikkje smuglast inn
  som transportrefaktorering.
- **REQ-024:** Før godkjenning skal fokuserte Apex-/LWC-testar og guida
  ikkje-produksjonsreiser dokumentere utfalla. Org-avhengige testar skal ikkje
  kallast grøne utan faktisk vellukka køyring. Ingen produksjonsdata skal brukast
  for å teste sperra.

### Key Entities

- **Scenariodefinisjon:** Stabil ID/versjon, beskriving, organisasjonar, rettar og feil.
- **Scenariotildeling:** Eksplisitt brukaraktivering og valt scenario.
- **Testidentitet:** Logisk alias som bind syntetisk brukar til scenariodata utan
  å lagre personidenten i scenariofilene.
- **Miljøpolicy:** Server-side avgjerd om scenario-bruk er tillaten.

## Scenario Catalogue

| ID | Innhald | Forventa applikasjonsutfall |
| --- | --- | --- |
| S01 | A, B og C, alle med søknad Permit | Søknadstilgang; eksisterande delingsflyt blir brukt |
| S02 | A, B og C med søknad Deny og brukerstøtte Permit | Berre brukerstøttetilgang |
| S03 | A, B og C med begge ressursar Deny | Ingen tilgang eller nye delingar for rein brukar |
| S04 | A, B og C med ulik rettsmatrise | Organisasjonsbyte nyttar rett svar per organisasjon |
| S05 | Vellukka tom organisasjonsliste | Ingen tilgjengeleg organisasjon; observer forståeleg tomtilstand |
| S06 | To AS, ENK, BEDR og ein Person | Dagens filtrering utført av UI, ikkje provider |
| S07 | Kontrollert feil ved organisasjons-/rettsoppslag | Ingen tilgang gitt; relevant feilmelding/feilgrense |
| S08 | Tidlegare valt organisasjon manglar | Registrer dagens åtferd; eventuell retting får eksplisitt godkjend slice |

S07 skil responsfeil frå kasta exception. Kva variantar live-klienten faktisk
leverer skal dokumenterast frå dagens kontrakt før scenarioa blir merkte som
realistiske. Vi utvidar ikkje integrasjonstesting for å gjere dette.

## Success Criteria

- Alle åtte scenario har repeterbare Apex-testar; S01-S04 og S06 har i tillegg
  eigne scratch-brukarar for nettlesartesting.
- Scratch-seedet opprettar syntetiske Account-, Application- og Agreement-postar
  for organisasjonane 111111111–444444444.
- S01-S04 gir forventa tilgangsutfall utan eksternt Altinn-oppsett.
- Ingen scenario kan gi syntetiske rettar i produksjon eller for uautorisert brukar.
- Installasjon utan scenario-record krev null ekstra Setup-handlingar for normal drift.
- Det valde cache-alternativet gir same scenario for liste og rettar ved teststart.
- Ingen endring i eksisterande delingar blir utført av scenario-provideren.

## Assumptions and Open Decision

- Føreslått første lagring er versjonerte scenariofiler bak ein eigen lesar.
  Brukaren ønskjer enklast mogleg veg til framtidig Admin-app; dette er eit
  designforslag, ikkje eit krav om at Admin skal redigere JSON.
- Eigen permission fungerer som eksplisitt godkjenning av den syntetiske brukaren.
  Administrator har ansvar for syntetisk identitet og isolerte testdata.
- **D01 - Avklart: A, dynamisk oppfrisking.** Brukaren valde dette alternativet
  etter omfangsgjennomgang; T015–T016 implementerer oppfrisking med `@wire` og
  `refreshApex`. REQ-016 gjeld. Alternativ B er ikkje valt.

Sjå [design og kritiske spørsmål](../../docs/integrations/altinn/README.md),
[grill-runden](../../docs/integrations/altinn/grill.md) og
[planen](../../docs/integrations/altinn/implementation-plan.md).
