# P360 Mapper Tests

Denne mappa inneheld testar for mapperar i P360-integrasjonen.

## Ansvar

Testane skal verifisere:

- mapping frå intern modell til P360 DTO
- mapping frå P360 response til internt resultat
- handtering av obligatoriske felt
- handtering av manglande eller ugyldige verdiar
- bruk av kodeverkteneste der relevant
- at mapperar ikkje gjer SOQL, DML eller callouts

## Skal ikkje

Testane skal ikkje:

- teste HTTP-transport
- teste orchestration-flyt
- teste P360 endpoint
- vere avhengige av ekte metadata dersom fake service kan brukast

## Typiske testar

```text
AAREG_ArchiveApplicationMapperTest.cls
AAREG_AgreementArchiveRequestMapperTest.cls
P360_ArchiveResultMapperTest.cls
```
