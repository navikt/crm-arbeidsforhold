# P360 Contract

Denne mappa inneheld tekniske kontraktsobjekt for P360-integrasjonen.

Kontraktlaget representerer strukturar som kryssar systemgrensa mot P360 eller støttar transporten mot P360.

## Innhald

Denne mappa kan innehalde:

- request-kontraktar
- response-kontraktar
- transportrelaterte strukturar
- DTO-undermappe for reine dataobjekt

## Struktur

```text
contract/
  dto/
```

## Ansvar

Contract-laget skal:

- representere tekniske P360-kontraktar
- vere stabilt og eksplisitt
- støtte serialisering og deserialisering
- gjere mapping testbar

## Skal ikkje

Contract-laget skal ikkje:

- innehalde use case-logikk
- hente Salesforce-data
- gjere SOQL
- gjere DML
- gjere callouts
- utføre transport
- bestemme arkiveringsflyt

## Namnestandard

DTO-ar skal liggje i `dto` og bruke mønster:

```text
P360_<Operation><Request|Response>Dto
P360_<Entity>Dto
```

## Test

Kontraktstestar skal liggje under:

```text
force-app/tests/classes/integration/p360/contract/
```
