# Dokumentasjonsarkiv

Her ligg tidlegare analysar, testar og planar som skal bevarast, men ikkje
brukast som fasit for dagens kode eller org. Dokumenta er merkte ved starten
og viser kva tidspunkt og avgrensing dei gjeld.

Start heller i [handboka](../architecture/aaregisteret-handbok.md),
[P360-guiden](../integrations/p360/README.md) eller
[scenario-testplanen](../testing/aaregisteret-scenario-testplan.md) for ny
forståing og nye testar. Jira- og Confluence-speglane ligg framleis under
`docs/context/`; dei er ikkje endra eller flytta. Repo-eigde, daterte
Jira-oppdateringar i same kontekstmappe er også historiske og er merkte slik.

## Produkt, Flow og pakkar

| Historisk materiale                                                                                                                                                                                                                   | Innhald                                                                                                           |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| [Handbok, 2026-11-14](architecture/aaregisteret-handbok-2026-11-14.md)                                                                                                                                                                | Tidlegare produktinngang og datert arbeidsstatus                                                                  |
| [Kjeldeinventar, 2026-11-14](architecture/aaregisteret-kjeldeinventar-2026-11-14.md)                                                                                                                                                  | Fil- og pakkekartlegging                                                                                          |
| [Funn og tiltak, 2026-11-14](architecture/aaregisteret-funn-og-tiltak-2026-11-14.md)                                                                                                                                                  | Opphavleg arbeidsregister; sjekk Issues for seinare oppfølging                                                    |
| [Heilskapleg analyse, 2026-11-13](architecture/helhetleg-analyse-og-teststrategi-2026-11-13.md) og [gjennomgangsplan](architecture/helhetleg-gjennomgang-plan.md)                                                                     | Tidlegare analyse, teststrategi og sjekklister                                                                    |
| [Første pakkematrise](architecture/aaregisteret-pakkekallsite-matrise-2026-11-14.md), [pakkesøk](architecture/aaregisteret-pakkeavstemming-2026-11-14.md) og [tillegg](architecture/aaregisteret-pakkekallsite-tillegg-2026-11-15.md) | Dokumenterte lokale symbolsøk; [pakkematrisa](../architecture/aaregisteret-pakkekallsite-matrise.md) samlar funna |
| [Tilgangskart, 2026-11-14](architecture/aaregisteret-tilgangskart-kjelde-2026-11-14.md)                                                                                                                                               | Kjeldebasert oversikt, ikkje effektiv brukartilgang                                                               |
| [Flow-avstemming, 2026-11-14](architecture/aareg-flow-org-source-reconciliation-2026-11-14.md) og [observasjon, 2026-11-15](architecture/aareg-flow-org-observation-2026-11-15.md)                                                    | Daterte samanlikningar av kjelde og scratch-org                                                                   |
| [Scratch-snapshot, 2026-11-14](architecture/aaregisteret-scratch-org-snapshot-2026-11-14.md) og [2026-11-15](architecture/aaregisteret-scratch-org-snapshot-2026-11-15.md)                                                            | Daterte pakke- og orgobservasjonar                                                                                |

## P360

| Historisk materiale                                                                                                                                 | Innhald                                                     |
| --------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| [Kodegjennomgang](p360/kodegjennomgang-tidlegare.md) og [stegvis gjennomgang](p360/steg-for-steg-gjennomgang-tidlegare.md)                          | Tidlegare forklaringar av jobb- og adaptergrunnlaget        |
| [Teknisk oversikt, 2026-11-05](p360/teknisk-oversikt-2026-11-05.md)                                                                                 | Tidlegare implementasjonsstatus                             |
| [Flytkartlegging, 2026-11-13](p360/kartlegging-av-flytar-2026-11-13.md)                                                                             | Tidlegare undersøking av inngangar og sideeffektar          |
| [Inngangar og verifikasjonsplan, 2026-11-14](p360/inngangar-og-verifikasjonsplan-2026-11-14.md)                                                     | Gamle kjeldefunn og planlagde kontrollar                    |
| [Scratch-kontrakttest, 2026-11-15](p360/scratch-kontrakttest-og-interne-val-2026-11-15.md)                                                          | Tidlegare interne val og datert testbevis                   |
| [Tidlegare arkitekturdiagram](p360/p360-current-architecture-tidlegare.mmd) og [komponentdiagram](p360/p360-component-diagram-tidlegare.mmd)        | Gamle illustrasjonar før søknadsbygginga vart kopla inn     |
| [Tidlegare kontraktsekvens](p360/p360-archive-sequence-tidlegare.mmd) og [jobboppretting](p360/p360-idempotent-job-creation-sequence-tidlegare.mmd) | Tidlegare diagram før ny innsending og adapterutvikling     |
| [Testlogg, november 2026](p360/test-logg-2026-11.md)                                                                                                | Kronologisk org- og mockevidens med opphavlege avgrensingar |
| [Testgjennomgang, 2026-10-14](operations/p360-og-crm-arbeidsforhold-testgjennomgang-2026-10-14.md)                                                  | Tidlegare testplan for P360 og eksisterande funksjonar      |

## Altinn og drift

| Historisk materiale                                                                                              | Innhald                                       |
| ---------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| [Altinn-scenariogjennomgang](altinn/altinn-scenario-gjennomgang-2026-10.md)                                      | Tidlegare design, framdrift og miljøfunn      |
| [Altinn-testguide](altinn/test-guide-community-plus-2026-10.md) og [testlogg](altinn/altinn-test-log-2026-10.md) | Historiske føresetnader, scenario og resultat |
| [Scratch-testlogg, 2026-10-15](operations/scratch-testlogg-2026-10-15.md)                                        | Tidlegare testdata, tilstand og oppfølging    |
| [Experience Cloud-diagnose, 2026-10-28](operations/experience-cloud-console-2026-10-28.md)                       | Daterte konsollfunn                           |
| [`[HELPER] Create Scratch Org`](workflows/helper_create-scratch-org.md)                                          | Fjerna workflow og den gamle skildringa       |

Gamle lenkjer kan peike til ei kort vidarevising. For ei ny observasjon må
resultat, dato, mål, versjon, trygg evidens og eventuelt oppryddingsbehov
registrerast på nytt; ein historisk `PASS` er ikkje ein ny test.

Nokre historiske kjeldetilvisingar viser ein lokal sti som kode og lenkjer til
den spora pakkeinngangen. Sjølve avhengnadskjelda er git-ignorert og kan
mangle i ein ny klone; pakkeinngangen er ikkje ei erstatning for kjeldebeviset.

## Originalfiler på `main` før omorganisering

Arkivkopiane ovanfor har fått historikkmerking og oppdaterte lenkjer. For
ordrett tidlegare innhald, sjå desse filene på den faste `main`-commiten før
omorganiseringa:

- [Altinn-scenariogjennomgang](https://github.com/navikt/crm-arbeidsforhold/blob/b0a7dd94636672012dde07bfd62ae47de5cdbbb2/docs/integrations/altinn/README.md)
- [Altinn-testlogg](https://github.com/navikt/crm-arbeidsforhold/blob/b0a7dd94636672012dde07bfd62ae47de5cdbbb2/docs/integrations/altinn/altinn-test-log.md)
- [Altinn-testguide](https://github.com/navikt/crm-arbeidsforhold/blob/b0a7dd94636672012dde07bfd62ae47de5cdbbb2/docs/integrations/altinn/test-guide.md)
- [P360 stegvis gjennomgang](https://github.com/navikt/crm-arbeidsforhold/blob/b0a7dd94636672012dde07bfd62ae47de5cdbbb2/docs/integrations/p360/steg-for-steg-gjennomgang.md)
- [Experience Cloud-diagnose](https://github.com/navikt/crm-arbeidsforhold/blob/b0a7dd94636672012dde07bfd62ae47de5cdbbb2/docs/operations/experience-cloud-console-2026-10-28.md)
