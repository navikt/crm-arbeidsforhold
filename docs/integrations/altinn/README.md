# Altinn-resultat som testscenario i Arbeidsforhold

**Dato:** 2026-10-20  
**Status:** Grunnoppsettet er deploya til `nav-community-dev`, og S01–S08 er
prøvde i nettlesaren. Rettingane etter S05/S07/S08 er òg deploya etter
godkjenning, med 20/20 LWC-testar og 19/19 Apex-testar grøne.
Nettlesarretest av S05/S07/S08, sortering og S01-gjenoppretting er no bestått.
Siste LWC-suite etter sorteringsretting: 22/22. Ei betre forklaring/neste
handling i S05-tomtilstanden er open UX-oppfølging.
Éin generisk Community Plus-testbrukar er sett opp.

Dette dokumentet gjeld konsumenten si teststøtte, ikkje simulering eller testing
av Altinn-integrasjonen. Spesifikasjonane er
[pakkegrensa](../../../.github/specs/altinn-provider-injection.md) og
[applikasjonsscenario](../../../.github/specs/altinn-consumer-scenarios.md).
Sjå også [kritiske avklaringar](grill.md) og [gjennomføringsplan](implementation-plan.md).
For guida scratch-org-verifikasjon, sjå [stegvis testguide](test-guide.md) og
[løpande testlogg](altinn-test-log.md).

For arbeid i integrasjonspakka: ta med
[sjølvstendig overlevering til pakkeagenten](package-agent-handoff.md).

## Gjeldande testoppsett — 2026-10-25

Bruk **Synthetic Community Test User** for alle scenario og andre community-
testar som krev Plus-lisens. Den eksisterande Permit-brukaren og kontakten er
migrerte med same identitet og historikk. Dei fire andre seed-brukarane og
scenarioinnstillingane deira er deaktiverte, ikkje sletta. Lisenskontrollen i
`nav-community-dev` viser Plus 1/1 i bruk og High Volume 0/5 i bruk.

`altinn-scenario-users`-poststeget opprettar/migrerer no berre denne generiske
brukaren og éi aktiv brukarsetting, med S01 og `subject-a`. Køyringa er
idempotent og gjenopprettar S01; vanleg scenariobyte skal derfor gjerast ved å
redigere brukarsettinga, ikkje ved å køyre seedet på nytt.
Sjå [den sjølvbetente GUI-/CLI-guiden](./test-guide.md) for oppsett,
kontrollskript, innlogging, alle scenario og gjenoppretting.

Rett etter den manuelle testøkta blei desse regresjonane retta og deploya:

- S05: tom liste viser ikkje lenger panelet som ber om val i ein manglande veljar.
- S07: teknisk feil tømmer gamle organisasjonar og blir ståande gjennom
  gjenteken oppfrisking. Tilgang er av; teknisk rights-feil utan avgjerd blir
  ikkje omgjord til vanleg Deny i controlleren.
- S08: dersom valt A fell bort, viser veljaren eksplisitt plasshaldar. B må
  veljast før lagring/rettskontroll; nettlesarens automatiske visuelle førsteval
  blir ikkje brukt som ein skjult tilgangsavgjerd.

Jest stadfestar DOM, brukartilhendingar, feil og gjenoppretting; Apex-dry-run
stadfestar controllerkontrakten. Nettlesarretesten er bestått; S05 si
forklaring/neste handling treng framleis UX-oppfølging. Gamle
avtaledelingar blir ikkje tilbakekalla ved scenariobyte, så gjenbruk av same
brukar beviser ikkje record-nivå-Deny. Eldre avsnitt nedanfor dokumenterer
historiske køyringar og lisensoppsett, ikkje dagens brukarfordeling.

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
  skriverettar. Scratch-oppsettet køyrer eit eige seed-steg etter publisering av
  nettstaden; det opprettar éin generisk syntetisk brukar og brukarsetting utan
  å setje passord. Steget brukar ein eksisterande intern scratch-testbrukar som
  kontoeigar og gir brukaren lågaste tilgjengelege rolle dersom det trengst;
  dette endrar rollehierarkiet sin delingsåtferd og er avgrensa til scratch.
  Dette er ikkje del av policy/provider-runtime.
- Policy og privat plattformlesar brukar `with sharing`. To eksplisitte
  `WITH SYSTEM_MODE`-oppslag les berre `Organization.IsSandbox` og den innlogga
  brukarens tilknytte identitet. Dette er den menneskeleg godkjende,
  avgrensa privilegiegrensa; ingen personident blir logga eller returnert.
  `without sharing` åleine løyste ikkje plattformens tilgangsfeil.
- Lesefeil blir vidareførte; ingen catch gjer feil om til «av» eller live-fallback.
  Katalogen validerer namn/alias uavhengig av policyen; provideren brukar begge.

### Verifikasjon

[Policytestane](../../../force-app/tests/classes/integration/altinn/AAREG_AltinnScenarioPolicyTest.cls)
brukar minimumstilgangsbrukar, reelle setting-records og reell permission-tildeling.
Testfixtures blir skrivne som administrator; runtime-kalla går som testbrukaren.
Produksjon, ukjent miljø, lesefeil og vellukka syntetisk identitetsbinding blir
testa gjennom ein privat testseam, ikkje mot ein produksjonsorg. Den faktiske
scratch-statusen og avvising av ein brukar utan kontaktidentitet er òg testa.
Ei syntetisk identitet bunden til ein faktisk Contact/Account-kjede på ein
syntetisk community-brukar blir testa i journey-skiva nedanfor; ingen reell
personidentitet blir brukt.

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

Etter at policygrunnlaget var verifisert, stod koplinga til controller/UI att.
Ho er sidan implementert og beskriven i
[controller-/journey-statusen](#controllerkopling-og-apex-journey--2026-10-25).
D01 er seinare valt som A; oppfriskingsarbeidet er beskrive nedanfor.

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
Provideren brukar policyen, også ved direkte providerkall.
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
produktdata eller fjernar delingar. Scratch-seedet opprettar S01- og S03-brukarar,
men autentisering i nettlesar, produktdata og andre utgåande kanalar må framleis
avklarast før ende-til-ende-testing.

Provider-mapping er implementert i T010–T011: organisasjonssvar blir merkte `v3`, og
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
aktivering vart utført i denne skiva. Pakkegrense og provider-mapping er seinare
verifiserte nedanfor; D01/A er implementert og dokumentert nedanfor.

## Implementert provider og factory

Installerte pakker i `crm-arbeidsforhold` viste `crm-platform-integration`
**0.177.0.4**. Ein konsumenttest kompilerte mot det faktisk installerte API-et og
verifiserte begge injiserte DTO-delegeringane, objektidentitet og eksplisitt
null-provider-feil. Dry-run `0AfJW00000nmREb0AM` var grøn.
Etter særskild godkjenning er avhengigheita i
[`sfdx-project.json`](../../../sfdx-project.json) låst til denne versjonen.
Ingen pakkeinstallasjon eller publisering vart utført. Konsumentbeviset lukkar
ikkje automatisk pakkeeigarens separate review-/releasearbeid i
[navikt/crm-platform-integration#478](https://github.com/navikt/crm-platform-integration/issues/478).

[AAREG_AltinnServiceFactory](../../../force-app/integration/altinn/classes/AAREG_AltinnServiceFactory.cls)
eksponerer `createService(targetUserId, personIdent)`:

- Avslått eller manglande brukarsetting gir den uendra standardkonstruktøren.
  Eksisterande v2/v3-val, oppsettskrav og feil blir bevarte.
- Aktiv, godkjend setting gir fasaden med
  [AAREG_AltinnScenarioProvider](../../../force-app/integration/altinn/classes/AAREG_AltinnScenarioProvider.cls).
  Ukjende scenarionamn/alias blir avviste ved første operasjon, ikkje ved
  factory-konstruksjonen. Feil gir aldri live-fallback.
- Kvar provideroperasjon køyrer policyen på nytt. Deaktivering, endra tildeling,
  identitet, permission eller miljø blir ikkje skjulte av ein tidlegare factory-
  eller providerinstans. Berre den pakkeleverte katalogen blir lesen éin gong
  per providerinstans.
- Resultata er nye konkrete DTO-ar, utan filtrering av organisasjonar,
  produkt-DML eller callouts. Endring av eit returnert svar endrar ikkje seinare
  svar. S01–S08 bevarer dei definerte Permit-/Deny-, tomliste- og feilutfalla.
- Ingen nye privilegerte oppslag eller brukarrettar er innførte.

### Provider-/factoryverifikasjon

[Factorytestane](../../../force-app/tests/classes/integration/altinn/AAREG_AltinnServiceFactoryTest.cls)
og [providertestane](../../../force-app/tests/classes/integration/altinn/AAREG_AltinnScenarioProviderTest.cls)
brukar felles
[syntetiske fixtures](../../../force-app/tests/classes/integration/altinn/AAREG_AltinnTestDataFactory.cls).
Scenario og sperrer blir testa med minimumstilgang og reelle setting-/permission-
tildelingar; den vellukka identitetsbindinga brukar framleis den private
syntetiske miljø-/identitetsseamen, ikkje ein faktisk community-journey.

Raud førstetest stoppa på manglande klassar; første implementasjon gav 34/34
samla grøne testar. Utvidinga avdekte to testkompileringsfeil som vart retta.
Deretter gav 59 testar to feil i eksisterande Altinn 2-tokenkode:
minimumsprofilen kunne ikkje lese `Maskinportenclient__mdt`.
Dei to transportregresjonane køyrer difor som scratch-administratoren, med
HTTP-mock. Dei beviser standardresultat for ein autorisert brukar, ikkje live
metadata-tilgang for minimumsprofilen. Ingen dependency-kode eller tilgangar
vart endra for å gjere testane grøne.

Siste samla validering, **`0AfJW00000nmRjF0AU`: Succeeded, checkOnly=true,
59/59 bestått**, utan dekningsvarsel. Fordeling: 11 factory-, 17 provider-,
15 policy- og 16 katalogtestar. Provider **54/54**, factory **7/7**, policy
**34/34** og repository **116/117** køyrbare linjer dekte.

```sh
sf project deploy start --dry-run \
  --source-dir force-app/integration/altinn \
  --source-dir force-app/tests/classes/integration/altinn \
  --source-dir force-app/tests/classes/integration/common/Integration_TestDataFactory.cls \
  --target-org crm-arbeidsforhold \
  --test-level RunSpecifiedTests \
  --tests AAREG_AltinnServiceFactoryTest \
  --tests AAREG_AltinnScenarioProviderTest \
  --tests AAREG_AltinnScenarioPolicyTest \
  --tests AAREG_AltinnScenarioRepositoryTest \
  --wait 10 --json
```

Ingen varig deploy, scenarioaktivering eller controller-/UI-kopling er utført
i denne provider-/factoryskiva. T012–T013 og D01/A er dokumenterte nedanfor.

## Controllerkopling og Apex-journey — 2026-10-25

[AAREG_HomeController](../../../force-app/externalAccess/classes/AAREG_HomeController.cls)
og [AAREG_CommunityUtils](../../../force-app/externalAccess/classes/AAREG_CommunityUtils.cls)
brukar no den felles factoryen for organisasjons- og rettsoppslag. Dei sender
innlogga brukar og identiteten frå brukarens kontakt-/kontokjede vidare; policyen
kontrollerer at scenario berre svarar for same innlogga brukar.

Den testspesifikke overstyringa som alltid sette siste organisasjon til
`DEFAULT_ORGANIZATION_NUMBER` er fjerna frå `shareAgreementsWithUser`.
Ho kunne få testar til å hevde deling mot standardorganisasjonen sjølv om
scenarioet hadde valt ei anna. Produksjonsåtferda er uendra; testbane brukar no
same lagra organisasjonsnummer som ordinær runtime.

[AAREG_AltinnScenarioJourneyTest](../../../force-app/tests/classes/externalAccess/AAREG_AltinnScenarioJourneyTest.cls)
køyrer offentlege controller-metodar som syntetisk community-brukar. Testane
verifiserer organisasjonsrespons frå S01, søknads-Permit, reell
ressursavhengig S02-fallback til brukerstøtte, rein S03-Deny utan nye delingar,
S07-responsfeil utan tilgang og null callouts. Den eksisterande
[HomeController-testen](../../../force-app/externalAccess/classes/AAREG_HomeControllerTest.cls)
og [CommunityUtils-testen](../../../force-app/externalAccess/classes/AAREG_CommunityUtilsTest.cls)
verifiserer ordinær bane og eksisterande delingslogikk.

Raud køyring før wiring gav fire feil fordi standard Altinn 3 vart vald utan
integrasjonsoppsett. Etter wiring var dei fem journey-testane grøne. Den første
focused dry-run vart likevel avvist av 75 %-dekningsgaten fordi han berre køyrde
journey-klassa. Samla dry-run `0AfJW00000nmxsn0AA` gav **80/80 testar,
checkOnly=true, utan feil eller dekningsvarsel**. Dekning: HomeController
106/106, CommunityUtils 10/10, provider 54/54, factory 7/7, policy 34/34 og
repository 116/117 køyrbare linjer.

Den dåverande `crm-arbeidsforhold`-scratch-org-en hadde berre High Volume
Customer Portal-profilar for eksterne testbrukarar; ingen rollebasert Customer
Community Plus/Partner-profil var tilgjengeleg. Journey-testen beviste difor
tilgangsavgjerda, ikkje at ei
`Agreement__Share`-rad kan opprettast for denne lisensen. Eksisterande
delingsregresjonar køyrde grønt for ordinær testbrukar. Positive scenario-delings-
åtferd med den faktiske lisensen må avklarast/verifiserast separat før ein
hevdar full community-delingsjourney.

Det første oppsettet i den separate `nav-community-dev`-scratch-org-en hadde
éin aktiv Customer Community Plus-brukar for S01 og fire High Volume-brukarar.
Nettlesarøkta stadfesta seinare positiv avtalevising for C og D med Plus-
brukaren. Oppsettet er no samla rundt éin generisk Plus-brukar; sjå gjeldande
oppsett ovanfor, [testguiden](./test-guide.md) og [testloggen](./altinn-test-log.md).

D01 er valt som A: dynamisk oppfrisking. Den lokale UI-endringa og Jest-
verifikasjonen er dokumenterte i neste avsnitt; dette Apex-dry-run-beviset er
ikkje ein ende-til-ende nettlesartest. Regresjonen vart køyrd på nytt etter
UI-arbeidet: `0AfJW00000nmxsn0AA`, 80/80 testar og null feil. Ingen permanent
deploy eller scenarioaktivering er utført.

Eksakt samla kommando, siste validering `0AfJW00000nmxsn0AA`:

```sh
sf project deploy start --dry-run \
  --source-dir force-app/integration/altinn \
  --source-dir force-app/externalAccess/classes/AAREG_HomeController.cls \
  --source-dir force-app/externalAccess/classes/AAREG_CommunityUtils.cls \
  --source-dir force-app/externalAccess/classes/AAREG_HomeControllerTest.cls \
  --source-dir force-app/tests/classes/externalAccess/AAREG_AltinnScenarioJourneyTest.cls \
  --source-dir force-app/tests/classes/integration/altinn \
  --source-dir force-app/tests/classes/integration/common/Integration_TestDataFactory.cls \
  --source-dir force-app/utility/classes/AAREG_TestDataFactory.cls \
  --target-org crm-arbeidsforhold \
  --test-level RunSpecifiedTests \
  --tests AAREG_AltinnScenarioJourneyTest \
  --tests AAREG_HomeControllerTest \
  --tests AAREG_CommunityUtilsTest \
  --tests AAREG_AltinnServiceFactoryTest \
  --tests AAREG_AltinnScenarioProviderTest \
  --tests AAREG_AltinnScenarioPolicyTest \
  --tests AAREG_AltinnScenarioRepositoryTest \
  --wait 10 --json
```

## Kjeldegrunnlag og avgrensing

Lesne lokale kjelder:

- [AltinnCalloutService](../../../crm-platform-integration/main/default/classes/AltinnCalloutService.cls)
  held ein privat provider og opprettar standardimplementasjonen i standardkonstruktøren.
  Referansekjelda har no òg den additive konstruktøren for provider-injeksjon;
  faktisk konsumentåtkomst i installert 0.177.0.4 er verifisert ovanfor.
- [IAltinnCalloutService](../../../crm-platform-integration/main/default/classes/IAltinnCalloutService.cls)
  har to operasjonar med `Object` som returtype.
- [AAREG_HomeController](../../../force-app/externalAccess/classes/AAREG_HomeController.cls)
  opprettar fasaden ved organisasjonsoppslag. Rettssjekken kan opprette delingar.
- [AAREG_CommunityUtils](../../../force-app/externalAccess/classes/AAREG_CommunityUtils.cls)
  opprettar fasaden ved rettsoppslag.
- [aareg_home](../../../force-app/externalAccess/lwc/aareg_home/aareg_home.js)
  hentar organisasjonar med `@wire`/`refreshApex` og sjekkar rettar i separate
  kall.

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

## Dynamisk oppfrisking av organisasjonar — D01/A

Brukaren valde alternativ A. `aareg_home` hentar organisasjonar gjennom `@wire`
og `refreshApex`, slik at handlinga ber Salesforce om ei fersk cacheable
Apex-respons. Ho nullstiller gammal tilgang før oppfrisking, brukar eksisterande
organisasjonsfiltrering, validerer lagra val på nytt og sjekkar rettar berre når
organisasjonen framleis er tilgjengeleg. Feil held tilgangen av og viser ei
brukarmelding; overlappande oppfriskingskall blir avviste.

Den fokuserte LWC-testen verifiserer ny organisasjon i lista, rettssjekk på nytt,
filtrert bortfall av valt organisasjon, feil, overlappande handling og feil i
første organisasjonsoppslag. `npm run test:unit -- -- --runInBand
force-app/externalAccess/lwc/aareg_home/__tests__/aareg_home.test.js` gav
5/5 grøne testar. Heile LWC-suiten med
`npm run test:unit -- -- --runInBand` gav 6/6 suites og 15/15 testar.
`sf project deploy preview --source-dir force-app --target-org crm-arbeidsforhold`
melde ingen konfliktar og at 497 metadatafiler ville bli med i ein deploy;
det var berre ein preview. Etter eksplisitt godkjenning vart dei avgrensa
Altinn-/LWC-endringane deployerte til scratch-org `crm-arbeidsforhold`:
`0AfJW00000nmyDl0AI`, `Succeeded`, 60 komponentar og 80/80 Apex-testar.
Dette var ikkje produksjon eller ein varig deploy.

Eit tidlegare målretta oppslag i `crm-arbeidsforhold` fann ingen eksisterande
syntetisk community-testbrukar. Scenario var derfor ikkje aktivert, og
ende-til-ende nettlesar-/delingsreise var ikkje utført. Ho krev ein syntetisk ekstern brukar som kan autentiserast i
nettlesaren; ingen innloggingsopplysningar er oppretta, etterspurde eller
handterte her. Positiv delingsverifikasjon for High Volume Customer Portal-
lisensen var ikkje stadfesta i denne historiske køyringa. Seinare Plus-
nettlesartest i `nav-community-dev` stadfesta avtalar for C og D; rettingane
frå den siste testøkta krev ny nettlesartest.

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

**Valstatus:** Brukaren valde A. T015–T016 er implementerte og lokalt
Jest-verifiserte. Alternativ B er ikkje valt. Lokal LWC-verifikasjon er ikkje
det same som ende-til-ende UI- eller community-delingsverifikasjon.

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
