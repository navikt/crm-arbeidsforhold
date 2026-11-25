# Produksjonsisolering av kontaktmodellen

Kan branchen `kontaktmodell/analyse-og-forslag` gå til produksjon utan at dagens åtferd endrar seg, og deretter
slåast på med brytarar? Denne vurderinga byggjer på kjeldekoden og scratch-orgen. Produksjon er ikkje undersøkt:
agentar har ikkje tilgang dit.

## Svar

**Ja, med vilkår.** Alt nytt i portalen og i innsendinga ligg bak `Feature_Flag__mdt`. Alle ti brytarane er
`false` i kjeldekoden, og ein brytar som manglar eller ikkje kan lesast, tel som av. Kontrollen ligg på serversida,
så ein brukar kan ikkje slå han på frå nettlesaren. Den gamle kontaktkoplinga blir skriven som før heilt til fase 7.

Vilkåra står under. Dei med høg alvorsgrad må vere oppfylte før pakka blir installert i produksjon.

## Vilkår og risiko

| #   | Alvor                     | Risiko                                                                                                                                                | Tiltak                                                                                                                 |
| --- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| R1  | Høg                       | Brytarpostane ligg i pakka. Ei pakkeoppgradering kan skrive over verdiar som er endra i Setup.                                                        | Endre brytarar berre med PR, eller flytt postane til unpackagable før første brytar blir slått på. Avgjerd før fase 2. |
| R2  | Høg dersom brytaren er på | `P360_Archive_Processing` er `false` i pakka. Står han på i produksjon i dag, kan oppgraderinga endre verdien.                                        | Les verdien i produksjon før installasjon. Avklar med Team Platforce om han skal stå som i dag.                        |
| R11 | Høg (vilkår)              | ACR-felta krev at «Contacts to Multiple Accounts» er slått på.                                                                                        | Stadfest innstillinga i produksjon. Er ho av, må Team Platforce avgjere før installasjon.                              |
| R3  | Middels                   | Banner og brødsmulesti hentar data med 2–4 ekstra Apex-kall per portalside.                                                                           | Målt i scratch utan merkbar forseinking. Vurder `cacheable=true` før fase 5.                                           |
| R4  | Middels                   | Innsendingsflytane er endra. Filteret `Role__c != 'Submitter'` gir same resultat så lenge `Role__c` er tom, slik han er når brytarane er av.          | Regresjonstest innsending i SIT2.                                                                                      |
| R13 | Middels (fase 2)          | `AAREG_Contact_Point__c.Contact__c` har `Restrict`. Når skuggeskriving er på, kan ein kontakt med kontaktpunkt ikkje slettast.                        | Avklar sletterutinen for kontaktar før fase 2.                                                                         |
| R14 | Middels                   | Experience-visningane blir ikkje deploya av CI. Publisering av nettstaden tek med alle ventande endringar. Dei nye rutene kan opnast med direkte URL. | Publiser i eit eige vindauge. Rutene viser ingenting nytt før brytarane er på.                                         |
| R5  | Låg                       | Andre flytar har fått nye greiner bak brytarane.                                                                                                      | Dekt av same regresjonstest.                                                                                           |
| R6  | Låg                       | `AAREG_CommunityPermission` får tilgang til to nye Apex-klassar.                                                                                      | Klassane sjekkar brytarane og gjer ingenting når dei er av.                                                            |
| R7  | Låg                       | Saksbehandlarar får lesetilgang til nye felt.                                                                                                         | Felta er tomme til fase 2.                                                                                             |
| R8  | Låg                       | Fana «Løyve og brukarar» og snarvegane blir synlege for alle med `AAREG_Admin_Viewer` med ein gong.                                                   | Berre lesing. Brukarlista krev eige løyve, sjå [Admin-appen](../../surfaces/aareg-admin-app.md#510-løyve-og-brukarar). |
| R9  | Låg                       | Appane får nye faner.                                                                                                                                 | Fanene viser tomme lister til fase 2.                                                                                  |
| R10 | Låg                       | Feltsporing er slått på for sju felt.                                                                                                                 | Kontroller at grensa på 20 sporingsfelt per objekt held i produksjon.                                                  |
| R12 | Låg                       | Nye unike felt.                                                                                                                                       | Felta er nye og tomme. Ingen eksisterande data blir påverka.                                                           |
| R15 | Låg                       | Hjelpekomponenten viser testlab-kommandoar.                                                                                                           | Kommandoane stoppar på alle org-ar som ikkje er scratch.                                                               |
| R16 | Låg                       | Pakka blir større.                                                                                                                                    | Ingen tiltak.                                                                                                          |

## Rekkjefølgje

1. **Evidens frå produksjon.** Eit menneske les verdien av `P360_Archive_Processing`, innstillinga
   «Contacts to Multiple Accounts» og talet på sporingsfelt. Lagre svara i saka.
2. **Pakke med alle brytarar av.** Ingen brytarar blir endra i same leveranse.
3. **Røyktest fase 1 «Mørk».** Innsending, kontaktkopling og P360-arkivering skal oppføre seg som før.
4. **Experience-visningane** blir publiserte i eit eige vindauge.
5. **Brytarar** blir slått på først når R1 er avgjort.
6. **Pilot** med løyvesettet `AAREG_ContactModel_Pilot` i fase 4.

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
