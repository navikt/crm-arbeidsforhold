---
adr: 0002
tittel: AccountContactRelation objekt brukes for kontakter tilknyttet Personkontoer
status: Foreslått
dato: 2026-08-26
kilde: Confluence — ADR-0002 (PDF-eksport)
hentet: 2026-09-08
speilkopi: ja
merknad: Navngitte beslutningstakere er utelatt ved speiling.
---

# ADR-0002: AccountContactRelation objekt brukes for kontakter tilknyttet Personkontoer

**Status:** Foreslått
**Dato:** 2026-08-26
**Beslutningstakere:** Se Confluence

## 1.1. Kontekst og problemstilling

Vi trenger et skalerbart mønster for å håndtere relasjoner der Kontakter eller Personkontoer kan være tilknyttet flere Kontoer på tvers av ulike roller (f.eks. arbeidstaker, partner, arbeidsgiver).

Vår nåværende datamodell krever at enkelte privatpersoner samhandler med NAV som en arbeidstaker eller som samarbeidspartnere eller arbeidsgivere. Å basere seg utelukkende på det standard direkte `AccountId`-feltet på Kontakt-objektet begrenser en post til en enkelt primærkonto.

Vi trenger derfor en løsning som tillater:

- Flere kontotilknytninger for en enkelt person.
- Egendefinert rollesporing (f.eks. arbeidstaker, Partner, arbeidsgiver osv.).
- Historisk sporing av aktive og inaktive relasjoner ved hjelp av start- og sluttdatoer.
- Minimal egendefinert utvikling ved å utnytte innebygd Salesforce-funksjonalitet.

## 1.2. Beslutningsdrivere

- **Funksjonelle krav:** Behovet for at en enkeltperson (kontakt/personkonto) skal kunne ha flere roller eller være knyttet til flere bedrifter samtidig (f.eks. både ansatt og partner).
- **Forretningsverdi / Effektivitet:** Ønske om å bruke standardplattformen (Out-of-the-box) for å slippe å bygge, teste og vedlikeholde egendefinerte kode- og løsninger (tilpasset koblingsobjekt).
- **Vedlikeholdbarhet og livssyklus:** Behovet for en løsning som er støttet av fremtidige Salesforce-oppgraderinger, slik at teknisk gjeld holdes lavt.
- **Historikk og sporing:** Mulighet å kunne spore historiske data over tid (f.eks. start- og sluttdatoer for en rolle eller tilknytning).
- **Brukeropplevelse (UI):** Ønske om å tilby en kjent og standard brukerflate for brukerstøtte med standard relaterte lister.
- **Tidspunkt:** Vi er i startfasen av å gjennomføre en brukerstøtteløsning for privatpersoner, og det er derfor viktig å avklare hvordan kontakter knyttet til personkontoer skal brukes i samhandlingen med dem. Hvis denne beslutningen ikke er på plass, risikerer vi å innføre en løsning som ikke er vedlikeholdbar over tid.

## 2. Beslutning

Vi vil bruke Salesforces standard **`AccountContactRelation` (ACR)**-funksjonalitet (Kontakter til flere kontoer) i stedet for egendefinerte koblingsobjekter eller å stole utelukkende på direkte foreldre-barn-oppslag.

Vi velger `AccountContactRelation` (ACR) fordi det gir et robust, plattformnært rammeverk for mange-til-mange-relasjoner mellom konto og kontakt. Det fjerner vedlikeholdskostnadene ved egendefinerte koblingsobjekter samtidig som det støtter rolletildeling og historisk sporing ut av boksen.

### 2.1. Positive konsekvenser

- Innebygd Salesforce-funksjonalitet (Kontakter til flere kontoer).
- Innebygde relaterte lister på både Konto- og Kontakt-sideoppsett.
- Innebygd flervalgspicklistefelt for `Roles` som kan tilpasses for verdier som _Ansatt_, _Partner_ og _Arbeidsgiver_.
- Innebygde sporingsfelt for `StartDate`, `EndDate` og `IsActive`.
- Fullt støttet av standard rapportering, listevisninger og tilgangs- og delingsregler.

### 2.2. Negative konsekvenser

- Krever aktivering av «Kontakter til flere kontoer» i Oppsett (Setup). Standard objektatferd krever nøye gjennomgang under datamigrering.

### 2.3. Annet

Konfigurasjon:

- Aktiver Kontakter til flere kontoer under Oppsett (`Account Settings`).
- Tilpass standard flervalgspickliste `Roles` på `AccountContactRelation`-objektet for å inkludere prosjektspesifikke verdier (f.eks. _Ansatt_, _Arbeidsgiver_, _Partner_).
- Konfigurer sideoppsett slik at de inkluderer de relaterte listene Relaterte kontakter og Relaterte kontoer.

Datamigrering: Sørg for at datainnlastingsskript knytter flerkontolinker direkte til `AccountContactRelation`-objektet i stedet for å forsøke å oppdatere primære oppslagsfelt.

Automatisering: Opplæring av teammedlemmer og oppdatering av eventuelle nedstrøms-triggere/flyter for å sjekke ACR-poster i stedet for eldre egendefinerte felt ved evaluering av relasjoner til flere kontoer.

## Merknader ved speiling

- Navngitte beslutningstakere er utelatt fordi repoet er offentlig. Se Confluence.
- Kilden har enkelte skrivefeil (`Personkontorer`, `enkleteperson`, `begrenser en post`). Åpenbare skrivefeil er rettet i denne speilkopien; innholdet er ikke endret.
- **Dato rettet.** PDF-eksporten oppgir 2025-08-26. Riktig år er 2026, bekreftet av dokumenteier. Rettet her.
