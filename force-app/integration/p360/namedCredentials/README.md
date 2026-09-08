# P360 Named Credentials

Denne mappa inneheld Named Credentials for kall mot P360.

Named Credentials skal brukast for å konfigurere endpoint og autentiseringsoppsett for P360-kall på ein trygg og miljøstyrt måte.

## Ansvar

Named Credentials skal støtte:

- trygg endpoint-konfigurasjon
- miljøskilje mellom test og produksjon
- bruk saman med External Credentials
- kall frå Apex utan hardkoda URL-ar og secrets

## Skal ikkje

Named Credentials skal ikkje:

- brukast saman med hardkoda secrets i Apex
- innehalde verdiar som burde styrast via sikker credential-konfigurasjon
- blandast med use case-logikk

## Typiske metadata

```text
P360_RPC.namedCredential-meta.xml
```

## Apex-regel

Apex-kode skal bruke Named Credential-alias, ikkje hardkoda endpoint.

Eksempel på prinsipp:

```text
callout:P360_RPC
```

## Drift

Endringar i Named Credential må koordinerast med:

- miljø
- Entra ID-oppsett
- P360-endepunkt
- External Credential
- CI/CD og deployment
