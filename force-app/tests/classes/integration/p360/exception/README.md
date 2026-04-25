# P360 Exception Tests

Denne mappa inneheld testar for P360-spesifikke exceptions.

## Ansvar

Testane skal verifisere:

- at exceptions kan opprettast med melding
- at exceptions kan opprettast med årsak der relevant
- at correlation ID kan vidareførast dersom støtta
- at feiltype kan skiljast der dette er implementert
- at retrybar og ikkje-retrybar feil kan skiljast dersom støtta

## Skal ikkje

Testane skal ikkje:

- teste logging direkte dersom logging eigast av eige lag
- teste HTTP-callout
- teste mapperar eller orchestration

## Typiske testar

```text
P360_IntegrationExceptionTest.cls
P360_TransportExceptionTest.cls
P360_ConfigExceptionTest.cls
P360_MappingExceptionTest.cls
```
