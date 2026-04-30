# P360 Client Tests

Denne mappa inneheld testar og HTTP mocks for P360 RPC client.

## Ansvar

Testane skal verifisere:

- at HTTP-request blir bygd riktig
- at Named Credential blir brukt
- at headers blir sette riktig
- at request blir serialisert
- at response blir deserialisert
- at HTTP-statuskodar blir handtert
- at timeout og transportfeil blir handtert
- at riktige exceptions blir kasta

## Teststøtte

HTTP mocks kan liggje her.

Eksempel:

```text
P360_RpcClientMock.cls
```

## Skal ikkje

Testane skal ikkje:

- gjere ekte callouts
- teste use case-logikk
- teste domain-reglar
- teste mapperar i detalj

## Typiske testar

```text
P360_RpcClientTest.cls
P360_RpcClientMock.cls
```
