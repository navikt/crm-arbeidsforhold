# P360 Contract Tests

Denne mappa inneheld kontraktstestar for P360 DTO-ar og tekniske kontraktsobjekt.

## Ansvar

Testane skal verifisere:

- JSON-serialisering
- JSON-deserialisering
- request-struktur
- response-struktur
- handtering av tomme eller manglande felt der relevant
- at DTO-ar er enkle dataobjekt utan skjult logikk

## Skal ikkje

Testane skal ikkje:

- teste use case-flyt
- teste HTTP-callout
- teste domain-reglar
- teste mapping utover enkel strukturverifisering

## Typiske testar

```text
P360_ArchiveRequestDtoTest.cls
P360_ArchiveResponseDtoTest.cls
P360_DocumentDtoTest.cls
P360_MetadataDtoTest.cls
```
