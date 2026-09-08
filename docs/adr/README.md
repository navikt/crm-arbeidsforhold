---
tittel: ADR (SF)
kilde: Confluence — ADR (SF) (PDF-eksport)
hentet: 2026-09-08
speilkopi: delvis
---

# ADR (SF)

Denne siden samler Architecture Decision Records for Aa-registeret Salesforce-løsningen.

ADR-er brukes til å dokumentere viktige arkitektur- og designbeslutninger, inkludert kontekst, vurderte alternativer, valgt løsning og konsekvenser.

Målet er ikke å dokumentere alt vi gjør, men å dokumentere beslutninger som er viktige nok til at framtidige utviklere bør forstå hvorfor løsningen ble slik.

## Når skal vi skrive en ADR?

Skriv en ADR når en beslutning:

- påvirker flere deler av løsningen
- er vanskelig eller kostbar å endre senere
- avklarer en teknisk retning
- velger mellom flere reelle alternativer
- påvirker sikkerhet, drift, testbarhet eller videreutvikling
- etablerer en standard andre bør følge

## Format

Hver ADR bør minimum inneholde:

- Status
- Dato
- Kontekst
- Beslutning
- Alternativer vurdert
- Konsekvenser
- Oppfølging

## Navngiving

ADR-er navngis med løpenummer og kort tittel.

## ADR-er i dette repoet

| ADR                                                               | Tittel                                                                                             | Status           | Dato       |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | ---------------- | ---------- |
| [ADR-0001](0001-arkitekturprinsipp-lagdeling-og-namnestandard.md) | Etablere felles arkitekturprinsipp, lagdeling og namnestandard for Aa-registeret Salesforce-pakken | UNDER BEHANDLING | 2026-04-26 |
| [ADR-0002](0002-accountcontactrelation-for-personkontoer.md)      | AccountContactRelation objekt brukes for kontakter tilknyttet Personkontoer                        | Foreslått        | 2026-08-26 |
| [ADR-0003](0003-e-post-for-personkonto-via-aareg-og-krr.md)       | Håndtering av e-postadresse for personkonto via AAREG og KRR                                       | Foreslått        | 2026-08-27 |

## Avvik funnet ved speiling

**Nummerserien er ikke entydig.** Confluence-indekssiden bruker «ADR-0001 Funksjonsbasert repositorystruktur innenfor force-app» som eksempel på navngiving, men den speilede ADR-0001 heter «Etablere felles arkitekturprinsipp, lagdeling og namnestandard». Det er uklart om eksempelet er fiktivt, om det finnes en eldre ADR-0001, eller om repositorystruktur-dokumentet var ment å være ADR-0001.

**Datoene er rettet.** PDF-eksporten av ADR-0002 og ADR-0003 oppga 2025. Riktig år er 2026, bekreftet av dokumenteier. Med rettede datoer følger nummereringen kronologi: ADR-0001 (april 2026), ADR-0002 (august 2026), ADR-0003 (august 2026).

**To ulike ADR-spor.** ADR-0002 og ADR-0003 handler om personkonto, kontaktrelasjoner og e-post — ikke om integrasjonsarkitektur. ADR-0001 handler om lagdeling og navnestandard. Det ser ut til å være to uavhengige beslutningsspor i samme nummerserie.

**Konsekvens:** neste ledige nummer er ADR-0004. Se sak #975 i GitHub.

**Statusvokabularet varierer:** «UNDER BEHANDLING» i ADR-0001, «Foreslått» i ADR-0002 og ADR-0003. Bør normaliseres.
