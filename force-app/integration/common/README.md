# Common integration

Denne mappa inneheld felles integrasjonsgrunnlag som kan brukast av fleire integrasjonar i Aa-registeret-pakken.

`common` er ikkje eigd av P360. P360 kan bruke klassar her, men klassar som berre gjeld P360 skal liggje under `force-app/integration/p360`.

## Innhald

Denne mappa kan innehalde:

- felles correlation context
- felles loggkontekst
- generelle integrasjons-exceptions
- generelle transport- eller konfigurasjons-exceptions
- felles integrasjonshelpers som ikkje er spesifikke for eitt eksternt system

## Struktur

```text
common/
  classes/
    CorrelationContext.cls
    IntegrationLogContext.cls
    IntegrationException.cls
    ConfigurationException.cls
    TransportException.cls
    MappingException.cls
```

## Ansvar

`common` skal gi ein liten og stabil grunnmur for integrasjonar.

Klassar her skal vere:

- generelle
- gjenbrukbare
- uavhengige av P360-kontrakt
- uavhengige av Aa-registeret use case-logikk
- enkle å teste isolert

## Skal ikkje

`common` skal ikkje:

- innehalde P360-spesifikk logikk
- innehalde P360 DTO-ar
- kjenne P360 endpoint, RPC-format eller headers
- innehalde Application-, Agreement- eller Decision-spesifikk domenelogikk
- bli ei dumping-sone for helpers som berre brukast éin stad

## Plasseringsregel

Legg berre kode her dersom minst eitt av punkta er sant:

- koden er nyttig for fleire integrasjonar
- koden er ein generell integrasjonsbyggestein
- koden representerer eit felles teknisk konsept, som correlation ID eller felles exception-hierarki

Dersom koden berre brukast av P360-integrasjonen, skal han liggje under:

```text
force-app/integration/p360/
```

## Avhengigheitsregel

`common` skal vere lågt i avhengigheitstreet.

Det betyr:

```text
integration/p360 -> integration/common
integration/common -> ikkje integration/p360
```

`common` skal ikkje avhenge av P360, Application, Agreement eller Decision.

## Namnestandard

Generelle klassar i `common` skal normalt ikkje ha `P360_` eller `AAREG_` prefiks.

Eksempel:

```text
CorrelationContext
IntegrationLogContext
IntegrationException
ConfigurationException
TransportException
MappingException
```

Bruk prefiks berre dersom klassen faktisk er eigd av eit spesifikt domene eller system. Då høyrer han som regel ikkje heime i `common`.
