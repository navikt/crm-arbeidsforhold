# Kjeldeinventar for Arbeidsforhold / Aa-registeret

**Status:** pågåande arbeid under [GitHub Issue #1185](https://github.com/navikt/crm-arbeidsforhold/issues/1185).  
**Inventert:** 2026-11-14 frå lokal arbeidskopi.  
**Avgrensing:** statisk kjeldestruktur og deklarerte dependencies; ikkje fersk Salesforce-org-tilstand eller full funksjonsdekning.

## Produkt- og pakkegrep

`sfdx-project.json` definerer `force-app` som produktpakken `crm-arbeidsforhold` og har 19 direkte dependencies. `src-temp` er ei eiga standardkildemappe, men ikkje ei av dei 19 dependencies. Alle 19 direkte dependency-mapper finst lokalt og har ei `README.md`. Etter prosjektreglane er dei pakkeeigde referansekjelder: dei skal lesast for forståing, ikkje endrast utan godkjenning frå eigar.

### Direkte dependencies i manifestet

| Pakke                           | Deklarert versjon | Lokal kjelde/README |
| ------------------------------- | ----------------- | ------------------- |
| `platform-data-model`           | `0.1.49.LATEST`   | Finst               |
| `custom-metadata-dao`           | `0.1.49.LATEST`   | Finst               |
| `custom-permission-helper`      | `0.1.49.LATEST`   | Finst               |
| `feature-toggle`                | `0.1.50.LATEST`   | Finst               |
| `record-type-cache`             | `0.1.17.LATEST`   | Finst               |
| `crm-platform-base`             | `0.311.0.LATEST`  | Finst               |
| `crm-platform-reporting`        | `0.47.0.LATEST`   | Finst               |
| `crm-shared-flowComponents`     | `0.4.0.LATEST`    | Finst               |
| `crm-henvendelse-base`          | `0.42.0.LATEST`   | Finst               |
| `crm-platform-integration`      | `0.177.0.LATEST`  | Finst               |
| `crm-platform-access-control`   | `0.179.0.LATEST`  | Finst               |
| `crm-thread-view`               | `0.8.0.LATEST`    | Finst               |
| `crm-shared-timeline`           | `1.45.0.LATEST`   | Finst               |
| `crm-community-base`            | `0.146.0.LATEST`  | Finst               |
| `crm-platform-email-scheduling` | `1.8.0.LATEST`    | Finst               |
| `crm-journal-utilities`         | `0.55.0.LATEST`   | Finst               |
| `crm-shared-user-notification`  | `0.27.0.LATEST`   | Finst               |
| `crm-platform-oppgave`          | `0.84.0.LATEST`   | Finst               |
| `crm-henvendelse`               | `0.209.0.LATEST`  | Finst               |

Dette er manifestversjonar, ikkje installerte org-versjonar. [Pakkeoversikta](pakkeavhengigheiter.md) dokumenterer ei tidlegare løysing frå 2026-10-24; til dømes er manifestet no `crm-platform-integration 0.177.0.LATEST`, medan den daterte rapporten viser `0.176.0.1`. Behald dette som skilnad mellom dagens manifest og historisk rapport til godkjend runtime-oppslag stadfestar installert versjon.

## Strukturelt inventar av `force-app/`

Tala er rekna med rekursiv lokal filoppteljing 2026-11-14. Dei uttrykkjer kjeldestorleik, ikkje funksjonsdekning eller testdekning.

| Område                               |    Filer | Første tolking                                                                                          |
| ------------------------------------ | -------: | ------------------------------------------------------------------------------------------------------- |
| Rotfil (`.DS_Store`)                 |        1 | Lokal fil på operativsystemnivå; ta med i oppryddingsvurderinga, men ikkje fjern utan eiga avgjerd.     |
| `main/`                              |      611 | Felles `main/default`-metadata, mellom anna Flow, LWC og delt konfigurasjon.                            |
| `integration/`                       |      280 | P360, Altinn, distribusjonstilgang og felles integrasjonskode.                                          |
| `tests/`                             |      143 | Sentralt organiserte Apex-testar og testdatafabrikkar.                                                  |
| `unpackagable/`                      |       94 | Særskild legacy-/pakkingsoverflate; må klassifiserast for eigarskap og distribusjonsbruk før endringar. |
| `externalApplication/`               |       28 | Ekstern søknadsflate.                                                                                   |
| `externalAgreement/`                 |       27 | Ekstern avtalesyning og avtalehandlingar.                                                               |
| `externalAccess/`                    |       25 | Ekstern verksemds- og tilgangsflate.                                                                    |
| `internalApplication/`               |       25 | Intern søknadsbehandling.                                                                               |
| `internalApplicationDecision/`       |       24 | Intern avgjerdsbehandling.                                                                              |
| `dialog/`                            |       11 | Dialog-/henvendingscontrollerar og metadata.                                                            |
| `internalApplicationAgreement/`      |       12 | Intern avtaleoppfølging.                                                                                |
| `aareg_CodeBaseList/`                |        9 | Aura-komponent/controller for kodeverk.                                                                 |
| `utility/`                           |       14 | Delte hjelpeklassar.                                                                                    |
| `externalApplicationDecision/`       |        4 | Ekstern avgjerdsflate.                                                                                  |
| `aareg_ApplicationDecisionInternal/` |        1 | Eitt særskilt internavgjerdsområde.                                                                     |
| `aareg_ApplicationInternal/`         |        1 | Eitt særskilt internt søknadsområde.                                                                    |
| **Totalt**                           | **1310** | Alle filtypar under `force-app/`.                                                                       |

Utvalde filtype-/testmengder frå same rekursive inventar:

| Type                                                   | Tal |
| ------------------------------------------------------ | --: |
| Apex-klasser (`.cls`)                                  | 208 |
| Apex-triggarar (`.trigger`)                            |   2 |
| Flow-definisjonar (`.flow-meta.xml`)                   |  37 |
| JavaScript under `lwc/` (`.js`, inkluderer Jest-filer) |  30 |
| LWC-HTML (`.html` under `lwc/`)                        |  21 |
| Apex-testklasser med namn som sluttar på `Test`        |  93 |
| Jest-filer med `.test.js`                              |   7 |

## Produktområde som skal sporast til konkrete inngangar

Dette er ei første gruppering frå eksisterande kjeldekart og mappestruktur; han er ikkje godkjend funksjonsinventar enno.

| Område                                    | Kjeldespor                                                                               | Inventar som står att                                                                                                                              |
| ----------------------------------------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ekstern identitet og organisasjonstilgang | `externalAccess/`, `integration/altinn/`                                                 | Alle inngangar, ressursrettar, brukar-/organisasjonsbyte og feilsvar knytte til konkret testbevis.                                                 |
| Søknad, utkast og vedlegg                 | `externalApplication/`, søknadsrelaterte Flow i `main/`                                  | Alle UI-handlingar, Apex-kontraktar, validering, filkoplingar og state transitions.                                                                |
| Intern saksbehandling og avgjerd          | `internalApplication/`, `internalApplicationDecision/`, Flow og PDF-service              | Kvar avgjerdstype, statusovergang, eigarskap, dokument og feilbane.                                                                                |
| Avtale og distribusjonstilgang            | `externalAgreement/`, `internalApplicationAgreement/`, `integration/distributionAccess/` | Avtaleendringar, tilgangsflagga, invocable/asynkrone utfall og rollback.                                                                           |
| Dialog og støtte                          | `dialog/`, `main/default/lwc/` og tilknytt Flow                                          | Inquiry/Thread/Message-livssyklus, eigarskap, filkopling, varsling og tilgang.                                                                     |
| P360                                      | `integration/p360/` og P360-spesifikasjonar/Issues                                       | Skil implementert jobbinfrastruktur frå godkjende forretningshendingar og reell ekstern transport. Arbeid held fram i #1095 og tilhøyrande Issues. |
| Delte plattformfunksjonar                 | `utility/`, `main/default/`, 19 dependencies                                             | Knyt kvar brukt pakke-API/metadata til konkret call-site og test; ikkje utlei bruk frå pakke-README åleine.                                        |

Eksisterande [heile-løysinga-kart](hele-loysinga.md), [kjeldekart/teststrategi](arbeidsforhold-kjeldekart-og-teststrategi.md), [Flow-katalog](aareg-flow-katalog.md) og [Flow-diagram](aareg-flow-diagrammer.md) er viktige kjelder. Dei erstattar ikkje kontroll av kvar call-site, test eller org-tilstand.

## Evidens og uavklarte punkt

- **Lokalt stadfesta:** produktpakke-path, 19 deklarerte dependency-namn/versjonar, at alle dependency-mappene og README-filene finst, dei rekursive fil-/testtala ovanfor og 37 Flow-kjelde-definisjonar.
- **Frå eksisterande dokument:** roller for dependencies, arbeidsflytmodellar, Flow-samandrag og tidlegare scenarioforslag. Nokre org-funn i dokumenta er daterte og historiske.
- **Ikkje stadfesta i denne arbeidsøkta:** installerte pakkeversjonar, effektiv brukarrett, aktiv org-Flow-versjon, scheduler-status, runtime-kall per funksjon, kva kvar dependency-API blir brukt til, og faktisk testdekning per forretningsscenario.
- **Neste steg i #1185:** bygg full call-site-matrise for dei 19 dependency-pakkane; kartlegg kvar Apex/LWC/Flow/metadata-inngang til brukarhandling, data, permission og test; reconciler eksisterande dokumentasjon og marker dekning/gap.
- **Org-status:** ingen Salesforce-org-kommando er køyrd for dette inventaret. Nye oppslag i eksisterande `crm-arbeidsforhold` scratch-org krev verifisering av eksplisitt mål og scratch-type, men ikkje ny brukargodkjenning. Andre ikkje-produksjonsorg krev fersk mål-/handlingsgodkjenning etter `AGENTS.md`; produksjon er forbode.
