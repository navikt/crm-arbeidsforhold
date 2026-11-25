# Produksjonsisolering av kontaktmodellen

Kan branchen `kontaktmodell/analyse-og-forslag` gå til produksjon utan at dagens åtferd endrar seg, og deretter
slåast på med brytarar? Denne vurderinga byggjer på kjeldekoden og scratch-orgen. Produksjon er ikkje undersøkt:
agentar har ikkje tilgang dit.

## Svar

**Ja.** Alt nytt i portalen og i innsendinga ligg bak `Feature_Flag__mdt`. Dei ni nye brytarane for
kontaktmodellen er `false` i kjeldekoden, og ein brytar som manglar eller ikkje kan lesast, tel som av. Kontrollen
ligg på serversida, så ein brukar kan ikkje slå han på frå nettlesaren. Den gamle kontaktkoplinga blir skriven som
før heilt til fase 7.

Diffen mot `main` endrar ingen eksisterande metadatapostar. Han legg berre til nye. Kvar pakkeversjon installerer
likevel alle postane i pakka på nytt, også `Feature_Flag.P360_Archive_Processing`. Han er `false` både på `main`, på
branchen og i produksjon, så installasjonen endrar ikkje verdien.

Produkteigar stadfesta dei blokkerande vilkåra R2 og R11 og kontrollen i R10 i produksjon 2026-11-25, sjå
[Stadfesta i produksjon](#stadfesta-i-produksjon). Experience-sidene er ikkje med i pakka. Dei blir deploya
manuelt etter [R14: Experience-sidene steg for steg](#r14-experience-sidene-steg-for-steg).

## Stadfesta i produksjon

Produkteigar las verdiane i produksjon 2026-11-25. Agenten har ikkje vore i produksjon.

| Vilkår | Spørsmål                                     | Svar i produksjon | Følgje                                                                                                             |
| ------ | -------------------------------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------ |
| R2     | Verdien av `P360_Archive_Processing`         | `false`           | Same verdi som i pakka. Det trengst ingen eigen PR.                                                                |
| R11    | Er «Contacts to Multiple Accounts» slått på? | Ja                | ACR-felta kan installerast.                                                                                        |
| R10    | Grense for felt med feltsporing per objekt   | 20                | Det høgste talet etter installasjonen er 4, på `Application__c`. Alle tre objekta har allereie historikk slått på. |

## Kva brukarane merkar når brytarane er av

Kontrollert fil for fil mot `origin/main` 2026-11-25. Alle eksisterande filer som PR-en endrar, er gjennomgått.

| Brukargruppe    | Endring                                                                                     | Merkar brukaren noko?                                                                                                                                                                        |
| --------------- | ------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Eksterne        | Forside, «Mine søknader», «Mine avtaler», «Mine meldingar», søknad, avtale og kontaktskjema | Nei. Banner og brødsmulesti spør `AAREG_EntryPortalController.getPortal`. Dei viser den gamle varianten når portalen er av eller kallet feilar, men kjem ein augeblink etter resten av sida. |
| Eksterne        | Lenkja «Min profil» på forsida (`aareg_home`)                                               | Nei. Lenkja blir berre vist når `AAREG_ContactModel_Profile` er på.                                                                                                                          |
| Eksterne        | Innsending (`AAREG_ApplicationController`)                                                  | Nei. P360-arkivering og skuggeskriving sjekkar brytaren før dei gjer noko. Filteret `Role__c != 'Submitter'` tek med tomme verdiar, så kontaktlista er den same.                             |
| Eksterne        | Ny metode `getApplicationAttachments`                                                       | Nei. Ingen komponent kallar han enno.                                                                                                                                                        |
| Saksbehandlarar | Tre flytar for innsending og vedtak                                                         | Nei. `AAREG_ContactModelRecipient` returnerer den gamle mottakaren når brytarane er av.                                                                                                      |
| Saksbehandlarar | Panelet for kontaktmodellen på søknad, søknad i støtteappen og konto                        | Nei. Synlegheitsregelen krev løyva `AAREG_ContactModelPilot` eller `AAREG_ContactModelMigrate`, og ingen har dei før dei blir tildelte.                                                      |
| Saksbehandlarar | `AAREG_Arbeidsforhold_Saksbehandling` får lesetilgang til 7 nye felt og éin ny Apex-klasse  | Nei. Ingen tilgang er fjerna eller gjord skrivbar.                                                                                                                                           |
| Saksbehandlarar | Feltsporing på 6 felt                                                                       | Ja, litt. Nye endringar i status, eigar og svarfrist blir viste i historikken.                                                                                                               |
| Administratorar | Arbeidsforhold Admin: startsida får snarvegar, og appen får seks nye faner                  | Ja, for brukarar med `AAREG_Admin_Viewer`. Dei ser nye faner for brukarreise, løyve og opprydding, med berre lesetilgang. Fanene for kontaktmodellen krev eigne løyvesett.                   |

## Vilkår og risiko

| #   | Alvor            | Risiko                                                                                                                                        | Tiltak                                                                                                                                                                                                                                                           |
| --- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R1  | Høg              | Brytarpostane ligg i pakka. Kvar pakkeoppgradering skriv verdien i kjeldekoden over verdien i Setup.                                          | Første installasjon er trygg, sidan dei nye brytarane ikkje har nokon produksjonsverdi frå før. Før første brytar blir slått på: avgjer at brytarar berre blir endra med PR, slik at kjeldekoden alltid har produksjonsverdien, eller flytt postane ut av pakka. |
| R2  | Stadfesta        | `P360_Archive_Processing` er `false` i pakka. Installasjonen set produksjonsverdien til `false`.                                              | Stadfesta `false` i produksjon 2026-11-25. Same verdi, så ingenting endrar seg. Les verdien på nytt før kvar seinare pakkeversjon dersom han kan ha blitt endra i Setup.                                                                                         |
| R11 | Stadfesta        | ACR-felta krev at «Contacts to Multiple Accounts» er slått på.                                                                                | Stadfesta på i produksjon 2026-11-25.                                                                                                                                                                                                                            |
| R3  | Middels          | Banner og brødsmulesti hentar data med 2–4 ekstra Apex-kall per portalside.                                                                   | Målt i scratch utan merkbar forseinking. Vurder `cacheable=true` før fase 5.                                                                                                                                                                                     |
| R4  | Middels          | Innsendingsflytane er endra. Filteret `Role__c != 'Submitter'` gir same resultat så lenge `Role__c` er tom, slik han er når brytarane er av.  | Regresjonstest innsending i SIT2.                                                                                                                                                                                                                                |
| R13 | Middels (fase 2) | `AAREG_Contact_Point__c.Contact__c` har `Restrict`. Når skuggeskriving er på, kan ein kontakt med kontaktpunkt ikkje slettast.                | Avklar sletterutinen for kontaktar før fase 2.                                                                                                                                                                                                                   |
| R14 | Middels          | Experience-sidene er ikkje med i pakka. Publisering av nettstaden tek med alle ventande endringar. Dei nye rutene kan opnast med direkte URL. | Deploy og publiser manuelt etter [stega under](#r14-experience-sidene-steg-for-steg). Rutene viser ingenting nytt før brytarane er på.                                                                                                                           |
| R5  | Låg              | Andre flytar har fått nye greiner bak brytarane.                                                                                              | Dekt av same regresjonstest.                                                                                                                                                                                                                                     |
| R6  | Låg              | `AAREG_CommunityPermission` får tilgang til to nye Apex-klassar.                                                                              | Klassane sjekkar brytarane og gjer ingenting når dei er av.                                                                                                                                                                                                      |
| R7  | Låg              | Saksbehandlarar får lesetilgang til nye felt.                                                                                                 | Felta er tomme til fase 2.                                                                                                                                                                                                                                       |
| R8  | Låg              | Fana «Løyve og brukarar» og snarvegane blir synlege for alle med `AAREG_Admin_Viewer` med ein gong.                                           | Berre lesing. Brukarlista krev eige løyve, sjå [Admin-appen](../../surfaces/aareg-admin-app.md#510-løyve-og-brukarar).                                                                                                                                           |
| R9  | Låg              | Appane får nye faner.                                                                                                                         | Fanene viser tomme lister til fase 2.                                                                                                                                                                                                                            |
| R10 | Stadfesta        | Feltsporing er slått på for 6 felt: 4 på `Application__c`, 1 på `Application_Decision__c` og 1 på `Inquiry__c`.                               | Grensa i produksjon er 20 per objekt, stadfesta 2026-11-25. Det høgste talet blir 4.                                                                                                                                                                             |
| R12 | Låg              | Nye unike felt.                                                                                                                               | Felta er nye og tomme. Ingen eksisterande data blir påverka.                                                                                                                                                                                                     |
| R15 | Låg              | Hjelpekomponenten viser testlab-kommandoar.                                                                                                   | Kommandoane stoppar på alle org-ar som ikkje er scratch.                                                                                                                                                                                                         |
| R16 | Låg              | Pakka blir større.                                                                                                                            | Ingen tiltak.                                                                                                                                                                                                                                                    |

## Rekkjefølgje

1. **Evidens frå produksjon.** Gjort 2026-11-25, sjå [Stadfesta i produksjon](#stadfesta-i-produksjon).
2. **Kjeldekoden har produksjonsverdiane.** `P360_Archive_Processing` er `false` både i kjeldekoden og i
   produksjon. Les verdien på nytt før ein seinare pakkeversjon dersom han kan ha blitt endra i Setup.
3. **Pakke med alle brytarane for kontaktmodellen av.** Ingen av dei blir endra i same leveranse.
4. **Røyktest fase 1 «Mørk».** Innsending, kontaktkopling og P360-arkivering skal oppføre seg som før. Kontroller at `P360_Archive_Processing` har same verdi som før installasjonen.
5. **Experience-sidene** blir deploya og publiserte i eit eige vindauge, sjå [R14](#r14-experience-sidene-steg-for-steg).
6. **Brytarar** blir slått på først når R1 er avgjort.
7. **Pilot** med løyvesettet `AAREG_ContactModel_Pilot` i fase 4.

Fasane og tilbakerullinga står i [utrulling.md](utrulling.md).

## Kva ein merge til `main` gjer

Ein merge startar `[PUSH] Create Package`. Den delte workflowen `packageCreate.yml` i `navikt/crm-workflows-base`
slettar `force-app/unpackagable` og byggjer ein betaversjon av pakka. Så installerer han versjonen i SIT-sandkassa
og lagar ein GitHub-release. Ingenting skjer i produksjon. Produksjon får versjonen først når han blir promotert og
installert manuelt med `package-promotion.yml`, med godkjenning frå Team Platforce.

## R14: Experience-sidene steg for steg

Pakka tek ikkje med `force-app/unpackagable/experiences/Aa_registret1`. Desse filene må deployast manuelt:

| Filer                                                                                                                                                                 | Endring                                                                                            |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `routes/` og `views/` for `minProfil`, `arbeidsgiver`, `privatperson` og `samarbeidspartner`                                                                          | Nye sider: `min-profil`, `arbeidsgiver`, `privatperson` og `samarbeidspartner`.                    |
| `views/home.json`                                                                                                                                                     | `c:aareg_home` blir bytt ut med `c:aaregEntryPortal`, som viser `c-aareg_home` når portalen er av. |
| `views/` for `mineSøknader`, `mineAvtaler`, `mineMeldinger`, `nyMelding`, `nySøknadAaRegistret`, `applicationDetailFlex`, `agreementDetailFlex` og `threadDetailFlex` | Får `c:aaregPortalNav`, som er skjult når portalen er av.                                          |

Gjer stega først i SIT2 eller preprod og deretter i produksjon. Agenten utfører ikkje stega utanfor scratch-orgen.
Kvar køyring i produksjon krev godkjenning frå Team Platforce.

1. **Installer pakkeversjonen først.** Sidene viser til `aaregEntryPortal`, `aaregPortalNav`, `aaregRolePage` og
   `aaregMyProfile`, som kjem med pakka. Deployar du sidene før pakka, feilar det.
2. **Ta backup av nettstaden.**

    ```bash
    mkdir -p backup/aa-registret && cd backup/aa-registret
    sf project retrieve start --metadata ExperienceBundle:Aa_registret1 \
      --target-metadata-dir . --unzip --target-org <org>
    ```

    Lagre backupen i saka. Samanlikn `views/` og `routes/` med `origin/main`. Er det gjort endringar i Builder som
    ikkje finst i repoet, må dei leggjast inn i repoet før steg 4. Elles blir dei skrivne over.

3. **Sjekk utkasta i Experience Builder.** Publisering tek med alle upubliserte endringar. Ligg det utkast som ikkje
   skal ut, må de avklare dei med eigaren først.
4. **Deploy sidene.** Kopier dei fire nye rutene og visningane og dei ni endra visningane frå `main` inn i ein kopi
   av backupmappa. Deploy kopien i metadataformat:

    ```bash
    sf project deploy start --metadata-dir <kopi med nye filer> --target-org <org> --wait 30
    ```

5. **Publiser** i eit avtalt vindauge:

    ```bash
    sf community publish --name "Aa-registret" --target-org <org>
    ```

6. **Røyktest som ekstern brukar.** Forsida, «Mine søknader», «Mine avtaler», «Mine meldingar» og «Ny søknad» skal
   sjå ut og oppføre seg som før, med det blå banneret og den gamle brødsmulestien. `/s/min-profil` og dei tre
   rollesidene skal ikkje vise noko nytt så lenge brytarane er av.
7. **Tilbakerulling.** Deploy den urørde backupen frå steg 2 og publiser på nytt. Pakka treng ikkje rullast
   tilbake, sidan komponentane viser den gamle varianten når brytarane er av.

## Tilbakerulling

Kvar fase blir rulla tilbake ved å setje brytarane til profilen for fasen før. Den gamle modellen blir skriven
vidare, så ingen fase før fase 7 krev at data blir flytta tilbake. Admin-flatene endrar ingen data og kan fjernast
ved å ta bort fana frå appen og løyvesetta frå brukarane.

## Grunnlag

- Kjeldekoden på branchen og diffen mot `main`.
- Køyringar i scratch-orgen `crm-arbeidsforhold`: Apex-testar, Jest og Playwright. Sjå
  [testing/README.md](testing/README.md).
- Semantisk diff av løyvesetta og gjennomgang av alle endra eksisterande filer, 2026-11-25.
- `Validate PR` på #1238 i ein eigen scratch-org: kompilering, Apex-testar og 85 % dekning er grøne.
- Produkteigar las verdiane i produksjon 2026-11-25. Agenten har ikkje vore i SIT2 eller produksjon.
