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
P360_Archive_Job_Viewer.permissionset-meta.xml
P360_RPC_Callout_Access.permissionset-meta.xml
P360_Code_Table_Access.permissionset-meta.xml
```

## Prinsipp

Bruk minste privilegium.

`P360_Archive_Release` gir custom permission for å setje frigivingssignalet på vedtak. Ordinær felttilgang kjem frå saksbehandlarsettet.

`P360_Archive_Job_Processing` gir avgrensa tilgang til jobbobjektet og felta som `ApplicationDocument`-slice, claim/lease og retry-worker bruker. Settet må utvidast eksplisitt når fleire jobbtypar eller worker-felt blir implementerte.

`P360_Archive_Job_Viewer` er for godkjende menneskelege operatørar som treng å lese jobbstatus i Salesforce. Det gir ikkje oppretting, redigering, sletting, tilgang til alle felt eller `View All Records`. Det gir eksplisitt lesing av tidsstempel og feilkode; feilmelding, correlation-/idempotensnøklar og domenelenkjer er ikkje inkluderte. `Archive_Event_Type__c`, `Attempt_Count__c` og `Status__c` er påkravde felt og kan ikkje ha eigne feltløyveoppføringar i permission-set-metadata; synlegheita deira må stadfestast i org etter deploy. Settet inngår ikkje i `P360_Integration_User`.

`P360_RPC_Callout_Access` gir tilgang til Custom Setting `P360_Integration_Setting__c` og til `P360_RpcClient`. External Credential Principal-tilgang må leggjast til manuelt i kvart target-org etter at Named Credential/External Credential er oppretta der, sidan Principal ikkje finst i kjeldekontrollert metadata. Settet inngår i Permission Set Group `P360_Integration_User` (sjå `permissionsetgroups/`). Sjølve tildelinga av settet/gruppa til ein brukar er data, ikkje metadata, og blir difor ikkje overskriven av deploy — ho må gjerast separat per miljø (prod/sit2).

I scratch orgar og sandkasser kan `P360_Integration_Setting__c.Use_Mock_Transport__c` setjast til `true` for å bruke stub-transport utan External Credential Principal. Dette gir ikkje automatisk mock-fallback i produksjon.

`P360_Code_Table_Access` gir lesetilgang til Custom Metadata Type `P360_Code_Table_Value__mdt` (sjå `objects/P360_Code_Table_Value__mdt/`). Inngår òg i `P360_Integration_User`.

Skil framleis mellom:

- vanleg brukar
- superbrukar
- integrasjonsadministrator
- teknisk/driftsrelatert tilgang

Ikkje legg `P360_Archive_Job_Viewer` til `P360_Integration_User`: prosesseringsgruppa er for teknisk integrasjonskøyring, medan viewer-settet er ei eksplisitt menneskeleg UI-tilgang. Tilordning til brukarar er ei eiga org-handling. Dersom same brukar framleis har `P360_Archive_Job_Processing`, er dei samla rettane additive og brukaren har framleis Create/Edit sjølv om Viewer-settet er read-only.
