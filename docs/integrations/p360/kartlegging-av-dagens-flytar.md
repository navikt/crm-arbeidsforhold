# P360: inngangar og sideeffektar

Tabellen beskriv lokal kjelde på `P360Test`. Sjå
[den arkiverte kartlegginga frå 2026-11-13](../../archive/p360/kartlegging-av-flytar-2026-11-13.md)
for opphavlege observasjonar. Ho er ikkje ein status for den nye koden.

| Inngang             | Kva kjelda gjer                                                                                                                                                                                                                               | Viktig avgrensing                                                                       |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Send søknad         | [Controlleren](https://github.com/navikt/crm-arbeidsforhold/blob/807fdcf12f3f281beb780173d0db427cf7fa0142/force-app/externalApplication/classes/AAREG_ApplicationController.cls) ber om `ApplicationDocument` etter lagring                   | Jobb berre ved open gate; køleggingsfeil stoppar ikkje innsendinga                      |
| Ny `ContentVersion` | [Vedleggshandteraren](https://github.com/navikt/crm-arbeidsforhold/blob/807fdcf12f3f281beb780173d0db427cf7fa0142/force-app/integration/p360/classes/P360_ContentVersionArchiveHandler.cls) krev direkte `FirstPublishLocationId` til søknaden | Portalen lenkjer filer etterpå; handteraren sjekkar ikkje her om søknaden er eit utkast |
| Frigiv vedtak       | [Guard-handteraren](https://github.com/navikt/crm-arbeidsforhold/blob/807fdcf12f3f281beb780173d0db427cf7fa0142/force-app/integration/p360/classes/P360_ArchiveGuardHandler.cls) kan opprette `DecisionDocument` ved overgang til frigitt      | Krev gate og tilgang; jobb er ikkje bevis på eit arkivert vedtak                        |
| Avtaledokument      | [Jobbservicen](https://github.com/navikt/crm-arbeidsforhold/blob/807fdcf12f3f281beb780173d0db427cf7fa0142/force-app/integration/p360/classes/job/P360_ArchiveJobService.cls) har ein jobbmetode                                               | Automatisk forretningsutløysar og dokumentinnhald er ikkje stadfesta                    |
| Prosesser jobb      | [Scheduler og claim](https://github.com/navikt/crm-arbeidsforhold/blob/807fdcf12f3f281beb780173d0db427cf7fa0142/force-app/integration/p360/classes/job/P360_ArchiveJobScheduler.cls) kan køyre workeren for kvalifiserte jobbar               | Kjeldekode beviser ikkje at scheduler er planlagd i eit org                             |

For krav om innsending, filval, retry og evidens, sjå
[verifikasjonsplanen](inngangar-og-verifikasjonsplan.md). E-post, SMS og
distribusjon kan ha eigne sideeffektar når ein testar brukarvegen; P360-mock
slår ikkje desse av.
