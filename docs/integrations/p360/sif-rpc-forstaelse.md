---
tittel: P360 SIF RPC-forståelse og implementasjonsstatus
kilde: Jira- og Confluence-speilkopier for P360-integrasjonen
hentet: 2026-09-08
speilkopi: ja
---

# P360 SIF RPC-forståelse og implementasjonsstatus

## Kort konklusjon

P360-integrasjonen i repoet følger den samme modellen som dokumentasjonen beskriver:

- Salesforce er arbeidsflate og orkestrering.
- Public 360 er det autoritative arkiv- og journalsystemet.
- SIF RPC er transportlaget, ikke forretningslogikken.
- Salesforce skal sende strukturert metadata og dokumentreferanser, ikke bygge P360-arkivlogikk direkte i Flow, trigger eller LWC.

Det betyr at det riktige implementasjonsgrensene er:

- domain og use case i Aa-registeret-laget
- mapper og kontrakt i integrasjonslaget
- adapter og transport i P360-laget
- autentisering og konfigurasjon i Named Credential / External Credential

## Hva dokumentasjonen sier om SIF RPC

Fra de speilede P360-dokumentene er forståelsen:

1. Salesforce bruker direkte, punkt-til-punkt kommunikasjon mot P360.
2. Autentisering er maskin-til-maskin via OAuth 2.0 mot Microsoft Entra ID.
3. Ved siden av token sendes `AuthKey` og `ClientID` for identifikasjon av kallet.
4. Konfigurasjon skal ligge i Salesforce-metadata for Named Credential og External Credential.
5. P360-endepunktene er et teknisk transportlag, mens domenelogikken ligger i Salesforce-arkitektur og P360-arkivmodell.
6. Sensitive data og dokumentinnhold skal ikke logges.
7. Korrelasjons-ID skal føres gjennom hele flyten for feilsøking og retry.

Dette samsvarer med den repo-lokale modellen i [docs/integrations/p360/overordnet-rammeverk.md](overordnet-rammeverk.md), [docs/integrations/p360/lagdelt-struktur-og-namnestandard.md](lagdelt-struktur-og-namnestandard.md) og [force-app/integration/p360/README.md](../../../force-app/integration/p360/README.md).

## Kjernearkitektur i repoet

Repoet har allerede den grunnleggende P360-strukturen som dokumentasjonen beskriver:

- [force-app/integration/p360/README.md](../../../force-app/integration/p360/README.md)
- [force-app/integration/p360/classes/adapter/P360_ArchiveAdapter.cls](../../../force-app/integration/p360/classes/adapter/P360_ArchiveAdapter.cls)
- [force-app/integration/p360/classes/client/P360_RpcClient.cls](../../../force-app/integration/p360/classes/client/P360_RpcClient.cls)
- [force-app/integration/p360/classes/orchestration/AAREG_ArchiveApplicationOrchestrator.cls](../../../force-app/integration/p360/classes/orchestration/AAREG_ArchiveApplicationOrchestrator.cls)

Mønsteret er tydelig:

- `AAREG_...` for use case / Salesforce-domene
- `P360_...` for P360-kontrakt og transport
- mapper og DTO-er skiller mellom interne modeller og eksterne kontrakter
- exceptions er egne P360-feilklasser som skal klassifiseres som kontrakt, transport eller integrasjonsfeil

## Hva som er avklart og hva som fortsatt må avklares

### Avklart i repoet

- P360-området er etablert i repoet som egen integrasjonsdomene.
- Lagdeling og ansvar er dokumentert i [docs/integrations/p360/lagdelt-struktur-og-namnestandard.md](lagdelt-struktur-og-namnestandard.md).
- Salesforce og P360-siden er skilt tydelig i navngivning og ansvar.
- Dokumentasjon for strukturen og sikkerhetsmodell er speilet inn i repoet.

### Få tilbakeværende avklaringer som fortsatt er reelle blocker

Disse må løses før implementasjonen kan gå videre uten å bygge på uklar kontrakt:

- presise feltnavn for `AuthKey` og `ClientID` i SIF RPC-kallet
- nøyaktig exception-hierarki for kontrakt, transport, auth, retry og validering
- full kontrakt for request/response DTO-er for case, journalpost og dokument
- tydelig idempotens- og retry-strategi
- ekstern ID-strategi og hvordan P360-id lagres tilbake i Salesforce

Det er disse punktene som fortsatt utgjør de relevante åpne GitHub-issue-funnene, ikke den generelle repo-arkitekturen.

## Relevante issue-funn

De faktiske blocker-issueene som fortsatt er relevante for implementasjonen er de som dekker:

- exception-hierarki og feilmodell
- navnestandard og kontrakt/DTO-justering
- kontrakt dokumentasjon for P360-operasjoner
- rett sikkerhetsmodell for auth og header-konfigurasjon

Dette er også de punktene som er eksplisitt omtalt i [docs/context/p360/jira-oversikt.md](../context/p360/jira-oversikt.md) og [docs/context/p360/jira-deloppgaver.md](../context/p360/jira-deloppgaver.md).

## Nåværende anbefalt status

Vi skal ikke bruke mer tid på gammel dokumentasjonsstøy eller speilingsarbeid som allerede er løst. Vi skal holde fokus på de få tingene som faktisk fortsatt blockerer implementasjonen:

1. avklare den endelige exception-hierarkiet
2. definere de faktiske P360 DTO-kontraktene
3. verifisere auth/header-konfigurasjon mot SIF RPC
4. skrive den første faktisk fungerende adapter/transport-implementasjonen

Når dette er avklart, er repoet klart for å fortsette med real P360/Salesforce-implementasjon uten grunnleggende usikkerhet.
