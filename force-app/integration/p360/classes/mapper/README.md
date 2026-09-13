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
AAREG_ApplicationToP360CaseMapper.cls
AAREG_ApplicationToP360DocumentMapper.cls
AAREG_DecisionToP360DocumentMapper.cls
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

`AAREG_ApplicationToP360CaseMapper` er første mock-baserte CreateCase-slice. Han bruker den godkjende `Default`-profilen frå `P360_Code_Table_Value__mdt` for standard metadata, utan SOQL eller callouts i sjølve mapperen. Full Salesforce-feltmapping og live transport er framleis separate steg.

`AAREG_ApplicationToP360DocumentMapper` er første mock-baserte CreateDocument-slice for søknadsdokument. Han mappar dokumentdato, case-nummer, ekstern identitet og dei godkjende standardverdiane for arkiv, journalstatus, tilgangskode og tilgangsgruppe. Filtransport og dokumentkategori er medvite separate avklaringar.

`AAREG_DecisionToP360DocumentMapper` mappar vedtaksdokument med dei godkjende utgåande standardverdiane `Sak` og `Dokument ut`, saman med journalstatus og tilgang. Filtransport er framleis ein eigen slice.
