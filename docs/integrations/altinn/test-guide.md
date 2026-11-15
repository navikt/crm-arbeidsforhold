# Altinn: trygg testing med scenario

Bruk syntetiske data og skil mellom lokal komponenttest, Apex-test i
scratch-org og faktisk Altinn-kall. Denne guiden er ein plan; ingen test er
køyrd i samband med dokumentasjonsoppryddinga.

## Før du startar

1. For lokal UI-logikk, bruk eksisterande Jest-testar med mocka Apex.
   Dei verifiserer ikkje Salesforce-sharing eller live Altinn.
2. For org-test, stadfest den eksisterande `crm-arbeidsforhold` scratch-orgen
   og den eksakte installerte kodeversjonen før handling.
3. Kontroller at den tiltenkte brukaren har ei **eksplisitt, aktiv og gyldig**
   scenariotildeling og nødvendige rettar. Scenario av kan velje vanleg
   Altinn-integrasjon; feil i eit aktivert scenario skal ikkje gjerast om til
   eit live fallback.
4. Vurder også e-post, SMS, distribusjon, P360 og andre sideeffektar. Stopp
   dersom det ikkje er dokumentert korleis den aktuelle testen er isolert.
5. Bruk testdata frå [testdatastrategien](../../testing/aaregisteret-testdata-strategi.md),
   ikkje historiske brukaridentitetar frå testloggar.

## Test ein representativ tilgangskjede

| Steg | Handling                                                                                        | Forventa resultat / evidens                                                               |
| ---- | ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| 1    | Set opp syntetiske verksemder og eksplisitt scenariodata for vald testbrukar.                   | Oppsett og rolle er sporbare utan persondata eller credentials i loggen.                  |
| 2    | Les rå scenarioresultat for søknads- og støtteressurs kvar for seg.                             | Registrer `Permit`, `Deny` eller teknisk feil kvar for seg.                               |
| 3    | Vel verksemd og kontroller produktrespons og alle relevante panel.                              | Panel samsvarar med produktflagga; rå ressursavgjerd og produktrespons blir ikkje blanda. |
| 4    | Byt til ei verksemd utan same tilgang og test feil/tomt resultat separat.                       | Gamle panel blir rydda; feil blir ikkje presentert som eit vanleg avslag.                 |
| 5    | Test direkte tilgang til ei anna verksemd sine postar og filer i ei eiga, isolert negativ test. | Ingen utilsikta tilgang. Ein skjult UI-lenkje er ikkje tilstrekkeleg evidens.             |

Registrer dato, mål, commit/pakkeversjon, scenario-ID, rolle, forventa og
faktisk resultat, sanert evidens og opprydding. Sjå
[ALT-01 til ALT-05](../../testing/aaregisteret-scenario-testplan.md#2-tilgang-og-altinn)
for detaljer og [tilgangskjeda](tilgangskjede-og-scenario.md) for korleis
produktet i kjelda skil søknadsrett og generell tilgang.

Den [gamle Community Plus-guiden](../../archive/altinn/test-guide-community-plus-2026-10.md)
og [gamle testloggen](../../archive/altinn/altinn-test-log-2026-10.md) er
historisk materiale, ikkje instruksjonar for eit nytt mål eller ein ny brukar.
