# P360 Apex-klasser

Denne mappa inneheld Apex-kode for P360-integrasjonen.

Apex-koden er delt etter teknisk ansvar for å halde flyt, domene, mapping, transport og kontraktar skilde.

## Struktur

```text
classes/
  orchestration/
  domain/
  adapter/
  client/
  mapper/
  contract/
    dto/
  exception/
```

## Plasseringsregel

Nye Apex-klasser skal plasserast etter ansvar, ikkje etter kven som opprettar dei.

## Lag

### orchestration

Styrer use case-flyten.

### domain

Hentar og validerer internt datagrunnlag for arkivering.

### adapter

Eksponerer forretningsnære P360-operasjonar.

### client

Handterer låg-nivå transport mot P360 RPC.

### mapper

Transformerer mellom intern modell og P360-kontrakt.

### contract

Inneheld tekniske kontraktsobjekt.

### exception

Inneheld P360-spesifikke feilklassar.

## Reglar

- Entry point og orchestration skal ikkje gjere HTTP-kall direkte.
- Domain service skal ikkje kjenne P360 DTO-ar.
- Mapperar skal ikkje gjere SOQL, DML eller callouts.
- Adapter skal skjule transportdetaljar.
- Client skal ikkje kjenne Aa-registeret-domene eller use case-logikk.
- DTO-ar skal vere enkle dataobjekt.
