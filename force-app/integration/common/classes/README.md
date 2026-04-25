# Common integration classes

Denne mappa inneheld felles Apex-klasser for integrasjonsgrunnlaget.

Klassane her skal kunne brukast på tvers av integrasjonar utan å kjenne til P360, konkrete eksterne API eller Aa-registeret-spesifikke use case.

## Typiske klasser

```text
CorrelationContext.cls
IntegrationLogContext.cls
IntegrationException.cls
ConfigurationException.cls
TransportException.cls
MappingException.cls
```

## Ansvar

Klassane her kan støtte:

- correlation ID
- felles loggkontekst
- felles exception-hierarki
- generell integrasjonsfeilhandtering
- felles teknisk kontekst for integrasjonsflyt

## Skal ikkje

Klassane her skal ikkje:

- innehalde P360-spesifikk logikk
- innehalde P360 DTO-ar
- kjenne P360 RPC-format
- kjenne Named Credential for P360
- hente Application-, Agreement- eller Decision-data
- gjere callouts til eksterne system
- innehalde use case-spesifikk flyt

## Klasseansvar

### CorrelationContext

Held correlation ID og eventuelle tekniske sporfelt som skal kunne vidareførast gjennom ein integrasjonsflyt.

Skal ikkje innehalde forretningslogikk.

### IntegrationLogContext

Held strukturert loggkontekst for integrasjonsflyt.

Kan innehalde tekniske felt som operasjon, system, correlation ID og status.

Skal ikkje innehalde dokumentinnhald eller sensitiv informasjon.

### IntegrationException

Felles basisexception for integrasjonsfeil.

Kan brukast som forelder for meir spesifikke exceptions.

### ConfigurationException

Felles exception for manglande eller ugyldig konfigurasjon.

### TransportException

Felles exception for transportnære feil, til dømes timeout, HTTP-feil eller utilgjengeleg endpoint.

### MappingException

Felles exception for mappingfeil mellom intern modell og ekstern kontrakt.

## Logging og sensitiv informasjon

Klassane skal ikkje legge til rette for logging av sensitiv informasjon.

Loggkontekst skal vere teknisk og nødvendig for feilsøking.

## Test

Testar for common integration classes skal liggje under:

```text
force-app/tests/classes/integration/common/
```
