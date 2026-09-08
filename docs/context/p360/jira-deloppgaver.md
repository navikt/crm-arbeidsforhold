---
tittel: Deloppgåver i CRMAAREG
kilde: Jira — CRMAAREG (CSV-eksport av deloppgåver)
hentet: 2026-09-08
speilkopi: ja
merknad: Tildelte personar og account-ID-ar er utelatne ved speiling.
---

# Deloppgåver i CRMAAREG

Deloppgåver knytte til P360-integrasjonen. Prosjektet har også deloppgåver frå anna arbeid (kodeverk, e-postmalar, `EventAccess__c`); dei er samla nedst.

For historiene sjølve, sjå [jira/](jira/README.md). For status og avvik, sjå [jira-oversikt.md](jira-oversikt.md).

## Statusoversikt

| Epic | Historie   | Deloppgåver | Ferdig | Under arbeid | Backlog |
| ---- | ---------- | ----------- | ------ | ------------ | ------- |
| 83   | F1 · 84    | 4           | **4**  | 0            | 0       |
| 83   | F2 · 89    | 12          | **10** | 2            | 0       |
| 83   | F3 · 101   | 13          | 0      | 0            | 13      |
| 83   | F4 · 115   | 5           | 0      | 0            | 5       |
| 83   | F5 · 121   | 7           | 0      | 0            | 7       |
| 83   | F6 · 129   | 5           | 0      | 0            | 5       |
| 83   | F7 · 135   | 6           | 0      | 0            | 6       |
| 142  | K1 · 143   | 10          | 0      | 0            | 10      |
| 142  | K2 · 155   | 7           | 0      | 0            | 7       |
| 142  | K3 · 163   | 5           | 0      | 0            | 5       |
| 142  | K4 · 169   | 5           | 0      | 0            | 5       |
| 142  | K5 · 175   | 4           | 0      | 0            | 4       |
| 180  | S1 · 181   | 5           | 0      | 0            | 5       |
| 180  | S2 · 188   | 5           | 0      | 0            | 5       |
| 194  | C1 · 195   | 4           | 0      | 0            | 4       |
| 194  | C2 · 200   | 7           | 0      | 0            | 7       |
| 194  | C3 · 208   | 6           | 0      | 0            | 6       |
| 215  | J1 · 216   | 4           | 0      | 0            | 4       |
| 215  | J2 · 221   | 7           | 0      | 0            | 7       |
| 215  | J3 · 229   | 6           | 0      | 0            | 6       |
| 236  | FLS1 · 237 | 4           | 0      | 0            | 4       |
| 236  | FLS2 · 242 | 7           | 0      | 0            | 7       |
| 236  | FLS3 · 250 | 3           | 0      | 0            | 3       |
| 254  | X1 · 255   | 5           | 0      | 0            | 5       |
| 254  | X2 · 261   | 4           | 0      | 0            | 4       |
| 254  | X3 · 266   | 3           | 0      | 0            | 3       |
| 267  | R1 · 268   | 5           | 0      | 0            | 5       |
| 267  | R2 · 274   | 5           | 0      | 0            | 5       |
| 283  | O1 · 284   | 5           | 0      | 0            | 5       |
| 283  | O2 · 290   | 4           | 0      | 0            | 4       |
| 295  | T1 · 296   | 6           | 0      | 0            | 6       |
| 295  | T2 · 303   | 5           | 0      | 0            | 5       |
| 309  | D1 · 310   | 4           | 0      | 0            | 4       |
| 309  | D2 · 315   | 5           | 0      | 0            | 5       |

**14 av 197 deloppgåver er ferdige.** Alle ligg under F1 og F2.

---

## F1 · CRMAAREG-84 — Etablere integrasjonskontraktar og namnestandard

Alle fire ferdige 2026-04-24.

| Nøkkel      | Tittel                                             | Status |
| ----------- | -------------------------------------------------- | ------ |
| CRMAAREG-85 | Lage pakkestruktur og mappekonvensjon              | Ferdig |
| CRMAAREG-86 | Skrive designnotat for lagdeling                   | Ferdig |
| CRMAAREG-87 | Dokumentere namnestandard                          | Ferdig |
| CRMAAREG-88 | Lage oversikt over planlagde klassar og interfaces | Ferdig |

---

## F2 · CRMAAREG-89 — Opprette domeneinterfaces og service skeletons

Ti ferdige 2026-04-26. To under arbeid.

| Nøkkel       | Tittel                                                                      | Status           | Finst i repoet |
| ------------ | --------------------------------------------------------------------------- | ---------------- | -------------- |
| CRMAAREG-90  | Opprette `P360_IArchiveAdapter`                                             | Ferdig           | Ja             |
| CRMAAREG-91  | Opprette `P360_ArchiveAdapter`                                              | Ferdig           | Ja             |
| CRMAAREG-92  | Opprette `P360_StubArchiveAdapter`                                          | Ferdig           | Ja             |
| CRMAAREG-93  | Opprette `P360_IRpcClient`                                                  | Ferdig           | Ja             |
| CRMAAREG-94  | Opprette `P360_RpcClient` skeleton                                          | Ferdig           | Ja             |
| CRMAAREG-95  | Opprette `AAREG_ApplicationDomainService` skeleton                          | Ferdig           | Ja             |
| CRMAAREG-96  | Opprette `AAREG_AgreementDomainService` skeleton                            | Ferdig           | Ja             |
| CRMAAREG-97  | Opprette `AAREG_ArchiveApplicationOrchestrator` skeleton                    | Ferdig           | Ja             |
| CRMAAREG-98  | Opprette `AAREG_ArchiveApplicationCommand`                                  | Ferdig           | Ja             |
| CRMAAREG-99  | Opprette `AAREG_ArchiveApplicationResult`                                   | Ferdig           | Ja             |
| CRMAAREG-100 | Lage stub-metodar med dokumenterte signaturar og kontrollert exception      | **Under arbeid** | Delvis         |
| CRMAAREG-321 | Opprette minimale placeholder DTO-ar og exceptions for å støtte kompilering | **Under arbeid** | Delvis         |

### CRMAAREG-100 — beskriving frå Jira

Lage stub-metodar i skeleton-klassar som kastar definert `P360_ContractException` eller `P360_IntegrationException`.

Til dømes i Apex:

```apex
public with sharing class P360_ArchiveAdapter implements P360_IArchiveAdapter {
    public P360_ArchiveResponseDto archive(P360_ArchiveRequestDto request) {
        throw new P360_ContractException('P360_ArchiveAdapter.archive is not implemented yet.');
    }
}
```

> Dette er den einaste deloppgåva med kodedøme i Jira. Namngivinga følgjer namnestandarden.

### CRMAAREG-321 — placeholder-oppgåva

Denne forklarer kvifor `P360_IntegrationException`, `P360_ContractException` og `P360_TransportException` er tomme `extends Exception` med kommentaren `TODO F5`. Dei er medvitne placeholders for å få F2 til å kompilere, ikkje ferdig arbeid.

---

## F3 · CRMAAREG-101 — DTO-ar og interne Apex data classes

| Nøkkel       | Tittel                                    |
| ------------ | ----------------------------------------- |
| CRMAAREG-102 | Lage `SalesforceCaseContext`              |
| CRMAAREG-103 | Lage `SalesforceJournalpostContext`       |
| CRMAAREG-104 | Lage `SalesforceJournalpostUpdateContext` |
| CRMAAREG-105 | Lage `SalesforceDocumentFile`             |
| CRMAAREG-106 | Lage `P360CreateCaseRequest/Response`     |
| CRMAAREG-107 | Lage `P360UpdateCaseRequest/Response`     |
| CRMAAREG-108 | Lage `P360GetCasesRequest/Response`       |
| CRMAAREG-109 | Lage `P360CreateDocumentRequest/Response` |
| CRMAAREG-110 | Lage `P360UpdateDocumentRequest/Response` |
| CRMAAREG-111 | Lage `P360GetDocumentsRequest/Response`   |
| CRMAAREG-112 | Lage `P360ExternalId`                     |
| CRMAAREG-113 | Lage `P360FileParameter`                  |
| CRMAAREG-114 | Lage test for JSON serialisering          |

> **Avvik:** Ingen av namna følgjer namnestandarden. Manglar underscore, og DTO-ane manglar `Dto`-suffikset som ADR-0001 krev. Skal truleg vere `P360_CreateCaseRequestDto` osv. Sjå GitHub-sak #994.

> **Nye P360-operasjonar:** `CreateCase`, `UpdateCase`, `GetCases`, `CreateDocument`, `UpdateDocument`, `GetDocuments`. Sjå GitHub-sak #995.

---

## F4 · CRMAAREG-115 — Omformar (mapper) skeletons

| Nøkkel       | Tittel                                         |
| ------------ | ---------------------------------------------- |
| CRMAAREG-116 | Opprette `P360CaseMapper`                      |
| CRMAAREG-117 | Opprette `P360JournalpostMapper`               |
| CRMAAREG-118 | Opprette `P360FileMapper`                      |
| CRMAAREG-119 | Dokumentere opne mapping-avklaringar           |
| CRMAAREG-120 | Lage test skeleton for omformarane (mapperane) |

> **Avvik:** Namnestandarden seier at mapperar forankra i Aa-registeret-use case skal ha `AAREG_`-prefiks, og at mønsteret er `AAREG_<Source>To<Target>Mapper`. Desse har `P360`-prefiks utan underscore. Sjå GitHub-sak #994.

---

## F5 · CRMAAREG-121 — Exception hierarchy og feilmodell

| Nøkkel       | Tittel                                      |
| ------------ | ------------------------------------------- |
| CRMAAREG-122 | Lage `P360IntegrationException`             |
| CRMAAREG-123 | Lage `P360AuthenticationException`          |
| CRMAAREG-124 | Lage `P360ValidationException`              |
| CRMAAREG-125 | Lage `P360TimeoutException`                 |
| CRMAAREG-126 | Lage `P360RetryableException`               |
| CRMAAREG-127 | Lage `P360MissingCodeTableMappingException` |
| CRMAAREG-128 | Dokumentere bruksmønster                    |

> **Kritisk avvik.** Dette er eit tredje exception-sett, ulikt både ADR-0001 og koden som finst. `P360_IntegrationException` finst allereie i repoet med underscore — deloppgåva ber om `P360IntegrationException` utan. Sjå GitHub-sak #993.

> `P360RetryableException` som eigen klasse svarer på det opne spørsmålet i #993 om korleis retrybarheit skal uttrykkjast — men det er ikkje forankra i ADR-0001.

---

## F6 · CRMAAREG-129 — Logging helper og correlation ID

| Nøkkel       | Tittel                                       |
| ------------ | -------------------------------------------- |
| CRMAAREG-130 | Lage `CorrelationIdProvider`                 |
| CRMAAREG-131 | Lage `IntegrationLogger`                     |
| CRMAAREG-132 | Definere struktur for loggfelt               |
| CRMAAREG-133 | Lage test for vidareføring av correlation ID |
| CRMAAREG-134 | Dokumentere maskering av sensitive felt      |

> Desse to klassenamna er dei einaste som følgjer standarden — generelle integrasjonsklassar utan domeneprefiks. Men ADR-0001 kallar dei `CorrelationContext` og `IntegrationLogContext`. Ulike namn, same formål.

---

## F7 · CRMAAREG-135 — Mock/fake services og basis test classes

| Nøkkel       | Tittel                            |
| ------------ | --------------------------------- |
| CRMAAREG-136 | Lage `FakeP360CaseService`        |
| CRMAAREG-137 | Lage `FakeP360JournalpostService` |
| CRMAAREG-138 | Lage `FakeP360FileService`        |
| CRMAAREG-139 | Lage `FakeP360CodeTableService`   |
| CRMAAREG-140 | Lage `BaseIntegrationTest`        |
| CRMAAREG-141 | Lage test data builders           |

> ADR-0001 nemner `P360_StubArchiveAdapter` som stub-mønster. Denne oppgåva brukar `Fake`-prefiks i staden. Stub og fake er ulike testdoublar, men det er uklart om skilnaden er meint.

---

## K1 · CRMAAREG-143 — Custom Metadata-modell

| Nøkkel       | Tittel                             |
| ------------ | ---------------------------------- |
| CRMAAREG-144 | Opprette `P360CodeTableValue__mdt` |
| CRMAAREG-145 | Opprette felt for table name       |
| CRMAAREG-146 | Opprette felt for Salesforce key   |
| CRMAAREG-147 | Opprette felt for language code    |
| CRMAAREG-148 | Opprette felt for P360 code        |
| CRMAAREG-149 | Opprette felt for P360 recno       |
| CRMAAREG-150 | Opprette felt for transport value  |
| CRMAAREG-151 | Opprette felt for display label    |
| CRMAAREG-152 | Opprette felt for active           |
| CRMAAREG-153 | Opprette felt for sort order       |
| CRMAAREG-154 | Dokumentere metadata-modellen      |

> **Avvik:** Designnotatet skriv `P360_Code_Table_Value.<record>.md-meta.xml`. Deloppgåva skriv `P360CodeTableValue__mdt`. Ulik namngiving på same metadata-type.

> Deloppgåvene gir ti konkrete felt — fleire enn dei fire historia nemner. `transport value` og `sort order` er nye.

---

## K2 · CRMAAREG-155 — Metadata-basert code table service

| Nøkkel       | Tittel                               |
| ------------ | ------------------------------------ |
| CRMAAREG-156 | Lage `P360CodeTableRow`              |
| CRMAAREG-157 | Lage `IP360CodeTableService`         |
| CRMAAREG-158 | Lage `P360CodeTableMetadataService`  |
| CRMAAREG-159 | Lage per-transaksjon-cache           |
| CRMAAREG-160 | Lage exception ved manglande mapping |
| CRMAAREG-161 | Lage test for metadata-oppslag       |
| CRMAAREG-162 | Lage test for manglande mapping      |

> Per-transaksjon-cache (CRMAAREG-159) er ikkje nemnd i historia eller i noko Confluence-dokument. Det er ei reell designavgjerd som ikkje er forankra.

---

## K3 · CRMAAREG-163 — Dependency injection / service locator

| Nøkkel       | Tittel                                                      |
| ------------ | ----------------------------------------------------------- |
| CRMAAREG-164 | Lage `P360ServiceLocator`                                   |
| CRMAAREG-165 | Lage `@TestVisible` injection hooks                         |
| CRMAAREG-166 | Oppdatere `P360CaseMapper` til constructor injection        |
| CRMAAREG-167 | Oppdatere `P360JournalpostMapper` til constructor injection |
| CRMAAREG-168 | Lage eksempeltest med fake adapter                          |

> **Svarer delvis på GitHub-sak #996.** Deloppgåva vel `P360ServiceLocator` — ikkje `P360_AdapterFactory` frå designnotatet. To ulike mønster for same formål, begge dokumenterte, ingen valt.

> Merk at `P360_ArchiveAdapter` som finst i repoet allereie brukar constructor injection.

---

## K4 · CRMAAREG-169 — Laste initiale kodeverk-verdiar

| Nøkkel       | Tittel                                        |
| ------------ | --------------------------------------------- |
| CRMAAREG-170 | Leggje inn initiale case status-verdiar       |
| CRMAAREG-171 | Leggje inn initiale document status-verdiar   |
| CRMAAREG-172 | Leggje inn initiale document category-verdiar |
| CRMAAREG-173 | Dokumentere opphav og eigarskap til verdiane  |
| CRMAAREG-174 | Lage endringsprosess for nye metadata-verdiar |

---

## K5 · CRMAAREG-175 — RPC-basert code table adapter (fase 2+)

| Nøkkel       | Tittel                                                  |
| ------------ | ------------------------------------------------------- |
| CRMAAREG-176 | Lage designnotat for RPC-adapter                        |
| CRMAAREG-177 | Dokumentere konfigurasjonsbehov                         |
| CRMAAREG-178 | Dokumentere feltmapping mellom metadata og RPC-resultat |
| CRMAAREG-179 | Lage backlog-punkt for seinare implementasjon           |

---

## S1 · CRMAAREG-181 — Named Credential / auth-strategi

| Nøkkel       | Tittel                                       |
| ------------ | -------------------------------------------- |
| CRMAAREG-182 | Avklare faktisk endpoint-auth-mønster        |
| CRMAAREG-183 | Opprette Named Credential eller tilsvarande  |
| CRMAAREG-184 | Opprette Custom Metadata for endpoint-konfig |
| CRMAAREG-185 | Implementere auth header builder             |
| CRMAAREG-186 | Implementere auth-feilhandtering             |
| CRMAAREG-187 | Dokumentere miljøkonfig                      |

> **Raud sone.** CRMAAREG-182 er den som faktisk lukkar det opne spørsmålet i `Overordnet rammeverk` om header- og feltnamn for AuthKey og ClientID.

---

## S2 · CRMAAREG-188 — Integrasjonsbrukar, tilgang og audit

| Nøkkel       | Tittel                               |
| ------------ | ------------------------------------ |
| CRMAAREG-189 | Definere integrasjonsbrukar-prinsipp |
| CRMAAREG-190 | Definere audit-hendingar             |
| CRMAAREG-191 | Definere maskering i logg            |
| CRMAAREG-192 | Dokumentere forventa sporbarheit     |
| CRMAAREG-193 | Oppdatere DoD med sikkerheitskrav    |

> **Raud sone.** CRMAAREG-193 endrar Definition of Done for heile teamet — det er ei prosessendring, ikkje berre teknisk arbeid.

---

## C1 · CRMAAREG-195 — Forretningsreglar for sak

| Nøkkel       | Tittel                              |
| ------------ | ----------------------------------- |
| CRMAAREG-196 | Workshop på triggerreglar           |
| CRMAAREG-197 | Avklare autoritativ kjelde per felt |
| CRMAAREG-198 | Dokumentere obligatoriske felt      |
| CRMAAREG-199 | Oppdatere omformer(mapper)-TODO-ar  |

---

## C2 · CRMAAREG-200 — Opprette P360-sak frå Salesforce

| Nøkkel       | Tittel                                       |
| ------------ | -------------------------------------------- |
| CRMAAREG-201 | Implementere validering for case create      |
| CRMAAREG-202 | Implementere mapping til create case request |
| CRMAAREG-203 | Implementere RPC-klientkall                  |
| CRMAAREG-204 | Parse respons og lagre eksterne ID-ar        |
| CRMAAREG-205 | Logge start, slutt og feil                   |
| CRMAAREG-206 | Lage unit-testar                             |
| CRMAAREG-207 | Lage feiltestar                              |

---

## C3 · CRMAAREG-208 — Oppdatere P360-sak

| Nøkkel       | Tittel                             |
| ------------ | ---------------------------------- |
| CRMAAREG-209 | Definere oppdaterbare felt         |
| CRMAAREG-210 | Implementere delta-sjekk           |
| CRMAAREG-211 | Implementere update mapping        |
| CRMAAREG-212 | Implementere update RPC-kall       |
| CRMAAREG-213 | Lage test for ingen-endring        |
| CRMAAREG-214 | Lage test for manglande ekstern ID |

---

## J1 · CRMAAREG-216 — Forretningsreglar for journalpost

| Nøkkel       | Tittel                                                      |
| ------------ | ----------------------------------------------------------- |
| CRMAAREG-217 | Kartleggje obligatoriske metadatafelt                       |
| CRMAAREG-218 | Avklare sender/mottakar-reglar per kategori                 |
| CRMAAREG-219 | Avklare journaldato, dokumentdato og dispatched date-reglar |
| CRMAAREG-220 | Dokumentere mappingreglar                                   |

> `dispatched date` er eit nytt P360-omgrep som ikkje er forklart nokon stad. Sjå GitHub-sak #995.

---

## J2 · CRMAAREG-221 — Opprette journalpost via DocumentService

| Nøkkel       | Tittel                                               |
| ------------ | ---------------------------------------------------- |
| CRMAAREG-222 | Implementere journalpost-validering                  |
| CRMAAREG-223 | Implementere mapping til `P360CreateDocumentRequest` |
| CRMAAREG-224 | Implementere RPC-klient for `CreateDocument`         |
| CRMAAREG-225 | Parse respons og lagre document ID-ar                |
| CRMAAREG-226 | Implementere logging                                 |
| CRMAAREG-227 | Lage unit-testar                                     |
| CRMAAREG-228 | Lage feiltestar                                      |

---

## J3 · CRMAAREG-229 — Oppdatere journalpostmetadata

| Nøkkel       | Tittel                                               |
| ------------ | ---------------------------------------------------- |
| CRMAAREG-230 | Definere oppdaterbare metadatafelt                   |
| CRMAAREG-231 | Implementere delta-sjekk                             |
| CRMAAREG-232 | Implementere mapping til `P360UpdateDocumentRequest` |
| CRMAAREG-233 | Implementere RPC-kall                                |
| CRMAAREG-234 | Lage test for oppdatering                            |
| CRMAAREG-235 | Lage test for ingen-endring                          |

---

## FLS1 · CRMAAREG-237 — Filstrategi for MVP

| Nøkkel       | Tittel                                         |
| ------------ | ---------------------------------------------- |
| CRMAAREG-238 | Kartleggje kjelde for dokumentfil i Salesforce |
| CRMAAREG-239 | Dokumentere MVP-strategi                       |
| CRMAAREG-240 | Avklare storleiksgrenser                       |
| CRMAAREG-241 | Dokumentere konverteringsansvar                |

---

## FLS2 · CRMAAREG-242 — Leggje til filer på dokument

| Nøkkel       | Tittel                                                     |
| ------------ | ---------------------------------------------------------- |
| CRMAAREG-243 | Implementere filvalidering                                 |
| CRMAAREG-244 | Implementere mapping til file payload                      |
| CRMAAREG-245 | Implementere RPC-klient for fil eller dokument-oppdatering |
| CRMAAREG-246 | Lagra kvittering / ekstern fil-ID                          |
| CRMAAREG-247 | Lage test for ugyldig filtype                              |
| CRMAAREG-248 | Lage test for stor fil                                     |
| CRMAAREG-249 | Lage test for timeout                                      |

---

## FLS3 · CRMAAREG-250 — Store filer (fase 2+)

| Nøkkel       | Tittel                               |
| ------------ | ------------------------------------ |
| CRMAAREG-251 | Dokumentere seinare storfil-strategi |
| CRMAAREG-252 | Lage backlog for `UploadStream`      |
| CRMAAREG-253 | Dokumentere operasjonelle risikoar   |

---

## X1 · CRMAAREG-255 — External ID strategy

| Nøkkel       | Tittel                                      |
| ------------ | ------------------------------------------- |
| CRMAAREG-256 | Definere external ID format for case        |
| CRMAAREG-257 | Definere external ID format for journalpost |
| CRMAAREG-258 | Definere external ID format for file        |
| CRMAAREG-259 | Definere Salesforce-felt for lagring        |
| CRMAAREG-260 | Dokumentere naming av type/system           |

---

## X2 · CRMAAREG-261 — Lookup basert på lagra eksterne ID-ar

| Nøkkel       | Tittel                               |
| ------------ | ------------------------------------ |
| CRMAAREG-262 | Lage local lookup utility            |
| CRMAAREG-263 | Definere lagringsmodell for status   |
| CRMAAREG-264 | Lage feilhandtering for manglande ID |
| CRMAAREG-265 | Lage test for retry og gjenopptaking |

---

## X3 · CRMAAREG-266 — Recovery-oppslag (fase 2+)

| Nøkkel       | Tittel                                  |
| ------------ | --------------------------------------- |
| CRMAAREG-280 | Dokumentere design for recovery-oppslag |
| CRMAAREG-281 | Lage backlog for RPC-adapter            |
| CRMAAREG-282 | Dokumentere fallback-scenario           |

---

## R1 · CRMAAREG-268 — Idempotens

| Nøkkel       | Tittel                                    |
| ------------ | ----------------------------------------- |
| CRMAAREG-269 | Definere idempotensnøkkel for case        |
| CRMAAREG-270 | Definere idempotensnøkkel for journalpost |
| CRMAAREG-271 | Implementere kontroll før create          |
| CRMAAREG-272 | Implementere duplikatrespons-handtering   |
| CRMAAREG-273 | Lage test for retry                       |

---

## R2 · CRMAAREG-274 — Retry-strategi og manuell oppfølging

| Nøkkel       | Tittel                                  |
| ------------ | --------------------------------------- |
| CRMAAREG-275 | Klassifisere feiltypar                  |
| CRMAAREG-276 | Definere retrypolicy                    |
| CRMAAREG-277 | Definere status for feila integrasjonar |
| CRMAAREG-278 | Dokumentere manuell re-køyring          |
| CRMAAREG-279 | Lage operasjonell test                  |

> CRMAAREG-275 overlappar direkte med F5. Sjå GitHub-sak #993.

---

## O1 · CRMAAREG-284 — Strukturert logging

| Nøkkel       | Tittel                         |
| ------------ | ------------------------------ |
| CRMAAREG-285 | Instrumentere case-flyt        |
| CRMAAREG-286 | Instrumentere journalpost-flyt |
| CRMAAREG-287 | Instrumentere file-flyt        |
| CRMAAREG-288 | Verifisere maskering           |
| CRMAAREG-289 | Dokumentere loggstruktur       |

---

## O2 · CRMAAREG-290 — Overvaking, alarmar og runbook

| Nøkkel       | Tittel                        |
| ------------ | ----------------------------- |
| CRMAAREG-291 | Definere alarmkriterium       |
| CRMAAREG-292 | Dokumentere runbook           |
| CRMAAREG-293 | Definere eigarskap for støtte |
| CRMAAREG-294 | Lage feilsøkingsguide         |

> **Svarer på GitHub-sak #997.** CRMAAREG-292 «Dokumentere runbook» ligg her, ikkje under D2. Men D2 har òg CRMAAREG-317 «Skrive feilsøkingsguide» — same tittel som CRMAAREG-294 her. To deloppgåver, to epicar, same arbeid.

---

## T1 · CRMAAREG-296 — Einingstestar og kontraktstestar

| Nøkkel       | Tittel                           |
| ------------ | -------------------------------- |
| CRMAAREG-297 | Lage test for case mapper        |
| CRMAAREG-298 | Lage test for journalpost mapper |
| CRMAAREG-299 | Lage test for file mapper        |
| CRMAAREG-300 | Lage test for code table service |
| CRMAAREG-301 | Lage test for exceptions         |
| CRMAAREG-302 | Lage test for serialisering      |

---

## T2 · CRMAAREG-303 — Integrasjonstest mot miljø

| Nøkkel       | Tittel                          |
| ------------ | ------------------------------- |
| CRMAAREG-304 | Definere E2E-scenario           |
| CRMAAREG-305 | Lage testdata                   |
| CRMAAREG-306 | Køyre integrasjonstest          |
| CRMAAREG-307 | Verifisere lagra eksterne ID-ar |
| CRMAAREG-308 | Dokumentere avvik og funn       |

---

## D1 · CRMAAREG-310 — Arkitektur, sekvensar og tekniske val

| Nøkkel       | Tittel                       |
| ------------ | ---------------------------- |
| CRMAAREG-311 | Lage komponentdiagram        |
| CRMAAREG-312 | Lage sekvensdiagram          |
| CRMAAREG-313 | Dokumentere adaptermønsteret |
| CRMAAREG-314 | Skrive ADR-ar                |

---

## D2 · CRMAAREG-315 — Drift, støtte og overlevering

| Nøkkel       | Tittel                              |
| ------------ | ----------------------------------- |
| CRMAAREG-316 | Skrive driftsguide                  |
| CRMAAREG-317 | Skrive feilsøkingsguide             |
| CRMAAREG-318 | Dokumentere re-køyring              |
| CRMAAREG-319 | Dokumentere fase 2 og teknisk gjeld |
| CRMAAREG-320 | Gjennomføre overleveringsmøte       |

---

## Deloppgåver utanfor P360-arbeidet

Desse høyrer til andre historier i `CRMAAREG` og er tekne med for fullstendigheit.

| Nøkkel       | Tittel                                           | Historie                  | Status                  |
| ------------ | ------------------------------------------------ | ------------------------- | ----------------------- |
| CRMAAREG-3   | Kartlegg påverka felt, valideringar og templates | CRMAAREG-2 Kodeverk       | Ferdig                  |
| CRMAAREG-4   | Oppdater metadata/kodeverk i Salesforce          | CRMAAREG-2                | Ferdig                  |
| CRMAAREG-5   | Migrere eksisterande data der nødvendig          | CRMAAREG-2                | Ferdig (Repareres ikke) |
| CRMAAREG-6   | Regresjonstest i stage; oppdater dokumentasjon   | CRMAAREG-2                | Ferdig                  |
| CRMAAREG-51  | Venter på tilbakemelding fra bruker epostmal     | CRMAAREG-9 Brotne lenkjer | Ferdig                  |
| CRMAAREG-52  | Søknad er sendt inn — epostvarsel                | CRMAAREG-9                | Ferdig                  |
| CRMAAREG-53  | Vedtaks-epost                                    | CRMAAREG-9                | Ferdig                  |
| CRMAAREG-54  | Søknaden er henlagt etter avtale                 | CRMAAREG-9                | Ferdig                  |
| CRMAAREG-55  | Brukerhenvendelses-epost                         | CRMAAREG-9                | Ferdig                  |
| CRMAAREG-322 | Fjerne                                           | CRMAAREG-9                | Ferdig                  |
| CRMAAREG-57  | Fjerne referanse til `EventAccess__c` i LWC      | CRMAAREG-56               | Ferdig                  |
| CRMAAREG-58  | Fjerne feltet frå `Application__c`               | CRMAAREG-56               | Ferdig                  |
| CRMAAREG-60  | Fjerne flow `AAREG_updateDecisionText`           | CRMAAREG-59 Opprydding    | Backlog                 |
| CRMAAREG-64  | Fjerne skedulert jobb `AAREG_ArchiveScheduler`   | CRMAAREG-59               | Ferdig                  |
| CRMAAREG-61  | Visualisering av søknadsprosessen                | CRMAAREG-44 Dokumentasjon | Backlog                 |
| CRMAAREG-62  | Dokumentasjon av Altinn-integrasjonen            | CRMAAREG-44               | Ferdig                  |
| CRMAAREG-63  | Dokumentasjon av kodeverket                      | CRMAAREG-44               | Ferdig                  |
| CRMAAREG-65  | Dokumentasjon av tilgangsstyring                 | CRMAAREG-44               | Under arbeid            |
| CRMAAREG-72  | Rapporter 1                                      | CRMAAREG-71 Rapportering  | Backlog                 |

### Confluence-URL-ar funne i kommentarar

| Dokument                              | URL                                                      |
| ------------------------------------- | -------------------------------------------------------- |
| Kodeverk                              | `https://confluence.adeo.no/spaces/TAF/pages/760449869/` |
| Innlogging via Maskinporten og Altinn | `https://confluence.adeo.no/spaces/TAF/pages/760449867/` |

Nyttig for GitHub-sak #984 og for Altinn-dokumentasjon.

## Merknader ved speiling

- Tildelte personar, rapportørar og account-ID-ar er utelatne. Sjå GitHub-sak #990.
- Kommentarar med skjermbilete, e-postmalinnhald og personnamn frå oppgåvene utanfor P360-arbeidet er ikkje kopierte inn.
- CRMAAREG-58 har ein svært lang kommentar med full `grep`-utskrift av `EventAccess__c`-referansar. Den er ikkje teken med.
