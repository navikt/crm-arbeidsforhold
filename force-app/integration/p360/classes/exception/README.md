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
P360_ConfigException.cls
P360_MappingException.cls
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
