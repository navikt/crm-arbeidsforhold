# P360 Mapper

Denne mappa inneheld mapperar for P360-integrasjonen.

Mapperane skal vere reine transformasjonsklasser mellom intern modell og ekstern P360-kontrakt.

## Ansvar

Mapperane skal:

- mappe frå intern Aa-registeret-modell til P360 request DTO
- mappe frå P360 response DTO til internt resultat
- bruke kodeverkteneste ved behov
- gjere eksplisitt og testbar feltmapping
- halde mappinglogikk samla på éin stad

## Skal ikkje

Mapperane skal ikkje:

- gjere SOQL
- gjere DML
- gjere callouts
- hente metadata direkte dersom dette skal gå via service
- innehalde use case-flyt
- innehalde transportlogikk
- skjule forretningsreglar som burde liggje i domain eller orchestration

## Typiske klasser

```text
AAREG_ArchiveApplicationMapper.cls
AAREG_AgreementArchiveRequestMapper.cls
P360_ArchiveResultMapper.cls
```

## Namnestandard

Aa-registeret-forankra mapperar:

```text
AAREG_<Source>To<Target>Mapper
```

P360-responsmapperar:

```text
P360_<Operation>ResultMapper
```

## Test

Testar for mapperar skal liggje under:

```text
force-app/tests/classes/integration/p360/mapper/
```

Mappertestar skal dekke både happy path og sad path.
