# P360 LWC

Denne mappa inneheld Lightning Web Components som høyrer til P360-integrasjonen.

Komponentane skal støtte brukarhandlingar og visning knytt til arkivering, P360-status, P360-referansar og feil frå arkiveringsflyta.

## Ansvar

LWC-komponentar her kan:

- starte arkiveringsflyt
- vise arkiveringsstatus
- vise P360-referansar
- vise feilmeldingar frå P360-integrasjonen
- vise filstatus eller arkiveringsgrunnlag
- gi brukar ein trygg måte å retrye eller følgje opp feil på dersom dette er støtta

## Skal ikkje

LWC-komponentar her skal ikkje:

- innehalde P360-mappinglogikk
- byggje P360 DTO-ar
- gjere direkte kall mot eksterne API
- innehalde forretningsreglar som høyrer heime i Apex
- handtere sensitiv informasjon unødvendig i klienten

## Namnestandard

Komponentar bør ha namn som viser P360-eigarskap.

Eksempel:

```text
p360ArchiveAction
p360ArchiveStatusPanel
p360ArchiveFileList
p360ArchiveErrorPanel
```

## Test

Jest-testar for LWC skal liggje i komponenten si `__tests__`-mappe dersom LWC-testar blir brukt.

Eksempel:

```text
p360ArchiveAction/
  __tests__/
    p360ArchiveAction.test.js
```
