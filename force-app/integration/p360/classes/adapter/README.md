# P360 Adapter

Denne mappa inneheld adapterlaget mot Public 360.

Adapterlaget er den forretningsnære grensa mot P360. Det skal skjule transportdetaljar frå orchestration og gi stabile metodar for P360-operasjonar.

## Ansvar

Adapterlaget skal:

- eksponere P360-operasjonar på eit stabilt grensesnitt
- skjule låg-nivå transportdetaljar
- bruke RPC client internt
- returnere kontrollerte resultat
- omsetje transportfeil til definerte P360-exceptions
- vere enkelt å stubbe eller fake i test

## Skal ikkje

Adapterlaget skal ikkje:

- hente Salesforce-domene direkte
- kjenne entry points
- innehalde use case-logikk
- gjere detaljert feltmapping
- byggje HTTP-request manuelt dersom det høyrer heime i client-laget

## Typiske klasser

```text
P360_IArchiveAdapter.cls
P360_ArchiveAdapter.cls
P360_StubArchiveAdapter.cls
P360_AdapterFactory.cls
```

## Namnestandard

Interfaces:

```text
P360_I<Capability>Adapter
```

Implementasjon:

```text
P360_<Capability>Adapter
```

Stub:

```text
P360_Stub<Capability>Adapter
```

Factory:

```text
P360_<Capability>Factory
```

## Test

Testar og fakes for adapterlaget skal liggje under:

```text
force-app/tests/classes/integration/p360/adapter/
```

Produksjonskode skal ikkje avhenge av test-fakes.
