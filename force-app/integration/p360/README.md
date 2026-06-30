# P360-integrasjon

Denne mappa inneheld all metadata og kode som høyrer til Public 360-integrasjonen for Aa-registeret.

P360-integrasjonen handterer arkivering frå Salesforce til Public 360, inkludert teknisk flyt, mapping, adapter, RPC-klient, kontraktar, feilhandtering, brukarflate og relevant konfigurasjon.

## Innhald

Denne mappa kan innehalde:

- Apex-klasser
- Lightning Web Components
- Custom objects
- Custom metadata
- Permission sets
- Named Credentials
- External Credentials
- Flows
- README-filer for underområde

## Struktur

```text
p360/
  classes/
  lwc/
  objects/
  customMetadata/
  permissionsets/
  namedCredentials/
  externalCredentials/
  flows/
```

## Ansvar

P360-området eig integrasjonsansvaret mot Public 360.

Det betyr:

- orkestrering av arkiveringsflyt
- mapping frå Aa-registeret-domene til P360-kontrakt
- adapter mot P360
- RPC-klient for kall mot P360
- DTO-ar for request og response
- P360-spesifikke exceptions
- P360-relatert brukarflate
- P360-relatert metadata og konfigurasjon

## Skal ikkje

P360-området skal ikkje eige generell Aa-registeret-logikk.

P360 kan bruke data frå Application, Agreement og Decision, men generell domenelogikk for desse områda skal liggje i eigne Aa-registeret-funksjonsmapper.

## Plasseringsregel

Legg ny metadata her dersom metadataen primært høyrer til P360-integrasjonen.

Dersom metadataen primært høyrer til Application, Agreement, Decision eller eit anna Aa-registeret-område, skal ho ikkje leggjast her sjølv om P360 bruker data frå området.

## Namnestandard

Bruk `P360_` for P360-spesifikke Apex-klasser og metadata der det gir eigarskap og reduserer kollisjonsfare.

Bruk `AAREG_` for Aa-registeret-spesifikke use case-klasser som høyrer til arkiveringsflyta.

## P360 LWC

Denne mappa inneheld Lightning Web Components som høyrer til P360-integrasjonen.

Komponentane skal støtte brukarhandlingar og visning knytt til arkivering, P360-status, P360-referansar og feil frå arkiveringsflyta.

### Ansvar lwc

LWC-komponentar her kan:

- starte arkiveringsflyt
- vise arkiveringsstatus
- vise P360-referansar
- vise feilmeldingar frå P360-integrasjonen
- vise filstatus eller arkiveringsgrunnlag
- gi brukar ein trygg måte å retrye eller følgje opp feil på dersom dette er støtta

### Skal ikkje lwc

LWC-komponentar her skal ikkje:

- innehalde P360-mappinglogikk
- byggje P360 DTO-ar
- gjere direkte kall mot eksterne API
- innehalde forretningsreglar som høyrer heime i Apex
- handtere sensitiv informasjon unødvendig i klienten

### Namnestandard lwc

Komponentar bør ha namn som viser P360-eigarskap.

Eksempel:

```text
p360ArchiveAction
p360ArchiveStatusPanel
p360ArchiveFileList
p360ArchiveErrorPanel
```

### Test

Jest-testar for LWC skal liggje i komponenten si `__tests__`-mappe dersom LWC-testar blir brukt.

Eksempel:

```text
p360ArchiveAction/
  __tests__/
    p360ArchiveAction.test.js
```
