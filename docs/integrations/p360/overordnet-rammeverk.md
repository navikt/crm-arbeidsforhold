---
tittel: Overordnet rammeverk (P360-integrasjonen)
kilde: Confluence — Overordnet rammeverk (PDF-eksport)
hentet: 2026-09-08
speilkopi: ja
merknad: Navngitte personer er utelatt ved speiling. Se «Merknader ved speiling».
---

# Overordnet rammeverk

## Formål

Denne integrasjonen skal sikre at Arbeidsgiver- og arbeidstakerregisteret (Aa-registeret)-relatert saksbehandling i Salesforce blir korrekt arkivert og sporbar i Public 360 (P360), med minst mulig manuell håndtering, og med tydelige tilbakemeldinger til brukerne.

- **Forretningsresultat:** Aa-registeret-saker og dokumenter håndtert i Salesforce blir arkivert i P360 med riktig metadata, riktig kobling og tydelig status tilbake i Salesforce.
- **Primære brukere / mottakere av verdi:** Saksbehandlere og støttepersonell som jobber i Salesforce, samt arkiv- og journalføringsfunksjoner som er avhengige av P360 som autoritativt arkiv.
- **Slik ser suksess ut (observerbart):**
    - En saksbehandler kan starte arkivering fra Salesforce og få et tydelig resultat (suksess/feil + referanse).
    - P360 inneholder forventet sak/journalpost/dokument(er) med korrekt metadata og sporbar lenke tilbake til Salesforce.
    - Feil blir synlige, forståelige og mulig å rette opp uten manuell «datakirurgi».

## Omfang

### Inkludert i leveransen

- Benytte og forholde oss til eksisterende arkivstruktur og konfigurasjon i Public 360 (P360) slik P360-teamet har etablert den i tråd med NOARK-standarden og gjeldende arkivlovgivning. Integrasjonen skal opprette og knytte arkivenheter via P360 sine grensesnitt i henhold til denne konfigurasjonen, uten å gjøre endringer eller konfigurere P360 fra Salesforce-siden.
- Arkivere dokumenter og vedlegg fra Salesforce til P360 med nødvendig metadata.
- Lagre P360-identifikatorer tilbake i Salesforce for sporbarhet og for å unngå duplikater.
- Gi status/tilstand tilbake til Salesforce (arkivert, avvist, under behandling, krever tiltak).
- Standard håndtering av feil, gjenforsøk og revisjonsspor med korrelasjons-ID.

### Ikke inkludert i leveransen

- Erstatte P360 som system for arkiv og journal.
- Fri redigering av ferdigstilte arkivoppføringer i P360 (med mindre dette eksplisitt kreves og støttes).
- Bulk-migrering av historiske Aa-registeret-data (med mindre dette avtales som eget tiltak).
- Komplekse arbeidsflyter utenfor Aa-registeret.

## Interessenter og roller

| Rolle                      | Ansvarlig                                                               |
| -------------------------- | ----------------------------------------------------------------------- |
| Produkteier / fagansvarlig | Se Confluence                                                           |
| Arkitekt / Tech Lead       | Se Confluence                                                           |
| Salesforce-team            | Team CRM Arbeidsforhold                                                 |
| P360-team                  | Team P360                                                               |
| Sikkerhet og personvern    | Team Arbeidsforhold                                                     |
| Drift og support           | Team Arbeidsforhold, Team CRM Arbeidsforhold, Team Platforce, Team P360 |

Team Arbeidsforhold i Teamkatalogen: `https://teamkatalog.nav.no/team/29d44f3f-ff09-477c-b26a-83cd0aa66116`

## Systemer og avgrensninger

- **Salesforce-org:** Nav Salesforce-miljøer for Aa-registeret (prod + test/sandkasser). Konkrete org-URL-er er dokumentert i Confluence.
- **Public 360 miljø:** P360 prod + test. Konkrete miljø-URL-er er dokumentert i Confluence.
- **Integrasjonsplattform:** Ikke aktuelt. Integrasjonen er punkt til punkt, direkte mellom Salesforce og Public 360 (P360), uten mellomvare eller separat integrasjonsplattform.
- **Identitet/autentisering:** Maskin-til-maskin autentisering direkte mellom Salesforce og P360 ved bruk av OAuth 2.0. Salesforce henter access token fra Microsoft Entra ID (Azure AD) for tilgang til P360 sine API-er. I tillegg sendes en AuthKey for å identifisere hvem som kaller P360-endepunktene, samt ClientID fra app-registreringen i Entra ID.
- **Logging/overvåking:** Sentral logging + alarmering, med korrelasjons-ID gjennom hele kjeden.

## Ansvar og avgrensning

- **P360-teamet** eier all konfigurasjon i P360, inkludert arkivstruktur, sakstyper, klassifikasjon, journalposttyper, obligatoriske metadata og valideringsregler, i tråd med Noark-standarden og norsk arkivlovgivning.
- **Salesforce-teamet** tilpasser mapping, prosess og teknisk implementasjon til den konfigurasjonen P360-teamet har etablert.
- **Integrasjonsansvar ved punkt-til-punkt:** Salesforce-løsningen håndterer orkestrering, feilhåndtering, nytt forsøk, idempotens/deduplisering og teknisk logging for kall mot P360, i tråd med P360 sine grensesnitt og valideringsregler.

## Begreper og felles språk

Denne dokumentasjonen bruker fagbegrepet **sak** som samlebegrep for Aa-registeret-prosessen. I Salesforce er prosessen modellert med flere objekter (Søknad/Application, Vedtak/Application Decision og Avtale/Agreement). Begrepene under beskriver både faglig betydning og systemrepresentasjon.

### Fagbegreper (domene)

- **Sak (Aa-registeret):** Samlebegrep for hele prosessen fra søknad mottas til vedtak er fattet og avtale er etablert.
    - _Salesforce-representasjon:_ Primært representert ved Søknad (Application), og knyttede data for vedtak og avtale.
    - _P360-representasjon:_ Vil typisk mappe til P360 sak (arkivsak), med journalposter og dokumenter knyttet til denne.
- **Søknad (Application):** Saksoppføringen som representerer selve søknaden/prosessinstansen i Salesforce.
    - _Salesforce-representasjon:_ `Application`-objektet.
    - _Typisk bruk i integrasjonen:_ Kilde for metadata og koblinger ved arkivering (hvilken «sak» arkiveringen gjelder).
- **Vedtak (Application Decision):** Det saksbehandler har besluttet, inklusive utfall og beslutningsgrunnlag slik det er definert i løsningen.
    - _Salesforce-representasjon:_ Vedtaksinformasjon knyttet til søknad, modellert som egne felt og/eller egen struktur (avhengig av datamodell).
    - _Typisk bruk i integrasjonen:_ Arkiveres som metadata og/eller dokumentasjon i P360, avhengig av krav.
- **Avtale (Agreement):** Avtalen mellom etaten og konsumenten, som inneholder vedtaket og relevante avtalevilkår.
    - _Salesforce-representasjon:_ `Agreement`-objektet (med kobling til Application og vedtak).
    - _Typisk bruk i integrasjonen:_ Arkiveres som dokument og/eller sentrale metadata i P360, avhengig av arkivkrav.

### Arkivbegreper (P360/Noark)

- **Sak (P360):** Arkivsak i P360 som samler journalposter og dokumenter for en Aa-registeret-sak.
- **Journalpost:** Registrering i P360 for en arkivhendelse/innføring, knyttet til sak.
- **Dokument:** Innhold som arkiveres i P360, med tittel, type og metadata.
- **Vedlegg:** Tilleggsfiler som arkiveres sammen med dokument/journalpost.

### Integrasjonstekniske begreper

- **Arkivering:** Overføring og lagring av dokument(er) og metadata i P360 med revisjonsspor.
- **Tilstand/status:** Livssyklus for objekter (utkast, sendt inn, ferdigstilt, låst) som styrer hva som kan oppdateres.
- **Korrelasjons-ID / Ekstern ID:** Stabil identifikator som brukes for sporbarhet og for å unngå duplikate operasjoner.

## Viktigste forretningsflyter (på overskriftsnivå)

1. **Arkivering fra Salesforce:** Brukerhandling i Salesforce starter arkivering av valgt innhold til P360.
2. **Tilbakeskriving av referanser:** Ved suksess lagres P360-ID-er og arkivstatus i Salesforce.
3. **Feilhåndtering:** Ved valideringsfeil, manglende tilgang eller nedetid får brukeren tydelig årsak og neste steg; operasjonen kan forsøkes på nytt på en trygg måte.
4. **Vedleggshåndtering:** Filer i Salesforce overføres og arkiveres i P360 med korrekt kobling og metadata.
5. **Statusavstemming (valgfritt):** Salesforce kan kontrollere arkivstatus mot P360 for å oppdage avvik.

## Datatyper og sensitivitet

- **Personopplysninger:** Ja (typisk identifikatorer, navn og saksmetadata; dokumenter kan inneholde sensitiv informasjon avhengig av Aa-registeret-innhold).
- **Særlige kategorier:** Avklares (avhengig av dokumenttyper og innhold).
- **Operasjonelle data:** ID-er, tidsstempler, korrelasjons-ID-er, tekniske feildetaljer.
- **Føringer for logging:** Ingen dokumentinnhold i logger. Kun nødvendig metadata for feilsøking. Korrelasjons-ID skal alltid logges.

## Antakelser

1. P360 er autoritativt system for arkiv og journal, etablert og konfigurert av P360-teamet i tråd med Noark og gjeldende arkivlovgivning.
2. Salesforce er primær arbeidsflate for Aa-registeret-saksbehandling, der sak som faglig samlebegrep primært representeres av Søknad (Application) med tilhørende Vedtak (Application Decision) og Avtale (Agreement).
3. Integrasjonen er punkt til punkt: Salesforce kommuniserer direkte med P360 uten integrasjonsplattform.
4. Autentisering skjer med OAuth 2.0 via Entra ID, og kall identifiseres i tillegg med AuthKey og ClientID som avtalt med P360-teamet.
5. Integrasjonen må støtte nytt forsøk uten å lage duplikate arkivoppføringer (idempotens/deduplisering).

## Begrensninger

- **Juridisk og regelverk:** Arkivering må følge gjeldende krav og intern styring.
- **Sikkerhet:** Minste privilegium, sikker hemmelighetshåndtering og rotasjon, sikker transport, korrelasjons-ID gjennom alle ledd.
- **Ytelse/latens:** Brukerinitierte operasjoner skal fullføre innen avtalt terskel, eller degraderes til asynkron prosess med tydelig tilbakemelding.
- **Tilgjengelighet:** Ved nedetid i P360 skal forespørsler ikke forsvinne; Salesforce skal vise tilstand og støtte gjenoppretting.
- **Dataresidens:** Data skal forbli innen godkjente regioner/miljøer.
- **Plattformbegrensninger:** Salesforce governor limits, filstørrelser, P360 API-rate limits/timeouts; lange operasjoner bør være asynkrone.

## Risiko og åpne spørsmål

### Risiko

- Uklare mappingregler (hva blir sak vs journalpost vs dokument) kan gi merarbeid og forsinkelser.
- Endringer i P360-konfigurasjon, Noark-parametre eller obligatoriske metadata kan påvirke integrasjonen og krever styrt endringsprosess og kontraktsoppdatering.
- Store filer og mange vedlegg kan kollidere med plattformgrenser og tidsfrister.

### Åpne spørsmål

- Hva er presis strategi for idempotens og deduplisering (korrelasjons-ID og trygt nytt forsøk)?
- Hvilken metadata er obligatorisk i P360 for Aa-registeret i praksis, og hvilke valideringsregler gjelder?
- Hvilke livssyklusregler låser oppføringer i P360, og hvordan håndterer vi forsøk på endring etter lås?
- Hvordan håndteres feil operasjonelt: brukerstyrt nytt forsøk, automatisk nytt forsøk, eller kombinasjon?
- Hvilke konkrete header-/felt-navn gjelder for AuthKey og ClientID i kallene mot P360?

## Ikke-mål

- Å bygge et generisk rammeverk for alle fremtidige integrasjoner.
- Å optimalisere for ekstrem gjennomstrømming før vi har reelle bruks- og volummålinger.
- Å støtte dokumenttransformasjoner utover det som kreves for korrekt arkivering og metadata.

## Merknader ved speiling

- **Navngitte personer er utelatt.** Kilden navngir produkteier/fagansvarlig og arkitekt/tech lead. Repoet er offentlig, så navnene er erstattet med «Se Confluence». Rollene og teamene er beholdt.
- **Konkrete org- og miljø-URL-er er utelatt.** Kilden lister Salesforce prod-/SIT-URL-er og P360 prod-/test-URL-er. De er ikke hemmeligheter, men de er heller ikke nødvendige i et offentlig repo. De ligger i Confluence.
- Ingen nøkler, tokens, AuthKey-verdier eller ClientID-verdier er kopiert inn. Kilden inneholdt heller ikke slike verdier.
