# P360 Test Builders

Denne mappa inneheld testdata builders for P360-integrasjonen.

Builders skal gjere testane meir lesbare, stabile og enkle å endre.

## Ansvar

Builders kan brukast til å lage:

- commands
- domain models
- P360 request DTO-ar
- P360 response DTO-ar
- dokumentdata
- metadata
- testresultat
- feilresponsar

## Skal ikkje

Builders skal ikkje:

- brukast frå produksjonskode
- gjere callouts
- vere avhengige av ekte P360
- skjule viktige testforventningar
- lage unødvendig kompleks testdata

## Namnestandard

```text
<ClassOrConcept>Builder
```

## Typiske builders

```text
AAREG_ArchiveApplicationCommandBuilder.cls
P360_ArchiveResponseDtoBuilder.cls
P360_DocumentDtoBuilder.cls
```

## Prinsipp

Testdata skal vere tydeleg.

Ein test skal kunne lese som:

```text
given valid archive command
when archive application is executed
then P360 archive adapter is called
and archive result is successful
```
