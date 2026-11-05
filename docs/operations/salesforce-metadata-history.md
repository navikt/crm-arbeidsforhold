# Historikk for sletta og omnamna Salesforce-metadata

Generert frå origin/main ved commit d399afd8b42acad6d812c5835644d5de070f834d. Historikken startar 2021-03-04T08:16:25+01:00.

## Resultat

- 472 filhendingar: 225 slettingar, 15 endra filnamn og 232 flyttingar med same filnamn.
- 91 unike gamle metadatakomponentar finst ikkje i dagens main: 91 under force-app og 0 i referansemapper/andre kjelderoter.
- 0 kandidatar har uavklart metadatatype.
- Talet som framleis finst i produksjon er **ukjent**. Ingen produksjonsorg er kontakta.

Alle 472 filhendingar er verifiserte mot Git-trea med 1191 kontrollar: gammal fil fanst i førre main-commit, gammal sti er borte etter hendinga, og eventuelt nytt filnamn finst i den nye commiten.

## Fullstendige lister

- [Alle filhendingar med dato, gammal/ny sti og commit](salesforce-metadata-history-events.csv).
- [Dedupliserte kandidatar for kontroll mot org](salesforce-metadata-cleanup-candidates.csv).

## Kandidatar per type

| Kjelderot | Type                     | Kandidatar |
| --------- | ------------------------ | ---------- |
| force-app | ApexClass                | 28         |
| force-app | ApexTestSuite            | 1          |
| force-app | CustomApplication        | 2          |
| force-app | CustomField              | 20         |
| force-app | Dashboard                | 5          |
| force-app | EmailTemplate            | 2          |
| force-app | FlexiPage                | 4          |
| force-app | Flow                     | 11         |
| force-app | Layout                   | 2          |
| force-app | LightningComponentBundle | 1          |
| force-app | ListView                 | 2          |
| force-app | PathAssistant            | 1          |
| force-app | PermissionSet            | 1          |
| force-app | PermissionSetGroup       | 2          |
| force-app | QuickAction              | 2          |
| force-app | RemoteSiteSetting        | 1          |
| force-app | Report                   | 2          |
| force-app | ReportFolder             | 1          |
| force-app | ReportType               | 2          |
| force-app | SecuritySettings         | 1          |

## Alle Git-gjenkjende filnamnendringar

| Dato i main | Gammal filsti                                                                                                    | Ny filsti                                                                                                          | Likskap | Merknad                                    |
| ----------- | ---------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------- | ------------------------------------------ |
| 2026-10-08  | force-app/utility/classes/AAREG_CheckObjectTypeNamingTest.cls-meta.xml                                           | force-app/integration/common/classes/IntegrationLogRedactor.cls-meta.xml                                           | 080 %   | Berre metadata-sidefil; mogleg feilkopling |
| 2026-07-10  | force-app/tests/classes/integration/p360/contract/dto/P360_ArchiveDtoTest.cls-meta.xml                           | force-app/integration/p360/classes/contract/P360_ContractDtoTest.cls-meta.xml                                      | 072 %   | Berre metadata-sidefil; mogleg feilkopling |
| 2026-07-09  | force-app/agreementExternal/classes/AAREG_Agreement.cls-meta.xml                                                 | force-app/internalApplicationDecision/classes/AAREG_ApplicationDecisionPDFFileSerTest.cls-meta.xml                 | 080 %   | Berre metadata-sidefil; mogleg feilkopling |
| 2026-07-08  | force-app/main/default/flows/AAREG_createDistributionAccess.flow-meta.xml                                        | force-app/main/default/flows/AAREG_Agreement_create_distribution_access.flow-meta.xml                              | 060 %   | Git-heuristikk; ikkje API-verifisert       |
| 2026-06-24  | force-app/main/default/applications/Arbeidsforhold.app-meta.xml                                                  | force-app/main/default/applications/AAREG_application.app-meta.xml                                                 | 098 %   | Git-heuristikk; ikkje API-verifisert       |
| 2026-06-24  | force-app/main/default/applications/Arbeidsforhold_henvendelse.app-meta.xml                                      | force-app/main/default/applications/AAREG_support.app-meta.xml                                                     | 098 %   | Git-heuristikk; ikkje API-verifisert       |
| 2026-06-08  | force-app/aareg_Utility/classes/AAREG_TestDataFactory.cls-meta.xml                                               | force-app/externalAccess/classes/AAREG_CommunityUtils.cls-meta.xml                                                 | 100 %   | Berre metadata-sidefil; mogleg feilkopling |
| 2026-06-08  | force-app/aareg_AccessExternal/classes/AAREG_CommunityUtils.cls-meta.xml                                         | force-app/utility/classes/AAREG_TestDataFactory.cls-meta.xml                                                       | 072 %   | Berre metadata-sidefil; mogleg feilkopling |
| 2026-02-10  | force-app/main/default/reportTypes/Accounts_with_Applications_Decisions_Decision_Details.reportType-meta.xml     | force-app/main/default/reportTypes/AAREG_Accounts_with_Applications_Decisions_Decision_Details.reportType-meta.xml | 100 %   | Git-heuristikk; ikkje API-verifisert       |
| 2026-01-30  | force-app/main/default/flows/AAREG_Decision_create_agreement.flow-meta.xml                                       | force-app/main/default/flows/AAREG_Decision_Completed.flow-meta.xml                                                | 056 %   | Git-heuristikk; ikkje API-verifisert       |
| 2026-01-30  | force-app/main/default/quickActions/Application_Decision__c.AAREG_Create_agreement.quickAction-meta.xml          | force-app/main/default/quickActions/Application_Decision__c.AAREG_completeDecision.quickAction-meta.xml            | 065 %   | Git-heuristikk; ikkje API-verifisert       |
| 2026-01-19  | force-app/main/default/objects/Application_Decision_Details__c/fields/Letter_complaint_section__c.field-meta.xml | force-app/main/default/objects/Application_Decision__c/fields/Letter_complaint_text__c.field-meta.xml              | 074 %   | Git-heuristikk; ikkje API-verifisert       |
| 2026-01-19  | force-app/main/default/objects/Application_Decision_Details__c/fields/Letter_terms_section__c.field-meta.xml     | force-app/main/default/objects/Application_Decision__c/fields/Letter_terms_text__c.field-meta.xml                  | 075 %   | Git-heuristikk; ikkje API-verifisert       |
| 2026-01-11  | force-app/aareg_Websak/classes/AAREG_ArchiveBatchHandler.cls-meta.xml                                            | force-app/aareg_ApplicationInternal/classes/AAREG_ApplicationInternalControllerTest.cls-meta.xml                   | 080 %   | Berre metadata-sidefil; mogleg feilkopling |
| 2021-11-24  | force-app/main/default/objects/Inquiry__c/listViews/Aareg_SupportApplicationQuestions.listView-meta.xml          | force-app/main/default/objects/Inquiry__c/listViews/Aareg_Saker_til_behandling.listView-meta.xml                   | 075 %   | Git-heuristikk; ikkje API-verifisert       |

## Gamle komponentar som ikkje finst i main

Datoen under er siste filhending på main for det gamle komponentnamnet. CSV-en viser alle hendingar og datoar. Git-kopla nye namn er ikkje automatisk stadfesta erstatningar.

| Kjelderot | Type                     | Gammalt namn                                                   | Siste dato i main | Commit   |
| --------- | ------------------------ | -------------------------------------------------------------- | ----------------- | -------- |
| force-app | ApexClass                | AAREG_ApplicationArchiveBatch                                  | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | AAREG_ApplicationArchiveBatchTest                              | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | AAREG_ApplicationControllerCoverageTest                        | 2026-07-13        | c1e600fc |
| force-app | ApexClass                | AAREG_ArchiveApplicationCommandTest                            | 2026-07-10        | ac3b22c2 |
| force-app | ApexClass                | AAREG_ArchiveApplicationResultTest                             | 2026-07-10        | ac3b22c2 |
| force-app | ApexClass                | AAREG_ArchiveBatchHandler                                      | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | AAREG_ArchiveBatchHandlerTest                                  | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | AAREG_ArchiveScheduler                                         | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | AAREG_ArchiveSchedulerTest                                     | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | AAREG_ArchiveService                                           | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | AAREG_ArchiveServiceTest                                       | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | AAREG_CheckObjectTypeNamingTest                                | 2026-10-08        | 4782dc2b |
| force-app | ApexClass                | AAREG_DecisionArchiveBatch                                     | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | AAREG_DecisionArchiveBatchTest                                 | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | AAREG_MyAppsCoverageTest                                       | 2026-07-13        | c1e600fc |
| force-app | ApexClass                | AAREG_WebsakXMLGenerator                                       | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | AAREG_WebsakXMLGeneratorTest                                   | 2026-01-11        | 8dbf7ec5 |
| force-app | ApexClass                | CRM_ApplicationDomain                                          | 2021-11-01        | 9b307d08 |
| force-app | ApexClass                | P360_ArchiveDtoTest                                            | 2026-07-10        | ac3b22c2 |
| force-app | ApexClass                | P360_ContractDtoTest                                           | 2026-07-10        | 29937202 |
| force-app | ApexClass                | P360_ExceptionTest                                             | 2026-07-10        | 29937202 |
| force-app | ApexClass                | P360_RpcDtoTest                                                | 2026-07-10        | ac3b22c2 |
| force-app | ApexClass                | TimeTestEventController                                        | 2026-08-05        | 733dbe70 |
| force-app | ApexClass                | TimeTestEventControllerTest                                    | 2026-08-05        | 733dbe70 |
| force-app | ApexClass                | TimeTestEventPlanner                                           | 2026-08-05        | 733dbe70 |
| force-app | ApexClass                | TimeTestEventRequest                                           | 2026-08-05        | 733dbe70 |
| force-app | ApexClass                | TimeTestEventRuleEngine                                        | 2026-08-05        | 733dbe70 |
| force-app | ApexClass                | TimeTestEventSummary                                           | 2026-08-05        | 733dbe70 |
| force-app | ApexTestSuite            | ArchiveTests                                                   | 2026-01-11        | 8dbf7ec5 |
| force-app | CustomApplication        | Arbeidsforhold                                                 | 2026-06-24        | e344554e |
| force-app | CustomApplication        | Arbeidsforhold_henvendelse                                     | 2026-06-24        | e344554e |
| force-app | CustomField              | Agreement__c.EventAccess__c                                    | 2026-03-09        | d24d0b31 |
| force-app | CustomField              | Application__c.ApplicationDeadline__c                          | 2022-11-14        | 2554e3d3 |
| force-app | CustomField              | Application__c.EventAccess__c                                  | 2026-03-09        | d24d0b31 |
| force-app | CustomField              | Application_Decision__c.isDetailStatusFilled__c                | 2026-02-05        | 5621f700 |
| force-app | CustomField              | Application_Decision__c.isNotNull__c                           | 2026-02-05        | 8f5ff7c2 |
| force-app | CustomField              | Application_Decision_Details__c.Letter_complaint_section__c    | 2026-01-19        | 26cadbea |
| force-app | CustomField              | Application_Decision_Details__c.Letter_terms_section__c        | 2026-01-19        | 26cadbea |
| force-app | CustomField              | Application_Decision_Details__c.Processing_basis_status__c     | 2026-02-05        | e642738a |
| force-app | CustomField              | ApplicationBasisCode__c.LegalBasisStateBusiness__c             | 2021-05-26        | 132d704b |
| force-app | CustomField              | ApplicationBasisCode__c.LegalBasisStateGeneral__c              | 2021-05-26        | 132d704b |
| force-app | CustomField              | ApplicationBasisCode__c.LegalBasisStateHealthAndSocial__c      | 2021-05-26        | 132d704b |
| force-app | CustomField              | ApplicationBasisCode__c.LegalBasisStateLegal__c                | 2021-05-26        | 132d704b |
| force-app | CustomField              | ApplicationBasisCode__c.LegalBasisStateMilitary__c             | 2021-05-26        | 132d704b |
| force-app | CustomField              | ApplicationBasisCode__c.LegalBasisStateResearch__c             | 2021-05-26        | 132d704b |
| force-app | CustomField              | ApplicationBasisCode__c.PurposeStateBusiness__c                | 2021-05-26        | 132d704b |
| force-app | CustomField              | ApplicationBasisCode__c.PurposeStateGeneral__c                 | 2021-05-26        | 132d704b |
| force-app | CustomField              | ApplicationBasisCode__c.PurposeStateHealthAndSocial__c         | 2021-05-26        | 132d704b |
| force-app | CustomField              | ApplicationBasisCode__c.PurposeStateLegal__c                   | 2021-05-26        | 132d704b |
| force-app | CustomField              | ApplicationBasisCode__c.PurposeStateMilitary__c                | 2021-05-26        | 132d704b |
| force-app | CustomField              | ApplicationBasisCode__c.PurposeStateResearch__c                | 2021-05-26        | 132d704b |
| force-app | Dashboard                | AaregistretDashboards/GKtYxPggRSehHAgZamtQodkAOOUTSD           | 2026-06-16        | 32df4c4f |
| force-app | Dashboard                | AaregistretDashboards/GQvEviCLZeKewgTwnAaPTJEQJmzuEa           | 2026-06-16        | 32df4c4f |
| force-app | Dashboard                | AaregistretDashboards/gRzFZpdxEiaCoJStEunYuFQsBNpjbe           | 2026-06-15        | 62164dba |
| force-app | Dashboard                | CompanyDashboards/cJnGwvGCUSKVeTaRvFsWdJsGDkPlHk               | 2021-09-21        | 73795596 |
| force-app | Dashboard                | CompanyDashboards/gRzFZpdxEiaCoJStEunYuFQsBNpjbe               | 2021-05-20        | 814c84ff |
| force-app | EmailTemplate            | unfiled$public/aaRegApplicationConfirmation_1622393053589      | 2025-11-23        | c6c2afbe |
| force-app | EmailTemplate            | unfiled$public/aaRegApplicationConfirmation_1636046532436      | 2021-11-04        | d41a2c7c |
| force-app | FlexiPage                | AAREG_CasehandlingRecordPage                                   | 2021-05-30        | c9840af9 |
| force-app | FlexiPage                | AgreementRecordPage                                            | 2021-05-30        | c9840af9 |
| force-app | FlexiPage                | ApplicationRecordPage                                          | 2021-05-30        | c9840af9 |
| force-app | FlexiPage                | Home_Page_Default                                              | 2021-05-26        | 83289254 |
| force-app | Flow                     | AAREG_applicationFinished                                      | 2026-03-09        | d24d0b31 |
| force-app | Flow                     | AAREG_applicationFinished_RT                                   | 2026-03-09        | d24d0b31 |
| force-app | Flow                     | AAREG_changeCasehandler                                        | 2026-01-15        | 897a49bb |
| force-app | Flow                     | AAREG_createDistributionAccess                                 | 2026-07-08        | 36eba55d |
| force-app | Flow                     | AAREG_Decision_create_agreement                                | 2026-01-30        | be433d2e |
| force-app | Flow                     | AAREG_getContactAndUpdateApplication                           | 2021-06-14        | 06b6df3c |
| force-app | Flow                     | AAREG_populateDecisionText                                     | 2026-03-10        | c2fdd7e9 |
| force-app | Flow                     | AAREG_subflowCreateTask_RT                                     | 2026-06-12        | 7462cb31 |
| force-app | Flow                     | AAREG_updateDecisionText                                       | 2026-03-10        | c2fdd7e9 |
| force-app | Flow                     | Agreement_Initiator                                            | 2026-06-05        | fc00a452 |
| force-app | Flow                     | Application_Processor                                          | 2021-06-23        | 603f21f8 |
| force-app | Layout                   | Application__c-Application Layout                              | 2021-05-30        | c9840af9 |
| force-app | Layout                   | Application_Decision_Details__c-Oppsettet Application Decision | 2026-01-19        | 26cadbea |
| force-app | LightningComponentBundle | aareg_ApplicationDecisionInternal                              | 2025-12-15        | a786703b |
| force-app | ListView                 | Inquiry__c.Aareg_SupportApplicationQuestions                   | 2021-11-24        | c6556bde |
| force-app | ListView                 | Inquiry__c.Aareg_SupportProfessionalFunctionalQuestions        | 2021-11-24        | c6556bde |
| force-app | PathAssistant            | ArbeidsforholdApplicationPath                                  | 2021-05-30        | c9840af9 |
| force-app | PermissionSet            | NAVArbeidsforhold                                              | 2022-01-20        | 438b72bc |
| force-app | PermissionSetGroup       | AAREG_Arbeidsforhold_Saksbehandling_GroupSet                   | 2021-11-26        | ce2ef88a |
| force-app | PermissionSetGroup       | AAREG_Arbeidsforhold_Support_GroupSet                          | 2021-11-26        | ce2ef88a |
| force-app | QuickAction              | Application__c.aaReg_ApplicationDone                           | 2026-01-30        | be433d2e |
| force-app | QuickAction              | Application_Decision__c.AAREG_Create_agreement                 | 2026-01-30        | be433d2e |
| force-app | RemoteSiteSetting        | AAREG_DistribusjonTilgangAPI                                   | 2025-10-23        | 7da15b25 |
| force-app | Report                   | Aa_registerReports/Aa_regNewFourthAndOlder                     | 2026-06-16        | 32df4c4f |
| force-app | Report                   | Aa_registerReports/aareg_oversikt_konsument_og_kontaktpersoner | 2026-02-10        | e285cce2 |
| force-app | ReportFolder             | Aa_registerReports/AAREG_arbeidsforholdTeam                    | 2026-04-20        | 23ae38a8 |
| force-app | ReportType               | Accounts_with_Applications_Decisions_Decision_Details          | 2026-02-10        | e285cce2 |
| force-app | ReportType               | Decision_Detail_Master_Application_Account                     | 2026-02-02        | 8a0b12e7 |
| force-app | SecuritySettings         | Security                                                       | 2026-04-09        | 63b226c3 |

## Metode og avgrensingar

Dato er commit-tidspunktet (med tidssone) då endringa kom inn på første-parent-hovudlinja til main, ikkje nødvendigvis den opphavlege arbeidsbranch-datoen eller produksjonsdeploy-datoen.

Git-gjenkjenning av rename brukar 50 % likskap. Ei rename-linje er ikkje bevis for ei Salesforce API-namnendring. XML-sidefiler kan feilaktig bli kopla til ein heilt annan komponent; sjekk type, gammalt/nytt komponentnamn og commit. Sletting pluss oppretting med mykje endra innhald kan vere registrert som sletting, ikkje rename.

Alle slettingar og Git-gjenkjende renames på hovudlinja er med, og reine filflyttingar er skilde ut. Metadata frå feature-branches som vart sletta før innfletting på main er ikkje med.

Kandidatlista grupperer etter metadatatype og fullName, ikkje fil. Apex source/sidefil og LWC/Aura-bundles blir difor ikkje talde fleire gonger. Ei sletta bundle-fil tyder ikkje at heile bundlen er sletta. Komponentar som framleis finst ein annan stad i main, eller som er gjenoppretta, er ikkje oppryddingskandidatar. Objektfelt blir kvalifiserte med objektnamn.

Filnamn og Salesforce fullName kan avvike, særleg for mapper, rapportar, dashboards, statiske ressursar og historiske source-format. XML-innhald er ikkje brukt til å bekrefte alle fullName-verdiar. Kandidatane er ein kontrolliste, ikkje eit ferdig destructiveChanges-manifest.

Berre filnamn/filsti blir undersøkte, ikkje API-namn endra inne i uendra XML-filer eller enkeltmetadata fjerna frå samansette filer. Settings (til dømes SecuritySettings) skal vurderast som konfigurasjon, ikkje som ein vanleg slettbar komponent. Bundle-namn med berre endra bokstavstorleik krev særskild kontroll i org.

Referanse-/pakke-eigde mapper er med i eiga gruppe; desse komponentane kan vere eigde av avhengigheitspakker og skal ikkje slettast som Aa-registeret-opprydding utan eigaravklaring. Felt og objekt kan ha data, og metadata kan ha avhengigheiter som må kontrollerast før sletting.

force-app er ei kjelderot, ikkje bevis for at fila var inkludert i ein pakke eller produksjonsdeploy. Historiske forceignore-reglar, unpackagable-mapper og deploy-manifest kan ha halde metadata utanfor deploy. Komponentar frå avhengigheitspakker kan finnast i org sjølv om referansekjelda ikkje finst lokalt.

## Kontroll mot produksjon

Hent eit type/fullName-inventar frå produksjon gjennom ein godkjend read-only Metadata API-prosess etter eksplisitt org-godkjenning. Match inventaret mot kandidatlista; berre treff er bekrefta som framleis til stades. Bruk historiske deploy-resultat for å avklare om komponenten nokon gong vart deploya. Vanleg source deploy slettar ikkje automatisk gamle komponentar.

Følg [runbooken](salesforce-metadata-cleanup-runbook.md) for eigarskap, avhengigheiter, godkjenning og eventuell seinare destructive deployment. Denne rapporten autoriserer ingen org-endringar.

## Reprodusering

```bash
node scripts/audit-salesforce-metadata-history.cjs --self-test
node scripts/audit-salesforce-metadata-history.cjs d399afd8b42acad6d812c5835644d5de070f834d
```
