# P360 Client

Denne mappa inneheld låg-nivå transport mot P360 RPC.

Client-laget har ansvar for teknisk kommunikasjon med P360. Det skal ikkje kjenne Aa-registeret-domene eller use case-logikk.

## Ansvar

Client-laget skal:

- byggje HTTP-requestar
- bruke Named Credential og External Credential
- setje nødvendige headers
- serialisere request
- deserialisere response
- handtere HTTP-statuskodar
- handtere timeout
- handtere transportfeil
- utføre låg-nivå transportlogging der det er relevant

## Skal ikkje

Client-laget skal ikkje:

- kjenne Application, Agreement eller Decision
- kjenne Aa-registeret-use case
- innehalde forretningsreglar
- gjere domenemapping
- vurdere arkivfaglege reglar
- hente Salesforce-data for arkivering

## Typiske klasser

```text
P360_IRpcClient.cls
P360_RpcClient.cls
P360_RpcRequest.cls
P360_RpcResponse.cls
```

## Namnestandard

Interface:

```text
P360_IRpcClient
```

Implementasjon:

```text
P360_RpcClient
```

Transportobjekt:

```text
P360_RpcRequest
P360_RpcResponse
```

## Feilhandtering

Transportfeil skal kastast som definerte P360-exceptions, til dømes:

```text
P360_TransportException
P360_ConfigException
P360_IntegrationException
```

## Test

Testar og mocks for client-laget skal liggje under:

```text
force-app/tests/classes/integration/p360/client/
```
