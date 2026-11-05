---
adr: 0005
tittel: Avgrense repositorystrukturen til ny kode
status: Foreslått
dato: 2026-10-04
---

# ADR-0005: Avgrense repositorystrukturen til ny kode

**Status:** Foreslått

**Beslutningsstatus:** Forslag til teamavklaring. Retninga er ikkje normativ før teamet har godkjent henne.

**Dato:** 2026-10-04

## Kontekst

Repositorystruktur-dokumentet beskriv `force-app/integration/`, `force-app/integration/common/` og `force-app/tests/`, men er ein Confluence-spegel merka som utkast. Repoet bruker allereie denne strukturen for integrasjonskode og felles integrasjonsgrunnlag. Repositoryet sine utviklingsinstruksar plasserer Apex-testar under `force-app/tests/classes/<matching-area>/`.

Den opphavlege skildringa i GitHub #975 av flat integrasjonsstruktur og testar ved sida av produksjonskode stemmer derfor ikkje for integrasjonsområdet. Det som står att, er å avklare om strukturen krev flytting av eksisterande kode.

`sfdx-project.json` definerer `force-app` som package directory for `crm-arbeidsforhold`. Funksjonsmapper under `force-app` er organisering innanfor den same pakken.

## Beslutning

Dette forslaget avgrensar strukturen til ny kode:

- Ny integrasjonsspesifikk produksjonskode blir plassert under `force-app/integration/<integration>/`.
- Generelle byggjesteinar som kan brukast på tvers av integrasjonar blir plasserte under `force-app/integration/common/`.
- Nye integrasjonstestar blir plasserte under `force-app/tests/classes/integration/<scope>/`.
- Eksisterande produksjonskode og testar blir ståande der dei er. Denne avgjerda inneber inga masseflytting eller omorganisering.
- Ei eventuell migrering av eksisterande kode krev ei eiga sak med avgrensa omfang og vurdering av avhengigheiter, pakke/deploy og testdekning.
- `force-app` held fram som einaste package directory. Denne strukturbeslutninga krev ingen endring i package directories eller package dependencies i `sfdx-project.json`.

## Alternativ vurdert

### Flytte all eksisterande kode og testar no

Forkasta for denne avgjerda. Ei slik flytting har større omfang enn nødvendig for å plassere ny integrasjonskode, og krev ei eiga migreringsplan og verifisering.

### La ny integrasjonskode følgje dei eldre flatstrukturane

Forkasta. Repoet har allereie ein fungerande integrasjonsstruktur og eit eige testtre som passar den nye koden.

## Konsekvensar

- Ny integrasjonskode får føreseieleg plassering utan at eksisterande metadata eller testar må flyttast.
- Ulik plassering av eldre og nyare kode blir ein medviten, mellombels tilstand.
- Ingen eksisterande Apex API-namn eller package directory blir endra av dette forslaget.
- Nye klassar blir framleis del av `crm-arbeidsforhold`-pakken fordi dei ligg under den eksisterande `force-app`-roten.

## Oppfølging

- Teamet må godkjenne eller endre forslaget før status blir sett til `Vedtatt`.
- Hald #975 open fram til teamavklaringa er fullført.
- Hald #976 blokkert fram til plasseringa er formelt avklart.
- Oppdater Confluence-kjelda for repositorystrukturen gjennom eigarens vanlege arbeidsflyt; spegelkopien i repoet skal ikkje redigerast åleine.
- #988 følgjer opp nummerering, statusvokabular og malbruk for ADR-ar.

## Relaterte artefaktar

- [Repositorystruktur](../architecture/repositorystruktur.md)
- [Shared integration correlation context](../../.github/specs/integration-correlation-context.md)
- [ADR-0001: Arkitekturprinsipp, lagdeling og namnestandard](0001-arkitekturprinsipp-lagdeling-og-namnestandard.md)
- GitHub #975 og #976
