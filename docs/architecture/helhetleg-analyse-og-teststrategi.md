# Helhetleg analyse av Arbeidsforhold og Aa-registeret

## Føremål og evidensgrenser

Dette dokumentet samlar den noverande forståinga av produktflytane, Salesforce-pakkane, metadataoversikta frå scratch-org-en og ein praktisk strategi for syntetiske testdata og scenario. Det er eit tillegg til, ikkje ei omskriving av, [oversikta over heile løysinga](./hele-loysinga.md), [pakkeoversikta](./pakkeavhengigheiter.md) og dei meir detaljerte [P360-flytdokumenta](../integrations/p360/kartlegging-av-dagens-flytar.md).

**Evidensdato:** 2026-11-13. Org-observasjonane kjem frå lesande metadata- og pakkeinventering av den godkjende scratch-org-en. Ingen forretningsrecordar, autentiseringsdata eller hemmelege verdiar vart lesne. Ingen deploy eller live-kall mot Altinn eller P360 vart utførte.

Skil mellom:

1. **Kjeldebevis:** metadata, Apex, LWC, Flow og testar i arbeidskopien.
2. **Orgbevis:** komponentar og pakkeversjonar som metadata-API-et rapporterte i scratch-org-en.
3. **Testbevis:** automatiserte testar som er køyrde eller dokumenterte; desse beviser ikkje i seg sjølve live-integrasjon.
4. **Forslag:** scenario og testdata som bør leggjast til eller gjerast meir systematiske.

Metadata-listing viser at komponentar finst, ikkje at ein Flow-versjon er aktiv, at ei permission set er tildelt, eller at ei integrasjonskopling fungerer. Denne gjennomgangen er difor ikkje ein full runtime- eller tilgangsrevisjon.

## Samandrag

- Hovudproduktet er Salesforce-pakka `crm-arbeidsforhold`, med Experience Cloud-flater for eksterne verksemder og interne flater for saksbehandling, avgjerder og oppfølging.
- Domenet omfattar søknader om tilgang/registrering, behandling og avgjerder, avtalar og delingstilgang, dialog/støtte, filer og integrasjonar. Altinn avgjer eksterne rettar; P360 er dokument-/arkivgrensa.
- Løysinga er Salesforce-sentrisk og kombinerer Apex, LWC, Flow, metadata og 19 separat eigde avhengnadspakkar. `src-temp` er ei synkroniseringsmappe, ikkje ei ekstra avhengnadspakke.
- Org-inventeringa fann alle 19 avhengnadspakkane, 110 Flow-metadataoppføringar og 61 PermissionSet-metadataoppføringar. Talla inkluderer komponentar frå installerte pakkar og er ikkje ei oppteljing av aktive produktflytar eller faktiske tildelingar.
- P360-testserien har eit dokumentert resultat på 98 beståtte testar. Dette er bevis på stubba/teststyrt åtferd, ikkje på at P360 oppretta ei sak eller eit dokument.
- Testgrunnlaget bør byggjast rundt isolerte, syntetiske organisasjonar, brukarar, søknader, avtalar, meldingar og filer. Integrasjonar skal vere mocka i automatiserte testar; ikkje bruk ekte persondata eller eksterne tenester som del av vanlege einingstestar.

## Produkt- og domeneforståing

### Aktørar og arbeidsflater

| Aktør                                        | Arbeidsflate                              | Hovudoppgåve                                                                                                       |
| -------------------------------------------- | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Ekstern brukar som representerer ei verksemd | Experience Cloud / eksterne LWC-flater    | Vel verksemd, søkjer om tilgang eller registrering, følgjer status, leverer dokumentasjon og kommuniserer med Nav. |
| Intern saksbehandlar                         | Salesforce interne flater og Flow         | Behandlar søknader, ber om meir informasjon, vurderer grunnlag og registrerer avgjerd.                             |
| Intern støtte-/dialogbrukar                  | Dialog- og henvendelsesflater             | Følgjer opp spørsmål, trådar, meldingar, vedlegg og varsling.                                                      |
| Bakgrunnsprosess                             | Apex, Flow, køyringar og planlagde jobbar | Behandlar deling/tilgang, dokumenthandtering, varsling og arkiveringsjobbar.                                       |
| Eksterne tenester                            | Altinn, P360 og andre integrasjonar       | Leverer autorisasjons- eller arkivfunksjonar gjennom eigne integrasjonsgrenser.                                    |

### Sentrale domenefamiliar

| Domenefamilie                | Salesforce-objekt/komponentar som er synlege i kjelde eller org-inventering          | Rolle i arbeidsflyten                                                                   |
| ---------------------------- | ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------- |
| Ekstern søknad og tilgang    | `Application__c`, `Access_Request__c`, detalj-/grunnlags- og kontaktmetadata         | Held på søknadsinnhald, verksemdsval, kontaktar og grunnlag for behandling.             |
| Intern behandling og avgjerd | Søknads-, avgjerds- og avgjerdsgrunnlagskomponentar, interne LWC/Flow                | Saksbehandling, statusovergangar, avgjerd og oppfølging.                                |
| Avtale og deling             | `Agreement__c` og tilgangs-/organisasjonsrelaterte komponentar                       | Representerer avtalevilkår og tilgang som skal delast, endrast eller trekkjast tilbake. |
| Dialog og støtte             | Henvendelse-, tråd-, melding- og varslingskomponentar frå hovud- og avhengnadspakkar | Kommunikasjon mellom ekstern brukar og interne team, inkludert vedlegg og varsling.     |
| Integrasjon og arkivering    | Altinn-integrasjon, P360-arkiveringsjobbar, kodeverk og innstillingar                | Hentar autorisasjonsgrunnlag eller sender dokument vidare på ein kontrollert måte.      |
| Referanse- og driftsdata     | Custom Metadata, Custom Permission, feature toggle og konfigurasjon                  | Styrer kodeverk, avgrensa funksjonar og tilgang til særskilde handlingar.               |

Objektnamna over er identifikatorar, ikkje ei full datamodell. For relasjonar, eigarskap og prosessdetaljar, sjå [arkitekturoversikta](./hele-loysinga.md). Verifiser alltid relasjonar mot metadata før dei blir brukte i ein ny test eller migrering.

### Samla forretningsflyt

1. Ekstern brukar identifiserer seg og vel ei verksemd.
2. Tilgangsgrunnlaget blir vurdert gjennom Altinn-integrasjonen. Den lokale scenariokatalogen er eit testverktøy, ikkje Altinn-fasit.
3. Brukaren opprettar eller oppdaterer ei søknad og legg ved relevant dokumentasjon.
4. Interne brukarar behandlar søknaden, kan be om meir informasjon og registrerer ei avgjerd.
5. Når avgjerda krev det, blir avtale- og distribusjonstilgang oppretta eller endra.
6. Dialog, varsling og dokumenthandtering følgjer prosessen. P360 er ei eiga arkivgrense og må verifiserast separat frå lokal Salesforce-status.

Dette er ein konseptuell samanheng, ikkje ei påstand om at alle steg alltid er synkrone eller at kvar statusovergang er ende-til-ende-verifisert. Den meir detaljerte arbeidsflyt- og sekvensoversikta ligg i [business-workflows.md](../../.github/modernize/assessment/engines/facts/business-workflows.md).

## Hovudpakke og avhengnader

Hovudkjelda ligg i `force-app/`. Manifestet oppgir hovudpakka som `crm-arbeidsforhold` versjon `0.316.0.NEXT` og 19 separat eigde avhengnader. Avhengnadsmappene er referansekjelder og skal ikkje endrast utan uttrykkeleg godkjenning.

| Avhengnad                       | Installert i scratch-org | Hovudrolle                                          |
| ------------------------------- | -----------------------: | --------------------------------------------------- |
| `crm-platform-email-scheduling` |                  1.8.0.2 | Planlegging og utsending av e-post.                 |
| `crm-shared-timeline`           |                 1.45.0.3 | Delt tidslinjevising.                               |
| `crm-henvendelse`               |                0.209.0.2 | Henvendelses- og dialogfunksjonalitet.              |
| `crm-journal-utilities`         |                 0.55.0.1 | Journal- og dokumenthjelparar.                      |
| `crm-platform-oppgave`          |                 0.84.0.1 | Oppgåvefunksjonalitet.                              |
| `crm-shared-user-notification`  |                 0.27.0.2 | Delte brukarvarsel.                                 |
| `crm-shared-flowComponents`     |                  0.4.0.3 | Gjenbrukbare Flow-komponentar.                      |
| `crm-platform-access-control`   |                0.179.0.1 | Tilgangs- og delingsmønster.                        |
| `crm-platform-base`             |                0.311.0.1 | Felles Salesforce-plattformfunksjonar og hjelparar. |
| `crm-platform-integration`      |                0.177.0.4 | Integrasjonsinfrastruktur og delte klientar.        |
| `crm-platform-reporting`        |                 0.47.0.2 | Rapportering.                                       |
| `crm-community-base`            |                0.146.0.1 | Felles Community-/Experience Cloud-funksjonar.      |
| `crm-henvendelse-base`          |                 0.42.0.1 | Grunnlag for henvendelses- og tråddomene.           |
| `crm-thread-view`               |                  0.8.0.1 | Delt trådvising.                                    |
| `platform-data-model`           |                 0.1.49.3 | Delt datamodell og plattformmetadata.               |
| `custom-metadata-dao`           |                 0.1.49.3 | Tilgang til Custom Metadata.                        |
| `feature-toggle`                |                 0.1.50.3 | Feature toggles.                                    |
| `custom-permission-helper`      |                 0.1.49.3 | Hjelparar for Custom Permission.                    |
| `record-type-cache`             |                 0.1.17.3 | Oppslag/cache for record types.                     |

Org-versjonane er eit øyeblikksbilete. Eit eldre pakkeoversyn oppgir `crm-platform-integration` 0.176.0.1, medan manifestet krev 0.177.0.LATEST og org-inventeringa fann 0.177.0.4. Bruk manifest og fersk org-inventering som kjelder for nye samanlikningar, ikkje det daterte oversynet åleine.

## Scratch-org: kva inventeringa viser

Den lesande inventeringa rapporterte:

- 19 installerte avhengnadspakkar.
- 382 komponentar av metadata-typen `CustomObject`; 50 namn enda på `__c` og 36 på `__mdt`. Dette inkluderer komponentar frå pakker og er ikkje lik talet på eigne forretningsobjekt.
- 110 Flow-metadataoppføringar.
- 61 PermissionSet-metadataoppføringar.
- Produktrelevante metadata finst, mellom anna Altinn-/P360-relaterte Custom Permissions og saksbehandlings-/støttepermission sets.

Dette stadfestar metadata-nærvær, ikkje aktive Flow-versjonar, brukartildelingar, effektiv tilgang, konfigurasjonsverdiar eller live integrasjonsresultat. Ingen organisasjonsrecordar vart lesne. Namn og verdiar frå Named Credentials, autentisering, brukarkontoar eller persondata inngår ikkje i denne rapporten.

## Teststatus og evidens

| Område                           | Kjent testbevis                                                                                                                                                                                                                                                                                                                                                                          | Avgrensing                                                                                                                              |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| P360                             | Den namngjevne `P360` Apex-testserien rapporterte 98 beståtte, 0 feila og 0 hoppa over. Serien er definert i [P360.testSuite-meta.xml](../../force-app/tests/testSuites/P360.testSuite-meta.xml).                                                                                                                                                                                        | Testane nyttar testgrenser/mocks. Resultatet beviser ikkje P360-oppretting av sak eller dokument i ei ekstern teneste.                  |
| Altinn-scenariopolicy og katalog | [Altinn-dokumentasjonen](../integrations/altinn/README.md) skildrar test av syntetiske scenario, avgrensa tilgang og feilstiar. Ho dokumenterer ei tidlegare 15/15-validering med 34/34 køyrbare policylinjer dekte.                                                                                                                                                                     | Historisk dokumentert validering, ikkje køyrd på nytt som del av denne analysen. Scenario er ikkje live Altinn-kontraktstest.           |
| Testdatafabrikkar                | Eksisterande byggesteinar omfattar [AAREG_AltinnTestDataFactory.cls](../../force-app/tests/classes/integration/altinn/AAREG_AltinnTestDataFactory.cls), [Integration_TestDataFactory.cls](../../force-app/tests/classes/integration/common/Integration_TestDataFactory.cls) og [P360_TestDataFactory.cls](../../force-app/tests/classes/integration/p360/test/P360_TestDataFactory.cls). | Fabrikkane dekkjer ikkje åleine alle domene, tilgangskombinasjonar eller integrasjonsfeil.                                              |
| LWC/Jest                         | Repoet har lokal Jest-validering for LWC.                                                                                                                                                                                                                                                                                                                                                | Ingen LWC-test blei køyrd i denne analyseoppgåva. Lokal Node-versjon observert var 22.20.0; repoet krev minst 22.22.1 for npm-verktøya. |

## Testdataprinsipp

1. **Berre syntetiske data.** Bruk tydeleg fiktive brukarar, verksemder, kontaktar, organisasjonsnummer og meldingstekstar. Ikkje kopier recordar frå org, e-postar, identifikatorar eller vedlegg frå verkelege brukarar.
2. **Ingen eksterne kall i vanlege automatiserte testar.** Bruk `HttpCalloutMock` eller eksisterande test-seam for Altinn, tilgangsdistribusjon, P360 og andre kall. Ein mock testar vår kontraktsbruk, ikkje motparten.
3. **Små, eksplisitte fixture-grafar.** Lag berre dei relasjonane scenariet treng: syntetisk organisasjon → kontakt → brukar → søknad/avtale → vedlegg. Unngå éin stor fabrikk som set alle felt for alle scenario.
4. **Minste tilgang først.** Bruk minimumstilgangsbrukar og `System.runAs` når åtferda ikkje treng administratorrettar. Opprett fixtures med nødvendig privilegium, men køyr operasjonen som aktøren som skal verifiserast.
5. **Isoler identitet og verksemd.** Test at resultat for éin brukar/verksemd ikkje lekk til ein annan. Inkluder brukar utan kontakt-/kontoidentitet, brukar med feil verksemd, og fleire verksemder med ulikt rettsutfall.
6. **Filer er syntetiske.** Opprett små deterministiske `ContentVersion`-blobbar og verifiser koplinga til rett record. Test manglande fil, fleire filer, duplikat/ugyldig metadata og feil ved arkivering utan å bruke verkelege dokument.
7. **Kontroller sideeffektar.** Verifiser oppretta/endra recordar, deling, status, kø-/arkivjobb, varsel og feillogg. «Kasta ikkje feil» er ikkje tilstrekkeleg.
8. **Ikkje stol på avleia verdiar.** Opprett recordar gjennom den relevante DML-/Flow-bana når trigger, formula eller Flow set status. Test både før og etter transaksjonsgrensa der det er relevant.
9. **Feature flags og scenario er eksplisitte.** Ha testar for av, på, manglande konfigurasjon og feil konfigurasjon. Testscenario skal vere merkt som syntetiske og må ikkje kunne falle tilbake til live-data.
10. **Ingen `SeeAllData=true` som standard.** Bruk repoets fabrikkar og Custom Metadata-mønster. Dersom ein plattformavhengig test krev standardmetadata, dokumenter kvifor og avgrens lesinga.

## Scenario-katalog

Prioritet: **P1** = kritisk for korrekt tilgang eller hovudflyt, **P2** = viktige feilstiar og robustheit, **P3** = drift/administrasjon og ekstra kombinasjonar.

| ID / prioritet | Domene            | Syntetisk oppsett og handling                                                                      | Forventa observasjon                                                                                                               |
| -------------- | ----------------- | -------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| APP-01 / P1    | Ekstern søknad    | Verksemd med godkjent tilgang opprettar og lagrar eit utkast.                                      | Rett eigar/verksemd, gyldig status og berre éi søknadseining etter gjenteken lagring.                                              |
| APP-02 / P1    | Ekstern søknad    | Komplett søknad blir sendt inn med nødvendige kontaktar og syntetiske vedlegg.                     | Søknaden går til innsendt tilstand, vedlegga er kopla til rett søknad og interne oppgåver oppstår som venta.                       |
| APP-03 / P1    | Ekstern søknad    | Påkravd opplysning eller dokument manglar.                                                         | Innsending blir stoppa med forståeleg validering; ingen delvis innsendt record eller uønskt sideeffekt.                            |
| APP-04 / P2    | Ekstern søknad    | Saksbehandlar ber om meir informasjon; ekstern brukar svarar og sender inn på nytt.                | Status og historikk blir konsistente, og berre relevant sak/verksemd kan svare.                                                    |
| APP-05 / P2    | Ekstern søknad    | Brukar prøver å opne eller endre ein annan verksemds søknad.                                       | Ingen data eller vedlegg blir eksponerte eller endra.                                                                              |
| ALT-01 / P1    | Altinn-tilgang    | Syntetisk brukar får Permit for søknadsressurs og vel ei godkjend verksemd.                        | Verksemda blir tilgjengeleg for den brukaren, utan å gje breiare tilgang enn regelen tilseier.                                     |
| ALT-02 / P1    | Altinn-tilgang    | Brukar får eksplisitt Deny.                                                                        | Søknads-/delingshandling blir avvist; ingen ny tilgang blir oppretta.                                                              |
| ALT-03 / P1    | Altinn-tilgang    | Brukar får Permit for støtte, men Deny for søknad, og motsett.                                     | Ressursane blir vurderte uavhengig; éin rett gir ikkje implisitt den andre.                                                        |
| ALT-04 / P1    | Altinn-tilgang    | Brukar har fleire verksemder med ulike rettar og skiftar valt verksemd.                            | Rett matrise følgjer vald verksemd; ingen stale tilgang frå førre val blir brukt.                                                  |
| ALT-05 / P2    | Altinn-tilgang    | Vellukka tom organisasjonsliste.                                                                   | Tomtilstand blir vist/handtert; ikkje forveksla med transportfeil eller Permit.                                                    |
| ALT-06 / P1    | Altinn-tilgang    | Manglande kontaktidentitet, manglande permission eller feil brukarsetting.                         | Eksplisitt avvising; ingen live-fallback og ingen tilgang på vegner av ein annan brukar.                                           |
| ALT-07 / P2    | Altinn-tilgang    | Mock svarar med response error, exception, tomt svar eller ugyldig struktur.                       | Feil blir skild frå eksplisitt Deny; ingen feil blir normalisert til Permit.                                                       |
| ALT-08 / P2    | Altinn-tilgang    | Tidlegare deling finst, men ny sjekk gir Deny.                                                     | Ny deling blir ikkje oppretta; eksisterande deling blir handtert etter eksplisitt revokeringsregel, ikkje stillteiande.            |
| CASE-01 / P1   | Intern behandling | Saksbehandlar tek eigarskap, vurderer søknad og registrerer avgjerd med syntetisk grunnlag.        | Status, eigarskap, avgjerd og grunnlag heng saman og er synlege for rett rolle.                                                    |
| CASE-02 / P1   | Intern behandling | Manglande eller ugyldig avgjerdsgrunnlag.                                                          | Avgjerda blir stoppa eller markert som ufullstendig etter gjeldande regel; ikkje falsk fullføring.                                 |
| CASE-03 / P2   | Intern behandling | Meir enn éin grunnlagskode eller organisasjonsform blir behandla.                                  | Alle gyldige kombinasjonar blir lagra; ugyldige kombinasjonar blir avviste utan delvis oppdatering.                                |
| CASE-04 / P1   | Intern behandling | Brukar utan saksbehandlingstilgang prøver å lese eller endre saka.                                 | Tilgang blir avvist på server-/delingsnivå, ikkje berre skjult i UI.                                                               |
| AGR-01 / P1    | Avtale og deling  | Godkjend avgjerd opprettar eller aktiverer avtale for syntetisk verksemd.                          | Avtale og tilhøyrande tilgang svarar til avgjerda og kan ikkje dupliserast ved retry.                                              |
| AGR-02 / P1    | Avtale og deling  | Avtale blir endra, avslutta eller trekt tilbake.                                                   | Oppdatert tilgang og Salesforce-status er konsistente; tidlegare verksemd får ikkje utilsikta ny tilgang.                          |
| AGR-03 / P2    | Avtale og deling  | Distribusjonskall gir 2xx, ikkje-2xx, timeout eller exception.                                     | Suksess og feil blir logga/representerte korrekt; test dokumenterer dagens manglande retry/kompensasjon dersom det framleis gjeld. |
| AGR-04 / P2    | Avtale og deling  | Same tilgangsoppdatering blir sendt to gonger eller i parallell.                                   | Idempotent resultat; ingen doble delingar eller motstridande status.                                                               |
| DLG-01 / P1    | Dialog og støtte  | Ekstern brukar opprettar henvendelse med syntetisk melding.                                        | Riktig verksemd/brukar-eigarskap, tråd og intern oppgåve/varsling blir oppretta.                                                   |
| DLG-02 / P1    | Dialog og støtte  | Intern og ekstern part svarar i same tråd.                                                         | Meldingar er synlege for rett part; person-/verksemdsgrenser blir haldne.                                                          |
| DLG-03 / P2    | Dialog og støtte  | Melding har syntetisk vedlegg, ugyldig fil eller manglande tilgang.                                | Gyldig fil blir kopla til rett melding; ugyldig/uautorisert fil blir avvist utan lekkasje.                                         |
| DLG-04 / P2    | Dialog og støtte  | Varsling feilar eller blir køyrd fleire gonger.                                                    | Feil er synleg og retry gir ikkje duplikatmelding eller duplikatvarsling utover avtalt åtferd.                                     |
| P360-01 / P1   | P360              | Arkiveringsjobb får gyldig søknad/avgjerd og syntetisk fil.                                        | Jobb får venta status og komplett payload; testverifiserer grensa mot mock, ikkje live P360.                                       |
| P360-02 / P1   | P360              | Nødvendig arkivmetadata eller vedlegg manglar.                                                     | Jobben blir stoppa med sporbar feil; ingen suksessforma status.                                                                    |
| P360-03 / P1   | P360              | Feature flag eller release-permission er av/manglar.                                               | Arkivering blir blokkert; ingen RPC-callout blir forsøkt.                                                                          |
| P360-04 / P2   | P360              | Worker køyrer på nytt etter success, timeout eller retryable error.                                | Idempotency-nøkkel, forsøkstal og sluttstatus er konsistente; ingen dobbeltarkivering.                                             |
| P360-05 / P2   | P360              | To jobbar konkurrerer om same kjeldedokument.                                                      | Éin kontrollert jobb vinn/tek eigarskap; låsing/duplikatvern gir ikkje tap eller dobbeltutsending.                                 |
| P360-06 / P1   | P360              | Søknad, avgjerd, avtale og kvar dokumenttype går gjennom arkivløypa.                               | Riktig arkivtype og tilhøyrande fil blir brukt for kvar støtta kjelde.                                                             |
| FILE-01 / P1   | Filer             | Fil blir lasta opp, lenka, opna og arkivert.                                                       | Same dokument er kopla til rett foreldre-record gjennom heile prosessen.                                                           |
| FILE-02 / P2   | Filer             | Fleire filer, manglande lenke, ugyldig filmetadata eller duplikat.                                 | Feil blir handtert eksplisitt; ingen stille bortfall eller feilkopling.                                                            |
| ASYNC-01 / P2  | Køyring og bulk   | Fleire søknader/avtalar blir oppdaterte i same transaksjon.                                        | Trigger/Flow/Apex er bulk-trygg; ingen governor-feil eller krysskopling av data.                                                   |
| ASYNC-02 / P2  | Køyring og bulk   | Asynkron jobb feilar og blir køyrd på nytt.                                                        | Status, feilmelding og forsøkstal er sporbare; retry er avgrensa og idempotent.                                                    |
| CFG-01 / P3    | Konfigurasjon     | Feature toggle, scenario-setting eller Custom Permission er av, på, manglande eller feilformatert. | Trygg standard og eksplisitt feilåtferd; ikkje utilsikta live-fallback.                                                            |

## Lagdelt valideringsstrategi

1. **Apex-einingstestar:** forretningsregel, validering, mapping og statusovergang med små fixture-grafar.
2. **Apex-transaksjons-/integrasjonstestar:** DML, trigger/Flow-samspel, sharing, asynkron oppførsel og `HttpCalloutMock`.
3. **LWC/Jest:** brukarhandlingar, valideringsvising, tom-/feiltilstandar og klientinteraksjonar. Bruk mocka Apex-/child-komponentar der dette er etablert mønster.
4. **Scratch-org verifikasjon:** berre når ein test krev faktisk plattform-/metadataoppførsel; bruk godkjend ikkje-produksjonsmål og avklar org-handling på nytt etter repo-reglane.
5. **Ekstern ende-til-ende:** eigne, eksplisitt godkjende ikkje-produksjonsintegrasjonstestar med syntetiske data. Ikkje bland desse med vanleg unit-test-suite.

Køyr først den minste relevante testen. For Apex er org-køyring org-avhengig; rapporter kommando, mål og faktisk resultat. For P360 må resultatet skilje mellom mocka transport og verifisert ekstern arkivering.

## Viktigaste gap og oppfølging

1. Utvid scenariodekninga for verksemdsmatching, identitetsbinding, manglande kontakt, fleire verksemder og ulike Altinn-ressursar.
2. Test tilgangsdeling som eiga livssyklus: opprett, gjenteken oppretting, endring, tilbakekalling, feila distribusjon og retry.
3. Kople forretningsscenario saman på tvers av søknad → intern avgjerd → avtale/deling → dialog/vedlegg → arkivering.
4. Dekk feilsvar og robustheit for alle integrasjonar, særleg timeout, response error, ugyldig payload, auth-feil og dupliserte asynkrone forsøk.
5. Gjer P360-testnamn/resultat tydelege på om dei verifiserer jobbmodell, payload, mocka RPC eller faktisk ikkje-produksjonsarkivering.
6. Gjer ein separat runtime-verifikasjon av aktive Flow-versjonar, permission assignments, feature-toggle-verdiar og Named Credential-koplingar dersom dette trengst. Ikkje utlei dei frå metadata-nærvær.
7. Oppdater eller merk eldre org-spesifikke testdokument når målorg eller testoppsett endrar seg; historiske resultat bør ikkje presenterast som fersk status.

## Relaterte kjelder

- [Heile løysinga](./hele-loysinga.md)
- [Pakkeavhengnader](./pakkeavhengigheiter.md)
- [Dagens P360-flytar](../integrations/p360/kartlegging-av-dagens-flytar.md)
- [P360 historisk testlogg](../integrations/p360/test-log.md)
- [Altinn-integrasjon og scenariokatalog](../integrations/altinn/README.md)
- [Hovudpakke og avhengnader](../../sfdx-project.json)
- [Altinn testdatafabrikk](../../force-app/tests/classes/integration/altinn/AAREG_AltinnTestDataFactory.cls)
- [Felles integrasjonstestdatafabrikk](../../force-app/tests/classes/integration/common/Integration_TestDataFactory.cls)
- [P360 testdatafabrikk](../../force-app/tests/classes/integration/p360/test/P360_TestDataFactory.cls)
