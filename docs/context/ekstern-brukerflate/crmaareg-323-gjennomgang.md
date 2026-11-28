# Gjennomgang av CRMAAREG-323 mot crm-arbeidsforhold

> **Status:** Analyse og forslag. Ingen Jira-saker eller eksisterande tekstar er endra.
> **Grunnlag:** Jira lesen 2026-11-09 i innlogga nettlesar. Koden er frå greina `P360Test`, revisjon `4beb2d28`.
> **Verifisering:** Tre lokale Jest-suitar har køyrt, og 20 av 20 testar bestod. Ingen Apex-test, org-test, deploy eller ende-til-ende-test er køyrd.

## Innhald

1. [Samandrag](#1-samandrag)
2. [Jira-strukturen](#2-jira-strukturen)
3. [Funn mot eksisterande kode og arkitektur](#3-funn-mot-eksisterande-kode-og-arkitektur)
4. [Forslag til tillegg og endringar per epic](#4-forslag-til-tillegg-og-endringar-per-epic)
5. [Forslag til dei første 10 user stories](#5-forslag-til-dei-første-10-user-stories)
6. [Opne avklaringar](#6-opne-avklaringar)
7. [Krav i crm-arbeidsforhold som alle saker må harmonisere med](#7-krav-i-crm-arbeidsforhold-som-alle-saker-må-harmonisere-med)
8. [Guide: Slik held du fram med agentmodus og intern nettlesar](#8-guide-slik-held-du-fram-med-agentmodus-og-intern-nettlesar)

---

## 1. Samandrag

Epicen bør vere ei **vidareutvikling av eksisterande Experience Cloud-løysing**, ikkje eit nytt portalprosjekt. Søknader, avtalar, kontroll av Altinn-rettar, brukarstøtte og dialog finst allereie i kodebasen. Fleire Jira-krav er likevel ikkje oppfylte i dagens kode eller er for upresise til å kunne testast.

Dei viktigaste punkta er:

- **P0:** Støttetilgang og avtaletilgang er ikkje konsekvent skilde.
- **P0:** Tilgangskontroll og deling kan bruke ulik organisasjonskontekst.
- **P1:** Innvilga søknader blir filtrerte bort frå søknadsoversikta.
- **P1:** Privatpersonar utan organisasjon har inga dokumentert inngang til meldingar.
- **P1:** P360-arkiveringa er ikkje ferdig frå ende til ende. Kvitteringa må derfor ikkje love arkivering.
- **P1:** Ved teknisk feil kan oversiktene vise ei tom liste i staden for ei feilmelding.

Sikkerheit og universell utforming (UU) bør vere ein **gjennomgåande kvalitetsgate** i [CRMAAREG-332](https://nav.atlassian.net/browse/CRMAAREG-332), ikkje ein fase heilt til slutt.

---

## 2. Jira-strukturen

| Sak                                                           | Type            | Innhald                                              | Status  |
| ------------------------------------------------------------- | --------------- | ---------------------------------------------------- | ------- |
| [CRMAAREG-323](https://nav.atlassian.net/browse/CRMAAREG-323) | Epic            | Ekstern brukerflate for eksterne brukere (hovudepic) | Backlog |
| [CRMAAREG-328](https://nav.atlassian.net/browse/CRMAAREG-328) | Epic (lenkt)    | Grunnmur, autentisering og portalrammeverk           | Backlog |
| [CRMAAREG-329](https://nav.atlassian.net/browse/CRMAAREG-329) | Epic (lenkt)    | Brukerstøtte og tovegs dialog                        | Backlog |
| [CRMAAREG-330](https://nav.atlassian.net/browse/CRMAAREG-330) | Epic (lenkt)    | Digital søknad                                       | Backlog |
| [CRMAAREG-331](https://nav.atlassian.net/browse/CRMAAREG-331) | Epic (lenkt)    | Mine søknader og Mine avtaler                        | Backlog |
| [CRMAAREG-332](https://nav.atlassian.net/browse/CRMAAREG-332) | Epic (lenkt)    | Sikkerheit, universell utforming og pilot/lansering  | Backlog |
| [CRMAAREG-324](https://nav.atlassian.net/browse/CRMAAREG-324) | Story under 323 | Målgruppehistorie                                    | Backlog |
| [CRMAAREG-325](https://nav.atlassian.net/browse/CRMAAREG-325) | Story under 323 | Målgruppehistorie                                    | Backlog |
| [CRMAAREG-326](https://nav.atlassian.net/browse/CRMAAREG-326) | Story under 323 | Målgruppehistorie                                    | Backlog |
| [CRMAAREG-327](https://nav.atlassian.net/browse/CRMAAREG-327) | Story under 323 | Målgruppehistorie                                    | Backlog |

Observasjonar:

- Dei fem epicane er **lenkte** til [CRMAAREG-323](https://nav.atlassian.net/browse/CRMAAREG-323), ikkje underordna saker.
- Den innlogga brukaren fann ingen underordna saker under dei fem lenkte epicane.
- Dei fire historiene er **breie målgruppehistorier**, ikkje leveransar som kan utviklast direkte. Bruk dei som krav- og brukarreisegrunnlag, og lenk mindre leveranse-stories til dei.
- Det fanst ingen kommentarar på epicane eller historiene.

---

## 3. Funn mot eksisterande kode og arkitektur

Funna skil mellom **observert kode**, **risiko** og **ikkje-verifisert org-åtferd**. Ingen funn er stadfesta i ein Salesforce-org.

### 3.1 P0 – Støttetilgang gir også avtaleinngang

- **Krav i Jira:** Brukarar med berre støttetilgang skal få brukarstøtte og meldingar, men ikkje søknader eller avtalar.
- **Observert:** [`aareg_home.html`](../../../force-app/externalAccess/lwc/aareg_home/aareg_home.html) skjuler søknadsvala utan søknadsrett, men viser «Mine avtaler» ved generell tilgang.
- **Observert:** [`AAREG_HomeController.cls`](../../../force-app/externalAccess/classes/AAREG_HomeController.cls) forsøker avtaledeling også når brukaren berre har fått støtterett, rundt linje 173.
- **Risiko:** Brukarar som berre skal ha støtte, kan få tilgang til avtalemenyen og avtaledeling.
- **Ikkje verifisert:** Faktisk Salesforce-deling i org.

### 3.2 P0 – Tilgangskontroll og deling kan bruke ulik organisasjonskontekst

- **Observert:** Rettskontrollen tek eit organisasjonsnummer. Den kallbare delingsmetoden bruker brukarens sist lagra organisasjon utan synleg kontroll av at organisasjonen er den same. Sjå [`AAREG_HomeController.cls`](../../../force-app/externalAccess/classes/AAREG_HomeController.cls) rundt linje 148 og 249.
- **Observert:** Lesing og oppdatering av sist vald organisasjon tek imot ein brukar-ID som parameter.
- **Delvis vern:** [`AAREG_CommunityUtils.cls`](../../../force-app/externalAccess/classes/AAREG_CommunityUtils.cls) kontrollerer at rettsoppslaget gjeld innlogga brukar, rundt linje 22. Det dekkjer ikkje alle andre inngangar.
- **Risiko:** Brukaren kan få tilgang i feil organisasjonskontekst. Dette er raud sone og krev menneskeleg sikkerheitsgjennomgang og negative org-testar.
- **Ikkje verifisert:** At svakheita faktisk kan utnyttast.

### 3.3 P1 – Innvilga søknader forsvinn frå oversikta

- **Observert:** Queryen i [`AAREG_MyApplicationsController.cls`](../../../force-app/externalApplication/classes/AAREG_MyApplicationsController.cls) tek ikkje med statusane `Approved` og `Approved Partially`, rundt linje 205.
- **Observert:** [`AAREG_Decision_Completed.flow-meta.xml`](../../../force-app/main/default/flows/AAREG_Decision_Completed.flow-meta.xml) set desse statusane ved innvilging, rundt linje 407.
- **Konsekvens:** Når flyten er aktiv, forsvinn innvilga søknader frå «Mine søknader». Det er i strid med kravet om statusoppfølging.

### 3.4 P1 – Privatperson utan organisasjon har ingen meldingsinngang

- **Observert:** [`AAREG_MyThreadsController.cls`](../../../force-app/dialog/classes/AAREG_MyThreadsController.cls) finn trådar gjennom sist vald organisasjon og returnerer ei tom liste utan organisasjonskontekst, rundt linje 22.
- **Byggesteinar finst:** [`AAREG_contactSupportController.cls`](../../../force-app/dialog/classes/AAREG_contactSupportController.cls) har allereie logikk for henvending, tråd og melding, rundt linje 350.
- **Ikkje vedteke:** [ADR-0002](../../adr/0002-accountcontactrelation-for-personkontoer.md) og [ADR-0003](../../adr/0003-e-post-for-personkonto-via-aareg-og-krr.md) er forslag. Personkonto, kommunikasjon og personvern må avklarast før utvikling.

### 3.5 P1 – Søknadsflyten finst, men må presiserast og sikrast

- **Observert:** [`aareg_application.js`](../../../force-app/externalApplication/lwc/aareg_application/aareg_application.js) har utkast og validering i klienten. [`aareg_application.html`](../../../force-app/externalApplication/lwc/aareg_application/aareg_application.html) har kvitteringsvising.
- **Observert:** Skjemaet er delt inn i seksjonar. Det er ikkje dokumentert som ein stegvis flyt.
- **Observert:** [`AAREG_ApplicationController.cls`](../../../force-app/externalApplication/classes/AAREG_ApplicationController.cls) er `without sharing` og gjer DML, rundt linje 125.
- **Risiko:** Validering i klienten er ikkje nok vern mot direkte Apex-kall. Servervalidering og autorisasjon må dokumenterast og testast.

### 3.6 P1 – P360 er ikkje ferdig ende-til-ende

- **Observert:** [`P360_RpcClient.cls`](../../../force-app/integration/p360/classes/client/P360_RpcClient.cls) kastar «not implemented», rundt linje 18.
- **Dokumentert:** [P360 teknisk oversikt](../../integrations/p360/teknisk-oversikt.md) og [P360 completion roadmap](../../../.github/specs/p360-completion-roadmap.md) skildrar ein jobbgrunnmur som er avslått som standard. Live transport, mapping, filstrategi og driftsavklaringar står att.
- **Konsekvens:** Kvitteringa til brukaren må ikkje påstå at søknaden er arkivert før arkiveringa er stadfesta.

### 3.7 P1 – Feil, cache og «sanntid»

- **Observert:** [`AAREG_MyAgreementsController.cls`](../../../force-app/externalAgreement/classes/AAREG_MyAgreementsController.cls) returnerer ei tom liste ved teknisk unntak, rundt linje 49. Queryen filtrerer ikkje på avtalestatus.
- **Observert:** [`aareg_myApplications.js`](../../../force-app/externalApplication/lwc/aareg_myApplications/aareg_myApplications.js) bruker hurtigbufra data basert på brukar-ID, rundt linje 88. Berre resultat som ikkje er tomme, blir handtert eksplisitt.
- **Risiko:** Ved organisasjonsbyte, tomme resultat eller feil kan gamle data bli viste, eller brukaren kan sjå «ingen avtalar» i staden for ei feilmelding. Dette er ikkje verifisert som datalekkasje i org.
- **Krav som manglar:** «Sanntid» i Jira treng eit målbart krav til oppfrisking.

### 3.8 Aksel og Salesforce

- Det blei ikkje funne `@navikt`-importar i dei undersøkte eksterne komponentane. Det finst heller ingen Aksel-avhengigheit i [`package.json`](../../../package.json).
- Aksel skil mellom React-komponentar og CSS eller design tokens. React-komponentar kan ikkje brukast direkte i LWC.
- **Tilråding:** Vidareutvikle eksisterande LWC-ar. Prøv ut Aksel-styling og tokens der Salesforce sin shadow DOM og CSP tillèt det, og verifiser UU. Ei separat React-flate gir eit nytt ansvar for autentisering, drift og integrasjon. Eit slikt val må grunngivast i ein ADR.

### 3.9 Testgrunnlag

| Kontroll                                             | Resultat               |
| ---------------------------------------------------- | ---------------------- |
| Jest: heimeside, avtalar og søknadsverktøy, 3 suitar | 20 av 20 bestått       |
| Apex-testar                                          | Ikkje køyrde, krev org |
| Deling, CRUD/FLS og org-åtferd                       | Ikkje verifisert       |
| Ende-til-ende i Experience Cloud                     | Ikkje køyrd            |

---

## 4. Forslag til tillegg og endringar per epic

> Dette er **forslag**. Ikkje endre eksisterande tekst i Jira utan godkjenning, og kopier alltid originalteksten før endring.

| Epic                                                          | Forslag                                                                                                                                                                                                                                                                          |
| ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [CRMAAREG-323](https://nav.atlassian.net/browse/CRMAAREG-323) | Legg til ei **tilgangsmatrise**: person × vald kontekst × Altinn-rett × tillaten handling. Avklar motstriden mellom formålet, som nemner innsyn i eller administrasjon av arbeidsforhold for arbeidsgivarar og privatpersonar, og scopet, som berre gir dei støtte og meldingar. |
| [CRMAAREG-328](https://nav.atlassian.net/browse/CRMAAREG-328) | Skildre eksisterande ID-porten- og Altinn-byggesteinar, autorisasjon på serveren for kvar handling, organisasjonsbyte, bortfall av rett og feiltilstandar. Ikkje lag ny innlogging før eksisterande pakkar er vurderte.                                                          |
| [CRMAAREG-329](https://nav.atlassian.net/browse/CRMAAREG-329) | Definer kven som eig og kan lese ei henvending eller ein tråd: privatperson, klientverksemd eller representant. Ta med svar, vedlegg, varsling og feil ved innsending. Knyt avklaringane til ADR-0002 og ADR-0003.                                                               |
| [CRMAAREG-330](https://nav.atlassian.net/browse/CRMAAREG-330) | Skil mellom eksisterande skjema og ny stegvis brukaroppleving. Presiser reglar for utkast, servervalidering, vedlegg, kvittering, dublettar og kva for P360-kopling som må vere klar ved innsending.                                                                             |
| [CRMAAREG-331](https://nav.atlassian.net/browse/CRMAAREG-331) | List alle synlege søknadsstatusar, inkludert innvilga og delvis innvilga. Definer oppfriskingstid og om avslutta avtalar skal visast som historikk. Skil ei tom liste frå ein feil.                                                                                              |
| [CRMAAREG-332](https://nav.atlassian.net/browse/CRMAAREG-332) | Gjer sikkerheit og UU til ferdigkriterium for **kvar** leveranse. Legg til eigar og målbare kriterium for sikkerheitstest, WCAG, pilot, ytelse, feilhandtering og avgjerd om lansering.                                                                                          |

---

## 5. Forslag til dei første 10 user stories

Formatet følgjer [user story-malen](../../../.github/ISSUE_TEMPLATE/user-story.yml): aktør, behov og effekt, testbare akseptansekriterium, scope, risiko og verifisering.

### Story 1 – Støttetilgang utan søknad og avtale

- **Epic:** [CRMAAREG-328](https://nav.atlassian.net/browse/CRMAAREG-328)
- **Story:** Som brukar med berre støtterett vil eg berre sjå støtte og meldingar, slik at eg ikkje får tilgang til funksjonar eg ikkje har rett til.
- **Akseptanse:**
    - Gitt berre støtterett, når heimesida lastar, så er menyane for søknad og avtale skjulte.
    - Gitt berre støtterett, når søknads- eller avtalemetodar blir kalla direkte, så blir kallet avvist.
    - Gitt berre støtterett, så blir det ikkje oppretta deling av avtalar.
- **Risiko:** Raud sone (tilgang). **Verifisering:** Jest for menyen, Apex med `System.runAs` og negative testar, og org-test av deling.

### Story 2 – Sikker brukar- og organisasjonskontekst

- **Epic:** [CRMAAREG-328](https://nav.atlassian.net/browse/CRMAAREG-328)
- **Story:** Som representant vil eg berre få tilgang til organisasjonen eg faktisk er autorisert for, slik at data om andre verksemder er verna.
- **Akseptanse:**
    - Rettskontroll og deling bruker same innlogga brukar og same organisasjon.
    - Kall med ein annan brukar-ID eller ein organisasjon brukaren ikkje har rett til, blir avviste.
    - Når retten fell bort, gir ikkje gamle delingar tilgang vidare.
- **Risiko:** Raud sone. Krev sikkerheitsgjennomgang. **Verifisering:** Negative Apex-testar og negativ org-test.

### Story 3 – Trygt organisasjonsbyte og feil ved oppslag

- **Epic:** [CRMAAREG-328](https://nav.atlassian.net/browse/CRMAAREG-328)
- **Story:** Som brukar med fleire organisasjonar vil eg kunne byte kontekst utan å sjå gamle data.
- **Akseptanse:**
    - Etter byte blir søknader, avtalar og meldingsindikatorar oppfriska for den valde organisasjonen.
    - Ein teknisk Altinn-feil blir vist som ein feil, ikkje som avslag på tilgang, og gir ikkje tilgang.
- **Verifisering:** Jest for cache og feil, og Apex for feilsti.

### Story 4 – Brukarstøtte for privatperson

- **Epic:** [CRMAAREG-329](https://nav.atlassian.net/browse/CRMAAREG-329)
- **Story:** Som privatperson vil eg kontakte Aa-registeret utan å velje ei verksemd.
- **Akseptanse:**
    - Henvendinga blir knytt til ein godkjend personkontekst.
    - Brukaren ser berre eigne dialogar.
    - Det blir ikkje oppretta ein kunstig organisasjonskontekst.
- **Avhengigheit:** Avgjerd i ADR-0002 og ADR-0003. **Risiko:** Personvern.

### Story 5 – Brukarstøtte på vegner av klient

- **Epic:** [CRMAAREG-329](https://nav.atlassian.net/browse/CRMAAREG-329)
- **Story:** Som fullmektig vil eg velje ein klient og kontakte Aa-registeret på vegner av klienten.
- **Akseptanse:**
    - Berre klientar med gyldig representasjon kan veljast.
    - Henvendinga og meldingane blir knytte til den valde klienten.
    - Andre klientar blir avviste.

### Story 6 – Tovegs dialog og varsel

- **Epic:** [CRMAAREG-329](https://nav.atlassian.net/browse/CRMAAREG-329)
- **Story:** Som brukar vil eg lese og svare i ein dialog med Aa-registeret.
- **Akseptanse:**
    - Ein autorisert brukar ser rett tråd og kan sende svar til saksbehandlinga.
    - Varsel om godkjend avtale kjem i rett kontekst.
    - Ved feil blir det vist ei feilmelding, ikkje ei falsk kvittering.

### Story 7 – Stegvis søknad og utkast

- **Epic:** [CRMAAREG-330](https://nav.atlassian.net/browse/CRMAAREG-330)
- **Story:** Som representant for ei verksemd vil eg fylle ut søknaden steg for steg og kunne halde fram seinare.
- **Akseptanse:**
    - Obligatoriske felt blir validerte for kvart steg.
    - Eit ufullstendig utkast kan lagrast og opnast igjen med rett organisasjon, innhald og vedlegg.
- **Verifisering:** Jest for stega og Apex for lagring av utkast.

### Story 8 – Trygg innsending og korrekt kvittering

- **Epic:** [CRMAAREG-330](https://nav.atlassian.net/browse/CRMAAREG-330)
- **Story:** Som representant vil eg sende inn ein gyldig søknad og vite at han er motteken.
- **Akseptanse:**
    - Serveren avviser ugyldige data.
    - Når same utkast blir sendt inn på nytt, blir det ikkje oppretta ein dublett.
    - Kvitteringa påstår ikkje at søknaden er arkivert i P360 før dette er stadfesta.
- **Risiko:** `without sharing`-controller og P360-avhengigheit.

### Story 9 – Status på alle eigne søknader

- **Epic:** [CRMAAREG-331](https://nav.atlassian.net/browse/CRMAAREG-331)
- **Story:** Som representant vil eg følgje søknaden også etter at han er innvilga.
- **Akseptanse:**
    - Lista tek med `Approved` og `Approved Partially` for rett organisasjon.
    - Status blir oppfriska etter ein avtalt regel.
    - Data frå andre organisasjonar blir aldri viste.
- **Verifisering:** Raud-test i Apex for statusfilteret, implementasjon og grøn test.

### Story 10 – Oversikt over avtalar og vilkår

- **Epic:** [CRMAAREG-331](https://nav.atlassian.net/browse/CRMAAREG-331)
- **Story:** Som autorisert representant vil eg sjå avtalar, status og relevante vilkår.
- **Akseptanse:**
    - Berre autoriserte avtalar og dokument er tilgjengelege.
    - Gjeldande avtalar og eventuell historikk er tydeleg skilde.
    - Ein teknisk feil blir ikkje vist som «ingen avtalar».

---

## 6. Opne avklaringar

1. Skal ein fullmektig med delegert søknadsrett likevel avgrensast til støtte?
2. Korleis blir privatpersonar identifiserte i dialogen? Dette heng saman med ADR-0002 og ADR-0003.
3. Er meldingsinnsyn knytt til personen eller organisasjonen?
4. Kan innsending kvitterast medan arkiveringa ventar? Kva skal brukaren få vite?
5. Skal avslutta avtalar visast som historikk?
6. Kva er datakjelda og oppdateringsfrekvensen for Enhetsregisteret?
7. Kva betyr «sanntid» i målbare termar, til dømes sekund eller oppfrisking ved sidelasting?
8. Skal Aksel brukast som styling og tokens i LWC, eller skal teamet vurdere ei separat React-flate?

---

## 7. Krav i crm-arbeidsforhold som alle saker må harmonisere med

Kvar story og task under epicane bør stemme med desse krava. Kjeldene er [`AGENTS.md`](../../../AGENTS.md), [`force-app/main/default/AGENTS.md`](../../../force-app/main/default/AGENTS.md), [`CONTEXT.md`](../../../CONTEXT.md), [utviklingsstandardane](../../utviklingsstandarder.md), [ADR-ane](../../adr/) og [agentisk utvikling](../../../.github/instructions/agentic-development.instructions.md).

| Område                | Krav                                                                                                                                                                                                                   |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Storyformat           | Aktør, behov og effekt. Akseptansekriteria som «Gitt/når/så». Scope og ut av scope, risiko, spesifikasjon eller ADR og planlagd verifisering.                                                                          |
| Arkitektur            | Vidareutvikle eksisterande feature-mapper under `force-app/`. Følg lagdelinga i ADR-0001 for ny integrasjonskode. Ikkje gi nytt namn til metadata eller endre offentlege API-ar utan migrasjonsplan.                   |
| Pakkegrenser          | Ikkje endre pakkeeigde mapper, til dømes `crm-platform-*`, `crm-henvendelse*` eller `crm-community-base`, utan eksplisitt godkjenning.                                                                                 |
| Apex                  | `with sharing` som standard. Grunngi `without sharing`. Masseverdig SOQL/DML, ingen hardkoda ID-ar eller URL-ar, og etablert feillogging.                                                                              |
| Testar                | TDD med raud, grøn og refaktorering. Testklassar under `force-app/tests/classes/<område>/`. Bruk `System.Assert.*`, `System.Test.*` og minst éin `System.runAs` med brukar som har minimumstilgang. Bruk Jest for LWC. |
| Tilgang og personvern | Raud sone. Krev menneskeleg gjennomgang, negative testar og security review før PR.                                                                                                                                    |
| Språk                 | Engelsk for API-namn og kode. Norsk tekst til brukarane skal ligge i Custom Labels og Translation Workbench.                                                                                                           |
| UI                    | Bruk LWC i Experience Cloud. Bruk Aksel-styling der det er mogleg, og verifiser UU, WCAG 2.1 AA, for kvar leveranse.                                                                                                   |
| Org-tryggleik         | Verifiser eksplisitt mål og scratch-type; arbeid i eksisterande `crm-arbeidsforhold` krev ikkje ny brukargodkjenning. Andre ikkje-produksjonsorg krev fersk mål-/handlingsgodkjenning. Produksjon er forbode.          |
| Verifisering          | Skil mellom lokal og org-avhengig kontroll. Ikkje rapporter ein org-test som grøn utan dokumentasjon.                                                                                                                  |
| Jira-tekst            | Ikkje endre eksisterande beskrivingar utan godkjenning. Kopier alltid originalteksten før endring.                                                                                                                     |

---

## 8. Guide: Slik held du fram med agentmodus og intern nettlesar

### 8.1 Føresetnader

- VS Code med GitHub Copilot Business gjennom Nav-organisasjonen. Ikkje bruk private abonnement.
- Repositoryet `navikt/crm-arbeidsforhold` skal vere opna lokalt.
- Tilgang til Jira-prosjektet `CRMAAREG` med eigen Nav-brukar.
- Agenten skal køyre i ei isolert løysing, til dømes `cplt`, i tråd med Nav sin AI-policy.

### 8.2 Opne Jira i den interne nettlesaren

1. Opne kommandopaletten med `Cmd/Ctrl + Shift + P` og søk etter **Browser**. Vel kommandoen som opnar den integrerte nettlesaren i VS Code. Namnet på kommandoen kan variere mellom VS Code-versjonar.
2. Gå til `https://nav.atlassian.net/browse/CRMAAREG-323` og logg inn som vanleg.
3. Del sida med chatten. Bruk delingsknappen i nettlesarfana eller legg sida til som kontekst i chatten. Når sida er delt, viser chatten ho under delte nettlesarsider. Agenten kan då lese sida gjennom den innlogga økta di.
4. Hald fana open så lenge agenten arbeider. Agenten kan navigere til andre Jira-saker og bruke Jira sitt søk i den same økta.
5. Kontroller at det fungerer: Be agenten lese tittelen og statusen på [CRMAAREG-323](https://nav.atlassian.net/browse/CRMAAREG-323) før du limer inn prompten.

> Agenten skal **berre lese** frå Jira. Ikkje la agenten redigere saker, endre status eller skrive kommentarar utan at du godkjenner kvar handling.

**Om den interne nettlesaren ikkje er tilgjengeleg:** Agenten kan bruke Playwright-verktøya i staden, som `openBrowserPage`, `readPage` og `runPlaywrightCode`. Du må då logge inn i vindauget som blir opna. Direkte API-kall til Jira utan innlogga økt gir HTTP 401.

### 8.3 Start agentmodus

1. Opne Copilot Chat og vel **Agent** som modus.
2. Legg ved denne fila og prompten som kontekst, gjerne med `#file`:
    - `docs/context/ekstern-brukerflate/crmaareg-323-gjennomgang.md`
    - `docs/context/ekstern-brukerflate/prompt-harmoniser-jira.md`
3. Kopier prompten frå [`prompt-harmoniser-jira.md`](./prompt-harmoniser-jira.md) inn i chatten.
4. Godkjenn verktøykall éin etter éin. Avvis alle forsøk på å endre Jira, koble til ein Salesforce-org eller gjere endringar utanfor `docs/`, med mindre du sjølv har bede om det.

### 8.4 Gode arbeidsvanar

- **Arbeid i bolkar:** Gå gjennom éin epic om gongen dersom det finst mange saker. Be agenten skrive delresultat til fila undervegs.
- **Kontroller kjeldene:** Opne nokre kode-lenkjer sjølv og kontroller at funna stemmer.
- **Org-testar:** Arbeid i verifisert eksisterande `crm-arbeidsforhold` scratch-org krev ikkje ny brukargodkjenning. Andre ikkje-produksjonsorg krev fersk mål-/handlingsgodkjenning etter `AGENTS.md`. Bruk aldri produksjon.
- **Raud sone:** Tilgang, personvern og autentisering krev menneskeleg gjennomgang og security review før PR.
- **Jira-endringar:** Dersom noko skal endrast i Jira, skal agenten først vise originalteksten og forslaget side om side. Du kopierer originalen og gjer endringa sjølv, eller godkjenner endringa eksplisitt.
