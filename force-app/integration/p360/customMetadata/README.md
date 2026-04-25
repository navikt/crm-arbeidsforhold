# P360 Custom Metadata

Denne mappa inneheld P360-relaterte custom metadata records.

Custom metadata skal brukast til konfigurasjon, kodeverk, mappingverdiar og miljøuavhengige oppslag for P360-integrasjonen.

## Ansvar

Custom metadata her kan brukast til:

- P360-kodeverk
- mapping mellom Salesforce-verdiar og P360-verdiar
- default-verdiar for arkivering
- aktiv/inaktiv status for mapping
- transportverdiar
- visingslabelar
- sortering eller prioritering der relevant

## Skal ikkje

Custom metadata her skal ikkje:

- innehalde hemmeligheiter
- innehalde access tokens
- innehalde AuthKey
- innehalde sensitiv personinformasjon
- brukast til miljøspesifikke secrets

## Typiske records

```text
P360_Code_Table_Value.CaseStatus_Draft.md-meta.xml
P360_Code_Table_Value.DocumentStatus_Closed.md-meta.xml
```

## Eigarskap

P360-relatert kodeverk skal ha tydeleg eigarskap.

Endringar i kodeverk eller mappingverdiar skal vurderast mot:

- P360-kontrakt
- arkivkrav
- eksisterande mapping
- testdata
- konsekvens for eksisterande flytar

## Test

Metadata-baserte oppslag skal testast via service-lag, ikkje ved at mapperar les metadata direkte.
