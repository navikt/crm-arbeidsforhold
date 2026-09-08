---
tittel: P360 SIF RPC-operasjonar og kontraktsstatus
kilde: Jira-speil og repo-lokal P360-arkitektur
hentet: 2026-09-08
speilkopi: delvis
status: open contract
---

# P360 SIF RPC-operasjonar og kontraktsstatus

Dette dokumentet samler P360-operasjoner som er nevnt i Jira-materialet, og skiller mellom det som er relevant for første arkiveringsflyt og det som er fremtidig arbeid.

Operasjonsnavnene under er ikke tilstrekkelige som implementasjonskontrakt. Request-/responsefelter, obligatoriske felter, feilkoder og timeout-/rate-limit-forventninger må bekreftes av P360-teamet før de brukes i produksjonskode.

## Operasjonsinventar

| Tjeneste          | Operasjon                | Kilde               | Fase         | Repo-status                                               |
| ----------------- | ------------------------ | ------------------- | ------------ | --------------------------------------------------------- |
| `DocumentService` | `CreateDocument`         | CRMAAREG-221 / J2   | MVP-kandidat | Navn og formål er kjent. Full kontrakt mangler.           |
| `SupportService`  | `GetCodeTableRows`       | CRMAAREG-175 / K5   | Senere fase  | Kodeverkstyper og responsformat må avklares.              |
| Ikke bekreftet    | `GetEntitiesExternalIds` | CRMAAREG-266 / X3   | Senere fase  | Tjeneste, request, response og recovery-strategi mangler. |
| Ikke bekreftet    | `UploadStream`           | CRMAAREG-250 / FLS3 | Senere fase  | Storfilstrategi og transportkontrakt mangler.             |

## MVP-grense

Første implementasjonsløp bør begrenses til den operasjonen som trengs for journalpost-/dokumentmetadataflyten:

- `DocumentService/CreateDocument`
- mapping fra Salesforce journalpostkontekst til P360-dokumentmetadata
- kobling til eksisterende eller opprettet P360-sak via avklart ekstern ID-strategi
- validering før callout
- lagring av P360-referanse og arkivstatus etter vellykket respons

Filoverføring, kodeverksoppslag og external-ID recovery skal ikke bygges inn i denne første transportkontrakten før de respektive strategiene er avklart.

## Kontrakt som mangler

Følgende må fylles inn for hver operasjon før DTO-ene kan anses som ferdige:

- eksakt SIF RPC-endepunkt og tjenestenavn
- requeststruktur og feltnavn
- responsstruktur og feltnavn
- obligatoriske og valgfrie felter
- format og betydning for `recno`
- betydning, tillatt bruk og kilde for `ADContextUser`
- feilkoder og klassifisering
- timeout og rate limits
- idempotensnøkkel og retry-forventning
- korrelasjons-ID og eventuelle påkrevde transportheaders
- hvordan P360-identifikatorer og document number returneres

Ingen AuthKey-, ClientID-, token- eller miljøverdier skal lagres i dette dokumentet.

## Begreper som krever P360-avklaring

### `recno`

`recno` er nevnt som et felt i Salesforce Custom Metadata-modellen for P360-kodeverk. Det er ikke dokumentert i de tilgjengelige P360-speilkopiene hva feltet identifiserer, hvem som tildeler verdien, eller om det skal sendes i SIF RPC-requester.

Feltet skal derfor ikke brukes i DTO-er eller mapping før P360-teamet har bekreftet format, eierskap og livsløp.

### `ADContextUser`

`ADContextUser` er nevnt i sikkerhetsarbeidet som noe som ikke skal brukes som standard. Den tilgjengelige dokumentasjonen forklarer ikke om begrepet gjelder en transportheader, en P360-brukerkontekst eller en operasjonell sporbarhetsmekanisme.

Dette er en sikkerhets- og sporbarhetsavklaring i rød sone. Repoet skal ikke innføre eller kopiere en `ADContextUser`-verdi før P360-teamet har bekreftet betydning, tillatt bruk og eventuell kobling til autentisering.

## Repo-konsekvens

Inntil kontrakten er bekreftet skal repoet bruke transport- og DTO-klasser som tydelige, men ikke ferdige kontraktgrenser. Det er bedre å ha en eksplisitt uferdig kontrakt enn å gjøre antatte P360-felter til en skjult offentlig API.

Den neste kodeendringen bør derfor være en testbar `CreateDocument`-kontrakt først etter at P360-teamet har levert request-/responseformatet. Frem til da skal implementasjonen ikke gjette JSON-felter eller feilkoder.

## Relaterte repo-dokumenter

- [Public 360 (SF)](README.md)
- [Overordnet rammeverk](overordnet-rammeverk.md)
- [P360 SIF RPC-forståelse](sif-rpc-forstaelse.md)
- [CRMAAREG-215 journalpost](../../context/p360/jira/crmaareg-215-journalpost.md)
- [CRMAAREG-236 filhåndtering](../../context/p360/jira/crmaareg-236-filhandtering.md)

## Åpen issue

GitHub issue `#995` holder denne avklaringen åpen. Den kan først lukkes når SIF RPC-dokumentasjonen eller en bekreftet kontrakt fra P360-teamet dekker MVP-operasjonen og de øvrige operasjonene er merket som relevante eller eksplisitt senere fase.
