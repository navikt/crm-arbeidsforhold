# P360 Orchestration

Denne mappa inneheld use case-styring for P360-integrasjonen.

Orchestrator-klasser koordinerer flyten frå Aa-registeret-kontekst til P360-operasjon.

## Ansvar

Orchestration skal:

- starte og koordinere arkiveringsflyt
- opprette eller vidareføre correlation ID
- hente nødvendig domenedata
- kalle mapper for kontraktsomforming
- kalle adapter for P360-operasjon
- handtere resultat frå P360
- klassifisere og vidareføre feil
- sikre kontrollert respons tilbake til kallande lag

## Skal ikkje

Orchestration skal ikkje:

- gjere HTTP-kall direkte
- serialisere eller deserialisere P360 RPC-requestar direkte
- innehalde detaljert feltmapping
- hente transportkonfigurasjon direkte
- innehalde låg-nivå retry- eller timeoutlogikk

## Typiske klasser

```text
AAREG_ArchiveApplicationOrchestrator.cls
AAREG_ArchiveApplicationCommand.cls
AAREG_ArchiveApplicationResult.cls
```

## Namnestandard

Bruk `AAREG_` for orchestratorar, commands og results som er forankra i Aa-registeret-use case.

Mønster:

```text
AAREG_<UseCase>Orchestrator
AAREG_<UseCase>Command
AAREG_<UseCase>Result
```

## Test

Testar for orchestration skal liggje under:

```text
force-app/tests/classes/integration/p360/orchestration/
```
