# Pakkekallstader for Arbeidsforhold og Aa-registeret

Denne oversikta samlar avgrensa kjeldesøk frå 2026-11-14 og 2026-11-15.
Av dei 19 direkte deklarerte pakkane hadde 11 konkrete produkt- eller
metadatareferansar. For fire til er det funne samsvar i omsetjingsmetadata,
ikkje direkte bevis på funksjonsbruk. Dei fire andre er **uavklarte**, ikkje
stadfesta ubrukte. Kjeldereferansar beviser ikkje installert pakkeversjon,
aktiv konfigurasjon eller fungerande integrasjon i eit org.

| Deklarert pakke                 | Funnen referanse eller status                                                                                                                                                                     | Kva står att                                                                                                         |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `platform-data-model`           | [P360-porten](../../force-app/integration/p360/classes/P360_ArchiveProcessingGate.cls) les `Feature_Flag__mdt`.                                                                                   | Stadfest eigarskap og versjon for faktisk installert type.                                                           |
| `custom-metadata-dao`           | [AAREG_Utility](../../force-app/utility/classes/AAREG_Utility.cls) brukar `CustomMetadataDAO`.                                                                                                    | Kontroller konfigurasjon og grensetilfelle i aktuell org.                                                            |
| `custom-permission-helper`      | Uavklart i det avgrensa søket.                                                                                                                                                                    | Undersøk også dynamiske kall, Flow og metadata.                                                                      |
| `feature-toggle`                | [P360-porten](../../force-app/integration/p360/classes/P360_ArchiveProcessingGate.cls) brukar `FeatureToggleBase`.                                                                                | Verifiser flagg og pakkekontrakt i aktuelt miljø.                                                                    |
| `record-type-cache`             | Uavklart i det avgrensa søket.                                                                                                                                                                    | Skil pakke-API frå vanlege `RecordType`-oppslag.                                                                     |
| `crm-platform-base`             | [Support-controlleren](../../force-app/dialog/classes/AAREG_contactSupportController.cls) og andre brukar `LoggerUtility`.                                                                        | Kartlegg andre kall og faktisk loggdekning.                                                                          |
| `crm-platform-reporting`        | [Norsk omsetjingsmetadata](../../force-app/main/default/translations/no.translation-meta.xml#L1246) nemner `CRM_Reporting_Data_Before_Insert_Index_Category`, som også finst i lokal pakkekjelde. | Oppføringa har tomt `flows`-element og beviser ikkje aktiv bruk eller køyring.                                       |
| `crm-shared-flowComponents`     | Uavklart i det avgrensa søket.                                                                                                                                                                    | Kontroller komponentreferansar og org-konfigurasjon.                                                                 |
| `crm-henvendelse-base`          | [Trådcontrolleren](../../force-app/dialog/classes/AAREG_MyThreadsController.cls) brukar `CRM_HenvendelseId__c`.                                                                                   | Avklar kva for delar av [pakken](../../crm-henvendelse-base/README.md) som faktisk er i bruk.                        |
| `crm-platform-integration`      | [Altinn-fabrikken](../../force-app/integration/altinn/classes/AAREG_AltinnServiceFactory.cls) refererer til Altinn-servicar.                                                                      | Kjeldekontrakt er ikkje bevis på vellukka live-kall. Sjå [pakkeinngangen](../../crm-platform-integration/README.md). |
| `crm-platform-access-control`   | [Norsk omsetjingsmetadata](../../force-app/main/default/translations/no.translation-meta.xml#L1639) nemner `Recalculate_sharing_for_person`, som også finst i lokal pakkekjelde.                  | Ei Flow-omsetjingsoppføring beviser ikkje aktiv sharing eller effektiv tilgang.                                      |
| `crm-thread-view`               | Uavklart i det avgrensa søket.                                                                                                                                                                    | Undersøk side- og komponentkomposisjon.                                                                              |
| `crm-shared-timeline`           | [Norsk omsetjingsmetadata](../../force-app/main/default/translations/no.translation-meta.xml#L309) omset `Timeline_Activities` og fleire labelar som finst i lokal pakkekjelde.                   | Labelomsetjing beviser ikkje at tidslinjekomponenten blir brukt.                                                     |
| `crm-community-base`            | [Søknadsskjemaet](../../force-app/externalApplication/lwc/aareg_application/aareg_application.html) refererer til `c-breadcrumbs`.                                                                | Dette beviser ikkje innlogging, callback eller UI-køyring.                                                           |
| `crm-platform-email-scheduling` | [Stadfestingsflowen](../../force-app/main/default/flows/AAREG_createContactSendConfirmation.flow-meta.xml) og andre refererer til `EmailQueue__c`.                                                | Aktiv Flow og faktisk e-postsending må kontrollerast separat.                                                        |
| `crm-journal-utilities`         | [Søknadssida](../../force-app/internalApplicationDecision/flexipages/Arbeidsforhold_application_record_page.flexipage-meta.xml) og andre sider refererer til `crmAlertBanner`.                    | Bannerreferansen beviser ikkje journalføring eller aktiv sidetilordning.                                             |
| `crm-shared-user-notification`  | [Dialog-permission-settet](../../force-app/main/default/permissionsets/AAREG_Dialog.permissionset-meta.xml) refererer til `UN_DoneProducerLegacy`.                                                | Klassetilgang beviser ikkje at varsel er sendt.                                                                      |
| `crm-platform-oppgave`          | [Norsk omsetjingsmetadata](../../force-app/main/default/translations/no.translation-meta.xml#L1083) nemner `CRM_Oppgave_Redirect`, som også finst i lokal pakkekjelde.                            | Ei Flow-omsetjingsoppføring beviser ikkje aktiv oppgåveflyt eller UI-binding.                                        |
| `crm-henvendelse`               | [Dialog-permission-settet](../../force-app/main/default/permissionsets/AAREG_Dialog.permissionset-meta.xml) refererer til `CRM_HenvendelseQuicktextController`.                                   | Kontroller faktisk UI-kall og runtime-tilgang; sjå [pakken](../../crm-henvendelse/README.md).                        |

Testfabrikkar og mockar er ikkje rekna som produktkall. Lokal pakkeeigd
referansekjelde kan vere git-ignorert og mangle i ei ny arbeidskopi; det
gjeldande [pakkeregisteret](../../sfdx-project.json) viser deklarerte
avhengnader, ikkje kva som er installert.

For dei fire omsetjingsfunna vart følgjande lokale referansar kontrollerte:
`crm-platform-reporting/main/default/flows/CRM_Reporting_Data_Before_Insert_Index_Category.flow-meta.xml`,
`crm-shared-timeline/crm-shared-timeline/main/default/labels/CustomLabels.labels-meta.xml`,
`crm-platform-oppgave/main/default/flows/CRM_Oppgave_Redirect.flow-meta.xml`
og `crm-platform-access-control/main/default/flows/Recalculate_sharing_for_person.flow-meta.xml`.
Desse git-ignorerte filene er ikkje tilgjengelege gjennom repo-lenkjer.

Opphavleg [matrise](../archive/architecture/aaregisteret-pakkekallsite-matrise-2026-11-14.md),
[pakkesøk](../archive/architecture/aaregisteret-pakkeavstemming-2026-11-14.md)
og [tillegg](../archive/architecture/aaregisteret-pakkekallsite-tillegg-2026-11-15.md)
er bevart. Vidare eigarskaps- og runtimekartlegging blir følgd i
[#1185](https://github.com/navikt/crm-arbeidsforhold/issues/1185).
