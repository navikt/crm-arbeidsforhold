# Implementation readiness checklist

**Status:** Specification review checklist — not approval to implement

Denne listen samler avklaringene som må være på plass før utvikling av utvidelsen av den eksterne brukerflaten kan starte. `open-questions.md` inneholder den løpende beslutningsregistertabellen, mens dette dokumentet er samlet gate-/klareringsliste.

## Mest kritiske avklaringer for umiddelbar videregang

Disse punktene må være avklart før den første implementasjonsfasen kan startes:

1. **ADR-0002 er godkjent eller eksplisitt erstattet av en godkjent beslutning.**
    - Personkonto/Contact og ACR som relasjonsmodell må være avklart.
    - Rollverdier, aktive/inaktive relasjoner, start/sluttdato og flere samtidige roller må være avklart.

2. **ADR-0003 er godkjent eller eksplisitt erstattet av en godkjent beslutning.**
    - Master for person-e-post må være avklart.
    - KRR/AAREG/manuell prioritet, oppdatering og personvernhåndtering må være avklart.

3. **Endelig rolle- og capability-matrise er godkjent.**
    - Brukergruppe og valgt rolle må ikke alene gi tilgang.
    - Hvilke handlinger som er tillatt for virksomhetsrepresentant, arbeidsgiver, samarbeidspartner og privatperson må være godkjent.

4. **Datakilder for partner- og privatpersonroller er avklart.**
    - Hvilken kilde som avgjør representasjon og adgang må være bestemt.
    - ACR og Altinn må ikke blandes sammen som om de er samme type beslutning.

5. **Meldings-eierskap og filtermodell er avklart.**
    - Eierskap for Inquiry, Thread, Attachment og svar må være bestemt.
    - Om meldinger er organisasjonsbaserte eller personbaserte per rolle må være bestemt.
    - Om meldinger skal være synlige på tvers av roller for samme person må være bestemt.

6. **Direkte lenke-, portal- og feilkontrakt er godkjent.**
    - Samme tilgangskontroll for portal og direkte lenke.
    - Tydelig forskjell mellom denial, teknisk feil og manglende rolle.
    - Safe retur til portal med begrenset statuskode.

7. **Server-side tilgangskontroll og minimumsaksesscenario er avklart.**
    - Klientinput kan ikke gi tilgang.
    - Hver Apex-kontroller må gjøre sin egen kontroll.
    - CRUD/FLS, sharing og minimum-access testing må være en del av implementasjonskravet.

## 1. Roller, representasjon og brukergrupper

- [ ] Første releases brukergrupper er godkjent.
- [ ] Virksomhetsrepresentant er mappet mot dagens eksisterende flyt.
- [ ] Arbeidsgiver er mappet mot rolle, kontekst og Altinn-rettigheter.
- [ ] Samarbeidspartner/fullmektig er mappet mot godkjent kilde for representasjon og tilgang.
- [ ] Privatperson/arbeidstaker er mappet uten obligatorisk organisasjonskontekst.
- [ ] Fremtidige roller, for eksempel styremedlem, skal kunne legges til uten å bygge ny nav-logikk.
- [ ] Flere samtidige roller for samme person er eksplisitt behandlet.
- [ ] Valgt rolle styrer opplevelse/kontekst, men ikke tilgang alene.

## 2. Handlinger og capabilities

- [ ] Capabilities er definert for alle handlinger:
    - [ ] `APPLICATION`
    - [ ] `MY_APPLICATIONS`
    - [ ] `AGREEMENTS`
    - [ ] `SUPPORT`
    - [ ] `MESSAGES`
- [ ] Matrise er godkjent for virksomhetsrepresentant.
- [ ] Matrise er godkjent for arbeidsgiver.
- [ ] Matrise er godkjent for samarbeidspartner.
- [ ] Matrise er godkjent for privatperson.
- [ ] Matrise er godkjent for eksisterende brukerstøttebruker.
- [ ] Hvilke av `sok-tilgang` og `brukerstotte` som gir hvert funksjonsområde er avklart.
- [ ] Det er avklart om brukerstøtterettighet gir Mine avtaler og skrivetilgang til avtale-/kontaktdata.
- [ ] Serveren returnerer `GRANTED`, `DENIED` eller `TECHNICAL_ERROR`.
- [ ] UI viser bare handlinger som er server-godkjent.
- [ ] Direkte Apex-kall kontrollerer den samme capability-beslutningen som UI.

## 3. Organisasjons- og personkontekst

- [ ] `LastUsedOrganization__c` brukes bare for virksomhetsrepresentanter.
- [ ] Arbeidsgiver må ha valgt eller leverert organisasjonsnummer.
- [ ] Samarbeidspartner må ha riktig godkjent organisasjonskontekst.
- [ ] Privatperson trenger ikke organisasjonsnummer.
- [ ] Det støttes bare én aktiv arbeidskontekst per flyt der organisasjon er påkrevd.
- [ ] Manuell organisasjonsbytte og organisasjonsformater er avklart.
- [ ] Ugyldig, manipulert eller utdatert organisasjonsnummer håndteres sikkert.
- [ ] URL-parametere brukes bare som kontekst og ikke som autorisasjonsbevis.
- [ ] Serveren revaliderer valgt organisasjonskontekst ved hver handling.

## 4. ACR og representasjonsrelasjoner

- [ ] ADR-0002 har endelig godkjent status eller er erstattet av godkjent beslutning.
- [ ] Personkonto eller Contact er valgt som personmaster der det er relevant.
- [ ] ACR er godkjent som relasjonsmodell for person-og-organisasjon.
- [ ] Rollverdier i ACR/Roles er definert.
- [ ] Historikk og tidsbegrensning med StartDate, EndDate og IsActive er definert.
- [ ] Samme person med flere ACR-relasjoner og flere roller er avklart.
- [ ] Eierskap for opprettelse og vedlikehold av ACR er avklart.
- [ ] Datakilde for migrering fra eksisterende koblingsmodeller er avklart.
- [ ] Tilgang til ACR-data er avklart på nivåer for CRUD/FLS og record sharing.

## 5. E-post og kommunikasjon

- [ ] ADR-0003 har endelig godkjent status eller er erstattet av godkjent beslutning.
- [ ] Master for person-e-post er avklart.
- [ ] Standard `Contact.Email`, `email_AAREG_KRR__c` eller annen modell er godkjent.
- [ ] Prioritet mellom AAREG, KRR og manuell overstyring er avklart.
- [ ] Oppdateringsfrekvens og synkronisering er avklart.
- [ ] Brukerstøtte sin rett til å korrigere e-post er avklart.
- [ ] Privatpersonens rett til å korrigere e-post er avklart.
- [ ] Historikk, retention og kilde-sporing er avklart.
- [ ] Email-to-Case og svar/trådkorrelasjon er avklart.
- [ ] E-postadgang, logging og personvern er godkjent.
- [ ] ADR-0003s «svar fra NAV/retur»-beskrivelse er avklart mot Confluence der den er tvetydig.

## 6. Meldinger, Inquiry og tråder

- [ ] Hvem som eier Inquiry, Thread, Attachment og svar er avklart.
- [ ] Om meldinger er personbaserte eller organisasjonsbaserte per rolle er avklart.
- [ ] Virksomhetsrepresentanter beholder dagens organisasjonsbaserte meldingsmodell.
- [ ] Arbeidsgiver/samarbeidspartner/privatperson har godkjent person- eller rollebaserte filtreringsregel.
- [ ] Meldinger synlige på tvers av roller for samme person er avklart.
- [ ] Meldinger begrenset til rolle/kontekst der meldingen ble opprettet er avklart.
- [ ] Serverfilter er implementert uavhengig av skjult navigasjon.
- [ ] Feil ved tomt resultat er skilt fra teknisk feil.

## 7. Portal, rollelenker og Experience Cloud

- [ ] Dagens Experience Cloud-URL er avklart som ny portal eller fallback.
- [ ] Rolle-sider har stabile, godkjente URLer/routing.
- [ ] Direkte lenker kjører samme tilgangskontroll som portalnavigasjon.
- [ ] Manglende tilgang sender brukeren til portalen med begrenset statuskode.
- [ ] Teknisk feil viser egen feilmelding og retry, ikke «ingen tilgang».
- [ ] Login/redirect og direkte link uten pålogging er avklart.
- [ ] Return-URL og redirect-beskyttelse er avklart.
- [ ] Experience Cloud audience/pageAccess er ikke brukt som eneste tilgangsvern.
- [ ] Alle serverkall har eksplisitt autorisasjon uavhengig av Experience Cloud-sidevisibility.

## 8. Feature toggle og overgang

- [ ] Togglemekanismen støtter faktisk Experience Cloud/LWC-entry.
- [ ] Verdi for on er avklart.
- [ ] Verdi for off er avklart.
- [ ] Manglende flaggverdi er fail-closed.
- [ ] Teknisk feil ved flaggvurdering er fail-closed.
- [ ] Toggle påvirker bare brukeropplevelse, ikke tilgangsregler.
- [ ] Cache- og oppdateringsatferd er avklart.
- [ ] Aktivering, rollback og feilmeldinger har eiere.
- [ ] Exit-kriterier for å fjerne gammel logikk og toggle er avklart.
- [ ] Gamle og nye flyter testes mot samme access-rules under overgang.

## 9. Sikkerhet, tilgang og personvern

- [ ] Bruker-ID hentes alltid fra `UserInfo.getUserId()` på serveren.
- [ ] Klienten sender aldri et `userId` som tilgangsbevis.
- [ ] CRUD/FLS valideres i relevant execution mode.
- [ ] Record sharing er avklart for alle lesing og skriving.
- [ ] Metoder i system-mode har eksplisitte data- og action-grenser.
- [ ] Hele dagens brukerflate er testet med minimum-access external user der relevant.
- [ ] Direkt Apex-kall som ikke kommer fra LWC er testet.
- [ ] Logging inkluderer ikke unødvendig persondata.
- [ ] E-post-, ACR-, Inquiry-, Thread- og Attachment-data behandles som rød sone.
- [ ] Human security/personvern-review er gjennomført før implementasjon av disse områdene.

## 10. Ytelse, cache og drift

- [ ] «Sanntid» er definert som målbart oppfriskingskrav.
- [ ] Altinn-kall og cache-strategi er avklart.
- [ ] Cache må aldri erstatte autorisasjonskontroll.
- [ ] Cache invalidation ved rolle-/organisasjonsbytte er avklart.
- [ ] Timeout-, retry- og circuit-breaker-kontrakt er avklart der det er relevant.
- [ ] Tomt resultat er ikke lik teknisk feil.
- [ ] Driftsansvar og alarm ved access-kildefeil er avklart.

## 11. Test- og verifikasjonskrav

- [ ] Jest-tester for portal, rollevalg og feiltilstander er planlagt.
- [ ] Jest-tester for ukjent rolle og manipulert URL er planlagt.
- [ ] Apex-tester for positive, negative og technical-error scenarios er planlagt.
- [ ] Apex-tester bruker `System.runAs(minimumAccessUser)` der oppførselen ikke krever høyere tilgang.
- [ ] Tester dekker alle roller og representative multi-role scenarios.
- [ ] Eksisterende virksomhetsrepresentantfløte er regresjonstestet.
- [ ] Eksisterende brukerstøttefløte er regresjonstestet.
- [ ] Toggle on/off/missing/error er testet.
- [ ] Direct URL og portal navigation er testet i godkjent ikke-produksjonsorg.
- [ ] UX, UU, direct-call safety og data access er verifisert separat.

## 12. Godkjennings- og leveransegate

- [ ] Produktowner har godkjent målbildet og brukergruppene.
- [ ] Technical lead har godkjent server/service- og kontekstmodell.
- [ ] Security/privacy-eier har godkjent rødsoneområdene.
- [ ] ADR-0002 er godkjent eller eksplisitt erstattet.
- [ ] ADR-0003 er godkjent eller eksplisitt erstattet.
- [ ] Rolle-/capability-matrise er godkjent.
- [ ] Portal-, direct-link-, feil- og toggle-kontrakt er godkjent.
- [ ] Organisasjons- og personkontekst er avklart.
- [ ] Regression strategy er godkjent.
- [ ] Runbook for rollout og rollback er godkjent.
- [ ] Skilt fra implementasjonsbeslutning at ingen kode startes før gate er oppfylt.

## Anbefalt avklaringsrekkefølge

1. GODKJENN målbilde: portal, rolepages, reuse og overgang.
2. GODKJENN rolle-/capability-matrise og datakilder.
3. GODKJENN ADR-0002 og deretter ADR-0003.
4. GODKJENN meldings-eierskap, email/threads og personvern.
5. GODKJENN server-access, feature-toggle og portal/direct-link-kontrakt.
6. FØRST DERETTER: start implementasjon i små vertikale skiver med regression baseline.
