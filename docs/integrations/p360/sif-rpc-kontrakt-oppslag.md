---
tittel: P360 SIF RPC kontraktsoppslag
status: open contract
kilde: Repo-local architecture and Jira/Confluence mirrors
hentet: 2026-09-08
---

# P360 SIF RPC kontraktsoppslag

Dette dokumentet er et samlet oppslag for hva repoet faktisk vet om P360/SIF RPC, og hva som fortsatt må bekreftes av P360-teamet. Det er ikke en erstatning for den eksterne P360-kontrakten.

## Bekreftet i repoet

- Salesforce kommuniserer direkte med Public 360 uten integrasjonsplattform eller mellomvare.
- SIF RPC er transportlaget. Forretningslogikk skal ligge i Salesforce-use case og integrasjonslag.
- MVP-kandidaten i Jira-/repo-materialet er `DocumentService/CreateDocument` for journalpost-/dokumentmetadata.
- Salesforce skal bruke constructor injection mot `P360_IArchiveAdapter` og `P360_IRpcClient`.
- RPC-klienten eier endpoint, headers, timeout, serialisering, deserialisering og lavnivå transportfeil.
- Adapteren skal skjule transportdetaljer for orchestrator og domene.
- Autentiseringsmodellen er maskin-til-maskin OAuth 2.0 via Microsoft Entra ID.
- `AuthKey` og `ClientID` er omtalt som ekstra identifikasjon av kallet i tillegg til access token.
- P360-teamet eier arkivstruktur, sakstyper, klassifikasjon, journalposttyper, obligatoriske metadata og P360-valideringsregler.
- Korrelasjons-ID skal følge flyten og brukes for sporbarhet og trygg retry.
- Dokumentinnhold og sensitive data skal ikke logges.

## Operasjoner som er nevnt

| Tjeneste          | Operasjon                | Fase         | Status                                                         |
| ----------------- | ------------------------ | ------------ | -------------------------------------------------------------- |
| `DocumentService` | `CreateDocument`         | MVP-kandidat | Navn og formål er kjent; full kontrakt mangler                 |
| `SupportService`  | `GetCodeTableRows`       | Senere fase  | Ikke implementer før kodeverk- og responskontrakt er bekreftet |
| Ikke bekreftet    | `GetEntitiesExternalIds` | Senere fase  | Tjeneste, request, response og recovery-strategi mangler       |
| Ikke bekreftet    | `UploadStream`           | Senere fase  | Storfilstrategi og transportkontrakt mangler                   |

## Dette trenger vi bekreftet før implementasjon

### Operasjon og endpoint

- Er `DocumentService/CreateDocument` faktisk første MVP-kall?
- Hva er det eksakte tjenestenavnet og operasjonsnavnet i SIF?
- Hvilket endpoint brukes i test og produksjon? URL-ene skal lagres som miljøkonfigurasjon, ikke i kode.
- Hvilken HTTP-metode, content type, RPC-envelope og protokollversjon gjelder?

### Request

- Komplett request-eksempel uten hemmeligheter.
- Eksakte feltnavn, nesting og datatyper.
- Obligatoriske og valgfrie felter.
- Tillatte enumverdier, dato-/tidssoner, null-regler og maksimal lengde.
- Hvordan journalpost, dokument, sak og eventuelle vedlegg representeres.
- Om `recno` skal brukes, hva det betyr, og hvem som eier verdien.

### Response

- Komplett suksessrespons uten sensitive data.
- Feltnavn og format for P360 case ID, document ID, document number og status.
- Hvordan delvis suksess eller warnings representeres.
- Hvordan correlation ID returneres eller videreføres.

### Feil og retry

- HTTP-/RPC-feilkoder og P360-felkoder.
- Skillet mellom validerings-, kontrakt-, auth-, timeout-, transport- og funksjonelle feil.
- Hvilke feil som kan retries.
- Timeout, rate limit, backoff og eventuell Retry-After-semantikk.
- Idempotensnøkkel, duplikatrespons og trygg gjenopptaking.

### Auth og headers

- Entra ID audience og scope.
- Eksakte header-/feltnavn for `AuthKey` og `ClientID`.
- Om `AuthKey` og `ClientID` sendes som headers, envelope-felter eller begge deler.
- Hvilken Named Credential/External Credential-modell som skal brukes.
- Hvilke headers som er påkrevd for correlation ID og teknisk sporbarhet.

## Ikke bekreftet og skal ikke gjettes

- Faktiske miljø-URL-er.
- OAuth scope, audience eller konkrete credential-verdier.
- JSON/XML-feltnavn og envelope-format.
- P360-spesifikke feilkoder.
- `ADContextUser` sin betydning eller tillatte bruk.
- `recno` sitt format og livsløp.
- Endelig mapping mellom Salesforce Application, P360-sak, journalpost og dokument.

## Forespurt kontraktpakke

For å starte en ekte `CreateDocument`-implementasjon trenger teamet en versjonert, ikke-hemmelig kontraktpakke med:

1. operasjons- og endpointbeskrivelse for testmiljø
2. request- og response-eksempler
3. feltkatalog med obligatoriske felter og datatyper
4. auth- og headerbeskrivelse uten hemmeligheter
5. feilkatalog med retryklassifisering
6. idempotens- og correlation-ID-regler
7. mappingansvar for sak, journalpost, dokument og vedlegg
8. testscenarioer eller en tilgjengelig P360 teststub

## Kilder i repoet

- [P360 SIF RPC-operasjoner og kontraktsstatus](sif-rpc-operasjonar.md)
- [P360 SIF RPC-forståelse](sif-rpc-forstaelse.md)
- [Overordnet rammeverk](overordnet-rammeverk.md)
- [Lagdeling og navnestandard](lagdelt-struktur-og-namnestandard.md)
- [CRMAAREG-215 journalpost](../../context/p360/jira/crmaareg-215-journalpost.md)
- [CRMAAREG-180 sikkerhet](../../context/p360/jira/crmaareg-180-sikkerheit.md)
- [CRMAAREG-267 feil, idempotens og retry](../../context/p360/jira/crmaareg-267-feilhandtering.md)
- [GitHub issue #995](https://github.com/navikt/crm-arbeidsforhold/issues/995)

## Arbeidsregel

Inntil kontraktpakken er bekreftet, kan vi fortsette med testutilities, validering, exception-taxonomi og eksplisitte adaptergrenser. Vi skal ikke implementere eller anta ekte RPC-payload, mapping, auth-header eller retrylogikk.
