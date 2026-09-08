# P360-integrasjon

Denne mappa inneheld all metadata og kode som høyrer til Public 360-integrasjonen for Aa-registeret.

P360-integrasjonen handterer arkivering frå Salesforce til Public 360, inkludert teknisk flyt, mapping, adapter, RPC-klient, kontraktar, feilhandtering, brukarflate og relevant konfigurasjon.

## Innhald

Denne mappa kan innehalde:

- Apex-klasser
- Lightning Web Components
- Custom objects
- Custom metadata
- Permission sets
- Named Credentials
- External Credentials
- Flows
- README-filer for underområde

## Struktur

```text
p360/
  classes/
  lwc/
  objects/
  customMetadata/
  permissionsets/
  namedCredentials/
  externalCredentials/
  flows/
```

## Ansvar

P360-området eig integrasjonsansvaret mot Public 360.

Det betyr:

- orkestrering av arkiveringsflyt
- mapping frå Aa-registeret-domene til P360-kontrakt
- adapter mot P360
- RPC-klient for kall mot P360
- DTO-ar for request og response
- P360-spesifikke exceptions
- P360-relatert brukarflate
- P360-relatert metadata og konfigurasjon

## Skal ikkje

P360-området skal ikkje eige generell Aa-registeret-logikk.

P360 kan bruke data frå Application, Agreement og Decision, men generell domenelogikk for desse områda skal liggje i eigne Aa-registeret-funksjonsmapper.

## Plasseringsregel

Legg ny metadata her dersom metadataen primært høyrer til P360-integrasjonen.

Dersom metadataen primært høyrer til Application, Agreement, Decision eller eit anna Aa-registeret-område, skal ho ikkje leggjast her sjølv om P360 bruker data frå området.

## Namnestandard

Bruk `P360_` for P360-spesifikke Apex-klasser og metadata der det gir eigarskap og reduserer kollisjonsfare.

Bruk `AAREG_` for Aa-registeret-spesifikke use case-klasser som høyrer til arkiveringsflyta.
