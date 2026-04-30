# P360 Orchestration Tests

Denne mappa inneheld testar for P360 orchestration.

## Ansvar

Testane skal verifisere:

- at orchestrator koordinerer riktig flyt
- at correlation ID blir oppretta eller vidareført
- at domain service blir brukt riktig
- at mapper blir brukt riktig
- at adapter blir kalla riktig
- at resultat blir handtert riktig
- at feil blir klassifiserte og returnerte kontrollert

## Skal ikkje

Testane skal ikkje:

- gjere ekte callouts
- vere avhengige av P360
- teste låg-nivå HTTP
- teste detaljert DTO-serialisering dersom det høyrer til kontraktstest

## Typiske testar

```text
AAREG_ArchiveApplicationOrchestratorTest.cls
```
