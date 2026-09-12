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

## Gjeldande permission sets

```text
P360_Archive_Release.permissionset-meta.xml
P360_Archive_Job_Processing.permissionset-meta.xml
```

## Prinsipp

Bruk minste privilegium.

`P360_Archive_Release` gir custom permission for å setje frigivingssignalet på vedtak. Ordinær felttilgang kjem frå saksbehandlarsettet.

`P360_Archive_Job_Processing` gir avgrensa tilgang til jobbobjektet og felta som første `ApplicationDocument`-slice bruker. Settet må utvidast eksplisitt når worker eller fleire jobbtypar blir implementerte.

Skil framleis mellom:

- vanleg brukar
- superbrukar
- integrasjonsadministrator
- teknisk/driftsrelatert tilgang
