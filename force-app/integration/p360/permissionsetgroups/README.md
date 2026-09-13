# P360 Permission Set Groups

Denne mappa inneheld permission set groups for P360-integrasjonen.

Ei permission set group samlar fleire permission sets slik at ein integrasjonsbrukar kan tildelast éin gruppe i staden for fleire enkeltsett.

## Gjeldande grupper

```text
P360_Integration_User.permissionsetgroup-meta.xml
```

`P360_Integration_User` samlar `P360_RPC_Callout_Access` og `P360_Archive_Job_Processing`.

## Tildeling

Tildeling av gruppa til ein brukar (`PermissionSetAssignment`) er data, ikkje metadata, og blir gjort separat per miljø. Dette hindrar at ein vanleg metadata-deploy overskriv kven som har integrasjonstilgang i prod eller sit2.
