---
adr: 0004
tittel: P360 composition root og kontraktsgrense
status: Foreslått
dato: 2026-09-10
---

# ADR-0004: P360 composition root og kontraktsgrense

**Status:** Foreslått  
**Dato:** 2026-09-10

## Kontekst

P360-integrasjonen skal kunne utviklast og testast før den endelege SIF RPC-transporten er bekrefta. Salesforce-domenet må derfor ikkje kjenne endpoint, autentisering, RPC-envelope eller P360-spesifikk serialisering.

Jira-oppgåvene nemner ein `P360ServiceLocator`, medan repoets arkitektur- og adapterdokumentasjon brukar constructor injection og `P360_AdapterFactory`. Eit felles val er nødvendig før fleire produksjonsklassar blir bygde rundt ulike avhengigheitsmønster.

## Beslutning

P360 bruker constructor injection som primær mekanisme for avhengigheiter.

`P360_AdapterFactory` er composition root for standard produksjonswiring. Factoryen vel og opprettar adapterimplementasjonar, men er ikkje ein service locator og skal ikkje slå opp vilkårlege tenester globalt.

Avhengigheitsretninga er:

```text
composition root / factory
        |
        v
orchestrator -> P360_IArchiveAdapter -> P360_IRpcClient
        |
        v
   domain context / mapper
```

`P360_IArchiveAdapter` er den forretningsnære integrasjonsgrensa. `P360_IRpcClient` er den låg-nivå transportgrensa. DTO-ar og transportobjekt skal vere eigne P360-kontraktar og skal ikkje lekke inn i Salesforce-domain service.

Ein reell RPC-implementasjon skal ikkje byggjast før SIF-kontrakten er bekrefta.

## Alternativ vurdert

### `P360ServiceLocator`

Forkasta som primærmekanisme. Ein global service locator skjuler avhengigheiter, gjer kallrekkja vanskelegare å teste og blandar composition root med runtime-oppslag.

### Direkte konstruksjon i orchestrator

Forkasta. Det bind use case-koden til konkrete adapter- og clientimplementasjonar og gjer testdoblar mindre eksplisitte.

### Constructor injection utan factory

Mogleg for små testar og eksplisitte use case-instansar, men ein composition root er nyttig når standard produksjonswiring skal samlast på éin stad.

## Konsekvensar

- Produksjonsklassar avheng av smale interfaces.
- Testar kan injisere `P360_StubArchiveAdapter` eller `P360_TestRpcClient` eksplisitt.
- Mapping, transport og domeneansvar held seg skilde.
- Factoryen kan seinare velje mellom metadata-basert og RPC-basert adapter utan å endre orchestrator-kontrakten.
- Den endelege transportimplementasjonen er framleis blokkert av miljø-, auth-, mapping-, idempotens- og filavklaringar.

## Oppfølging

- Få menneskeleg godkjenning før status blir endra til `Vedtatt`.
- Bruk denne avgjerda som grunnlag for K3 og vidare P360-implementasjon.
- Implementer `CreateDocument` først når SIF RPC-kontrakten er bekrefta.
- Oppdater ADR-en dersom P360-teamet krev eit anna composition-root-mønster.

## Relaterte artefaktar

- [P360 dependency injection og adapterval](../integrations/p360/di-og-adapterval.md)
- [P360 component architecture](../architecture/p360-component-diagram.mmd)
- [P360 archive sequence](../architecture/p360-archive-sequence.mmd)
- [P360 adapter contract boundary](../../.github/specs/p360-adapter-contract-boundary.md)
- [P360 RPC client boundary](../../.github/specs/p360-rpc-client-boundary.md)
- GitHub issues #995, #996, #1015, #1016, #1017 og #1018
