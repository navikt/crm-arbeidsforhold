# P360 Adapter Tests

Denne mappa inneheld testar og fakes for P360 adapter-laget.

## Ansvar

Testane skal verifisere:

- at adapter kallar RPC client riktig
- at adapter handterer vellykka respons
- at adapter handterer feilrespons
- at adapter kastar definerte exceptions
- at adapter skjuler transportdetaljar frå orchestration

## Teststøtte

Fake adapterar kan liggje her.

Eksempel:

```text
FakeP360ArchiveAdapter.cls
```

## Skal ikkje

Testane skal ikkje:

- gjere ekte callouts
- teste mapping i detalj
- hente Salesforce-domene direkte
- teste orchestration-flyt utover adapteransvaret

## Typiske testar

```text
P360_ArchiveAdapterTest.cls
P360_AdapterFactoryTest.cls
FakeP360ArchiveAdapter.cls
```
