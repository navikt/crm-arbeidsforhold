# P360: arkivering

Målet er å arkivere søknaden og tilhøyrande dokument i Public 360. Dette er
ikkje ei ferdig live-integrasjon: faktisk transport, autentisering, ekstern
kontrakt og komplett dokumentinnhald må framleis avklarast og verifiserast.

`main` har ein avgrensa jobb- og adaptergrunnmur. `P360Test` har i tillegg
arbeid med søknadsinnsending, bygging av førespurnader og eit simulert
scratch-mottak. Desse greinstegene er ikkje bevis på at dei er merga,
installert eller aktiverte i eit org.

## Vel leserute

| Eg vil                                           | Start her                                                                                                                                                                                                                    |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Forstå jobb, dokument og skiljet mellom greinene | [Kodegjennomgang](kodegjennomgang.md) og [teknisk oversikt](teknisk-oversikt.md)                                                                                                                                             |
| Sjå inngangar og sideeffektar                    | [Inngangskart](kartlegging-av-dagens-flytar.md)                                                                                                                                                                              |
| Teste stegvis med forventa resultat              | [Verifikasjonsplan](inngangar-og-verifikasjonsplan.md) og [scenario-testplan](../../testing/aaregisteret-scenario-testplan.md)                                                                                               |
| Forstå testmottaket utan P360-server             | [Scratch-guide](scratch-brukarguide.md) og [kontrakttest](scratch-kontrakttest-og-interne-val.md)                                                                                                                            |
| Finne tidlegare resultat                         | [Testlogg og evidens](test-log.md) og [arkivet](../../archive/README.md#p360)                                                                                                                                                |
| Forstå filval og ny innsending                   | [Vedleggsutval og innsendingsidentitet](vedleggsutval-og-innsendingsidentitet-design.md)                                                                                                                                     |
| Undersøkje SIF-kontrakten                        | [SIF-operasjonar](sif-rpc-operasjonar.md), [API-kontraktar](sif-api-kontrakter.md) og [adapterval](di-og-adapterval.md)                                                                                                      |
| Sjå jobbmodell og vidare arbeid                  | [Datamodell](../../architecture/p360-data-model-og-arkiveringsjob.md), [roadmap](../../../.github/specs/p360-completion-roadmap.md) og [historisk Jira-oppdateringsforslag](../../context/p360/jira-oppdateringsoversikt.md) |

## Viktige grenser

- `P360_Archive_Processing` er prosesseringsporten. Kjeldemetadata set han til
  `false`; det er ikkje ei observasjon av eit org.
- `Use_Mock_Transport__c` vel suksess-stub, ikkje prosesseringsport.
  `P360_Archive_Release` styrer frigivingsrett, ikkje prosesseringsport.
- `Succeeded` med stub eller ei scratch-kvittering beviser ikkje at ekte P360
  har motteke noko. Live testing og eventuell aktivering krev eigne avklaringar
  og godkjenningar; agentar skal ikkje aksessere produksjon.
- Andre integrasjonar og varslingar kan framleis ha sideeffektar sjølv om
  P360 er mocka. Sjå [verifikasjonsplanen](inngangar-og-verifikasjonsplan.md).
- [SIF RPC-forståelse](sif-rpc-forstaelse.md) er ei historisk speilkopi frå
  2026-09-08, ikkje oppdatert implementasjonsstatus eller transportbevis.
