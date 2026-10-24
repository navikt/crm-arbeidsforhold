# Altinn-resultat som testscenario i Arbeidsforhold

**Dato:** 2026-10-20  
**Status:** Policy og scenariokatalog, T006–T009, er implementerte og dry-run-verifiserte.
Resten er planlagt; ingen varig deploy eller ende-til-ende-verifikasjon er utført.

Dette dokumentet gjeld konsumenten si teststøtte, ikkje simulering eller testing
av Altinn-integrasjonen. Spesifikasjonane er
[pakkegrensa](../../../.github/specs/altinn-provider-injection.md) og
[applikasjonsscenario](../../../.github/specs/altinn-consumer-scenarios.md).
Sjå også [kritiske avklaringar](grill.md) og [gjennomføringsplan](implementation-plan.md).

For arbeid i integrasjonspakka: ta med
[sjølvstendig overlevering til pakkeagenten](package-agent-handoff.md).

## Implementert policygrunnlag — 2026-10-25

[AAREG_AltinnScenarioPolicy](../../../force-app/integration/altinn/classes/AAREG_AltinnScenarioPolicy.cls)
eksponerer `resolveAssignment(targetUserId, personIdent)`. Metoden returnerer den
rå brukarsettinga etter godkjende sperrer, eller `null` når scenario er av.
Han opprettar ikkje ein provider, gjer ingen callouts og skriv ingen data.

- Hierarkisk `AAREG_AltinnScenarioSetting__c` har dei tre planlagde felta.
  `getValues(userId)` les rå brukarverdiar; ein manglande record blir identifisert
  med manglande `Id`. Org-/profilverdiar aktiverer aldri scenario gjennom arv.
- Manglande oppsett, utelaten aktivering og eksplisitt false gir ordinær bane
  utan miljøoppslag eller krav om testpermission. Checkbox-feltet kan ikkje lagre
  eksplisitt null; utelaten verdi får metadataens default false.
- Brei aktivering utan brukarrecord gir eksplisitt feil. Brukarrecord med false
  overstyrer breitt oppsett for den brukaren.
- Aktiv brukarsetting krev verifisert ikkje-produksjon, custom permission
  `AAREG_UseAltinnScenario`, same målbrukar som innlogga brukar, namn/alias og
  samsvarande ikkje-tom identitet frå brukarens kontakt-/kontokjede.
- `AAREG_AltinnScenarioUser` gir berre custom permission, ikkje Setup- eller
  skriverettar. Setting-records blir ikkje leverte eller automatisk oppretta.
- Policy og privat plattformlesar brukar `with sharing`. To eksplisitte
  `WITH SYSTEM_MODE`-oppslag les berre `Organization.IsSandbox` og den innlogga
  brukarens tilknytte identitet. Dette er den menneskeleg godkjende,
  avgrensa privilegiegrensa; ingen personident blir logga eller returnert.
  `without sharing` åleine løyste ikkje plattformens tilgangsfeil.
- Lesefeil blir vidareførte; ingen catch gjer feil om til «av» eller live-fallback.
  Katalogen validerer namn/alias uavhengig av policyen; framtidig provider må bruke begge.

### Verifikasjon

[Policytestane](../../../force-app/tests/classes/integration/altinn/AAREG_AltinnScenarioPolicyTest.cls)
brukar minimumstilgangsbrukar, reelle setting-records og reell permission-tildeling.
Testfixtures blir skrivne som administrator; runtime-kalla går som testbrukaren.
Produksjon, ukjent miljø, lesefeil og vellukka syntetisk identitetsbinding blir
testa gjennom ein privat testseam, ikkje mot ein produksjonsorg. Den faktiske
scratch-statusen og avvising av ein brukar utan kontaktidentitet er òg testa.
Gyldig identitetsbinding mot ein faktisk community-brukar står att i seinare
konsument-/UI-verifikasjon.

Første raude dry-run stoppa i kompilering fordi policyklassen mangla; ingen test
køyrde då. Utvida raud køyring avdekte òg testsyntaks som vart retta. Første
implementasjon køyrde 13 testar med feil i tilgang/oppsett. Seinare køyring hadde
14 av 15 grøne og avdekte at eksplisitt null ikkje kan skrivast til Checkbox.
Dette er ikkje ei påstand om ei ubrutt rein raud–grøn-rekkje.

Følgjande kommando gav **Succeeded, checkOnly=true, 15/15 testar, null feil og
34/34 køyrbare policylinjer dekte**, også etter refaktorering. Siste validering:
`0AfJW00000nmQ0n0AE`.

```sh
sf project deploy start --dry-run \
  --source-dir force-app/integration/altinn \
  --source-dir force-app/tests/classes/integration/altinn \
  --source-dir force-app/tests/classes/integration/common/Integration_TestDataFactory.cls \
  --target-org crm-arbeidsforhold \
  --test-level RunSpecifiedTests \
  --tests AAREG_AltinnScenarioPolicyTest \
  --wait 10 --json
```

Ein mellomliggjande dry-run stoppa med «That object name is already in use»;
seinare identisk validering fullførte utan omdøyping eller sletting av metadata.
Ingen varig deploy, pakkeoperasjon eller aktivering er utført.

Factory, provider og kopling til controller/UI er **ikkje**
implementerte. Cache-val D01 er framleis ope. Policygrunnlaget åleine gir ikkje
moglegheit til å gjennomføre ein mocka brukarjourney.

## Implementert scenariokatalog — 2026-10-25

[AAREG_AltinnScenarioRepository](../../../force-app/integration/altinn/classes/AAREG_AltinnScenarioRepository.cls)
les den pakkeleverte
[JSON-ressursen](../../../force-app/integration/altinn/staticresources/AAREG_AltinnScenarios.resource)
éin gong per instans. Ressursen har `schemaVersion=1`; alle S01–S08 har
definisjonsversjon 1 og ei beskriving av det forventa applikasjonsutfallet.
Ukjende schema-/definisjonsversjonar blir avviste, ikkje normaliserte.

Lesaren har fire Apex-operasjonar:

- `getScenarios()` listar definisjonane i katalogrekkjefølgje.
- `getScenario(name)` finn ei eksakt, case-sensitiv scenarioidentitet.
- `getSubject(name, alias)` finn organisasjonsresultat og rettsmatrise for eit logisk alias.
- `getRights(name, alias, organizationNumber, resource)` finn berre ei eksplisitt
  definert kombinasjon. Ukjende eller tomme nøklar gir feil, aldri implisitt Permit/Deny.

Dette er **definisjonslesing, ikkje scenarioautorisasjon eller Altinn-svar**.
Lesaren kjenner verken Setup-tildeling, faktisk brukaridentitet eller UI.
Framtidig factory/provider må bruke policyen, også ved direkte providerkall.
Eitt godkjent `WITH SYSTEM_MODE`-oppslag les berre `StaticResource.Body` for det
eksakte namnet `AAREG_AltinnScenarios` med tom namespace. Ingen nye brukarrettar,
callouts, DML eller cache på tvers av brukarar/transaksjonar er innførte.

### Format og forventa scenario

Katalogen blir deserialisert strengt til typa interne modellar. Heile innhaldet
blir validert før definisjonar blir tilgjengelege. Ukjende JSON-felt, manglande
felt/lister, duplikate scenario/alias/organisasjonar/rettsnøklar og motstridande
utfall gir eksplisitte feil utan kjeldedata i feilmeldinga.

Kvart alias har eitt organisasjonsutfall og ei liste med rettsutfall:

- Organisasjonar: `Success` med ei ikkje-null liste, eller `ResponseError`/
  `Exception` med syntetisk feilmelding og utan liste. Ei tom liste er eit
  gyldig vellukka resultat, ikkje ein oppsettsfeil.
- Rettar: `Decision` med `action=Access` og eksplisitt `decision=Permit|Deny`,
  eller `ResponseError`/`Exception` utan action/decision.
- Feilvariantar krev klassifiseringa `Robustness`. `ContractShape` beskriv berre
  strukturen i dagens referansekode, ikkje verifisert Altinn-interoperabilitet.
- Organisasjonsnummer er syntetiske ni-sifra plasshaldarar, ikkje gyldig
  testdatagrunnlag for oppslag mot andre integrasjonar. Person-oppføringa har
  ingen personident, organisasjonsnummer eller organisasjonsform.

| Scenario | Alias                          | Definisjon og forventa seinare applikasjonsobservasjon                                                                                               |
| -------- | ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| S01      | `subject-a`                    | A (`111111111`): søknad og brukerstøtte Permit. Ordinær søknads-/delingsflyt.                                                                        |
| S02      | `subject-a`                    | A: søknad Deny, brukerstøtte Permit. Berre brukerstøttetilgang.                                                                                      |
| S03      | `subject-a`                    | A: begge Deny. Rein brukar skal ikkje få nye delingar; tidlegare delingar blir observerte separat.                                                   |
| S04      | `subject-a`                    | A: søknad Permit/støtte Deny. B (`222222222`): søknad Deny/støtte Permit. Organisasjonsbyte skal bruke rett matrise.                                 |
| S05      | `subject-a`                    | Vellukka tom organisasjonsliste og tom rettsmatrise. Observer tomtilstand.                                                                           |
| S06      | `subject-a`                    | A med AS, B med ENK, C (`333333333`) med BEDR og éi Person-oppføring. Alle organisasjonane har begge Permit; berre UI filtrerer partar/former.       |
| S07      | `subject-a` / `subject-throws` | `ResponseError` respektive `Exception` for begge operasjonar. Separate robustheitsinput, ikkje live-kontraktevidens.                                 |
| S08      | `subject-a`                    | Berre B med søknad Deny/støtte Permit. Start seinare med A valt gjennom S01 og observer at A manglar; katalogen endrar ikkje lagra organisasjonsval. |

Ingen av UI-utfalla i tabellen er verifiserte enno. Katalogen opprettar ikkje
produktdata eller fjernar delingar. Administrator må framleis sikre syntetiske
brukarar, produktdata og andre utgåande kanalar før ende-til-ende-testing.

Provider-mapping står att i T010–T011: organisasjonssvar skal merkast `v3`, og
dagens rettssemantikk må bevarast. Referansekoden returnerer Permit med
`success=true`; Deny har `success=false`, `errorMessage='Access denied'` og ein
eksplisitt `Access/Deny/Resource`-rett. Vi endrar ikkje dette i katalogskiva.
S07 sitt organisasjons-ResponseError er eit robustheitsinput, fordi dagens
v3-metode normalt returnerer `success=true` med ei liste, også når den interne
organisasjons-callouten ikkje gir organisasjonar.

### Katalog- og policyverifikasjon

[Katalogtestane](../../../force-app/tests/classes/integration/altinn/AAREG_AltinnScenarioRepositoryTest.cls)
testar den pakkeleverte ressursen gjennom lesaren sine Apex-operasjonar, inkludert
minimumstilgang, eitt ressursoppslag og null DML/callouts. Ugyldige JSON-fixtures
går gjennom same konstruksjons-/valideringsbane via ein privat testkonstruktør;
det finst ikkje eit offentleg API for å erstatte kjelda.

- Raud førstetest: kompilatorfeil for manglande repository/type; null testar køyrde.
- Grøn førstetest: 1/1 bestått for minimumstilgang, alle åtte identitetar og S01.
- Raud valideringsrunde: 15 testar køyrde, 8 bestått og 7 feila på manglande
  semantisk validering eller uomsett JSON-feil.
- Grøn valideringsrunde: 15/15 bestått etter innhaldsvalidering.
- Utvida regresjon: ein ny test av null-listeelement avdekte at
  `JSON.deserializeStrict` avviser slike element som JSON-feil før den semantiske
  valideringa. Testforventninga vart tilpassa dette eksplisitte, trygge feilutfallet.
- Endeleg samla køyring: **Succeeded, checkOnly=true, 31/31 bestått**, fordelt på
  16 katalogtestar og 15 policytestar. Repository: **116/117 linjer dekte**;
  policy: **34/34**. Manglande ressurs er ikkje simulert; den siste udekte
  repositorylinja er denne feilbana. Ingen dekningsvarsel.

Eksakt samla kommando, siste validering `0AfJW00000nmR050AE`:

```sh
sf project deploy start --dry-run \
  --source-dir force-app/integration/altinn \
  --source-dir force-app/tests/classes/integration/altinn \
  --source-dir force-app/tests/classes/integration/common/Integration_TestDataFactory.cls \
  --target-org crm-arbeidsforhold \
  --test-level RunSpecifiedTests \
  --tests AAREG_AltinnScenarioRepositoryTest \
  --tests AAREG_AltinnScenarioPolicyTest \
  --wait 10 --json
```

Ingen varig deploy, pakkeoperasjon, provider-/controller-/UI-endring eller
aktivering vart utført i denne skiva. Cache-val D01 og faktisk pakkeleveranse/
konsumentkompilering for provider-injeksjon er framleis eigne gater.

## Kjeldegrunnlag og avgrensing

Lesne lokale kjelder:

- [AltinnCalloutService](../../../crm-platform-integration/main/default/classes/AltinnCalloutService.cls)
  held ein privat provider og opprettar standardimplementasjonen i standardkonstruktøren.
  Referansekjelda har no òg den additive konstruktøren for provider-injeksjon;
  faktisk pakkeleveranse og konsumentåtkomst må framleis dokumenterast separat.
- [IAltinnCalloutService](../../../crm-platform-integration/main/default/classes/IAltinnCalloutService.cls)
  har to operasjonar med `Object` som returtype.
- [AAREG_HomeController](../../../force-app/externalAccess/classes/AAREG_HomeController.cls)
  opprettar fasaden ved organisasjonsoppslag. Rettssjekken kan opprette delingar.
- [AAREG_CommunityUtils](../../../force-app/externalAccess/classes/AAREG_CommunityUtils.cls)
  opprettar fasaden ved rettsoppslag.
- [aareg_home](../../../force-app/externalAccess/lwc/aareg_home/aareg_home.js)
  hentar organisasjonar imperativt frå ein cacheable Apex-metode og sjekkar rettar
  i separate kall.

Dette er observasjonar i referansekjelda, ikkje bevis på deploya revisjon.
Pakkeeigar må stadfeste kontrakten i autoritativt repository. Arkitekturretninga
følgjer eksplisitt wiring som i
[ADR-0004](../../adr/0004-p360-composition-root-og-kontraktsgrense.md), men den ADR-en
er ikkje ei godkjenning av dette Altinn-designet.

## Føreslått arkitektur

```text
Community -> eksisterande controller/utils -> app-eigd factory
                                                  |
                                      les eksplisitt brukaroppsett
                                                  |
                              +-------------------+------------------+
                              |                                      |
                           modus av                              modus paa
                              |                                      |
                     eksisterande fasade                miljo-/brukar-/scenariovern
                              |                                      |
                       ordinaer provider               fasade med injisert provider
                                                                     |
                                                       scenario -> responsobjekt
                              |                                      |
                              +-------------------+------------------+
                                                  |
                                 eksisterande UI-/tilgangs-/delingslogikk
```

Grafisk kjelde: [komponentdiagram](diagrams/consumer-scenarios.mmd).
Ord som `modus paa` i tekstdiagrammet tyder eksplisitt brukaraktivering, ikkje
org-global aktivering.

## Kode og eigarskap

Nye namn og plasseringar er forslag som skal stadfestast før implementering.
Nye runtime-klassar er pakkelevert funksjonalitet med produksjonssperre, ikkje
`@IsTest`-klassar. Apex-testar skal liggje under `force-app/tests/classes/`.

| Plassering                                                                                         | Endring og ansvar                                                                                  |
| -------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Integrasjonspakka: `AltinnCalloutService.cls`                                                      | Additiv offentleg konstruktør med `IAltinnCalloutService`; null avvist; standardkonstruktør uendra |
| Integrasjonspakka: `AltinnCalloutServiceTest.cls`                                                  | Injeksjon, delegering, feil, null og bakoverkompatibilitet                                         |
| `force-app/externalAccess/classes/AAREG_HomeController.cls`                                        | Bruk felles factory for organisasjonar; ikkje flytt tilgang eller deling inn i mock                |
| `force-app/externalAccess/classes/AAREG_CommunityUtils.cls`                                        | Bruk same factory for rettar                                                                       |
| `force-app/integration/altinn/classes/AAREG_AltinnServiceFactory.cls`                              | Opprett ordinær eller scenario-basert fasade; ingen dynamisk service locator                       |
| `force-app/integration/altinn/classes/AAREG_AltinnScenarioPolicy.cls`                              | Miljø, rå brukarsetting, permission og identitetsbinding; ingen skriveoperasjonar                  |
| `force-app/integration/altinn/classes/AAREG_AltinnScenarioProvider.cls`                            | Implementer eksisterande interface med konkrete, typa responsobjekt                                |
| `force-app/integration/altinn/classes/AAREG_AltinnScenarioRepository.cls`                          | Les/valider versjonerte scenario til ein typa intern modell                                        |
| `force-app/integration/altinn/objects/AAREG_AltinnScenarioSetting__c/`                             | Hierarkisk setting, felta `UseScenarioProvider__c`, `ScenarioName__c`, `SubjectAlias__c`           |
| `force-app/integration/altinn/staticresources/AAREG_AltinnScenarios.resource`                      | Syntetiske scenario, schema-versjon, scenario-ID, beskriving og logiske alias                      |
| `force-app/integration/altinn/customPermissions/AAREG_UseAltinnScenario.customPermission-meta.xml` | Eksplisitt godkjenning av testbrukaren                                                             |
| `force-app/integration/altinn/permissionsets/AAREG_AltinnScenarioUser.permissionset-meta.xml`      | Berre nødvendige runtime-tilgangar og testpermission; ingen admin-/skriverettar                    |
| `force-app/externalAccess/lwc/aareg_home/`                                                         | Berre alternativ A krev oppfrisking av UI i denne leveransen                                       |

Alle nye Apex-/ressursfiler får nødvendige metadata-følgesfiler. Eksisterande
community-permission set skal ikkje gi mock-rett til alle.

Ingen endring i `Altinn3CalloutService`, Named/External Credentials,
HTTP-transport, token-cache, eksisterande DTO-ar eller v2-utfasing inngår.
`IAltinnCalloutService` sitt `Object`-API blir bevart; provideren skal likevel
konstruere konkrete responsobjekt, ikkje vilkårlege utypede verdiar.

## Konfigurasjons- og miljøkontrakt

Factoryen les ein faktisk brukarspesifikk record, ikkje berre den samanslegne
hierarkiverdien. Verifiser Salesforce sitt rå-record-oppslag i ein fokusert test:
det må kunne skilje ingen brukarrecord frå arv og frå eit tomt syntetisert objekt.

| Oppsett                                             | Resultat                                                                           |
| --------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Ingen org-/profil-/brukarrecord                     | Ordinær bane, ingen scenario-relatert feil                                         |
| Brukarrecord manglar eller aktivering er null/false | Ordinær bane                                                                       |
| Ingen org-record, brukarrecord eksplisitt true      | Vurder miljø, permission, identitet og scenario                                    |
| Org/profil true utan eksplisitt brukar true         | Avvis ugyldig brei aktivering; ikkje bruk arv til å aktivere mock                  |
| Eksplisitt brukar false over org/profil true        | Ordinær bane for denne brukaren; breitt oppsett er framleis ugyldig for aktivering |
| Aktivt scenario med ukjend ID/versjon/alias         | Eksplisitt oppsettsfeil, ingen live-fallback                                       |
| Aktivt scenario i produksjon eller ukjent miljø     | Avvis før provider-resultat, callout og scenarioutløyst DML                        |

Metadata finst i pakken; records treng ikkje finnast i org-en.
Forventa fråvær er normalt. Lesefeil eller ugyldig aktiv konfigurasjon er ikkje
det same som fråvær og skal ikkje fangast og returnerast som «av».

Føreslått tillaten miljøregel er Salesforce-verifisert `Organization.IsSandbox`
for scratch/sandbox, ikkje URL eller redigerbart org-namn. Stadfest scratch-åtferda
i godkjend scratch. Policyen skal kunne testast med ein injisert miljølesar utan
eit offentleg runtime-override eller bruk av produksjonsorg.

Med scenario av skal ikkje nye miljø-/testtilgangskrav blokkere ordinær drift.
Ved aktivt scenario må både factory og providerens runtime-operasjonar handheve
vernet, slik at direkte providerbruk ikkje omgår sperra.
Dette vernar dei leverte testinngangane; det er ikkje ein sandbox for annan
vilkårleg Apex-kode som ein administrator sjølv deployer.

## Identitet og data

- `SubjectAlias__c` er eit logisk alias, ikkje personident.
- Målbrukar må vere innlogga brukar. Provideren bind scenarioet til denne
  brukarens syntetiske kontakt-/kontokjede server-side og samanliknar førespurd
  personident med verdien i den kjeda. Personident skal ikkje loggast eller
  kopierast inn i scenariofila.
- Administrator må stadfeste at testbrukar og data er syntetiske. Eit alias eller
  ei permission kan ikkje i seg sjølv bevise dette.
- Rettar blir slått opp på alias, organisasjon og ressurs. Ukjent kombinasjon gir
  oppsettsfeil, ikkje Permit eller live-kall. Normalt avslag er eksplisitt Deny.
- Provideren les konfigurasjon/scenario og returnerer resultat; han gjer ikkje
  DML, seed, opprydding eller auth.
- Katalogen skal beskrive både realistiske resultat og eventuelle separate
  robustheitstestar. Ingen HTTP-statusar eller tokenformat treng simulerast.

## Framtidig Admin-app

Første leveranse har berre Setup som administrasjonsflate. Kataloglesar og
runtime-policy skal ikkje kjenne Setup eller LWC. Framtidig administrasjonsteneste
kan bruke dei til å vise scenario og validere tildelingar, med eiga autorisering,
endringshistorikk og server-side produksjonssperre for skriving.

Føreslått start er versjonerte scenariofiler, fordi vi ikkje byggjer ein editor no.
For ein framtidig meny «vel scenario for testbrukar» kan dei same filene brukast.
Ein framtidig editor krev derimot skrivbar lagring, validering, tilgang og
migrering. Ein lesekontrakt reduserer kopling, men gjer ikkje ein slik migrering gratis.

Admin-app, administrasjonsteneste, skrive-API, auditlagring, dataoppretting og
oppryddingsverktøy er eksplisitt utsette; dei er ikkje skjulte føresetnader for MVP.

## Produksjonspolicy

| Handling                               | Scratch/sandbox                           | Produksjon                         |
| -------------------------------------- | ----------------------------------------- | ---------------------------------- |
| Ordinær teneste med scenario av        | Normal drift                              | Normal drift                       |
| Bruke scenario                         | Eksplisitt godkjend syntetisk brukar      | Sperra                             |
| Gjere UI-handlingar etter mock Permit  | Reell applikasjons-DML; isolerte testdata | Scenario-bana sperra               |
| Framtidig Admin-statusvising           | Kan planleggjast                          | Berre lesing kan vurderast seinare |
| Framtidige seed-/oppryddingshandlingar | Eiga godkjend leveranse                   | Sperra; ingen overstyring no       |

Setup er Salesforce-administrasjon og kan ikkje erstattast av eit app-vern.
Ein privilegert administrator kan framleis skrive ein setting direkte i Setup.
Runtime skal avvise eit slikt aktivt produksjonsoppsett; det er ikkje mogleg å
love at appen hindrar all direkte administrativ metadata-/settingredigering.
Vi leverer ingen skrivefunksjon i produksjon og ingen «Allow in production».
Forsøk på bruk skal gi tydeleg feil etter eksisterande feil-/loggstandard utan
sensitivt innhald. Cacheable lesing må ikkje innføre DML for logging.

## D01: To cache-alternativ, ikkje eit skjult val

Dette er cache av organisasjonssvar i klienten, ikkje Altinn-token.
Rettssjekk skjer i eit separat ikkje-cacheable kall.

### A - Dynamisk oppfrisking

**Omfang:** Endre JS, HTML og LWC-testar. Bruk wire med støtta `refreshApex`-flyt,
eller anna dokumentert reell ferskhenting; ikkje kall `refreshApex` på eit
imperativt svar som om det var eit wire-resultat.

Ei vanleg oppfriskingshandling skal:

1. Nullstille gamle tilgangsverdiar og hindre overlappande handlingar.
2. Hente fersk organisasjonsliste og bruke dagens filtrering.
3. Hente/validere lagra organisasjonsval mot lista.
4. Berre sjekke rettar for eit gyldig val; elles krevje nytt val.
5. Halde tilgangen av og vise feil dersom oppfriskinga feilar.

**Konsekvens:** Betre brukarflyt ved scenariobyte og eit større UI-regresjonsomfang
også utan mock. Administrativt scenariobyte under eit pågåande kall er framleis
ikkje ein atomisk operasjon. Testaren skal byte utan pågåande brukarhandlingar.

### B - Faste scenario per brukar og kontrollerte testøkter

**Omfang:** Ingen ny oppfriskingsfunksjon no. Kvar syntetisk brukar held fast på
eitt scenario i denne testrunden. Bruk separate, isolerte nettlesarkontekstar ved
teststart og dokumenter at organisasjonslista faktisk samsvarar med tildelinga.
Vanleg refresh aleine er ikkje godkjend cache-verifikasjon.

**Konsekvens:** Mindre UI-kode, men fleire brukarar, meir oppsett og avhengigheit av
community-lisenskapasitet. Tel brukar-/lisensbehov før valet, utan å anta at
tidlegare rapportert kapasitet framleis er tilgjengeleg.

Dette alternativet lovar ikkje raskt scenariobyte på same brukar.
Permit-til-Deny blir karakterisert med fokuserte Apex-testar og, ved UI-testing,
ei eksplisitt verifisert ny testøkt. Dersom det ikkje kan repeterast påliteleg,
er B utilstrekkeleg for den reisa og A må vurderast.

**Valstatus:** Begge er planlagde; brukaren ønskjer omfang før val. Ingen
cache-/UI-endring eller påstand om full UI-verifikasjon før D01 er avgjort.

## Delingar og andre sideeffektar

Mock Permit kan utløyse faktiske `Agreement__Share` og `RelatedContact__Share`
gjennom dagens applikasjonskode. Den koden slettar ikkje tidlegare delingar ved Deny.

- Rein Deny-test startar med brukar/data utan tidlegare delingar.
- Permit-til-Deny er eigen karakterisering av UI og lagra tilgang, ikkje bevis på
  automatisk tilbakekalling.
- Manuell opprydding krev presise testrecordar og særskild avtale. Ingen brei
  sletting eller automatisk opprydding inngår.
- Altinn-mock sperrar ikkje e-post, P360 eller andre integrasjonar. Kontroller
  andre kanalar før innsendingar og andre sideeffektar i testmiljø.
- S08 kan avdekkje at dagens UI brukar eit forelda organisasjonsval. Dokumenter
  funnet; ein produktretting skal vere eiga godkjend åtferdsslice.

## Well-Architected vurdering

- **Trusted:** Hard produksjonssperre, eksplisitt brukaraktivering og permission,
  ingen live-fallback, identitetsbinding og isolerte testdata. Risiko: mock Permit
  utløyser reell DML i testmiljø; dette krev menneskeleg kontroll.
- **Easy:** Eit smalt pakke-API og berre to kallestader blir endra. Setup først,
  ingen mock-server eller generell administrasjonsplattform.
- **Adaptable:** Eksplisitt provider-injeksjon og UI-uavhengig katalog/policy.
  Framtidig editor eller produksjonstesting krev framleis eigne godkjende endringar.

Hovudtradeoff: Pakkelevert runtime-teststøtte gjer bruk i fleire testmiljø enklare,
men krev at produksjonssperra blir verifisert ved alle leverte runtime-inngangar.
