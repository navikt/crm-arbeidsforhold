---
tittel: P360 datamodell og asynkron arkiveringsjobb
status: foreslått
dato: 2026-09-10
---

# P360 datamodell og asynkron arkiveringsjobb

**Beslutningsstatus:** Retninga er valt i dette arbeidet. Teamavklaring og endeleg normativ godkjenning står att.

## Føremål

Dette dokumentet fastset den førebelse datamodellen for P360-arkivering i Salesforce. Modellen byggjer på eksisterande relasjonar mellom `Access_Request__c`, `Application__c`, `Application_Decision__c` og `Agreement__c`, men innfører ikkje nye Salesforce-felt i denne skiva.

## Vedteken domenehierarki

`Access_Request__c` er overbygget for éi tilgangssak. Under overbygget ligg livsløpet for søknad, vedtak og avtale:

```text
Access_Request__c
├── Application__c
│   └── Application_Decision__c
└── Agreement__c
```

Den faktiske metadataen har desse relasjonane:

- `Application__c.Access_Request__c` er optional Lookup til `Access_Request__c`.
- `Application_Decision__c.Application__c` er Master-Detail til `Application__c`.
- `Application_Decision__c.Agreement__c` er optional Lookup til `Agreement__c`.
- `Agreement__c.Application__c` er optional Lookup til `Application__c`.
- `Agreement__c.Access_Request__c` er optional Lookup til `Access_Request__c`.

## Eigarskap til P360-referansar

P360-referansar skal lagrast på objektet som eig den eksterne entiteten:

| Salesforce-objekt         | P360-entitet                                   | Referansar som skal innførast seinare                  |
| ------------------------- | ---------------------------------------------- | ------------------------------------------------------ |
| `Access_Request__c`       | P360-sak                                       | P360 case ID og case number                            |
| `Application__c`          | Inngåande søknadsdokument                      | P360 document ID, eventuelt document number og file ID |
| `Application_Decision__c` | Utgåande vedtaksdokument                       | P360 document ID, eventuelt document number og file ID |
| `Agreement__c`            | Avtaledokument, dersom avtalar skal arkiverast | P360 document ID, eventuelt document number og file ID |

Det eksisterande `Agreement__c.Public_360_id__c` blir ikkje gjenbrukt i denne skiva. Det skal vurderast separat før eventuell migrering.

## `P360_Archive_Job__c`

`P360_Archive_Job__c` er eit eige teknisk objekt for éi asynkron arkiveringshending. Objektet eig jobbstatus, retry, feilkontekst og korrelasjon. Det eig ikkje dei autoritative P360-identifikatorane.

Det skal opprettast éin jobb per konkret arkiveringshending, ikkje éin jobb per `Application__c` eller per `Access_Request__c`:

| Salesforce-kontekst                         | Jobbtype              | Idempotensnøkkel                            |
| ------------------------------------------- | --------------------- | ------------------------------------------- |
| `Application__c` + søknadsdokument          | `ApplicationDocument` | `APPLICATION_DOCUMENT:{ApplicationId}`      |
| `Application_Decision__c` + vedtaksdokument | `DecisionDocument`    | `DECISION_DOCUMENT:{ApplicationDecisionId}` |
| `Agreement__c` + avtaledokument             | `AgreementDocument`   | `AGREEMENT_DOCUMENT:{AgreementId}`          |

Idempotensnøkkelen skal vere unik på `P360_Archive_Job__c`. Aa-register-nummeret skal framleis brukast til domenekopling og P360-søk, men ikkje åleine som teknisk jobbidentitet.

Retry skal alltid gjenbruke jobben med same idempotensnøkkel. Det skal ikkje opprettast ein ny jobb for same arkiveringshending.

| Eksisterande status | Retry-åtferd                                                                             |
| ------------------- | ---------------------------------------------------------------------------------------- |
| `Succeeded`         | Ikkje køyr på nytt; bruk eksisterande resultat.                                          |
| `Pending`           | Køyr eksisterande jobb.                                                                  |
| `Failed`            | Oppdater same jobb, auk `Attempt_Count__c` og set ny retry-tid.                          |
| `Manual Review`     | Køyr berre etter eksplisitt manuell frigiving.                                           |
| `In Progress`       | Ikkje start parallelt forsøk; vurder jobben på nytt etter definert lease-/timeout-regel. |

Ei ny dokumentversjon eller ei ny arkiveringshending skal få ein ny idempotensnøkkel og dermed ein ny jobb.

### Relasjonar

`Access_Request__c` skal vere obligatorisk Lookup på jobben. Jobben kan i tillegg peike til den konkrete kjelda:

- `Application__c` for søknadsdokument
- `Application_Decision__c` for vedtaksdokument
- `Agreement__c` for avtaledokument

### Obligatoriske konseptuelle felt

**Kontekst:**

- `Access_Request__c`
- `Application__c`, når jobben gjeld søknad
- `Application_Decision__c`, når jobben gjeld vedtak
- `Agreement__c`, når jobben gjeld avtale
- `Archive_Event_Type__c`

**Status:**

- `Status__c`: `Pending`, `In Progress`, `Succeeded`, `Failed`, `Manual Review`
- `Attempt_Count__c`
- `Last_Attempt_Date__c`
- `Next_Attempt_Date__c`
- `Last_Error_Code__c`
- `Last_Error_Message__c`
- `Correlation_Id__c`
- `Idempotency_Key__c`
- `Manual_Release_Reason__c`
- `Manual_Release_Type__c`: `Business`, `Technical`
- `Manual_Released_By__c`
- `Manual_Released_Date__c`

**Tidsstempel:**

- `Queued_Date__c`
- `Started_Date__c`
- `Lease_Expires_Date__c`

### Frigivingsvalidering for vedtak

`Ready_For_P360_Archive__c` kan berre setjast til `true` når eit felles minimumssett er oppfylt, og når eventuelle tilleggskrav for den aktuelle vedtakstypen er oppfylte.

Det felles minimumssettet skal minst omfatte:

- gyldig kopling til `Application__c` og `Access_Request__c`
- vedtaksstatus, vedtaksdato og vedtaksgrunngiving
- vedtaksdetaljar med godkjenningsstatus, tilgangstype, heimel, føremål og behandlingsgrunnlag
- organisasjonsnummer, Aa-register-nummer og anna nødvendig P360-kontekst

Vedtakstype-spesifikk validering skal kunne krevje eller avvise felt og detaljar som ikkje gjeld alle vedtakstypar. Salesforce skal stoppe frigiving når minimumsvalideringa feilar. P360 kan i tillegg avvise førespurnaden dersom den endelege SIF-kontrakten har strengare transport- eller kodeverkskrav.

- `Succeeded_Date__c`
- `Failed_Date__c`

### Førebels MVP-retrypolicy

Følgjande policy er vald som førebels MVP-standard. Ho skal justerast dersom P360-teamet stadfestar andre timeoutar, rate limits eller feilkodeklassifiseringar:

```text
Callout-timeout:       120 sekund
Jobb-lease:            10 minutt
Maks automatiske forsøk: 5
Retry-vindauge:        24 timar
Backoff:               1 minutt, 5 minutt, 15 minutt, 1 time, 6 timar
Etter grensa:          Manual Review
```

Når ein jobb går til `In Progress`, skal `Lease_Expires_Date__c` setjast. Ein jobb kan berre takast opp att etter utløpt lease, og statusovergangen må vere atomisk nok til å hindre parallell behandling.

Retrybare feil er mellombelse timeoutar, nettverksfeil, rate limiting og mellombelse serverfeil. Ugyldige requestar, mappingfeil, autentiseringsfeil, fleire sakstreff og permanente P360-feil skal ikkje retryast automatisk; dei skal gå til `Manual Review` eller kontrollert `Failed` etter endeleg teamavklaring.

### Manuell frigiving

`Manual Review` kan berre frigivast eksplisitt av autoriserte interne roller:

- Saksbehandlar kan frigive fagleg avklarte feil (`Manual_Release_Type__c = Business`).
- Drift/integrasjonseigar kan frigive tekniske feil, timeoutar og hengande jobbar (`Manual_Release_Type__c = Technical`).
- Eksterne brukarar kan ikkje frigive jobbar.
- Frigiving skal logge grunn, brukar og tidspunkt.
- Frigiving skal ikkje slette tidlegare feilkode, feilmelding eller forsøkshistorikk.

Ved manuell frigiving skal statusovergangen vere:

```text
Manual Review -> Pending -> In Progress
```

Den manuelle handlinga set jobben til `Pending`. Berre queueable/worker kan setje jobben til `In Progress`, etter atomisk krav på jobben og oppdatering av `Lease_Expires_Date__c`. Manuell frigiving skal ikkje starte eit eksternt callout direkte.

Ved frigiving skal `Attempt_Count__c`, tidlegare feilkode og feilmelding bevarast. `Next_Attempt_Date__c` kan setjast til no eller eit eksplisitt valt tidspunkt. Dersom jobben feiler på nytt, går han tilbake til `Failed` eller `Manual Review` etter feilklassifisering.

## Arkiveringsreglar

- Utkast skal ikkje opprette arkiveringsjobb.
- Ved innsending skal ein jobb av typen `ApplicationDocument` opprettast.
- Ved ferdig vedtak skal ein jobb av typen `DecisionDocument` opprettast.
- `DecisionDocument` skal berre opprettast når `Application_Decision__c.Ready_For_P360_Archive__c = true`.
- `Ready_For_P360_Archive__c` skal vere eit eingongssignal. Når feltet er sett til `true`, kan det ikkje setjast tilbake til `false`.
- Når signalet er sett til `true`, skal vedtaksdata som inngår i arkiveringa låsast for ordinære endringar. Nye forsøk på å endre vedtaket skal avvisast, også medan arkiveringsjobben står i `Pending`, `In Progress`, `Failed` eller `Manual Review`.
- Retry skal berre gjenta arkiveringa av same låste vedtaksinnhald. Retry skal ikkje opne vedtaket eller tillate at ein ny versjon blir arkivert på same `DecisionDocument`-nøkkel.
- Korrigering etter frigiving krev ein separat, kontrollert prosess for ny vedtaksversjon og ny idempotensnøkkel. Det skal ikkje løysast ved å nullstille eller overskrive det opphavlege eingongssignalet.
- Salesforce skal ikkje generere vedtaks-PDF for P360-arkivering; P360 skal generere og eige arkivversjonen, fortrinnsvis PDF/A.
- `DecisionDocument` skal sende vedtaksmetadata til P360 og lagre P360 document ID og eventuelt document number som P360-referanse.
- Salesforce skal ikkje hente eller vise PDF/A frå P360 i MVP. Salesforce viser berre arkiveringsstatus og lagra P360-referansar.
- Vedtaksflyten skal ikkje gjerast avhengig av dagens Salesforce-PDF-generering.
- Ei seinare utviding kan leggje til PDF/A-referanse eller separat oppslag dersom brukar- eller driftsbehov blir stadfesta.
- Alle jobbar skal bruke `Application__c.Name` som Aa-register-nummer når søknadskontekst finst.
- Eksisterande P360-sak skal søkast fram før ny sak blir oppretta.
- Null treff kan opprette ny sak.
- Eitt treff brukar eksisterande sak.
- Fleire treff stoppar jobben med `Manual Review`.
- Nye P360-referansar skal skrivast både til rett domeneobjekt og jobbresultatet dersom jobbobjektet skal vere søkbart i drift.

## Frigiving av vedtak til arkivering

Følgjande modell er vald for denne fasen:

- Automasjon skal validere at alle obligatoriske vedtaksdata og P360-metadata er komplette.
- Berre ein autorisert intern saksbehandlar skal kunne setje `Ready_For_P360_Archive__c = true` og frigi vedtaket til arkivering.
- Eksterne brukarar skal ikkje kunne setje eller endre feltet.
- Frigivinga skal logge brukar og tidspunkt.
- Når feltet er sett til `true`, er vedtaket låst for ordinære endringar og signalet kan ikkje setjast tilbake til `false`.
- Retry av arkiveringsjobben skal ikkje oppheve låsen eller endre vedtaksinnhaldet.
- Korrigering etter frigiving krev ein separat, kontrollert prosess for ny vedtaksversjon og ny idempotensnøkkel.

Dette er ei lokal arbeidsavgjerd for vidare design og implementering. Endeleg tilgangsmodell, permission set og fagleg godkjenning må stadfestast av teamet før metadata og låsemekanisme blir oppretta.

## Status og eksisterande felt

Eksisterande felt som `AA_ApplicationArchived__c`, `AA_ApplicationArchivedDate__c`, `AA_DecisionArchived__c` og `AA_DecisionArchivedDate__c` skal ikkje fjernast eller endrast i denne skiva. Dei skal vere forretningsindikatorar for vellukka arkivering.

Dei skal ikkje brukast som full teknisk jobbstatus. `P360_Archive_Job__c` skal vere kjelde for `Pending`, `In Progress`, `Failed` og `Manual Review`.

## Framtidig modellforbetring og migrering

Vi innfører ingen nye Salesforce-felt eller objekt i denne dokumentasjonsskiva. Når metadataarbeidet startar, skal det følgje denne rekkefølgja:

1. Opprett `P360_Archive_Job__c` med obligatorisk `Access_Request__c`.
2. Opprett nye, tydeleg namngjevne P360-felt på dei fire domeneobjekta.
3. Opprett `Application_Decision__c.Ready_For_P360_Archive__c` som eksplisitt arkiveringssignal.
4. Opprett validering og låsemekanisme for `Ready_For_P360_Archive__c` og vedtaksdata som inngår i arkiveringa.
5. Opprett validering som krev `Access_Request__c` på nye relevante søknads-, vedtaks- og avtalejobbar.
6. Implementer asynkron jobboppretting og statusovergangar.
7. Kartlegg eksisterande `Agreement__c.Public_360_id__c` og arkivfelt.
8. Migrer eksisterande verdiar berre etter dataanalyse, eigarskap og godkjend deployplan.
9. Marker gamle felt som legacy først etter at rapportar, flows, Apex og integrasjonar er oppdaterte.
10. Fjern eller avvikle gamle felt i ein separat, godkjend migreringssak.

## Forbetringar som bør vurderast seinare

- Gjere `Application__c.Access_Request__c` obligatorisk gjennom validering eller kontrollert datamigrering.
- Sikre at `Agreement__c` har både `Application__c` og `Access_Request__c` når domeneregelen krev det.
- Gjere P360 case number og document number søkbare, men halde interne Salesforce-ID-ar og eksterne P360-ID-ar skilde.
- Legge til eigne list views og rapportar for feila og manuelle arkiveringsjobbar.
- Avklare om `P360_Archive_Job__c` skal vere ein historisk jobbtabell eller berre halde siste aktive jobb per entitet.
- Avklare felt- og objekt-tilgang før metadata blir deploya.
- Definere permission set og intern brukaroppleving for manuell frigiving.

## Ikkje del av denne avgjerda

- SIF RPC endpoint og autentisering
- konkret request-/responsemapping
- retry-intervall og maks forsøk
- førebels retrypolicy: 120 sekund timeout, 10 minutt lease, fem forsøk og 24 timars retry-vindauge
- filstrategi og storfiltransport
- personvernklassifisering av alle felt
- migrering av `Public_360_id__c` eller eksisterande arkivfelt

Auth-verdiar, tokens og cookies frå testeksempel skal ikkje lagrast i kode, dokumentasjon, issue eller shell-historikk. Credential-rotasjon og kontroll av eksponerte testverdiar er spora i GitHub issue #1020.

Desse punkta er spora i GitHub-issues #1015, #1016, #1017 og #1018.
