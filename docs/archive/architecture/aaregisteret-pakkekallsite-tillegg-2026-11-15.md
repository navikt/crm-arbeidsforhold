# Aa-registeret: tillegg til pakkekallsite-matrisa

> **Arkivert kjeldegjennomgang:** Dette er eit datert tillegg, ikkje ein installasjonsrapport.

**Kontrollert:** 2026-11-15 frå lokal kjelde. Dette tillegget supplerer den
daterte [kallsite-matrisa](../../architecture/aaregisteret-pakkekallsite-matrise.md) utan å endre
det opphavlege biletet. Pakkemappene er lokale, pakkeeigde referansekjelder,
ikkje bevis på nøyaktig innhald i installerte pakkeversjonar. Pakkekjeldene
under `main/default` er git-ignorerte og kan mangle i ei ny arbeidskopi;
lenkjene nedanfor går derfor til repo-spora README-filer.

## Nye referansar

| Deklarert pakke                | Produktreferanse                                                                                                                                                                                                                                                                                                                                                                                         | Lokal pakkereferanse                                                                                                                                       | Evidens og avgrensing                                                                                                                                   |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `crm-community-base`           | Søknadsskjemaet nyttar [`c-breadcrumbs`](../../../force-app/externalApplication/lwc/aareg_application/aareg_application.html#L17); også avtale- og dialogflater refererer til komponenten.                                                                                                                                                                                                               | Lokal `main/default/lwc/breadcrumbs/breadcrumbs.js-meta.xml` i [pakkemappa](../../../crm-community-base/README.md).                                        | Konkrete LWC-referansar i kjelda. Dette beviser ikkje at innlogging, callback eller UI-køyring fungerer i org.                                          |
| `crm-journal-utilities`        | [Søknadssida](../../../force-app/internalApplicationDecision/flexipages/Arbeidsforhold_application_record_page.flexipage-meta.xml#L101), [avtalesida](../../../force-app/main/default/flexipages/AAREG_AgreementRecordPage.flexipage-meta.xml#L93) og [vedtakssida](../../../force-app/main/default/flexipages/Arbeidsforhold_Vedtak_Recordpage.flexipage-meta.xml#L383) refererer til `crmAlertBanner`. | Lokal `main/default/lwc/crmAlertBanner/crmAlertBanner.js-meta.xml` i [pakkemappa](../../../crm-journal-utilities/README.md).                               | Konfigurasjonsreferansar til ein bannerkomponent. Dette beviser ikkje journalføring, aktiv sidetilordning eller vising i org.                           |
| `crm-shared-user-notification` | [AAREG_Dialog](../../../force-app/main/default/permissionsets/AAREG_Dialog.permissionset-meta.xml#L32) og [AAREG_CommunityPermission](../../../force-app/main/default/permissionsets/AAREG_CommunityPermission.permissionset-meta.xml#L100) gir klassetilgang til `UN_DoneProducerLegacy` og `UN_InnboksProducerLegacy`.                                                                                 | Lokale `main/default/classes/UN_DoneProducerLegacy.cls` og `UN_InnboksProducerLegacy.cls` i [pakkemappa](../../../crm-shared-user-notification/README.md). | Permission-set-metadata refererer til pakkeklassane. Dette beviser ikkje effektiv brukartilgang, at ein Flow kallar klassane, eller at varsel er sendt. |

Dette gir konkrete produkt- eller metadatareferansar for **11 av dei 19**
direkte deklarerte pakkane: dei åtte frå den tidlegare matrisa og dei tre
ovanfor. Dei åtte andre er framleis uavklarte, ikkje stadfesta ubrukte:
`custom-permission-helper`, `record-type-cache`, `crm-platform-reporting`,
`crm-shared-flowComponents`, `crm-platform-access-control`, `crm-thread-view`,
`crm-shared-timeline` og `crm-platform-oppgave`.

## Søkeavgrensing

Ein lokal kandidatsjekk samanlikna namn på Apex-klasser, permission sets og
LWC-bundles i dei 11 tidlegare uavklarte referansemappene med innhald i
repo-eigd `force-app/`. Dei konkrete treffa ovanfor vart kontrollerte manuelt.
Generiske ord og reine omsetjingsreferansar vart ikkje rekna som produktkall.
Sjekken dekkjer ikkje alle feltnamn, dynamiske oppslag, transitive avhengnader
eller org-eigd konfigurasjon og kan ikkje brukast som grunnlag for å fjerne ei
avhengnad.

Ein tilleggskontroll søkte etter lokale objekt- og kvalifiserte feltnamn og
LWC-taggar frå dei åtte pakkane i ikkje-testfiler under `force-app/`. Einaste
objektnamntreff var `Application_Log__c` i ein
[support-rapport](../../../force-app/main/default/reports/AAREG_SupportReports/AAREG_ALTINN_Errors_last_week.report-meta.xml#L7)
og eit dashboard. Objektet finst både i `crm-platform-base` og som ein tom
metadata-stub i `crm-platform-oppgave`; namnet åleine beviser derfor ikkje at
`crm-platform-oppgave` eig eller leverer objektet. Denne kontrollen omfattar
ikkje alle dynamiske oppslag, indirekte Flow-referansar eller org-konfigurasjon.

Siste daterte observasjon av installerte pakkar er
[scratch-org-snapshotet frå 2026-11-15](aaregisteret-scratch-org-snapshot-2026-11-15.md);
installasjon og kjeldereferansar beviser ikkje funksjonell kompatibilitet.
Vidare eigar- og runtimeavklaring blir følgd i
[#1185](https://github.com/navikt/crm-arbeidsforhold/issues/1185) og
[#1182](https://github.com/navikt/crm-arbeidsforhold/issues/1182).
