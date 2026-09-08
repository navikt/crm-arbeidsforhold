# P360 Flows

Denne mappa inneheld flows som høyrer til P360-integrasjonen.

Flows her skal støtte P360-relatert prosess, brukarstyrt arkivering eller enkel automasjon rundt arkiveringsflyta.

## Ansvar

Flows her kan:

- starte arkiveringsprosess
- vise eller oppdatere arkiveringsstatus
- kalle invocable Apex for P360-operasjonar
- støtte brukarstyrt retry dersom dette er avklart
- handtere enkel routing knytt til P360-status

## Skal ikkje

Flows her skal ikkje:

- innehalde kompleks P360-mapping
- byggje P360 request-strukturar
- gjere direkte HTTP-kall
- duplisere orchestration-logikk frå Apex
- innehalde tekniske secrets
- logge sensitiv informasjon

## Typiske flows

```text
P360_Archive_Application.flow-meta.xml
```

## Prinsipp

Kompleks logikk skal liggje i Apex.

Flow skal brukast der det gir brukar- eller prosessverdi utan å gjere integrasjonslogikken skjør.
