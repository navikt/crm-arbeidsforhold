# P360 External Credentials

Denne mappa inneheld External Credentials for autentisering mot P360 og Entra ID.

External Credentials skal støtte trygg autentisering utan at secrets hardkodast i Apex.

## Ansvar

External Credentials skal støtte:

- autentisering mot P360
- integrasjon med Entra ID der relevant
- principal-konfigurasjon
- sikker handtering av credentials
- miljøstyrt autentisering

## Skal ikkje

External Credentials skal ikkje:

- innehalde use case-logikk
- brukast til å lagre forretningskonfigurasjon
- erstatte P360-kodeverk eller mappingmetadata

## Typiske metadata

```text
P360_Entra.externalCredential-meta.xml
```

## Drift

Endringar må koordinerast med:

- Named Credential
- Entra ID-appregistrering
- P360-endepunkt
- tilgangsstyring
- sikkerheitsansvarlege
