# Altinn-resultat som testscenario i Arbeidsforhold

**Dato:** 2026-10-20  
**Status:** Føreslått design. Ingen implementering, deploy eller org-verifikasjon.

Dette dokumentet gjeld konsumenten si teststøtte, ikkje simulering eller testing
av Altinn-integrasjonen. Spesifikasjonane er
[pakkegrensa](../../../.github/specs/altinn-provider-injection.md) og
[applikasjonsscenario](../../../.github/specs/altinn-consumer-scenarios.md).
Sjå også [kritiske avklaringar](grill.md) og [gjennomføringsplan](implementation-plan.md).

## Kjeldegrunnlag og avgrensing

Lesne lokale kjelder:

- [AltinnCalloutService](../../../crm-platform-integration/main/default/classes/AltinnCalloutService.cls)
  held ein privat provider og opprettar standardimplementasjonen i konstruktøren.
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
