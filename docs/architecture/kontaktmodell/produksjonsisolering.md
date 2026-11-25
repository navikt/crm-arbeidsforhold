# Produksjonsisolering av kontaktmodellen

Kan branchen `kontaktmodell/analyse-og-forslag` gå til produksjon utan at dagens åtferd endrar seg, og deretter
slåast på med brytarar? Denne vurderinga byggjer på kjeldekoden og scratch-orgen. Produksjon er ikkje undersøkt:
agentar har ikkje tilgang dit.

## Svar

**Ja, men berre dersom verdiane som gjeld i produksjon i dag, blir bevarte.** Alt nytt i portalen og i
innsendinga ligg bak `Feature_Flag__mdt`. Dei ni nye brytarane for kontaktmodellen er `false` i kjeldekoden, og ein
brytar som manglar eller ikkje kan lesast, tel som av. Kontrollen ligg på serversida, så ein brukar kan ikkje slå han
på frå nettlesaren. Den gamle kontaktkoplinga blir skriven som før heilt til fase 7.

Diffen mot `main` endrar ingen eksisterande metadatapostar. Han legg berre til nye. Likevel installerer kvar
pakkeversjon alle postane i pakka på nytt, også `Feature_Flag.P360_Archive_Processing`, som er `false` både på `main`
og på branchen. Er han sett til `true` i produksjon i dag, slår installasjonen av P360-arkiveringa. Då er påstanden
om uendra åtferd feil.

Pakka skal difor ikkje installerast før vilkåra R2 og R11 er oppfylte. Er produksjonsverdien ukjend, blir det ikkje
installert.

## Vilkår og risiko

| #   | Alvor                       | Risiko                                                                                                                                                | Tiltak                                                                                                                                                                                                                                                                                                                       |
| --- | --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R1  | Høg                         | Brytarpostane ligg i pakka. Kvar pakkeoppgradering skriv verdien i kjeldekoden over verdien i Setup.                                                  | Første installasjon er trygg, sidan dei nye brytarane ikkje har nokon produksjonsverdi frå før. Før første brytar blir slått på: avgjer at brytarar berre blir endra med PR, slik at kjeldekoden alltid har produksjonsverdien, eller flytt postane ut av pakka.                                                             |
| R2  | Høg, blokkerer installasjon | `P360_Archive_Processing` er `false` i pakka. Installasjonen set produksjonsverdien til `false`, same kva han er i dag.                               | Ein person les verdien i produksjon før pakkeversjonen blir bygd. Er han `true`, må kjeldekoden setjast til `true` i ein eigen godkjend PR før pakkeversjonen blir bygd. Er han `false`, trengst ingen endring. Å setje verdien attende manuelt etter installasjonen er ikkje godt nok, for då står arkiveringa av ei stund. |
| R11 | Høg, blokkerer installasjon | ACR-felta krev at «Contacts to Multiple Accounts» er slått på.                                                                                        | Stadfest innstillinga i produksjon. Er ho av, blir ikkje pakka installert. Det å slå ho på er ei eiga endring som Team Platforce må avgjere.                                                                                                                                                                                 |
| R3  | Middels                     | Banner og brødsmulesti hentar data med 2–4 ekstra Apex-kall per portalside.                                                                           | Målt i scratch utan merkbar forseinking. Vurder `cacheable=true` før fase 5.                                                                                                                                                                                                                                                 |
| R4  | Middels                     | Innsendingsflytane er endra. Filteret `Role__c != 'Submitter'` gir same resultat så lenge `Role__c` er tom, slik han er når brytarane er av.          | Regresjonstest innsending i SIT2.                                                                                                                                                                                                                                                                                            |
| R13 | Middels (fase 2)            | `AAREG_Contact_Point__c.Contact__c` har `Restrict`. Når skuggeskriving er på, kan ein kontakt med kontaktpunkt ikkje slettast.                        | Avklar sletterutinen for kontaktar før fase 2.                                                                                                                                                                                                                                                                               |
| R14 | Middels                     | Experience-visningane blir ikkje deploya av CI. Publisering av nettstaden tek med alle ventande endringar. Dei nye rutene kan opnast med direkte URL. | Publiser i eit eige vindauge. Rutene viser ingenting nytt før brytarane er på.                                                                                                                                                                                                                                               |
| R5  | Låg                         | Andre flytar har fått nye greiner bak brytarane.                                                                                                      | Dekt av same regresjonstest.                                                                                                                                                                                                                                                                                                 |
| R6  | Låg                         | `AAREG_CommunityPermission` får tilgang til to nye Apex-klassar.                                                                                      | Klassane sjekkar brytarane og gjer ingenting når dei er av.                                                                                                                                                                                                                                                                  |
| R7  | Låg                         | Saksbehandlarar får lesetilgang til nye felt.                                                                                                         | Felta er tomme til fase 2.                                                                                                                                                                                                                                                                                                   |
| R8  | Låg                         | Fana «Løyve og brukarar» og snarvegane blir synlege for alle med `AAREG_Admin_Viewer` med ein gong.                                                   | Berre lesing. Brukarlista krev eige løyve, sjå [Admin-appen](../../surfaces/aareg-admin-app.md#510-løyve-og-brukarar).                                                                                                                                                                                                       |
| R9  | Låg                         | Appane får nye faner.                                                                                                                                 | Fanene viser tomme lister til fase 2.                                                                                                                                                                                                                                                                                        |
| R10 | Låg                         | Feltsporing er slått på for sju felt.                                                                                                                 | Kontroller at grensa på 20 sporingsfelt per objekt held i produksjon.                                                                                                                                                                                                                                                        |
| R12 | Låg                         | Nye unike felt.                                                                                                                                       | Felta er nye og tomme. Ingen eksisterande data blir påverka.                                                                                                                                                                                                                                                                 |
| R15 | Låg                         | Hjelpekomponenten viser testlab-kommandoar.                                                                                                           | Kommandoane stoppar på alle org-ar som ikkje er scratch.                                                                                                                                                                                                                                                                     |
| R16 | Låg                         | Pakka blir større.                                                                                                                                    | Ingen tiltak.                                                                                                                                                                                                                                                                                                                |

## Rekkjefølgje

1. **Evidens frå produksjon.** Eit menneske les verdien av `P360_Archive_Processing`, innstillinga
   «Contacts to Multiple Accounts» og talet på sporingsfelt. Lagre svara i saka. Utan desse svara blir det ikkje
   installert.
2. **Kjeldekoden får produksjonsverdiane.** Er `P360_Archive_Processing` `true` i produksjon, blir han sett til
   `true` i ein eigen PR før pakkeversjonen blir bygd. Les verdien i pakkeversjonen før installasjon.
3. **Pakke med alle brytarane for kontaktmodellen av.** Ingen av dei blir endra i same leveranse.
4. **Røyktest fase 1 «Mørk».** Innsending, kontaktkopling og P360-arkivering skal oppføre seg som før. Kontroller at `P360_Archive_Processing` har same verdi som før installasjonen.
5. **Experience-visningane** blir publiserte i eit eige vindauge.
6. **Brytarar** blir slått på først når R1 er avgjort.
7. **Pilot** med løyvesettet `AAREG_ContactModel_Pilot` i fase 4.

Fasane og tilbakerullinga står i [utrulling.md](utrulling.md).

## Tilbakerulling

Kvar fase blir rulla tilbake ved å setje brytarane til profilen for fasen før. Den gamle modellen blir skriven
vidare, så ingen fase før fase 7 krev at data blir flytta tilbake. Admin-flatene endrar ingen data og kan fjernast
ved å ta bort fana frå appen og løyvesetta frå brukarane.

## Grunnlag

- Kjeldekoden på branchen og diffen mot `main`.
- Køyringar i scratch-orgen `crm-arbeidsforhold`: Apex-testar, Jest og Playwright. Sjå
  [testing/README.md](testing/README.md).
- SIT2 og produksjon er ikkje undersøkte.
