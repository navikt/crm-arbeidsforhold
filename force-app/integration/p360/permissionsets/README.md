# P360 Permission Sets

Denne mappa inneheld permission sets for P360-integrasjonen.

Permission sets skal gi kontrollert tilgang til P360-relaterte objekt, felt, Apex-klasser, flows og komponentar.

## Ansvar

Permission sets her kan støtte:

- brukarrettar for arkivering
- administratorrettar for integrasjonsoppsett
- tilgang til P360-status og referansar
- tilgang til P360-relaterte flows
- tilgang til P360-relaterte LWC-komponentar
- tekniske rettar som trengst for integrasjonsflyt

## Skal ikkje

Permission sets her skal ikkje:

- gi breiare tilgang enn nødvendig
- blande P360-administrasjon og vanleg brukarfunksjonalitet utan grunn
- gi tilgang til sensitiv informasjon utan avklart behov
- brukast som snarveg for å omgå delingsmodell eller sikkerheitskrav

## Typiske permission sets

```text
P360_Archive_User.permissionset-meta.xml
P360_Integration_Admin.permissionset-meta.xml
```

## Prinsipp

Bruk minste privilegium.

Skil mellom:

- vanleg brukar
- superbrukar
- integrasjonsadministrator
- teknisk/driftsrelatert tilgang
