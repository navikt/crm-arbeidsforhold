---
slug: altinn-provider-injection
status: proposed
---

# Feature Specification: Injiserbar Altinn-provider

**Dato:** 2026-10-20  
**Eigar:** `crm-platform-integration`  
**Status:** Planlagt kontraktendring; ikkje implementert eller org-verifisert.

## Scope Baseline

Kjeldegrunnlag: den lokale referansekjelda for `AltinnCalloutService`,
`IAltinnCalloutService` og eksisterande testar. Fasaden opprettar i dag sjølv
implementasjonen; konsumentar kan ikkje injisere gjennom det offentlege API-et.

Tre eksisterande komponentar er relevante: fasade, interface og fasadetest.
Berre fasaden og testen treng endring. Dette er arbeid for eigaren av
integrasjonspakka, ikkje løyve til å endre den lokale referansemappa.

Formålet er at konsumenten kan levere kontrollerte tenesteresultat. Verken
Altinn-transport, auth, token-cache, responssemantikk eller v2-utfasing inngår.

## User Scenarios & Testing

### US1 - Velje provider som konsument (P1)

Som konsumentutviklar vil eg levere ein provider som returnerer organisasjonar og
rettar, utan å konfigurere eller kontakte Altinn.

**Sjølvstendig test:** Opprett fasaden med ein deterministisk provider og kall begge
offentlege operasjonane.

1. **Given** ein gyldig provider og inga live-konfigurasjon, **When** fasaden blir
   oppretta med provideren, **Then** kan begge operasjonane brukast utan å opprette
   standardimplementasjonen eller gjere callouts.
2. **Given** ein provider som leverer eit feilresultat eller kastar ei feil,
   **When** konsumenten kallar fasaden, **Then** blir utfallet vidareført utan eit
   oppdikta vellukka svar eller fallback til live.

### US2 - Bevare eksisterande konsumentar (P1)

Som eksisterande konsument vil eg halde fram med dagens offentlege kontrakt.

1. **Given** bruk av konstruktøren utan parameter, **When** fasaden blir oppretta,
   **Then** blir eksisterande val av standardimplementasjon bevart.
2. **Given** null som eksplisitt provider, **When** fasaden blir oppretta,
   **Then** blir feil input avvist eksplisitt, utan live-fallback.

## Requirements

### Functional Requirements

- **REQ-001:** Konsumenten skal kunne velje ei implementering av eksisterande
  `IAltinnCalloutService` ved oppretting av fasaden. Injisert bane skal ikkje
  opprette eller konfigurere live-tenesta og skal ikkje gjere eigne callouts.
- **REQ-002:** Eksisterande konstruktør, operasjonar, DTO-ar og retursemantikk skal
  vere bakoverkompatible. Gyldige providersvar og exceptions skal vidareførast.
- **REQ-003:** Null provider skal gi eksplisitt feil utan fallback.
  Integrasjonspakka skal ikkje avhenge av konsumenten sine scenario, innstillingar
  eller klassar.

### Key Entities

- **Provider:** Implementasjon av dagens offentlege tenesteinterface.
- **Respons:** Dagens organisasjons- og rettsrespons, uendra.

## Success Criteria

- Begge operasjonane kan demonstrerast med konsumentstyrte svar utan Altinn-oppsett.
- Eksisterande fasadebruk har ingen tilsikta åtferdsendring.
- Alle tre krava har fokuserte regresjonstestar i integrasjonspakka før levering.

## Delivery Boundary

Endringa skal leverast frå integrasjonspakka sitt autoritative repository.
Faktisk repository, ansvarleg team, tilgang på tvers av pakker og kompatibel
avhengigheitsversjon skal stadfestast før konsumenten tek i bruk API-et.
Ingen pakkeversjon eller publiseringsdato er føresett.

Sjå [konsumentspesifikasjonen](altinn-consumer-scenarios.md) og
[gjennomføringsplanen](../../docs/integrations/altinn/implementation-plan.md).
