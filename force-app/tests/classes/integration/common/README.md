# Common integration tests

Denne mappa inneheld testar for felles integrasjonsgrunnlag.

Testane skal sikre at common-klassane fungerer uavhengig av P360 og andre konkrete integrasjonar.

## Ansvar

Testane skal verifisere:

- oppretting og vidareføring av correlation ID
- strukturert loggkontekst
- felles exception-klasser
- konfigurasjonsfeil
- transportfeil
- mappingfeil
- at common-klassar ikkje krev P360-avhengigheiter

## Skal ikkje

Testane skal ikkje:

- gjere ekte callouts
- teste P360-spesifikk logikk
- teste Application-, Agreement- eller Decision-use case
- vere avhengige av P360 DTO-ar
- vere avhengige av P360 Named Credential

## Typiske testar

```text
CorrelationContextTest.cls
IntegrationLogContextTest.cls
IntegrationExceptionTest.cls
ConfigurationExceptionTest.cls
TransportExceptionTest.cls
MappingExceptionTest.cls
```

## Testreglar

- Testane skal vere deterministiske.
- Testane skal kunne køyrast utan P360-tilgang.
- Testane skal ikkje krevje miljøspesifikk konfigurasjon.
- Testdata skal vere minimal og tydeleg.

## Namnestandard

Testklassar skal følgje mønsteret:

```text
<ClassBeingTested>Test
```

Eksempel:

```text
CorrelationContextTest
IntegrationLogContextTest
TransportExceptionTest
```
