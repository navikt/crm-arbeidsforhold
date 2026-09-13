# P360 Code Table

Denne mappa inneheld tenesta for oppslag mot `P360_Code_Table_Value__mdt` (K2, CRMAAREG-155).

## Klassar

```text
P360_ICodeTableService.cls
P360_CodeTableMetadataService.cls
```

## Cache

`P360_CodeTableMetadataService` cachar oppslag per transaksjon i eit statisk `Map`, for å unngå gjentekne SOQL-kall mot same tabell/nøkkel i éin execution context. Cachen blir aldri delt mellom transaksjonar.

## Feilhandtering

Manglande aktiv mapping kastar `P360_MissingCodeTableMappingException` (sjå `classes/exception/`), ikkje `null`.

## Testdekning

`P360_CodeTableMetadataServiceTest` dekker den deterministiske manglande-mapping-stien. Testing av eit faktisk treff krev ekte code table-data, som ikkje er lagt inn enno sidan konkrete kodeverdiar krev P360-fagleg avklaring (GitHub-sak #1016).

Merk: Custom Metadata Type-oppslag krev `P360_Code_Table_Access` (sjå `permissionsets/`). Testar som køyrer som ein avgrensa brukar (`System.runAs`) må tildele dette permission settet før dei kallar tenesta, elles kastar SOQL ein `sObject type ... not supported`-feil i staden for den forventa `P360_MissingCodeTableMappingException`.
