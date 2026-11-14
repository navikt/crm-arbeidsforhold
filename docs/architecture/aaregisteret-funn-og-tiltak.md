# Funn og tiltak for Arbeidsforhold / Aa-registeret

**Status:** kjeldebasert arbeidsregister, 2026-11-14. Dette er ikkje
produksjonsklar risikovurdering eller sign-off. Prioritet er rekkjefølgje for
avklaring og verifikasjon, ikkje ein stadfesta feilgrad.

Registeret samlar funn frå kjelde, tidlegare avgrensa org-oppslag og
testplanlegging. Det skil mellom dokumenterte gap og testmål som ikkje er
stadfesta som feil. Eksisterande produktkode, metadata, dokumenttekst og org
er ikkje endra som del av registeret.

## Evidensstatus

- **Kjelde:** lokalt undersøkt kode eller metadata; ikkje eit runtime-resultat.
- **Historisk org:** datert tidlegare oppslag; gjeld ikkje automatisk no.
- **Produktkrav:** brukaravklart ønskt åtferd; ikkje implementasjon eller
  ekstern kontraktsakseptanse.
- **NOT RUN / OPEN:** test eller avgjerd står att.

## Prioriterte funn

### P360-F01 — Innsending garanterer ikkje arkiveringsgrunnlag for alle vedlegg

- **Prioritet / status:** P1 før P360-akseptanse; kjeldegap mot avklart
  produktkrav.
- **Evidens:** produktkravet er arkivering ved innsending med søknaden og
  alle vedlegg, også frå utkast. Den undersøkte controller-bana lagar fil
  og `ContentDocumentLink` i eigne steg; P360-handleren krev direkte
  `FirstPublishLocationId`, og controlleren har ikkje ei funnen automatisk
  `ApplicationDocument`-jobbtilknyting. Sjå
  [inngangs- og verifikasjonsplanen](../integrations/p360/inngangar-og-verifikasjonsplan.md).
- **Påverknad:** synleg fil eller portal-kvittering beviser ikkje at ein
  P360-jobb vart oppretta, og utkastvedlegg kan falle utanfor den undersøkte
  handlerinngangen.
- **Neste steg / avgjerd:** stadfest støtta innsendingsevent,
  filversjonsutval, representasjon av dokumentsett og testisolering før
  implementasjon eller manuell test.
- **Sporing:** [#1095](https://github.com/navikt/crm-arbeidsforhold/issues/1095),
  [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016),
  [#1018](https://github.com/navikt/crm-arbeidsforhold/issues/1018),
  [#1181](https://github.com/navikt/crm-arbeidsforhold/issues/1181).

### P360-F02 — Retry og ny innsending har ikkje separate identitetar

- **Prioritet / status:** P1; kjeldeverifisert modellgap mot
  produktkravet om eit komplett nytt sett ved ny innsending.
- **Evidens:** `ApplicationDocument`-nøkkel er basert på søknads-ID og
  vedleggsnøkkel på søknads-ID + `ContentVersion`-ID. Same søknad og
  uendra filversjon får same nøkkel ved ei ny innsending; jobbservicen
  gjenbrukar då eksisterande jobb. Detaljar og kjeldepeikarar står i
  [P360-verifikasjonsplanen](../integrations/p360/inngangar-og-verifikasjonsplan.md).
- **Påverknad:** dagens nøkkelmodell skil ikkje i seg sjølv retry av same
  innsending frå eit nytt komplett dokumentsett.
- **Neste steg / avgjerd:** avklar stabil innsendingsidentitet,
  ekstern deduplisering, mapping og recovery samla. Ikkje generer tilfeldig
  ny nøkkel per retry eller vel migrering utan kontraktsavgjerd.
- **Sporing:** [#1015](https://github.com/navikt/crm-arbeidsforhold/issues/1015),
  [#1016](https://github.com/navikt/crm-arbeidsforhold/issues/1016),
  [#1018](https://github.com/navikt/crm-arbeidsforhold/issues/1018),
  [#1181](https://github.com/navikt/crm-arbeidsforhold/issues/1181).

### P360-F03 — Ekte transport og referanselagring er ikkje implementert

- **Prioritet / status:** P1 før ende-til-ende-akseptanse; kjeldeverifisert
  avgrensing.
- **Evidens:** den lokale stub-adapteren kan rapportere kontrollert suksess,
  medan undersøkte reell adapter/RPC-klient stoppar før implementert
  transport. Worker sender idempotensnøkkel som ekstern ID, men den
  undersøkte banen lagrar ikkje returnerte P360-saks-, dokument- og
  filreferansar på domenerecordane. Sjå
  [P360-kartlegginga](../integrations/p360/inngangar-og-verifikasjonsplan.md)
  og [P360-roadmapen](https://github.com/navikt/crm-arbeidsforhold/issues/1095).
- **Påverknad:** DTO- og mock-testar beviser ikkje ekstern arkivering,
  responslagring eller recovery etter timeout.
- **Neste steg / avgjerd:** P360-/integrasjonseigarar må avklare transport,
  autentisering, payload, svar, persistens og retry-kontrakt før
  ikkje-produksjonstesting.
- **Sporing:** [#1095](https://github.com/navikt/crm-arbeidsforhold/issues/1095),
  [#1017](https://github.com/navikt/crm-arbeidsforhold/issues/1017).

### P360-F04 — Release/replay og atomisk claim står att

- **Prioritet / status:** P1 for recovery; kjeldebaserte testmål, ikkje
  påviste runtime-feil.
- **Evidens:** avgjerdsjobben blir oppretta på undersøkt
  ikkje-true-til-true-overgang etter gatekontroll. Insert med `ready=true`
  og replay etter at gate har vore av er ikkje same testa update-hending.
  Claim-queryen bruker ikkje `FOR UPDATE`; samtidig konkurranse er ikkje
  demonstrert. Gate-av er samtidig ei tilsikta kompatibilitetsgrense for
  ordinær avgjerds-DML.
- **Påverknad:** utan avtalt recovery kan hendingar som vart lagra medan
  behandling var av mangle jobbhending; samtidig claim/retry-åtferd er ikkje
  testa.
- **Neste steg / avgjerd:** avgjer støtta release-inngang, replay og atomic
  claim, og bevar gate-av-åtferda. Køyr ikkje manuell replay eller reset av
  releaseflagget utan godkjend testplan.
- **Sporing:** [#1015](https://github.com/navikt/crm-arbeidsforhold/issues/1015),
  [#1095](https://github.com/navikt/crm-arbeidsforhold/issues/1095),
  [#1181](https://github.com/navikt/crm-arbeidsforhold/issues/1181).

### DATA-F01 — Flow-opprydding slettar ContentDocument, ikkje berre lenkja

- **Prioritet / status:** P1 testmål; kjeldeverifisert sideeffekt, omfanget
  for delte filer må verifiserast.
- **Evidens:** planlagd
  [`AAREG_deleteDraftInquiriesANDrelatedDocuments`](../../force-app/main/default/flows/AAREG_deleteDraftInquiriesANDrelatedDocuments.flow-meta.xml)
  les `ContentDocumentLink` for utkastet, samlar `ContentDocumentId` og
  slettar recordar av typen `ContentDocument` før utkastet blir sletta.
  Den undersøkte Flow-en kontrollerer ikkje om dokumentet har andre
  `ContentDocumentLink`-recordar.
- **Påverknad:** eit dokument som også er lenka til ein annan record kan
  vere påverka av slettinga; dette er ein risiko som må testast, ikkje ein
  påstand om at slik deling finst i org.
- **Neste steg / verifikasjon:** isolert test med eige dokument og kontroll
  med delt dokument, ny Draft og innsendt Inquiry; stadfest alders-/status-
  vilkår, slettingsutfall og rollback før eventuell org-test.
- **Sporing:** [FLOW-03 i scenario-testplanen](../testing/aaregisteret-scenario-testplan.md),
  [#1180](https://github.com/navikt/crm-arbeidsforhold/issues/1180),
  [#1181](https://github.com/navikt/crm-arbeidsforhold/issues/1181).

### DATA-F02 — Avtale-Flow slettar RelatedContact etter berre avtale-ID

- **Prioritet / status:** P1/P2 testmål; mogleg skilnad frå dokumentert
  controlleråtferd, ikkje stadfesta feil.
- **Evidens:** `AAREG_removeAccessToDistribution` slettar
  `RelatedContact__c`-recordar filtrert på `Agreement__c = $Record.Id`.
  Domenemodellen tillèt at ein RelatedContact er knytt til både søknad og
  avtale. Den dokumenterte controllerbana beheld ein søknadskopla record
  når han blir fjerna frå avtale; eksisterande scenario AGR-04 uttrykkjer
  same vernekrav.
- **Påverknad:** dersom Flow-en tek bort ein RelatedContact som framleis er
  knytt til søknad, kan søknadskoplinga gå tapt. Kva bane som faktisk køyrer
  og kva data som finst i org er ikkje verifisert her.
- **Neste steg / avgjerd:** test ei felles søknads-/avtalekopling gjennom
  den faktiske Flow-utløysaren; avgjer om sletting er tilsikta eller om
  berre avtaletilknytinga skal fjernast før eventuell kode-/metadatafiks.
- **Sporing:** [AGR-04 og FLOW-02/03 i scenario-testplanen](../testing/aaregisteret-scenario-testplan.md),
  [#1180](https://github.com/navikt/crm-arbeidsforhold/issues/1180),
  [#1181](https://github.com/navikt/crm-arbeidsforhold/issues/1181).

### ACCESS-F01 — Effektiv tilgang er ikkje utleidd frå permission-set XML

- **Prioritet / status:** P1 menneskeleg tilgangsreview; kjeldekart
  fullført, effektiv org-tilgang OPEN.
- **Evidens:** dei åtte lokale permission-setta og sentrale
  `with sharing`/`without sharing`-grenser er dokumenterte i
  [tilgangskartet](aaregisteret-tilgangskart-kjelde-2026-11-14.md).
  Den daterte runtime-sjekken rapporterer éi assignment kvar for
  `AAREG_CommunityPermission` og `AAREG_Arbeidsforhold_Saksbehandling`,
  utan brukaridentitet. Det viser ikkje effektiv record-, felt- eller
  filtilgang.
- **Påverknad:** UI-skjuling, sharing-deklarasjon eller assignment-teljing
  åleine kan ikkje stadfeste tilgangsgrenser eller dataisolasjon.
- **Neste steg / avgjerd:** menneskeleg review av dei privilegerte
  `without sharing`-inngangane og kontrollert negativ testing av direkte
  record-ID, filer og verksemd A/B i godkjend testoppsett.
- **Sporing:** [#1182](https://github.com/navikt/crm-arbeidsforhold/issues/1182),
  [#1181](https://github.com/navikt/crm-arbeidsforhold/issues/1181),
  [#1179](https://github.com/navikt/crm-arbeidsforhold/issues/1179).

### ALT-F01 — Altinn-ressursar og produktnavigasjon er ikkje same avgjerd

- **Prioritet / status:** P1 produkteigaravgjerd; kjelde og UI er kartlagde,
  policyfasit OPEN.
- **Evidens:** Altinn-kartet følgjer ressursavgjerd gjennom aggregerte
  tilgangsflagg til faktiske panel. Generell `hasAccess` kan gi fleire
  panel enn `hasApplicationAccess`; eksisterande kjeldetest og tidlegare
  Jest-resultat beviser ikkje at policyen er rett.
- **Påverknad:** scenariofasit og forventningar til support-/avtalepanel kan
  bli feil om rå ressursrett og produktnavigasjon blir blanda.
- **Neste steg / avgjerd:** produkteigar fastset om aggregert navigasjon er
  ønskt; deretter oppdater scenarioakseptanse og test relevant server-/UI-
  grense utan å tolke UI-skjuling som autorisasjon.
- **Sporing:** [#1180](https://github.com/navikt/crm-arbeidsforhold/issues/1180),
  [#1181](https://github.com/navikt/crm-arbeidsforhold/issues/1181).

### DEP-F01 — Elleve direkte pakkar har uavklart produktbruk

- **Prioritet / status:** P2 inventar; 19/19 deklarasjonar er talde, 8/19
  direkte kallsite-grupper kartlagde, 11/19 uavklarte.
- **Evidens:** avgrensa lokale søk fann ikkje dei kjende API-/metadata-
  namna for dei 11 pakkane. Dette beviser ikkje at pakkane er ubrukt.
  Manifestet og den daterte pakkeoversikta har òg eit versjonsavvik for
  `crm-platform-integration`; installed org-versjon er ikkje utleidd frå
  manifestet.
- **Påverknad:** eigarskap, transitive/dynamiske bruksmønster og runtime-
  dependency-lineage står att før cleanup eller package-konklusjon.
- **Neste steg / avgjerd:** fullfør eigar-/transitive-/metadata-lineage;
  ikkje fjern dependencies eller endre pakkeeigd kjelde på grunnlag av
  manglande treff.
- **Sporing:** [#1185](https://github.com/navikt/crm-arbeidsforhold/issues/1185).

### FLOW-F01 — Dokumentasjonen dekkjer kjelda, ikkje Flow-åtferda

- **Prioritet / status:** P2 verifikasjon; lokal dokumentasjonsdekning
  kontrollert 37/37, funksjonell testdekning NOT RUN.
- **Evidens:** 37 lokale Flow-definisjonar har 37 unike lenkjer i
  [Flow-katalogen](aareg-flow-katalog.md), og alle 37 API-namna finst i
  [Flow-diagramma](aareg-flow-diagrammer.md). Tidlegare datert org-oppslag
  fann 35 aktive og to utan aktiv versjon; det er ikkje ei ny runtime-
  sjekk eller test av Flow-utfall.
- **Påverknad:** UI-bindingar, feilhandsaming, aktiv body og faktisk
  forretningsutfall står att.
- **Neste steg / verifikasjon:** prioriter risikofylte sideeffektar,
  særleg cleanup og RelatedContact, med isolerte fixtures og eksplisitte
  assertions.
- **Sporing:** [#1180](https://github.com/navikt/crm-arbeidsforhold/issues/1180),
  [#1181](https://github.com/navikt/crm-arbeidsforhold/issues/1181),
  [#1182](https://github.com/navikt/crm-arbeidsforhold/issues/1182).

## Trygg dokumentasjons- og metadataopprydding

| Kandidat / område                 | Klassifisering og evidens                                                                                                                                                                      | Tiltak no                                                                            | Stoppvilkår / sporing                                                                                              |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| `force-app/.DS_Store`             | Lokal inventory rapporterte éi OS-fil; Git viser ho som ignored og ikkje tracked.                                                                                                              | Ikkje nødvendig med repository-sletting; ikkje rør lokale arbeidskopifiler.          | Vurder på nytt berre dersom fila er tracked eller inngår i ein build.                                              |
| Confluence-spegelkopiar           | [`docs/architecture/README.md`](README.md) er merkt `speilkopi: delvis`; `repositorystruktur.md` og `arkitekturprinsipp-lagdeling-og-namnestandard.md` er merkte `speilkopi: ja`.              | Behald original og kjeldepeikar; ingen edit, flytting eller arkivering anbefalt her. | Confluence-eigar må stadfeste kjeldeendring før speilkopi blir redigert.                                           |
| `AAREG_CheckObjectTypeNamingTest` | Fjerna frå repo i tidlegare endring; eksisterande [metadata-oppryddingsrunbook](../operations/salesforce-metadata-cleanup-runbook.md) dokumenterer API-namn, avhengnader og verifikasjonssteg. | Ikkje gjenta eller utvid sletting. Runbooken beviser ikkje org-sletting.             | Behald org-verifikasjon som OPEN til dokumentert resultat finst; metadataendringar krev separat godkjend scope.    |
| `docs/archive/`                   | Ingen repo-eigde arkivkandidat er stadfesta av dette kjeldekartet.                                                                                                                             | Ikkje opprett mappe og ikkje flytt dokument.                                         | Før framtidig arkivering: klassifisering, eigar, originalkopi, proveniens, lenkekontroll, rollback og godkjenning. |
| Navigasjon frå handboka           | [Handboka](aaregisteret-handbok.md) har ikkje lenkje til det nyare tilgangskartet og pakkeavstemminga. Dette er navigasjonsgjeld, ikkje tap av innhald.                                        | Ingen endring i eksisterande tekst gjort.                                            | Be om eksplisitt løyve før eksisterande handboktekst blir oppdatert; ta kopi av originalinnhaldet først.           |

## Opne kontrollar

- Ingen ny Salesforce-org-kommando, Apex-/Flow-test, manuell scenario eller
  ekstern P360/Altinn-test er utført i samband med dette registeret.
- P360-testplanen skil `NOT RUN` frå historiske/mock-resultat; mock-suksess
  er ikkje ekstern arkivering.
- Issues over står opne. Ingen funn er automatisk ei avgjerd om å endre
  produktkode, metadata, dependency, dokument eller Salesforce-data.
- GitHub Issues er arbeidskjelda for eigar, prioritet og godkjend
  oppfølging. Dersom eigar ikkje er stadfesta i Issue, må eigar namngjevast
  der før handling.
