---
tittel: P360 dependency injection og adapterval
status: vedtatt for P360-integrasjonen
kilde: repo-arkitektur og eksisterende P360-skjelett
hentet: 2026-09-08
---

# P360 dependency injection og adapterval

## Beslutning

P360-integrasjonen bruker constructor injection som primær mekanisme for avhengigheter.

`P360_AdapterFactory` er en valgfri composition-root for å velge standard produksjonsadapter. Den er ikke en service locator og skal ikke brukes av domenet, mapperne eller adapterne til å slå opp vilkårlige tjenester.

Det opprettes ikke en separat `P360ServiceLocator` for samme ansvar.

## Ansvar

### Constructor injection

Klassen som trenger en adapter eller client mottar interfacet i konstruktøren. Dette gjelder allerede for:

- `P360_ArchiveAdapter(P360_IRpcClient rpcClient)`
- `AAREG_ArchiveApplicationOrchestrator(P360_IArchiveAdapter archiveAdapter)`

Dette gir:

- eksplisitte avhengigheter
- enkel testing med stub eller fake
- ingen skjult global tilstand
- tydelig kontroll over livsløpet til implementasjonen

### `P360_AdapterFactory`

Factoryen kan senere brukes i composition root når produksjonskoden trenger å velge mellom for eksempel:

- metadata-basert adapter
- RPC-basert adapter
- stub-adapter i lokal utvikling eller testnære scenarioer

Factoryen skal returnere et interface og skal ikke flytte forretningslogikk eller mapping inn i valget.

### Service locator

En service locator som kan hente vilkårlige adaptere eller services globalt innfører skjulte avhengigheter og gjør kallrekken vanskeligere å teste. Den skal derfor ikke introduseres i P360 som alternativ til constructor injection.

## Konsekvens for K3 og K5

K3 skal forstås som etablering av et testbart injeksjonspunkt, ikke som krav om en global service locator.

K5 kan senere bytte kodeverkadapter bak et interface. Det byttet kan settes sammen i factory/composition root, mens mapperne fortsatt mottar interfacet gjennom constructor injection.

## Eksempel på avhengighetsretning

```text
composition root / factory
        |
        v
orchestrator -> P360_IArchiveAdapter -> P360_IRpcClient
        |
        v
      mapper / domain context
```

Produksjonsklasser skal avhenge av interfacene. `P360_StubArchiveAdapter` skal bare brukes som eksplisitt injisert implementasjon i test eller lokal utvikling.

## Navne- og plasseringregel

- `P360_AdapterFactory` er P360-spesifikk og hører hjemme i adapterlaget.
- En generell factory eller DI-komponent for flere integrasjoner hører ikke hjemme i P360-mappen og må eventuelt besluttes i en egen arkitektursak.
- `P360ServiceLocator` skal ikke opprettes som parallell mekanisme.

## Relaterte issue

Dette dokumentet avklarer GitHub issue `#996` og gir en repo-lokal beslutning for K3/K5. Jira-speilkopien beholdes som historisk kontekst; GitHub issue og dette dokumentet er arbeidsfasit for videre kodearbeid.
