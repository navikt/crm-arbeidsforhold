# P360 Domain Tests

Denne mappa inneheld testar for P360-spesifikt domain-lag.

## Ansvar

Testane skal verifisere:

- at nødvendig Salesforce-data blir samla riktig
- at manglande datagrunnlag blir handtert kontrollert
- at interne valideringar fungerer
- at domain-laget ikkje krev P360 DTO-ar
- at domain-laget ikkje gjer callouts

## Skal ikkje

Testane skal ikkje:

- teste P360 transport
- teste ekstern kontrakt direkte
- vere avhengige av ekte P360-data

## Typiske testar

```text
AAREG_ApplicationArchiveDomainServiceTest.cls
AAREG_AgreementArchiveDomainServiceTest.cls
```
