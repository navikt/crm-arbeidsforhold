# P360 Domain

Denne mappa inneheld P360-spesifikt datagrunnlag og domenetenester for arkiveringsflyta.

Domain-laget skal hente, samle og validere Salesforce-data som trengst før mapping til P360-kontrakt.

## Ansvar

Domain-laget skal:

- hente relevante Application-data
- hente relevante Agreement-data
- hente relevante Decision-data ved behov
- validere at internt datagrunnlag er komplett nok for arkivering
- uttrykkje interne reglar før mapping
- produsere eit internt datagrunnlag som orchestration og mapper kan bruke

## Skal ikkje

Domain-laget skal ikkje:

- kjenne P360 request- eller response-DTO-ar
- gjere callouts
- kjenne RPC-format
- kjenne headers, endpoint eller Named Credential
- serialisere eller deserialisere P360-kontraktar

## Flytting av ansvar

Dersom ei domain service blir nyttig utanfor P360-integrasjonen, bør ho flyttast til relevant Aa-registeret-funksjonsmappe.

Eksempel:

- Application-logikk bør liggje under Application-området.
- Agreement-logikk bør liggje under Agreement-området.
- Decision-logikk bør liggje under Decision-området.

## Typiske klasser

```text
AAREG_ApplicationArchiveDomainService.cls
AAREG_AgreementArchiveDomainService.cls
```

## Namnestandard

Bruk `AAREG_` for domain services som uttrykkjer Aa-registeret-domene.

Mønster:

```text
AAREG_<DomainArea><Purpose>DomainService
```

## Test

Testar for domain-laget skal liggje under:

```text
force-app/tests/classes/integration/p360/domain/
```
