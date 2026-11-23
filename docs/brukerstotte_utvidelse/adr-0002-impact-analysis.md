# Konsekvensanalyse av ADR-0002

**Status:** Komplett statisk analysegrunnlag — ikke godkjent ADR-beslutning
**Dato for analyse:** 2026-11-19
**Dato for utvidet metadata-/kryssrepoanalyse:** 2026-11-23
**Omfang:** crm-arbeidsforhold, crm-ips, sf-arkiv-jobbsporet og tilknyttede arbeidsgiverrepoer

Denne analysen vurderer hvordan foreslått bruk av `AccountContactRelation` (ACR) for Personkontoer påvirker alle repositoriene i arbeidsgiver-/Aa-registeret-landskapet. Metoden kombinerer lokal Salesforce-metadata og kodegjennomgang, offentlig statisk GitHub-gjennomgang og kryssanalyse av pakkeavhengigheter. Ingen Salesforce-org, Apex-tests eller produksjonsdata er verifisert som del av analysen.

## Sammendrag

| Repo/app                              | Samlet risiko                           | Dominerende påvirkning                                                                                               |
| ------------------------------------- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `crm-arbeidsforhold`                  | Middels                                 | Ekstern tilgang, support, søknader, avtaler, meldinger, Altinn, Contact/Personkonto og Flow/permission-set-koblinger |
| `crm-ips`                             | Lav til middels                         | PersonAccount, Work Trail, portal, ACR-layout, permission sets og rolebasert sharing                                 |
| `sf-arkiv-jobbsporet`                 | Ingen direkte, lav indirekte            | fnr/orgnr-payload, arkivnøkler og downstream-kontrakt må bevares                                                     |
| `arena-arbeidsgiver-aktivitet-filter` | Lav indirekte                           | Arena-/Kafka-data må fortsatt kobles mot stabilt organisasjonsnummer, ikke Salesforce-/ACR-ID                        |
| `crm-arbeidsgiver-base`               | Høyest direkte kontakt-/relasjonsrisiko | Shared Contact-opprettelse, e-postmatching, `AccountContactRelation`, ACR-status og PersonAccount                    |
| `crm-arbeidsgiver-innsyn`             | Lav til middels indirekte               | Kandidat-/personidentitet, snokelogg og synlig persondata må ikke endres via ACR                                     |
| `crm-arbeidsgiver-integration`        | Høy indirekte import-/migreringsrisiko  | Mange Kafka-handlere bruker orgnr, Account, Contact og ACR-lignende relasjoner                                       |
| `crm-arbeidsgiver-kontaktskjema`      | Lav direkte ACR-risiko                  | Publikumsinnsender må ikke kobles til PersonAccount eller ACR som autorisasjon                                       |
| `crm-arbeidsgiver-tcrm`               | Lav til middels indirekte               | Rapportering og KPI kan påvirkes av delte Account-/Contact-/Personkonto-data                                         |
| `crm-arbeidsgiver-utilities`          | Lav direkte                             | Felles Kafka/Salesforce REST kan ikke få ACR-ID eller person-ID som ny implisitt kontrakt                            |
| `crm-arbeidsgiver-dialog`             | Høy tilgangsrisiko                      | Personkonto, organisasjonskontekst, Altinn og Salesforce `Thread__Share` må samordnes                                |

Den mest sannsynlige negative konsekvensen er ikke kompileringsfeil i øvrige repoer. Hovedrisikoen ligger på tvers av alle repoene i:

- migrering som endrer eller sletter eksisterende relasjoner,
- globale ACR-triggere eller batchjobber som skriver til andre pakker,
- bruk av ACR som implisitt tilgangs- eller representasjonskilde,
- endring av standardfelter eller rolleverdi,
- endring av Personkonto-, ContactId-, AccountId- eller personidentitetsmodell,
- duplikater og konflikt i samtidig relasjons-/e-postimport,
- endring av fnr/orgnr- og nedstrøms integrasjonskontrakter.

**Anbefalt mål for alle repositoriene:** Lavere eller ingen negativ påvirkning ved en additiv, avgrenset, idempotent og migreringssikker implementasjon. Ingen repo skal få ny ACR- eller Personkontoavhengighet uten et eksplisitt behov, package-/domeneavhengighet og regresjonstest.

---

## ADR-0002 i dag

Den foreslåtte ADR-0002 beslutningen er å bruke Salesforce-standardobjektet `AccountContactRelation` i stedet for egendefinerte koblingsobjekter eller å stole utelukkende på primære foreldre-barn-oppslag.

ADR-tekstens foreslåtte endringer inkluderer:

- bruk av ACR for mange-til-mange-relasjoner mellom Personkontoer og kontoer
- brukerdefinerte rolleverdier som Ansatt, Arbeidsgiver og Partner
- historisk sporing med StartDate, EndDate og IsActive
- migrering av relasjoner til ACR
- oppdatering av nedstrøms triggere/flyter

ADR-0002 har status **Foreslått** i repoet. Se [ADR-0002](../adr/0002-accountcontactrelation-for-personkontoer.md).

### Viktig avgrensing

ADR-0002 bør behandles som en relasjonsmodellbeslutning, ikke som en beslutning om tilgang.

ACR bør ikke alene:

- gi en bruker tilgang til en rollepage
- bestemme hva en bruker kan skrive eller lese
- åpne en organisasjonskontroll
- velge hvilke meldinger eller søknader en bruker ser
- erstatte Salesforce sharing, CRUD/FLS eller server-side autorisasjon

---

## Funn i sf-arkiv-jobbsporet

### Teknisk basis

`sf-arkiv-jobbsporet` er en Kotlin-applikasjon med PostgreSQL og et HTTP/OpenAPI-grensesnitt.

Sentral avhengighetsliste i [build.gradle](../../../sf-arkiv-jobbsporet/build.gradle):

- Kotlin/JVM 21
- HTTP4K
- PostgreSQL JDBC
- HikariCP
- Gson/Jackson
- Nav token-validation
- ingen Salesforce SDK
- ingen Salesforce package dependency

### Funn i kodebasen

- Ingen direkte referanse til `AccountContactRelation` ble funnet i applikasjonskoden.
- Ingen direkte referanse til `PersonAccount` eller `PersonContact` ble funnet.
- Ingen Apex/SOObject/Salesforce data-modellavhengighet ble funnet.
- Ingen ACR-felter eller Salesforce-relasjon-ID-er inngår i API-kontrakten.
- API-et arkiverer og henter poster i [openapi.yaml](../../../sf-arkiv-jobbsporet/src/main/resources/openapi.yaml).

Relevante API-felt er:

- `aktoerid`
- `fnr`
- `orgnr`
- `kilde`
- `tema`
- `dokumentasjonId`
- `dokumentdato`

Data lagres i PostgreSQL-tabeller, ikke i Salesforce.

### sf-arkiv-jobbsporet: Mulig kompileringspåvirkning

**Ingen forventet påvirkning.**

ADR-0002 trenger ikke å gi Salesforce-klientkode eller nye Gradle-avhengigheter til dette repoet.

### sf-arkiv-jobbsporet: Mulig kjøretids-/datapåvirkning

**Lav indirekte risiko.**

Mulig påvirkning oppstår bare hvis endringer i Salesforce upstream:

- endrer verdien som sendes som `fnr`
- endrer verdien som sendes som `orgnr`
- lager duplikater i arkivkilden
- sender feil person-/organisasjonsnøkkel
- endrer innholdet i `kilde`, `tema` eller `dokumentasjonId`

### Konklusjon for sf-arkiv-jobbsporet

- Kompileringsrisiko: Ingen
- Kjøretidsrisiko: Lav
- Datataprisiko: Lav
- Forretningslogikkrisiko: Lav
- Avhengighet til ACR: Ingen direkte

---

## Funn i crm-ips

### Relevante Salesforce-avhengigheter

CRM-IPS har allerede støtte for personkontoer og bruker ACR i flere deler av løsningen.

#### Personkontoer

Eksempel på personkontoavhengighet:

- [IPS_Utility.cls](../../../crm-ips/force-app/ipsUtility/classes/IPS_Utility.cls)
    - Henter `User.AccountId`
    - Leser `Account.CRM_Person__r.INT_Confidential__C`
    - Brukes i person-/brukerkontekst
- [ips_Participant__c.field-meta.xml](../../../crm-ips/force-app/main/default/objects/Work_Trail__c/fields/ips_Participant__c.field-meta.xml)
    - Felter på Work Trail må peke til PersonAccount
    - Har lookup filter `Account.IsPersonAccount = true`

Andre relevante felter inkluderer:

- `ips_Participant__c`
- `AMS_Employer__c`
- `ips_Employer__c`
- `Konto_kontakt__c`
- `Account.CRM_Person__c`
- `Account.IsPersonAccount`

#### Eksisterende ACR-visninger

Følgende metadata bruker standard ACR-relasjoner:

- [Account layout](../../../crm-ips/force-app/main/default/layouts/Account-IPS%2FUO%20Account.layout-meta.xml)
    - Viser `ACCCONRELATION.ROLES`
    - Viser `RelatedAccountContactRelationList`
- [IPS Employer Record Page](../../../crm-ips/force-app/main/default/flexipages/IPS_EmployerRecordpage.flexipage-meta.xml)
    - Viser `AccountContactRelation`
- [AMS Employer Record Page](../../../crm-ips/force-app/main/default/flexipages/AMS_EmployerRecordpage.flexipage-meta.xml)
    - Viser ACR-relaterte data
- [IPS Contact Record Page](../../../crm-ips/force-app/main/default/flexipages/IPS_ContactRecordPage.flexipage-meta.xml)
    - Eksponerer ACR-relaterte kontoer

#### Permission set-avhengigheter

Følgende permission sets har eksplisitt lesetilgang til `AccountContactRelation.IsActive`:

- `IPS_management.permissionset-meta.xml`
- `IPS_Metodeveileder_Management.permissionset-meta.xml`
- `IPS_AMS_User_Support.permissionset-meta.xml`
- `IPS_Utvidet_oppf_lging_management.permissionset-meta.xml`
- `CE_management.permissionset-meta.xml`

Dette betyr at metadata allerede forventer at objektet finnes i org og at IsActive er tilgjengelig som standardfelt.

#### Pakkavhengigheter

CRM-IPS avhenger blant annet av:

- `crm-platform-base`
- `crm-platform-access-control`
- `crm-arbeidsgiver-base`
- `crm-henvendelse`
- `crm-thread-view`
- `crm-community-base`
- `crm-shared-timeline`

Pakkene er definert i [sfdx-project.json](../../../crm-ips/sfdx-project.json).

Dette utvider blast radius hvis ACR-migrering eller datavitser endrer data som deles mellom disse pakkene.

### crm-ips: Mulig kompileringspåvirkning

**Lav risiko.**

Søket fant ingen Apex-kode som refererer til nye prosjektspesifikke ACR-feltnavn som ennå ikke finnes i metadata eller atferdsbeskrivelse.

Kompileringsfeil kan oppstå bare dersom:

- ADR-implementasjonen refererer til felter som ikke finnes i CRM-IPS dependency-pakken
- en felles PersonAccount-/Contact-feltmodell endres og eksisterende referanser ikke oppdateres
- standardet for `AccountContactRelation.Roles` eller IsActive endres på en måte som gjør at CRM-IPS metadata blir ugyldig
- nye SObject-klasser brukes i Apex uten at Salesforce-konfigurasjon støtter dem

### crm-ips: Mulig kjøretids-/datapåvirkning

**Lav til middels risiko.**

Mulige problemer:

- personen får flere relaterte kontoer samtidig
- gamle og nye ACR-posteringer eksisterer parallelt
- CRM-IPS viser flere relasjoner i samme liste
- kode antar én relevant konto eller ett hovedforhold
- endringer i standard rolleliste gir uventede UI-resultater
- sharing-/record-tilgang påvirker hvor mye av Personkonto- eller arbeidsgiverdata som synes

### Mulig datataprisiko

**Lav til middels, avhengig av migrering.**

Risiko øker hvis implementasjonen:

- sletter eksisterende koblinger
- flytter koblinger uten å bevare historikk
- erstatter direkte konto-/kontaktkoblinger
- overskriver eksisterende rolleverdier
- oppretter duplikatrelasjoner
- ikke er idempotent ved retry

Additiv og migreringssikker implementasjon gir lavere datataprisiko.

### Mulig forretningspåvirkning

**Lav til middels risiko.**

CRM-IPS bruker PersonAccount som deltakeridentitet i Work Trail, jobber og aktiviteter.

En ACR-endring kan påvirke:

- hvilke arbeidsgivere som vises som relevante
- hvilke kontaktpersoner som synes på arbeidsgiverkonto
- hvordan `AccountContactRelation.Roles` tolkes i UI
- personens flere samtidige relasjoner
- sharing av arbeidsgiver- eller deltakerdata

Det finnes ikke indikasjon på at CRM-IPS Apex-logikken i dag bruker ACR som primær autorisasjonskilde. Hovedrisikoen er derfor data- og relasjonsmodellering, ikke en direkte ACR-kodeavhengighet.

---

## Virkninger på andre Nav-domener

### Personkonto og kontaktrelasjoner

CRM-IPS har allerede PersonAccount-funksjonalitet og bruker ACR i metadata.

ADR-0002 bør derfor ikke antas å være isolert til crm-arbeidsforhold. Samme Personkonto kan brukes i flere pakker og org.

Dette betyr at endringer kan påvirke:

- partnerrelasjoner
- arbeidsgiverkontakter
- Personkonto-identitet
- relaterte listdata
- permissions og sharing
- kontakt-/AccountData i Work Trail og tilknyttede hendelser

### Temaer som må koordineres

- samme ACR-post kan sees i flere pakker
- samme `Roles`-verdi kan tolkes forskjellig
- samme Personkonto kan ha flere roller
- én ACR-endring kan påvirke flere Work Trail- eller arbeidsgiverflater
- oppdateringer må ikke bli globalt stillings- eller forretningsspesifikk automatikk

---

## Konkrete anbefalinger til ADR-0002

### 1. Bruk en additiv modell

ADR-teksten bør eksplisitt si:

> ADR-0002 legger til ACR som standardmodell for personkontoens mange-til-mange-relasjoner. Eksisterende Personkonto, Account, Contact, primærkjede og forretningsobjekter skal ikke erstattes eller slettes som en del av denne beslutningen.

### 2. Behold eksisterende koblinger under migrering

Krav til migrering:

- opprett ACR-poster uten å slette eksisterende koblinger
- oppretthold historiske relasjoner
- unngå duplikater
- sikre idempotent migreringsjobb
- verifiser relasjon og rolle før sletting av legacy-data
- legg til rollback og re-kjørbarhet
- migrering skal ikke endre Personkonto-ID eller primærkontakt

### 3. Ikke bruk ACR som tilgangskilde

Legg til følgende form for ADR-prinsipp:

> ACR beskriver relasjon og representasjonskontekst. ACR gir ikke i seg selv datatilgang, brukerrettigheter eller myndighet. Tilgang vurderes fortsatt gjennom Salesforce sharing, CRUD/FLS og server-side autorisasjon. Organisasjonsrettighet skal validere mot godkjent kilde som Altinn eller annen foreskreven autoritativ kilde.

### 4. Begrens endringer i standard rollen

ADR-teksten bør si:

> Standardfeltet AccountContactRelation.Roles utvides additivt. Eksisterende verdier skal ikke omdøpes eller slettes. Eventuelle prosjektspecifikke verdier skal dokumenteres og ikke brukes som implisitt autorisasjonsnøkkel.

Foreslått avgrensing av domeneverdier:

- `Employee`
- `Employer`
- `Partner`
- `AuthorizedRepresentative`
- separate fremtidige roller

Rolleverdi må ikke brukes som eneste identifikasjon av personens faktiske rettighet.

### 5. Ingen global automatikk som endrer andre pakker

ADR-tekst bør kreve:

> Ingen trigger, Flow eller batchjob som skriver ACR skal endre Work_Trail__c, Personkontoer, hendelser eller CRM-IPS-felt uten eksplisitt pakkeavhengighet og testdekning.

Automatikk skal være:

- package-eid
- record-scoped
- eksplisitt begrenset
- event-/domene-basert der det er mulig
- uten utilsiktet sideeffekt på andre Salesforce-pakker

### 6. Isolerer personmaster og relasjonsmaster

ADR-teksten bør skille mellom:

- Personmaster for identitet
- Relasjonsmaster for koblinger
- Tilgangskilde for autorisasjon
- UI-context for brukeropplevelse

Det anbefales at ikke samme komponent prøver å være alle fire.

### 7. Behold stabile integrasjonsnøkler

For `sf-arkiv-jobbsporet` og andre downstream-systemer bør ADR-0002 kreve:

- eksisterende fnr/orgnr-kontrakter beholdes
- Salesforce-ID eller ACR-ID er ikke virksomhetsnøkkel
- nye relasjoner påvirker ikke eksisterende arkivfelt
- nedstrøms API-versjon skal ikke endres uten versjonert kontrakt
- ACR-ID sendes ikke implisitt som ersstatning for fnr/orgnr

### 8. Package- og deploymentkontroll

Følgende bør være obligatoriske før utrulling:

- endring av `Account Settings` etter godkjent admin-endring
- oppgradering av permission set i alle berørte pakker
- regresjon i CRM-IPS layout og relaterte lister
- regresjon i crm-arbeidsgiver-base
- kontroll av deling for multi-relationship-user
- SIT2-verifisering av metadata endring
- Tilbakerulling av migrering uten at Personkontoer endres

### 9. Konkrete testkrav

#### CRM-IPS

- PersonAccount opprettes eller leses uten uendret ACR
- flere ACR-relasjoner påvirker ikke eksisterende Work Trail
- Participant lookup fortsatt krever PersonAccount
- relaterte kontoer/lister viser korrekt rolle
- permission sets gir fortsatt riktig lesetilgang
- ingen endring i eksisterende arbeidsgiver-/deltakerlogikk

#### CRM-arbeidsforhold

- Person representerer flere organisasjoner
- Person har samme tid som virksomhetsrepresentant og arbeidsgiver
- inaktive/utløpte ACR-poster ignoreres
- Aktiv ACR brukes ikke som eneste tilgangskilde
- rolle og organisasjonskontekst kan ikke brukes som autorisasjon

#### sf-arkiv-jobbsporet

- fnr/orgnr payload er uendret
- arkiv-ID og API-kontrakt er uendret
- ingen Salesforce-ID overskriver payload-nøkler
- integrasjonstest godkjent

### 10. Målbar exit-kriterie

ADR-0002 bør anses som kompatibelt først når:

- CRM-IPS har ingen nye regresjonsfeil
- eksisterende Personkonto-/Work Trail-data er uendret
- eksisterende relasjoner er bevart
- ingen globale sideeffekter er observert i andre pakker
- fnr/orgnr-avleveringskontrakten er uendret
- en rollback uten datatap er dokumentert

---

## Samlet risiko og anbefalt ADR-formulering

**CRM-IPS: Lav til middels risiko.**  
**Sf-arkiv-jobbsporet: Ingen direkte risiko, lav indirekte risiko.**

Foreslått ADR-konklusjon:

> ACR brukes som additiv standard relasjonsmodell for Personkontoer og flere kontotilknytninger. Implementeringen skal ikke endre eksisterende Personkonto- eller forretningsdata, skal ikke overskrive legacykoblinger, skal ikke bruke ACR som tilgangskilde alene, og skal ikke endre integrasjonskontrakter eller andre Salesforce-pakkers data uten eksplisitt avhengighet og regresjonstest. Migreringen skal være additiv, idempotent, rollbackbar og isolert fra globale forretningsautomatiseringer.

## Teamdiskusjonspunkter

Før teamet godkjenner ADR-0002 bør følgende besluttes:

1. Skal ACR bare brukes som representasjonsrelasjon eller også som datakilde for meldings- og supportkontekst?
2. Skal eksisterende ACR-relasjoner i CRM-IPS gjøres om til prosjektspecifikke rolleverdi ved utrulling?
3. Hvem eier Personkonto-/ACR-migreringen og hvordan verifiseres den i CRM-IPS og CRM-arbeidsforhold?
4. Skal rolleverdien `Employee`, `Employer`, `Partner` eller norske businessrolleverdi være autoritativ?
5. Hvilken pakke kan eie og distribuere standardrolleverdien i ACR?
6. Hvilke globale ACR-triggere/flows finnes i org i dag og hvilke pakker berøres de?
7. Hvilke nedstrøms repoer får Personkonto-, AccountId- eller rolleendringer uten å være pakkeavhengige i samme endring?
8. Hvordan skal flere ACR-relasjoner håndteres i UI og sharing for samme person?
