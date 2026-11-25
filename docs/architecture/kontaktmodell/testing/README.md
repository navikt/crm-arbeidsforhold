# Testing av kontaktmodellen

Kontaktmodellen kan testast heilt i scratch-orgen `crm-arbeidsforhold`. Alle data er syntetiske.

| Dokument                                      | Bruk                                                                          |
| --------------------------------------------- | ----------------------------------------------------------------------------- |
| [Operatørrettleiing](operatorrettleiing.md)   | Set opp orgen, slå brytarane av eller på og køyr migrering og tilbakerulling. |
| [Manuelle testskript](manuelle-testskript.md) | Steg, forventa resultat og avkryssing for menneskeleg test.                   |
| Denne fila                                    | Føresetnader og automatiske testar.                                           |

Krava og klassane A–E står i [spesifikasjonen](../../../../.github/specs/aareg-contact-model.md).

## Føresetnader

1. Salesforce CLI på maskina, med scratch-orgen `crm-arbeidsforhold` autentisert.
2. Org-ID-en til scratch-orgen i miljøvariabelen `AAREG_SCRATCH_ORG_ID`. Skripta stoppar om
   målet ikkje er ein scratch-org med denne ID-en.
3. `npm ci` og `npx playwright install chromium`.
4. Orgen er sett opp etter [operatørrettleiinga](operatorrettleiing.md#første-oppsett).

```bash
export AAREG_SCRATCH_ORG_ID=<org-ID frå «sf org display --target-org crm-arbeidsforhold»>
```

## Automatiske testar

| Lag        | Kommando                                                                            | Dekkjer                                                                          |
| ---------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| Apex       | `sf apex run test --target-org crm-arbeidsforhold --class-names <klasse> --wait 20` | Teneste, klassifisering, batch, kontrollarar og deling.                          |
| LWC (Jest) | `npm run test:unit -- -- --runInBand force-app/contactModel`                        | Admin-side, panel, profil, organisasjonsveljar og start-steget i søknaden.       |
| Node       | `npm run test:node`                                                                 | Operatørskriptet: brytarverdiar, utrullingsfasar og ukjende modusar.             |
| Playwright | `npm run e2e:contact-model`                                                         | Interne flater, rapportar, dashboard, portalprofilen og start-steget i søknaden. |

Apex-testklassane ligg i `force-app/tests/classes/contactModel/`.

### Playwright

Suiten ligg i `e2e/contact-model/` og køyrer mot den verifiserte scratch-orgen.

```bash
npm run e2e:contact-model
npx playwright show-report        # HTML-rapport etter køyringa
```

Global setup stadfestar org-ID-en, opnar ei innlogga økt utan å logge URL-en og hentar ID-ar til
syntetiske testdata. Meldingstesten krev at `npm run contact-model -- seed` har delt ei syntetisk melding med
portalbrukaren (`seed-4-portal-message.apex`). Elles blir han hoppa over. Køyringa tek om lag tre til ti minutt, avhengig av orgen.

| Fil                         | Testar | Kontrollerer                                                                                            |
| --------------------------- | -----: | ------------------------------------------------------------------------------------------------------- |
| `admin.spec.ts`             |      5 | Seksjonar og knappar på admin-sida, stadfesting og avbryting av APPLY og ROLLBACK, fana i tre appar.    |
| `record-panels.spec.ts`     |      3 | Kontaktmodellpanelet på søknad, organisasjon og kontakt.                                                |
| `reports.spec.ts`           |      7 | Dei fem rapportane, dashboardet og at diagramma blir teikna.                                            |
| `portal-profile.spec.ts`    |      3 | «Min profil»: ingenting vist før val, lagring for «Meg selv» og søk på organisasjon.                    |
| `entry-portal.spec.ts`      |      6 | Forsida med rolleval, rollesider, direktelenkjer, faste meldingar og «Bytt rolle».                      |
| `portal-navigation.spec.ts` |      5 | Brødsmulesti, vald virksomheit på undersidene og «Bytt virksomhet», breitt søkjefelt, smal skjerm.      |
| `record-pages.spec.ts`      |      4 | Dei tolv listevisningane, listevisning og postside for kontaktpunkt, og postside for migreringskøyring. |
| `admin-access.spec.ts`      |      5 | Snarvegar i Arbeidsforhold Admin, løyveoversikta, brukaroversikta og effektiv tilgang for ein brukar.   |

Testane stadfestar aldri ei migreringskøyring. Dei trykkjer berre «Avbryt» i stadfestingsdialogen.
Profiltesten lagrar ei syntetisk privatadresse på testbrukaren.

### Skjermbilete

```bash
CM_DOC_SCREENSHOTS=1 npm run e2e:contact-model
```

Skjermbileta blir lagra i `skjermbilete/` og viser berre syntetiske data.

| Bilete                                                                                                  | Flate                                          |
| ------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| [01-admin-kontaktmodell](skjermbilete/01-admin-kontaktmodell.png)                                       | Admin-sida for kontaktmodellen.                |
| [01b-admin-stadfest-rollback](skjermbilete/01b-admin-stadfest-rollback.png)                             | Stadfesting før tilbakerulling.                |
| [02-panel-soknad](skjermbilete/02-panel-soknad.png)                                                     | Panelet på søknaden.                           |
| [03-panel-organisasjon](skjermbilete/03-panel-organisasjon.png)                                         | Panelet på organisasjonen.                     |
| [04-panel-kontakt](skjermbilete/04-panel-kontakt.png)                                                   | Panelet på kontakten.                          |
| [05-dashboard](skjermbilete/05-dashboard.png)                                                           | Dashboardet «Aa-registeret Kontaktmodell».     |
| [06-min-profil-vel-forst](skjermbilete/06-min-profil-vel-forst.png)                                     | «Min profil» før val.                          |
| [07-min-profil-meg-selv](skjermbilete/07-min-profil-meg-selv.png)                                       | «Min profil» med «Meg selv» valt.              |
| [11-forside-min-profil](skjermbilete/11-forside-min-profil.png)                                         | Forsida med inngangen til «Min profil».        |
| [12-inngangsportal-rolleval](skjermbilete/12-inngangsportal-rolleval.png)                               | Forsida: vel rolle.                            |
| [13-rolleside-arbeidsgiver-vel-virksomheit](skjermbilete/13-rolleside-arbeidsgiver-vel-virksomheit.png) | Arbeidsgivar vel virksomheit.                  |
| [14-rolleside-privatperson](skjermbilete/14-rolleside-privatperson.png)                                 | Rollesida for privatperson.                    |
| [15-inngangsportal-ingen-tilgang](skjermbilete/15-inngangsportal-ingen-tilgang.png)                     | Forsida med fast melding om manglande tilgang. |
| [16-brodsmulesti-rolleside](skjermbilete/16-brodsmulesti-rolleside.png)                                 | Rollesida med brødsmulesti.                    |
| [17-brodsmulesti-min-profil](skjermbilete/17-brodsmulesti-min-profil.png)                               | «Min profil» med sti tilbake til rolla.        |
| [18-tilbakelenkje-mobil](skjermbilete/18-tilbakelenkje-mobil.png)                                       | «Tilbake til Forside» på smal skjerm.          |
| [19-brodsmulesti-melding](skjermbilete/19-brodsmulesti-melding.png)                                     | Meldingssida med éin felles sti.               |
| [20-brodsmulesti-mine-meldinger](skjermbilete/20-brodsmulesti-mine-meldinger.png)                       | «Mine meldinger» utan den gamle stien.         |
| [21-rolleside-vald-virksomheit](skjermbilete/21-rolleside-vald-virksomheit.png)                         | Rollesida med vald virksomheit og stort felt.  |
| [22-kontekstlinje-underside](skjermbilete/22-kontekstlinje-underside.png)                               | «Mine søknader» med kontekstlinja.             |
| [23-listevisning-kontaktpunkt](skjermbilete/23-listevisning-kontaktpunkt.png)                           | Listevisninga «All Contact Points».            |
| [24-postside-kontaktpunkt](skjermbilete/24-postside-kontaktpunkt.png)                                   | Postsida for eit kontaktpunkt.                 |
| [25-postside-migreringskoyring](skjermbilete/25-postside-migreringskoyring.png)                         | Postsida for ei migreringskøyring med rader.   |
| [26-admin-snarvegar](skjermbilete/26-admin-snarvegar.png)                                               | Startsida i Arbeidsforhold Admin.              |
| [27-admin-loyveoversikt](skjermbilete/27-admin-loyveoversikt.png)                                       | Løyveoversikta med detaljar om eitt løyve.     |
| [28-admin-interne-brukarar](skjermbilete/28-admin-interne-brukarar.png)                                 | Interne brukarar med problem.                  |
| [29-admin-brukar-tilgang](skjermbilete/29-admin-brukar-tilgang.png)                                     | Effektiv tilgang for éin brukar.               |
| [30-admin-metadata-opprydding](skjermbilete/30-admin-metadata-opprydding.png)                           | Fjerna metadata og status i orgen.             |
| [31-admin-metadata-filter](skjermbilete/31-admin-metadata-filter.png)                                   | Søk og filter i oppryddingsoversikta.          |
| [32-admin-metadata-arkivering](skjermbilete/32-admin-metadata-arkivering.png)                           | Miljø, verifisert sletting og arkivering.      |

## Kjende avgrensingar

- Berre `Synthetic Community Test User` har portaltilgang i scratch. Seed-brukarane finst berre for migreringa.
- Portaltesten loggar inn som Experience-brukaren med «Log in to Experience as User». Altinn er
  ikkje kopla til i scratch, så organisasjonslista kan vere tom. Søketesten blir då hoppa over.
- Skjerma personar (klasse D) og delingsreglar må testast manuelt, sjå
  [testskript 8](manuelle-testskript.md#8-skjerma-person-og-deling). Apex-testane dekkjer regelen i
  `AAREG_ContactModelShieldingTest`.
- Stadfestinga til kontekstadressa (K8) blir testa i Apex gjennom flowen og manuelt i
  [testskript 10](manuelle-testskript.md#10-stadfesting-til-adressa-for-organisasjonen). Playwright sender ikkje inn
  søknader.
- Rapportar og dashboard ligg i ein iframe. Testane les difor innhaldet inne i ramma.
