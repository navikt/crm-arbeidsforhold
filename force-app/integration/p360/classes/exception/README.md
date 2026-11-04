# P360 Exception

Denne mappa inneheld P360-spesifikke feilklassar.

Feilklassane skal støtte kontrollert feilhandtering, logging, correlation ID og tydeleg skilje mellom ulike feiltypar.

## Ansvar

P360 exceptions skal:

- gjere feilklassifisering tydeleg
- støtte strukturert logging
- kunne vidareføre correlation ID der det er relevant
- skilje mellom transportfeil, konfigurasjonsfeil, mappingfeil og kontraktsfeil
- gjere retrybar og ikkje-retrybar feil enklare å handtere

## Typiske klasser

```text
P360_IntegrationException.cls
P360_ContractException.cls
P360_TransportException.cls
P360_AuthenticationException.cls
P360_ConfigException.cls
P360_MappingException.cls
P360_MissingCodeTableMappingException.cls
P360_TimeoutException.cls
P360_RetryableException.cls
```

## Feiltypar

### IntegrationException

Generell P360-integrasjonsfeil.

### ContractException

Feil i request, response eller forventa P360-kontrakt.

### TransportException

Feil i HTTP, RPC, timeout eller nettverksnær transport.

### ConfigException

Feil i konfigurasjon, Named Credential, External Credential, endpoint eller miljøoppsett.

### MappingException

Feil i mapping mellom intern modell og P360-kontrakt.

## Bruksmønster

Kast den mest presise exception-typen ved feilkjelda. Bruk `P360_ContractException` for brot på request-/response-kontrakten, `P360_MappingException` for mappingfeil og `P360_MissingCodeTableMappingException` når ei aktiv kodeverk-mapping manglar. Retrybarheit er ei avgjerd for kallaren: `isRetryable` er `false` som standard, og kan setjast med `withRetryable(Boolean)` når utfallet trygt kan prøvast på nytt. `P360_RetryableException` er ein snarveg som set verdien til `true`.

Fest ein kjent correlation ID med `withCorrelationId(String)` når exception blir kasta eller ført vidare. I dagens worker kjem correlation ID for feil-loggen frå jobbrada (`Correlation_Id__c`); workeren les ikkje `error.correlationId`. Dette er ikkje ende-til-ende-korrelasjon gjennom transporten.

Sjå [P360-flyten steg for steg](../../../../../docs/integrations/p360/steg-for-steg-gjennomgang.md#bruk-av-exceptions) for korleis workeren brukar klassifiseringa.

## Skal ikkje

Exception-klasser skal ikkje:

- innehalde retry-logikk
- gjere logging direkte dersom logging blir handtert av høgare lag
- innehalde forretningslogikk
- skjule teknisk årsak der han trengst for feilsøking

## Test

Exception-testar skal liggje under:

```text
force-app/tests/classes/integration/p360/exception/
```
