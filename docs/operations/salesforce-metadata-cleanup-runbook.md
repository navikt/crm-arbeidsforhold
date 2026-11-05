# Runbook: Salesforce-metadataopprydding

Status: vedteken teknisk sjekkliste for denne oppryddinga. Org-gjennomforing er ikkje utført som del av denne endringa.

Operativ godkjenning, eigar og endringsvindu skal registrerast i Confluence og GitHub Issue/PR for kvar org. Dette dokumentet skal ikkje innehalde org-ID-ar, credentials, secrets eller persondata.

[Team Arbeidsforhold](https://teamkatalog.nav.no/team/29d44f3f-ff09-477c-b26a-83cd0aa66116) eig produktet og repoet; `@navikt/crm-arbeidsforhold` er
GitHub-teamet for bidragsytarar og review. Sletting skal verifiserast i SIT2.
[Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f) skal godkjenne menneskelege produksjonsmetadataendringar og
utføre produksjonsverifikasjon og sletting. Agentar skal aldri aksessere
produksjon, heller ikkje etter godkjenning. Før kvar agentkommando mot eit
ikkje-produksjonsorg krevst ny stadfesting av eksakt mål og handling.

## Formal

Denne runbooken skal brukast nar metadata er fjerna frå repoet, men framleis kan liggje i ein eller fleire Salesforce-orgar. Ei vanleg source deploy slettar ikkje automatisk metadata som ikkje lenger finst i source tree. Sletting i org krev ein eksplisitt destructive deployment og kontrollert verifikasjon.

## Metadata som er fjerna i denne endringa

| Metadata type | Full name                         | Repo path                                                                | Grunngjeving                                                                                                                                   | Org-handling                                                                                         |
| ------------- | --------------------------------- | ------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `ApexClass`   | `AAREG_CheckObjectTypeNamingTest` | `force-app/utility/classes/AAREG_CheckObjectTypeNamingTest.cls`          | Redundant testklasse for same invocable action. Testen godtok bade suksess og exception, og hadde derfor ingen paaleggeleg kontraktsassertion. | Vurder og verifiser sletting per org. Ikkje slett produksjonsklassen `AAREG_checkObjectTypeNameche`. |
| `ApexClass`   | `AAREG_CheckObjectTypeNamingTest` | `force-app/utility/classes/AAREG_CheckObjectTypeNamingTest.cls-meta.xml` | Metadatafil for klassen over.                                                                                                                  | Blir sletta saman med Apex-klassen i destructive deployment.                                         |

Den bevarte testen er `AAREG_checkObjectTypeNamecheTest.cls`. Produksjonsklassen `AAREG_checkObjectTypeNameche.cls` blir ikkje sletta. Flow-actionen `AAREG_checkObjectTypeNameche` og permission-set-referansane skal vere uendra.

## Forhandskontroll

1. Opprett eller oppdater ei GitHub Issue med:
    - målorg og miljø;
    - metadata som skal slettast;
    - grunn og avhengigheitskontroll;
    - godkjenningar, endringsvindu og rollback-eigar.
2. Få eksplisitt godkjenning for kvar org og handling. Produksjon krev separat godkjenning frå [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f) og menneskeleg utføring; agentar har ikkje tilgang.
3. Verifiser at `AAREG_CheckObjectTypeNamingTest` ikkje er referert frå Flow, Apex, permission sets, package manifest eller CI-konfigurasjon.
4. Verifiser at produksjonsklassen `AAREG_checkObjectTypeNameche` framleis er referert der han skal vere, mellom anna frå:
    - `AAREG_getObjectTypeName.flow-meta.xml`;
    - `AAREG_Arbeidsforhold_Saksbehandling.permissionset-meta.xml`;
    - `AAREG_CommunityPermission.permissionset-meta.xml`.
5. Hent metadata frå målorgen eller bruk Salesforce Setup/Metadata API til å kontrollere at `AAREG_CheckObjectTypeNamingTest` faktisk finst der. Ikkje anta at repo-statusen er lik org-statusen.
6. Ta vare på deploy-resultat og relevant metadata-/dependency-inventar i Issue/PR. Ikkje lagre credentials eller persondata.
7. List alle relevante metadata-API-namn, inkludert gammalt og nytt namn ved
   omdøyping. Avklar avhengigheiter, stoppkriterium og rollback.
8. Skript som [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f) skal køyre, skal vere sjekka inn, gjennomgått,
   testa, verifiserte og godkjende før køyring. Registrer revisjon,
   føresetnader, ansvarleg utførar, godkjenning og forventa resultat.

## Lesebasert Apex-kontroll

`AAREG_MetadataCleanupAudit` kontrollerer Apex-klasser via ein eksaktnamn Tooling API REST-query.
Andre støtta metadata-typar blir kontrollerte via Metadata API SOAP `readMetadata`.
Dette skiljet er nødvendig fordi `readMetadata(ApexClass)` i scratch-orgen returnerte SOAP-feilen
Han har ingen slettemetode, ingen DML og inga automatisk aktivering av P360.
Føresetnader per miljø:

- ApexClass-oppslag brukar Tooling API REST med den køyrande brukaren sin Salesforce-sesjon.
  `Modify All Data`, slik Salesforce dokumenterer. Klassa aukar ikkje brukaren sine rettar.
- Same-org HTTPS-callout frå dagens direkte-endepunkt må vere tillaten gjennom Remote Site Settings.
  Oppsett må kontrollerast i kvart miljø. Ved seinare overgang til Named Credential skal Remote Site Settings
  ikkje vere nødvendig for callouten som brukar Named Credential.
- Koyr synkront frå ein godkjend API-aktiv sesjon, til dømes Execute Anonymous.
  Asynkrone kontekstar og enkelte UI-sesjonar gir ikkje ein brukbar API-sesjon.
- Produksjon krev eksplisitt godkjenning, også for lesekontrollen. Ikkje legg sesjons-ID-ar i kode,
  loggar eller rapportar. SOAP-requesten inneheld sesjons-ID, og API-svaret kan innehalde sensitiv metadata;

### Brukartilgang for dagens køyring

Den dokumenterte inngangen er Execute Anonymous, ikkje ein brukarvend Apex-, REST- eller LWC-teneste.

- `API Enabled` for API-sesjonen som `sf apex run` brukar.
- `Author Apex` for å køyre Execute Anonymous. Dette er ei kraftig rett: brukaren kan køyre vilkårleg Apex.
  Tildel henne berre til godkjende operatørar; ikkje til vanlege sluttbrukarar.
- Det avgrensa permission set-et for audit-operatørar bør gi Apex Class Access til fasaden
  `AAREG_MetadataCleanupAudit`; ikkje eksponer hjelpeklassene som eigne inngangar. Denne class access-en
  erstattar ikkje `Author Apex` for Execute Anonymous.
- `Modify Metadata Through Metadata API Functions` når kandidaten inneheld typar som blir kontrollerte med
  Metadata API SOAP `readMetadata`. Bruk denne framfor `Modify All Data` når det er tilstrekkeleg.

`API Enabled` åleine gir ikkje SOAP-metadatarettane. ApexClass Tooling API-oppslaget brukar den innlogga
brukaren sin tilgang; `Modify Metadata Through Metadata API Functions` er ikkje dokumentert som krav for
Tooling-oppslaget. Verifiser den minste rettskombinasjonen i kvar org med den faktiske operatørprofilen.
Klassa har ikkje `@AuraEnabled`- eller `@RestResource`-inngang, så Apex Class Access åleine gjer ikkje
verktøyet tilgjengeleg for vanlege brukarflater.

Credential-administrator er ei eiga rolle. For å vise credentials krev Salesforce `View Setup and Configuration`;
for å opprette eller endre Named/External Credentials krevst `Manage Named Credentials` eller `Customize Applications`.
Ikkje gje desse administrasjonsrettane til audit-operatørar berre om dei skal køyre kontrollen.

### Named Credential og External Credential

Dette er oppsettet for ei mogleg credential-basert Tooling API-migrering; dagens Apex-kode brukar framleis
`URL.getOrgDomainUrl()` og `UserInfo.getSessionId()`. Oppretting eller endring av credentials er ikkje del av
runbook-køyringa og krev eiga godkjenning per miljø.

1. I kvart målmiljø opprettar credential-administrator ein External Auth Identity Provider/OAuth-klient etter
   organisasjonen sin godkjende Salesforce API-authstandard. Bruk My Domain for målorg; ikkje legg klient-ID,
   klienthemmelegheit, token eller org-spesifikk URL i kjeldekode eller dokumentasjon.
2. Opprett External Credential, til dømes `MetadataAudit_PerUser`, med OAuth og ein `Per User` principal.
   Vel OAuth-flow, scope og refresh-policy etter godkjend identitetsoppsett; dei verdiane må stadfestast i
   målorgen og kan ikkje utleiast frå P360-konfigurasjonen.
3. Opprett Named Credential, til dømes `MetadataAudit_SameOrg`, med URL-rota
   `https://<MyDomain>.my.salesforce.com`, aktiver callouts og knyt henne til External Credential.
   Ikkje legg API-sti eller query i URL-rota. Apex byggjer då endepunktet som
   `callout:MetadataAudit_SameOrg/services/data/v67.0/tooling/query/...`; Named Credential legg ved
   autentiseringsheaderen automatisk.
4. Lag eit eige permission set for audit-operatørar. Gje det Apex Class Access til fasaden og
   External Credential Principal Access til `Per User`-principal-en. Tildel permission set berre til
   godkjende operatørar. Kvar brukar må òg fullføre si eiga OAuth-autorisering før Per User-callouten kan gå.
5. Verifiser i scratch med den faktiske operatørbrukaren at Named Credential-callouten finn ein eksisterande
   klasse og returnerer `NOT_FOUND` for ein kontrollert manglande klasse. Ingen produksjonscredential eller
   delt brukar skal brukast i denne testen.

Salesforce-referansar: [Opprett External Credential](https://help.salesforce.com/s/articleView?id=sf.nc_create_edit_external_credential.htm&type=5),
[opprett Named Credential](https://help.salesforce.com/s/articleView?id=sf.nc_create_edit_named_credential.htm&type=5),
og [OAuth Named Credential-oppsett](https://developer.salesforce.com/docs/platform/named-credentials/guide/nc-create-oauth-cred.html).
Per User bevarer at resultatet blir avgrensa av den som køyrer kontrollen. Ein Named Principal ville i staden
gjeve alle kall identiteten og tilgangen til ein delt integrasjonsbrukar, og ville endra tydinga av `FOUND` og
`NOT_FOUND`; ikkje vel det utan eit medvite policyvedtak.

Named Credential-migreringa fjernar ikkje automatisk rettskravet til Metadata API SOAP. SOAP-klienten sender i dag
sesjons-ID i `SessionHeader`; ho skal ikkje endrast til å stole på Named Credential sin HTTP Authorization-header
før SOAP-auth er testa med same External Credential i scratch. Fram til då gjeld gjeldande SOAP-rettar og direkte
callout-føresetnader.

Eksempel for eit godkjent miljø:

```apex
List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>{
        new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_CheckObjectTypeNamingTest'),
        new AAREG_MetadataCleanupAudit.Candidate('Flow', 'AAREG_createDistributionAccess'),
        new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'Application__c.EventAccess__c')
};
List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(candidates);
System.debug(LoggingLevel.INFO, JSON.serializePretty(results));
```

Bruk `type` og `fullName` frå kandidat-CSV-en, ikkje filsti eller visningsnamn.
Send høgst ti kandidatar per separat transaksjon; eitt lesekall blir sendt per kandidat med ti sekund timeout.
Koyr alle batchane i kvart godkjent miljø og registrer miljø og køyringstid utanfor resultatlista.
Kopier berre dei saniterte resultata til den godkjende operasjonssaka.

### Automatisk generering av Execute Anonymous

Frå repo-roten:

```bash
npm run metadata:audit:anonymous
```

Kommandoen byggjer kandidatane frå Git-historikken til `origin/main`, med same logikk som CSV-rapporten.
Han genererer ferdige Apex-script med høgst ti kandidatar i kvar fil, men kontaktar ingen org.
Eksisterande CSV-/historikkrapportar blir ikkje skrivne om, og manuelle CSV-endringar blir ikkje lesne inn.
For å bruke nøyaktig same grunnlag som ein eldre rapport, oppgi commit-ID-en frå rapporten:

```bash
npm run metadata:audit:anonymous -- <report-commit-sha>
```

Opne [batchoversikta](../../scripts/apex/metadata-cleanup-audit/README.md).
Opne kvar oppført Apex-fil og bruk heile innhaldet i Execute Anonymous i det godkjende miljøet.
Koyr éi fil per transaksjon, ikkje alle filene samla. Berre filene i oversikta skal brukast;
gamle genererte filer kan bli liggjande om kandidatlista seinare blir kortare.

Alternativt, etter separat godkjenning for scratch-org-kontrollen:

```bash
sf apex run --file scripts/apex/metadata-cleanup-audit/batch-01.apex --target-org crm-arbeidsforhold
```

Resultatet i loggen startar med `METADATA_AUDIT_BATCH_01`, følgd av innrykka JSON frå `JSON.serializePretty`.
Gjenta for kvar batch og kvart godkjent miljø. Produksjon krev framleis eiga godkjenning.

### Eksporter resultat til ei JSON-fil

Eksisterande kompakte loggar og nye multiline-loggar kan eksporterast lokalt:

```bash
npm run metadata:audit:export -- <debug-log-path>
```

Standardfil er `logs/metadata-audit-results.json`. Oppgi ein annan filsti som andre argument
for å skilje batchar og miljø. Eksporten nektar å overskrive ei eksisterande fil:

```bash
npm run metadata:audit:export -- <debug-log-path> logs/metadata-audit-batch-02.json
```

JSON-fila inneheld berre batchnummer og resultata sine `status`, `metadataType`, `fullName` og `errorCode`.
Sesjonsinformasjon, SOAP-body og andre trace-data blir ikkje eksporterte. Råloggen blir ikkje endra.
Øydelagd/trunkert JSON blir avvist, ikkje eksportert som eit komplett resultat.

Execute Anonymous har ingen separat returkanal for metodeverdien. Ein autentisert Apex REST-endpoint
kan gi JSON direkte utan debug-logg, men vil vere ei eiga API-/tilgangsendring med godkjenning og testar.
Han er ikkje implementert her. `UNKNOWN` og `HTTP_500` er framleis uavklarte API-resultat,
uavhengig av om dei blir viste i logg eller eksporterte til fil.

- `FOUND`: API-et returnerte det nøyaktige gamle komponentnamnet; komponenten er ein stadfesta kandidat for vidare avhengigheits-/eigarkontroll.
- `NOT_FOUND`: For ApexClass fullførte Tooling-queryen med `totalSize=0`; for SOAP-typar returnerte API-et ein eksplisitt nil-record. Dette viser berre synlegheit for den innlogga brukaren, ikkje om komponenten nokon gong vart deploya.
- `UNKNOWN`: tilgang, sesjon, callout, unsupported type, namn-/case-avvik eller uventa svar må avklarast. Ikkje tolk dette som sletta metadata.

Settings, pakke-eigde komponentar og namn med berre endra bokstavstorleik krev særskild vurdering.
Tooling-oppslaget brukar berre `ApexClass.Name`; namespace-kvalifiserte kandidatar blir derfor `UNKNOWN` og må kontrollerast manuelt. Ein namespace-aware query er ikkje validert.
Ingen av statusane er godkjenning for sletting. `NOT_FOUND` er særleg ikkje ei oppmoding om destructive deploy.
Named Credentials og sentral tilgang til andre orgar er ikkje implementerte i denne same-org-kontrollen.

Fokusert test etter godkjend deploy til standard scratch-org:

```bash
sf apex run test --class-names AAREG_MetadataCleanupAuditTest --target-org crm-arbeidsforhold --result-format human --wait 10
```

Testane brukar `HttpCalloutMock` og kontaktar ikkje ein ekte Metadata API-endpoint.
Den 2026-10-12 blei klassene deploya til den godkjende scratch-orgen `crm-arbeidsforhold`; den fokuserte
`AAREG_MetadataCleanupAuditTest` køyrde 15 testar utan feil. Ei separat Tooling API-kontroll fann
`AAREG_ApplicationController` (`FOUND`) og rapporterte `AAREG_CheckObjectTypeNamingTest` (`NOT_FOUND`).
Direkte `readMetadata(ApexClass)` gav `sf:INVALID_TYPE`; vellykka SOAP-oppslag for andre metadata-typar
er ikkje verifiserte mot ein ekte org. Named/External Credential er heller ikkje oppretta eller testa.

## Destructive deployment

### Generer eit lokalt utkast frå logg eller JSON

```bash
npm run metadata:audit:destructive -- <debug-log-or-exported-json> --environment <environment-label>
```

Kommandoen genererer `destructiveChangesPost.xml`, `review.json` og ei README i ei ny mappe
under `logs/metadata-audit-draft/<environment-label>`. Miljønamnet er berre ei opplysning frå operatøren;
verktøyet kan ikkje bekrefte kva org loggen kjem frå. Ikkje bland loggar frå ulike miljø.
Kommandoen kontaktar ingen org, slettar ingen metadata og køyrer ingen deploy.

Utkastet tek berre med `FOUND` utan feilkode, der typen/namnet er ein historisk kandidat
som ikkje finst i dagens `origin/main`. Komponentar som framleis finst i main, settings,
referanse-/pakke-eigd kjelde og motstridande funn blir ekskluderte. Duplikat blir samla.
Teksttreff i dagens `force-app`-kjelde blir òg ekskluderte og oppførte i review-fila.
Dette er ein konservativ tekstsjekk, ikkje ein full Salesforce dependency-analyse.
`UNKNOWN` og `NOT_FOUND` gir aldri slettelinjer. Berre `HTTP_500`-resultat gir eit tomt XML-utkast.

Oppgi eventuelt ei ny output-mappe og annan main-ref:

```bash
npm run metadata:audit:destructive -- logs/metadata-audit-batch-01.json \
  --environment unverified \
  --output-dir logs/metadata-audit-draft/review-01 \
  --ref origin/main
```

Eksisterande mapper/filer blir ikkje overskrivne. API-versjonen blir lesen frå
`sfdx-project.json` i den valde main-refen. XML blir bygd med DOM-serialisering frå JSDOM,
som allereie er del av Jest-verktøykjeda og no er deklarert som direkte dev-avhengigheit.

Før bruk må eigar godkjenne alle inkluderte linjer og verifisere API-fullName, faktisk målorg,
pakkeeigarskap, org-only-avhengigheiter, loggalder, eventuell datataprisiko og rollback.
Utkastet er ikkje ei deploygodkjenning, heller ikkje når `FOUND` er stadfesta.

Lag ei mellombels pakke utanfor repoets produksjonskatalog, eller bruk teamet si godkjende deploymekanisme:

`destructiveChangesPost.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>AAREG_CheckObjectTypeNamingTest</members>
        <name>ApexClass</name>
    </types>
    <version>66.0</version>
</Package>
```

Koyr alltid ein dry-run/deploy preview mot eksplisitt vald sandbox forst. Bruk ikkje `--target-org` med ein ukjend eller implisitt default-org. Eksempel på kommandoform, som skal tilpassast godkjend lokal deployprosess:

```bash
sf project deploy start \
  --manifest manifest/package.xml \
  --post-destructive-changes path/to/destructiveChangesPost.xml \
  --target-org <approved-sandbox-alias> \
  --dry-run
```

Etter separat godkjenning av deploy kan same pakke deployast til godkjend sandbox
med eksplisitt mål. Verifiser slettinga i SIT2 og registrer evidens.
Produksjon krev separat godkjenning og utføring frå [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f); agenten skal
ikkje køyre produksjonskommandoar. Ikkje gjenbruk sandbox-kommandoen mot produksjon.

## Verifikasjon etter deploy

1. Kontroller at deployen er `Succeeded` og lagre deploy-ID og testresultat i Issue/PR.
2. Kontroller at `AAREG_CheckObjectTypeNamingTest` ikkje lenger finst i målorgen.
3. Kontroller at `AAREG_checkObjectTypeNameche` framleis finst og er aktiv.
4. Kontroller at Flow `AAREG_getObjectTypeName` framleis kan referere til invocable actionen.
5. Kontroller at begge relevante permission sets framleis kan referere til produksjonsklassen.
6. Køyr den bevarte Apex-testen `AAREG_checkObjectTypeNamecheTest` i ein godkjend ikkje-produksjonsorg. [Team Platforce](https://teamkatalog.nav.no/team/06a47c6b-557c-491e-b036-d6abbc77b04f) utfører produksjonsverifikasjon etter godkjend release- og smoke-testprosess.
7. Dokumenter resultatet separat for kvar org: målorg, tidspunkt, deploy-ID, status, testar og eventuelle avvik.
8. Registrer eksplisitt verifikasjon av sletting i SIT2 og referanse til Team
   Platforce si godkjenning og evidens for produksjonsverifikasjon og sletting.
   Ikkje marker stega fullførte utan dokumenterte resultat.

## Feil og rollback

Sletting av ein Apex-testklasse påverkar normalt ikkje produksjonsruntime, men ein feil deploy skal likevel stoppast og eskalerast. Rollback er å gjenopprette den sletta klassen og metadatafila frå Git commit før slettinga, og deploye henne som ein vanleg ApexClass. Ikkje prøv å rulle tilbake ved å endre produksjonsklassen eller Flow-kontrakten.

Dersom kontrollen finn referansar til den sletta testklassen, stopp destructive deployment. Gjenopprett klassen i ei eiga endring, fjern eller migrer referansen med godkjend plan, og oppdater denne loggen.

## Logg per org

Kopier denne tabellen inn i Issue/PR eller Confluence-operasjonssaka for kvar målorg:

| Felt                                   | Verdi                                       |
| -------------------------------------- | ------------------------------------------- |
| Målorg og miljø                        |                                             |
| Godkjend av                            |                                             |
| Endringsvindu                          |                                             |
| Metadata sletta                        | `ApexClass/AAREG_CheckObjectTypeNamingTest` |
| Preview/deploy-ID                      |                                             |
| Deploy-status                          |                                             |
| Etterkontroll utført av                |                                             |
| Runtime-/Flow-/permission-set-kontroll |                                             |
| Apex-testresultat                      |                                             |
| Avvik og oppfølging                    |                                             |

## Avgrensing

Denne runbooken dokumenterer berre testklassen som er fjerna i commit `193bd400`. Han dokumenterer ikkje sletting av `AAREG_checkObjectTypeNameche`, andre Apex-klasser, Flow, permission sets eller data. Slike slettingar krev eigne metadata-linjer, dependency-kontrollar og godkjenning.
