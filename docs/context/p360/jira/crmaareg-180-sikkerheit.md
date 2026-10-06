---
jira: CRMAAREG-180
tittel: Sikkerheit, autentisering og konfigurasjon
type: Epic
status: Backlog
prioritet: Medium
opprettet: 2026-03-18
kilde: Jira — CRMAAREG (CSV-eksport + XML)
kilde-url: https://nav.atlassian.net/browse/CRMAAREG-180
hentet: 2026-09-13
speilkopi: ja
---

# CRMAAREG-180 — Sikkerheit, autentisering og konfigurasjon

**Type:** Epic · **Status:** Backlog · **Prioritet:** Medium
**Epicnamn i Jira:** `SF/P360 - Sikkerheit, autentisering og konfigurasjon`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-180)

## Formål

Setje opp trygg, miljøstyrt og driftsvennleg autentisering og konfigurasjon mot P360.

## Kvifor denne epicen finst

Integrasjon som ikkje får logga inn, eller loggar inn feil, er berre ein dyr måte å få 401 på.

> **Raud sone.** Heile denne epicen rører autentisering, tilgang og audit. Krev menneskeleg gjennomgang etter `CONTEXT.md`.

---

## CRMAAREG-181 · S1 — Etablere Named Credential / auth-strategi for P360 RPC

**Status:** Backlog · **Prioritet:** A - Kritisk · **Estimat:** M
**Etikettar:** `auth` `configuration` `named-credential` `security`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-181)

### Arbeidstype

**Type:** Security

### Brukarbehov og verdi

**Som** plattformutviklar
**vil eg** ha standardisert auth-oppsett
**slik at** kall mot P360 skjer trygt og likt i alle miljø

### Akseptansekriterier

- Endpoint-strategi for auth er avklart
- Authkey eller token blir ikkje hardkoda
- Authkey kan sendast i header
- Løysinga kan skilje mellom miljø
- Auth-feil gir definert exception og logg

### Relatert kontekst

`Overordnet rammeverk` beskriv autentiseringsmodellen: OAuth 2.0 via Microsoft Entra ID, med AuthKey og ClientID i tillegg. Konkrete header- og feltnamn for AuthKey og ClientID står som **ope spørsmål** i same dokument.

Confluence-designnotatet nemner metadata `P360_SIF_RPC.namedCredential-meta.xml` og `P360_Entra_ID.externalCredential-meta.xml`.

Akseptkriteriet «Auth-feil gir definert exception» heng saman med F5 (CRMAAREG-121) og GitHub-sak #993.

---

## CRMAAREG-188 · S2 — Etablere integrasjonsbrukar, tilgang og audit-prinsipp

**Status:** Under arbeid · **Prioritet:** A - Kritisk · **Estimat:** M
**Etikettar:** `audit` `privacy` `security`
[Opne i Jira](https://nav.atlassian.net/browse/CRMAAREG-188)

### Arbeidstype

**Type:** Security

### Brukarbehov og verdi

**Som** sikkerheitsansvarleg
**vil eg** ha kontroll på kven som køyrer integrasjonen
**slik at** sporbarheit og ansvar blir tydelege

### Akseptansekriterier

- Integrasjonsbrukar eller tenestekonto er definert
- Prinsipp for audit er dokumenterte
- Sensitive felt som ikkje skal i logg er identifiserte
- Bruk av `ADContextUser` er avklart og som standard ikkje brukt

> **Merk:** `ADContextUser` er ikkje forklart i noka speilkopi frå Confluence. Sjå GitHub-sak #995.
