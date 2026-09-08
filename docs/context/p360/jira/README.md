---
tittel: Jira-saker for P360-integrasjonen
kilde: Jira — CRMAAREG (CSV-eksport + XML per epic)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-83
hentet: 2026-09-08
speilkopi: ja
merknad: Tildelte personar og account-ID-ar er utelatne ved speiling.
---

# Jira-saker for P360-integrasjonen

Full tekst for alle epicar og historier i `CRMAAREG`, slik at innhaldet er tilgjengeleg utan Jira-tilgang.

Éi fil per epic. Kvar historie er ei underoverskrift og kan lenkjast direkte.

For status, prioritet, avhengigheiter og avviksanalyse, sjå [jira-oversikt.md](../jira-oversikt.md).

## Epicar

| Fil                                   | Epic         | Tittel                                             | Historier |
| ------------------------------------- | ------------ | -------------------------------------------------- | --------- |
| [83](crmaareg-83-teknisk-grunnmur.md) | CRMAAREG-83  | Teknisk grunnmur og integrasjonskontraktar         | F1–F7     |
| [142](crmaareg-142-kodeverk.md)       | CRMAAREG-142 | Kodeverk, metadata-adapter og dependency injection | K1–K5     |
| [180](crmaareg-180-sikkerheit.md)     | CRMAAREG-180 | Sikkerheit, autentisering og konfigurasjon         | S1–S2     |
| [194](crmaareg-194-sakssynk.md)       | CRMAAREG-194 | Sakssynk mellom Salesforce og P360                 | C1–C3     |
| [215](crmaareg-215-journalpost.md)    | CRMAAREG-215 | Journalpost som document metadata-flyt             | J1–J3     |
| [236](crmaareg-236-filhandtering.md)  | CRMAAREG-236 | Filhandtering og vedleggsflyt                      | FLS1–FLS3 |
| [254](crmaareg-254-external-id.md)    | CRMAAREG-254 | External ID-strategi og oppslag                    | X1–X3     |
| [267](crmaareg-267-feilhandtering.md) | CRMAAREG-267 | Feilhåndtering, idempotens og retry                | R1–R2     |
| [283](crmaareg-283-logging.md)        | CRMAAREG-283 | Logging, overvaking og drift                       | O1–O2     |
| [295](crmaareg-295-test.md)           | CRMAAREG-295 | Test, kvalitet og verifikasjon                     | T1–T2     |
| [309](crmaareg-309-dokumentasjon.md)  | CRMAAREG-309 | Arkitektur, dokumentasjon og overlevering          | D1–D2     |

## Estimatnøkkel

Kjelde: CRMAAREG-84. Same forklaring er gjentatt i alle historier i Jira, men er samla her i staden.

| Estimat | Tyding                                                                                                                          |
| ------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **S**   | Avgrensa arbeid, låg usikkerheit. Ofte noko ein utviklar kan ta relativt raskt — nokre timar til rundt ein dag eller litt meir. |
| **M**   | Fleire steg eller fleire klassar, litt usikkerheit. Ofte 1–3 dagar, grovt sett.                                                 |
| **L**   | Fleire lag, meir kompleksitet, meir risiko. Bør ofte vurderast delt opp. Gjerne fleire dagar eller meir.                        |

## Arbeidstypar

Historiene er merkte med ein av desse typane i Jira:

`Foundation` · `Technical` · `Functional` · `Security` · `Operations` · `Test` · `Documentation`

## Merknader ved speiling

- Estimatforklaringa er fjerna frå kvar enkelt historie og samla over, sidan den var identisk overalt.
- Tildelte personar og rapportørar er utelatne. Sjå GitHub-sak #990.
- Sub-taskar er ikkje eksporterte. CRMAAREG-84 har fire (85, 86, 87, 88) som ikkje er dekte.
- Felt utan verdi i Jira (Sprint, Story Points, Kontrollpunktstatus) er utelatne.
