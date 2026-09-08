# P360 DTO

Denne mappa inneheld reine dataobjekt for P360 request og response.

DTO-ar representerer tekniske kontraktar mot P360. Dei skal vere enkle, serialiserbare og utan forretningslogikk.

## Ansvar

DTO-ar skal:

- representere P360 requestar
- representere P360 responsar
- representere dokument, metadata og andre kontraktsdelar
- støtte JSON-serialisering
- støtte JSON-deserialisering
- vere enkle å teste isolert

## Skal ikkje

DTO-ar skal ikkje:

- innehalde forretningslogikk
- gjere SOQL
- gjere DML
- gjere callouts
- kjenne orchestration
- kjenne adapter
- kjenne client
- utføre validering utover enkel teknisk struktur dersom det ikkje er eksplisitt avtalt

## Typiske klasser

```text
P360_ArchiveRequestDto.cls
P360_ArchiveResponseDto.cls
P360_DocumentDto.cls
P360_MetadataDto.cls
```

## Namnestandard

Request:

```text
P360_<Operation>RequestDto
```

Response:

```text
P360_<Operation>ResponseDto
```

Entity/detail DTO:

```text
P360_<Entity>Dto
```

## Test

DTO-testar skal liggje under:

```text
force-app/tests/classes/integration/p360/contract/
```

DTO-testar bør minimum verifisere:

- serialisering
- deserialisering
- obligatoriske felt i testdata
- handtering av tomme eller manglande verdiar der relevant
