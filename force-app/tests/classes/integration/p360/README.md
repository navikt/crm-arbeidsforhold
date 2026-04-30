# P360 Tests

Denne mappa inneheld Apex-testar og teststøtte for P360-integrasjonen.

Teststrukturen skal spegle produksjonsstrukturen der det gir verdi.

## Struktur

```text
p360/
  orchestration/
  domain/
  adapter/
  client/
  mapper/
  contract/
  exception/
  builders/
```

## Ansvar

Testområdet skal innehalde:

- unit-testar
- kontraktstestar
- fake implementasjonar
- HTTP mocks
- testdata builders
- base test helpers der relevant

## Reglar

- Testklassar skal ikkje liggje saman med produksjonskode.
- Fakes, mocks og builders skal ikkje brukast frå produksjonskode.
- Testane skal dekke både happy path og sad path.
- Testar skal vere deterministiske.
- Testar skal ikkje vere avhengige av ekte P360-tilgang.
- Callouts skal mockast.

## Namnestandard

```text
<ClassBeingTested>Test
Fake<ClassOrCapability>
<ClassOrCapability>Mock
<ClassOrCapability>Builder
```

## Eksempel

```text
P360_RpcClientTest.cls
P360_RpcClientMock.cls
FakeP360ArchiveAdapter.cls
P360_ArchiveResponseDtoBuilder.cls
```
