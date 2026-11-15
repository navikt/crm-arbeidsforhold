# Aa-register Admin: plan

Status: forslag til vedtak. Spec: [.github/specs/aareg-admin-app.md](../../.github/specs/aareg-admin-app.md).

## 1. Kva er problemet?

I dag må ein som vil teste eller feilsøkje Aa-registeret hoppe mellom mange stader:

- tre ulike appar (`Aa-registeret – Brukerstøtte`, `AAREG_application`, `Arbeidsforhold Admin`);
- objektfaner for søknad, tilgang, vedtak, avtale og henvending;
- `Application_Log__c` for loggar, `P360_Archive_Job__c` for arkivjobbar og `P360ScratchCapture__c` for simulerte P360-kvitteringar;
- Setup for feature flags, trigger-innstillingar, permission sets og Flow-ar;
- `docs/` for å forstå kva som skal skje.

Ingen stad svarar på dei tre spørsmåla ein faktisk har:

1. **Kva skjer med Aa-registeret akkurat no?** Kva står fast, kva feila og kva ventar?
2. **Kva skjedde med denne søknaden?** Kva steg gjekk han gjennom, i kva rekkjefølgje, og kva sende vi ut?
3. **Korleis testar eg dette trygt?** Kva testdata, scenario og kvitteringar finst, og korleis nullstiller eg?

## 2. Mål

Éin intern Lightning-app, **Aa-register Admin**, som samlar:

| Område                 | Svarar på                                                | Kvar              |
| ---------------------- | -------------------------------------------------------- | ----------------- |
| Driftsoversikt         | Kva står fast, feilar eller ventar no?                   | Pakke og scratch  |
| Saksreise              | Kva hende med denne søknaden, frå innsending til arkiv   | Pakke og scratch  |
| Integrasjonsmonitor    | P360, distribusjonstilgang, Altinn, SMS og e-post        | Pakke og scratch  |
| Konfigurasjon          | Er P360 på? Mock eller ekte transport? Kva trigger går?  | Pakke og scratch  |
| Tilgangsdiagnose       | Kvifor ser eller ser ikkje brukar X dette?               | Pakke og scratch  |
| Testlab                | Lag testdata, køyr scenario, sjå kvitteringar, nullstill | **Berre scratch** |
| Hjelp og dokumentasjon | Kva betyr dette, og kvar står det meir?                  | Pakke og scratch  |

## 3. Prinsipp

1. **Bygg vidare på det som finst.** Den pakkeeigde appen `Arbeidsforhold_Admin` er nesten tom: berre heimeside, e-postmalar, dashboard og rapportar. Han blir utvida. API-namnet blir ikkje endra. Om etiketten skal endrast til «Aa-register Admin», er eit eige vedtak.
2. **Les, ikkje skriv, i pakka.** Den pakkeeigde delen viser og forklarer. Han endrar ikkje domenedata, startar ikkje integrasjonar og omgår ikkje tilgangskontroll.
3. **Testverktøy blir berre i scratch.** Alt som lagar testdata, simulerer P360 eller nullstiller data ligg under `scripts/scratch/` og blir aldri pakka.
4. **Standard Salesforce før eigen kode.** Bruk listevisingar, rapportar, dashboard, dynamiske relaterte lister og `flexipage:richText` først. Lag LWC berre der standarden ikkje kan svare på spørsmålet, til dømes saksreisa.
5. **Ingen nye eksterne kall.** Appen les Salesforce-data. Han kontaktar ikkje P360, Altinn, distribusjonstenesta, KRR eller andre tenester.
6. **Forklar i GUI-et.** Kvar side skal seie kva ein ser på, kva som er normalt og kva ein bør gjere vidare.

## 4. Arkitektur

```mermaid
flowchart TB
    subgraph App["Aa-register Admin (Lightning app)"]
        Home["Driftsoversikt (heimeside)"]
        Journey["Saksreise (LWC på søknad)"]
        Monitor["Integrasjonsmonitor"]
        Config["Konfigurasjon (les)"]
        AccessDiag["Tilgangsdiagnose (les)"]
        Help["Hjelp og lenkjer"]
        Lab["Testlab (berre scratch)"]
    end

    subgraph Pkg["crm-arbeidsforhold (pakke)"]
        Domain["Application, Access Request, Decision, Agreement, Inquiry"]
        P360Job["P360_Archive_Job__c"]
        Settings["P360_Integration_Setting__c, AAREG_Default_Settings__c"]
        Svc["AAREG_Admin*-servicar (with sharing, USER_MODE)"]
    end

    subgraph Deps["Dependency-pakkar (les)"]
        Log["Application_Log__c"]
        Flags["Feature_Flag__mdt, MyTriggerSetting__mdt"]
        Sms["SMS__c, Thread__c, Message__c"]
    end

    subgraph Scratch["scripts/scratch (ikkje pakka)"]
        Capture["P360ScratchCapture__c"]
        Seed["Syntetisk testdata og scenario"]
    end

    Home --> Svc
    Journey --> Svc
    Monitor --> Svc
    Config --> Svc
    AccessDiag --> Svc
    Svc --> Domain
    Svc --> P360Job
    Svc --> Settings
    Svc --> Log
    Svc --> Flags
    Svc --> Sms
    Lab --> Capture
    Lab --> Seed
    Seed --> Domain
```

### 4.1 Kva som er pakke og kva som er scratch

| Del                                                        | Plassering                                          | Kan gå til SIT2/prod |
| ---------------------------------------------------------- | --------------------------------------------------- | -------------------- |
| App, faner, heimeside, listevisingar, rapportar, dashboard | `force-app/main/default/` (eksisterande app)        | Ja, etter vedtak     |
| Lese-servicar og LWC for oversikt, saksreise og diagnose   | `force-app/internalAdmin/` (ny mappe)               | Ja, etter vedtak     |
| Permission set `AAREG_Admin_Viewer`                        | `force-app/internalAdmin/permissionsets/`           | Ja, etter vedtak     |
| Testlab, scenario, nullstilling, P360-kvitteringar         | `scripts/scratch/admin/` og `scripts/scratch/p360/` | **Nei**              |
| Permission set `AAREG_Scratch_Test_Operator`               | `scripts/scratch/admin/`                            | **Nei**              |

Mappa `force-app/internalAdmin/` følgjer eigarskapsmodellen i [repositorystruktur.md](../architecture/repositorystruktur.md). Plasseringa skal stadfestast i spec-gjennomgangen.

## 5. Modular

### 5.1 App-skal og navigasjon

- Utvid `Arbeidsforhold_Admin` med faner for søknad, tilgangsførespurnad, vedtak, avtale, henvending, P360-arkivjobb og applikasjonslogg.
- Scratch-utrullinga legg til faner for `P360ScratchCapture__c` og testlaben.
- Verktøylinja får snarvegar til hjelp og, i scratch, til testlaben.

### 5.2 Driftsoversikt

Heimesida viser fliser med tal og lenkjer til filtrerte lister:

- søknader per status, og søknader som har stått i same status lenger enn ein konfigurerbar terskel;
- vedtak som ventar på P360-frigjeving;
- P360-jobbar per status: venta, i arbeid, feila, til manuell handsaming og leasen utgått;
- feil i `Application_Log__c` siste 24 timar, gruppert på `Source_Class__c`;
- opne henvendingar utan eigar.

Tersklar ligg i Custom Metadata, ikkje i kode.

### 5.3 Saksreise

Ein LWC på søknadssida og i appen syner ei tidslinje for éin søknad:

- oppretting, innsending og statusendringar;
- vedtak, avtale og distribusjonstilgang;
- vedlegg og vedtaksfiler;
- P360-jobbar med status, forsøk, correlation ID og siste feil;
- loggar der `Referrence_ID__c` peikar på søknaden, vedtaket eller avtalen;
- e-post, SMS og dialogtrådar.

Kvart steg viser kjelde, tidspunkt og lenkje til posten. Steg som manglar data blir merkte som «ikkje registrert», ikkje gøymde.

**Blokkar:** Historikksporing er slått på for objekta, men ingen felt er markerte med `trackHistory`. Statusendringar kan derfor ikkje visast før eit vedtak avgjer kva felt som skal sporast. Sjå [opne vedtak](#7-opne-vedtak).

### 5.4 Integrasjonsmonitor

| Integrasjon          | Kjelde i Salesforce                                          | Visning                                                |
| -------------------- | ------------------------------------------------------------ | ------------------------------------------------------ |
| P360                 | `P360_Archive_Job__c`, `Application_Log__c`                  | Kø, feil, retry, manuell frigjeving, correlation ID    |
| P360 i scratch       | `P360ScratchCapture__c`                                      | Kvitteringar, førespurnad, svar, filer (berre scratch) |
| Distribusjonstilgang | `Application_Log__c` frå `AAREG_distributionAccess*`, avtale | Siste kall og feil per avtale                          |
| Altinn               | `Application_Log__c`, scenario-repository                    | Siste kall og feil                                     |
| SMS og e-post        | `SMS__c`, `EmailMessage`, e-postvarslingsmetadata            | Sende, feila og ventande varsel                        |

Monitoren viser berre metadata og redigerte felt. Payloadar blir ikkje viste utan at tilgangsvedtaket tillèt det.

### 5.5 Konfigurasjon

Ei leseside som samlar:

- feature flag `P360_Archive_Processing` og om han er på;
- `P360_Integration_Setting__c`, inkludert om mock-transport er vald;
- `MyTriggerSetting__mdt`-oppføringar for Aa-registeret-objekta;
- `AAREG_Default_Settings__c` og varslingsmetadata;
- kva Named Credentials som finst, utan endepunkt-hemmelegheiter eller tokenar.

Sida forklarer kva kvar innstilling gjer og lenkjer til Setup for endring. Ho endrar ingenting sjølv.

### 5.6 Tilgangsdiagnose

Vel ein brukar og sjå:

- profil, permission sets og grupper med Aa-registeret- eller P360-relevans;
- custom permissions, til dømes `P360_Archive_Release`;
- om brukaren kan lese og endre hovudobjekta.

Svaret er ei forklaring, ikkje ei tildeling. Tildeling skjer framleis i Setup. Diagnose av andre brukarar er raud sone og krev eige tilgangsvedtak.

### 5.7 Testlab (berre scratch)

- Lag syntetiske testscenario frå [testdata-strategien](../testing/aaregisteret-testdata-strategi.md) med eitt klikk eller éin kommando.
- Køyr steg i [scenario-testplanen](../testing/aaregisteret-scenario-testplan.md) og lagre evidens.
- Sjå P360-kvitteringar frå `P360ScratchCapture__c`.
- Nullstill syntetiske testdata utan å røre anna data.
- Bruk same Node-køyrar som `npm run p360:scratch`, slik at det fungerer på macOS, Linux og Windows.

Testlaben skal kontrollere at målet er ein scratch-org (`Organization.IsSandbox=true` og scratch-domene) før han endrar noko.

### 5.8 Hjelp

Kvar side har ein kort tekst øvst om kva ho viser og kva som er normalt. Verktøylinja har lenkjer til [heile løysinga](../architecture/hele-loysinga.md), [Flow-katalogen](../architecture/aareg-flow-katalog.md), [P360 scratch-guiden](../integrations/p360/scratch-brukarguide.md) og [testplanen](../testing/aaregisteret-scenario-testplan.md).

## 6. Fasar

```mermaid
flowchart LR
    F0["F0 Vedtak og spec"] --> F1["F1 App-skal og tilgang"]
    F1 --> F2["F2 Driftsoversikt"]
    F1 --> F3["F3 Konfigurasjon"]
    F1 --> F5["F5 Testlab (scratch)"]
    F2 --> F4["F4 Integrasjonsmonitor"]
    F3 --> F4
    F4 --> F6["F6 Saksreise"]
    F1 --> F7["F7 Tilgangsdiagnose"]
    F6 --> F8["F8 Hjelp, review og utrulling"]
    F5 --> F8
    F7 --> F8
```

| Fase | Innhald                                          | Avhengnad           | Ferdig når                                                    |
| ---- | ------------------------------------------------ | ------------------- | ------------------------------------------------------------- |
| F0   | Spec, vedtak om namn, tilgang og historikk       | –                   | Opne vedtak i kapittel 7 er avgjorde                          |
| F1   | App, faner, `AAREG_Admin_Viewer`, heimeside      | F0                  | App synleg i scratch for brukar med permission set            |
| F2   | Driftsoversikt med fliser og listevisingar       | F1                  | Fliser viser rette tal mot syntetiske data                    |
| F3   | Konfigurasjonsside                               | F1                  | Viser flag, mock-transport og triggerinnstillingar korrekt    |
| F4   | Integrasjonsmonitor                              | F2, F3              | P360-jobbar og loggar kan følgjast frå feil til årsak         |
| F5   | Testlab i scratch                                | F1                  | Scenario kan lagast, køyrast og nullstillast på alle tre OS   |
| F6   | Saksreise                                        | F4, historikkvedtak | Tidslinja viser éin søknad frå innsending til arkiv           |
| F7   | Tilgangsdiagnose                                 | F1, tilgangsvedtak  | Diagnosen stemmer med faktiske tilgangar for tre testbrukarar |
| F8   | Hjelp, security-review, dokumentasjon, utrulling | F5, F6, F7          | Review er gjennomført; SIT2 er verifisert etter godkjenning   |

## 7. Opne vedtak

| Vedtak                                                                                    | Kvifor det trengst                                                            | Kven                     |
| ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------ |
| Skal etiketten på `Arbeidsforhold_Admin` endrast til «Aa-register Admin»?                 | Endrar eksisterande tekst brukarane ser                                       | Produkteigar             |
| Kven skal ha `AAREG_Admin_Viewer`, og skal han gje `View All` på hovudobjekta?            | Persondata og private objekt; raud sone                                       | Produkteigar, sikkerheit |
| Kva felt skal ha `trackHistory=true`? Status, eigar, frist og vedtaksutfall er forslaget. | Saksreisa kan ikkje vise endringar utan sporing; grense på 20 felt per objekt | Produkteigar             |
| Skal monitoren vise payloadar frå `Application_Log__c`?                                   | Kan innehalde persondata                                                      | Sikkerheit               |
| Skal tilgangsdiagnose kunne sjå andre brukarar enn ein sjølv?                             | Krev lesing av andre sine tilgangar                                           | Sikkerheit               |
| Skal appen rullast ut til produksjon, eller berre scratch og SIT2?                        | Produksjonsmetadata krev Team Platforce-godkjenning                           | Team Platforce           |

## 8. Teststrategi

| Lag           | Kva                                                                | Kommando eller stad                           |
| ------------- | ------------------------------------------------------------------ | --------------------------------------------- |
| Apex          | Lese-servicar: aggregering, sharing, USER_MODE, minimumstilgang    | `force-app/tests/classes/internalAdmin/`      |
| LWC Jest      | Fliser, tidslinje, tomme og feilande tilstandar                    | `npm test -- --runInBand`                     |
| Node          | Testlab-køyrar, scratch-målkontroll, nullstilling                  | `npm run test:node`                           |
| GUI i scratch | Stegvise kontrollar med skjermbilete som evidens                   | Scenario-testplanen                           |
| Tilgang       | Minimumsbrukar ser ingenting; viewer ser berre det vedtaket tillèt | `System.runAs` i Apex og manuell GUI-kontroll |

Ingen test skal kontakte eksterne tenester. Testlaben brukar den simulerte P360-mottakaren.

## 9. GitHub-issues

Epic: [#1186](https://github.com/navikt/crm-arbeidsforhold/issues/1186).

| Fase | Issue                                                                                                |
| ---- | ---------------------------------------------------------------------------------------------------- |
| F0   | [#1187](https://github.com/navikt/crm-arbeidsforhold/issues/1187) Avgjer opne val                    |
| F1   | [#1188](https://github.com/navikt/crm-arbeidsforhold/issues/1188) App-skal, faner og permission sets |
| F2   | [#1189](https://github.com/navikt/crm-arbeidsforhold/issues/1189) Driftsoversikt                     |
| F3   | [#1190](https://github.com/navikt/crm-arbeidsforhold/issues/1190) Konfigurasjonsside                 |
| F4   | [#1191](https://github.com/navikt/crm-arbeidsforhold/issues/1191) Integrasjonsmonitor                |
| F5   | [#1192](https://github.com/navikt/crm-arbeidsforhold/issues/1192) Testlab i scratch                  |
| F6   | [#1193](https://github.com/navikt/crm-arbeidsforhold/issues/1193) Saksreise                          |
| F7   | [#1194](https://github.com/navikt/crm-arbeidsforhold/issues/1194) Tilgangsdiagnose                   |
| F8   | [#1195](https://github.com/navikt/crm-arbeidsforhold/issues/1195) Hjelp, review og utrulling         |
