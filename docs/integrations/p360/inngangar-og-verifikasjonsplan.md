# P360: verifikasjonsplan

Dette er ein plan, ikkje ein utføringsrapport. Scenarioa er **ikkje køyrde i
denne dokumentasjonsrunden**. Målet er å skilje forventa produktåtferd,
noverande kjelde og faktisk evidens. Den
[tidlegare planen](../../archive/p360/inngangar-og-verifikasjonsplan-2026-11-14.md)
er arkivert.

## Før testing

1. Stadfest eksakt eksisterande `crm-arbeidsforhold` scratch-org, installert
   versjon, rett brukarrolle og syntetiske testdata. Alias åleine er ikkje
   bevis for mål.
2. Undersøk feature-flagg, val av stub eller testmottak, aktive Flow-ar og
   planlagde jobbar. P360-mock sikrar ikkje at Altinn, distribusjon, e-post
   eller SMS er mocka. Stopp dersom ei sideeffekt ikkje er avklart.
3. Bruk testmottaket berre etter den avgrensa
   [scratch-guiden](scratch-brukarguide.md). Live eksterne integrasjonar
   krev separat godkjenning og er ikkje ein del av denne planen.
4. Registrer test-ID, dato, commit/pakkeversjon, mål, rolle, føresetnader,
   forventa og faktisk resultat, sanert evidens og opprydding.

## Scenario

| ID                                       | Steg                                                                                                                                                                       | Forventa resultat og evidens                                                                                                                                                                                      |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| P360-A: første innsending                | 1. Lag syntetisk utkast med fleire vedlegg og utan lagra P360-saksnummer. 2. Kontroller open gate og testmottak. 3. Send éin gong. 4. Les jobb og simulerte førespurnader. | Éin relevant søknadsjobb; testmottaket viser `CreateCase` og `CreateDocument` med forventa samandrag og filer. Registrer jobbtilstand og sanert referanse til kvitteringane. Dette beviser ikkje live-arkivering. |
| P360-B: utkast og filinngang             | 1. Lagre utkast med vedlegg utan å sende. 2. Kontroller søknad, fillenkjer og eventuelle jobbar. 3. Undersøk direkte filpublisering separat.                               | Produktkravet er arkivering ved innsending. Kjelda sin direkte `ContentVersion`-inngang sjekkar ikkje utkaststatus; resultatet må målast, ikkje antas.                                                            |
| P360-C: ny innsending                    | 1. Fullfør første simulerte jobb. 2. Be om meir informasjon. 3. Send søknaden på nytt med både vidareførte og nye filer. 4. Samanlikn jobbidentitet og motteke innhald.    | Kravet er nytt, komplett dokumentsett per innsending. Kjelda kan lage ny nøkkel etter terminal jobb, men manglar lagra brukarutval og frose sett. Heile kravet er derfor ikkje dokumentert oppfylt.               |
| P360-D: ny innsending medan jobb er open | 1. Hald første jobb `Pending`, `In Progress` eller `Failed`. 2. Send inn på nytt i ei isolert testoppsetting. 3. Tel jobbar og samanlikn innhaldet.                        | Dokumenter at dagens kode gjenbruker open jobb, og vurder avvik mot kravet om eige sett per innsending. Ikkje marker kravet som bestått berre fordi det finst éin jobb.                                           |
| P360-E: feil og retry                    | 1. Injiser retrybar og permanent feil kvar for seg. 2. Les status, forsøkstal og tidspunkt. 3. Kontroller at ingen ekstern teneste blir kontakta.                          | Retrybar feil går til `Failed` med nytt tidspunkt; permanent eller uttømt feil går til `Manual Review`. Utløpt lease har ikkje automatisk recovery i dagens claim-service.                                        |
| P360-F: andre hendingar                  | 1. Test direkte vedleggs- og vedtaksinngang kvar for seg. 2. Kontroller jobbrad og adapterrespons.                                                                         | Ein oppretta jobb er ikkje bevis på arkivert innhald. Worker byggjer ikkje tilsvarande dokumentrequest for desse typane i den reelle adapterbana.                                                                 |

Ein suksess-stub kan gi `Succeeded` utan å lagre førespurnaden. Bruk
kvitteringar frå testmottaket når innhald skal etterprøvast, og unngå å
kopiere dokument, persondata eller autentiseringsinformasjon ut av orgen.

For breiare brukarvegar og negative tilgangstestar, sjå
[scenario-testplanen](../../testing/aaregisteret-scenario-testplan.md) og
[testdatastrategien](../../testing/aaregisteret-testdata-strategi.md).
