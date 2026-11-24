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

| Lag        | Kommando                                                                            | Dekkjer                                                 |
| ---------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------- |
| Apex       | `sf apex run test --target-org crm-arbeidsforhold --class-names <klasse> --wait 20` | Teneste, klassifisering, batch, kontrollarar og deling. |
| LWC (Jest) | `npm run test:unit -- -- --runInBand force-app/contactModel`                        | Admin-side, panel, profil og organisasjonsveljar.       |
| Node       | `npm run test:node`                                                                 | Operatørskriptet: brytarverdiar og ukjende modusar.     |
| Playwright | `npm run e2e:contact-model`                                                         | Interne flater, rapportar, dashboard og portalprofilen. |

Apex-testklassane ligg i `force-app/tests/classes/contactModel/`.

### Playwright

Suiten ligg i `e2e/contact-model/` og køyrer mot den verifiserte scratch-orgen.

```bash
npm run e2e:contact-model
npx playwright show-report        # HTML-rapport etter køyringa
```

Global setup stadfestar org-ID-en, opnar ei innlogga økt utan å logge URL-en og hentar ID-ar til
syntetiske testdata. Køyringa tek om lag tre til ti minutt, avhengig av orgen.

| Fil                      | Testar | Kontrollerer                                                                                         |
| ------------------------ | -----: | ---------------------------------------------------------------------------------------------------- |
| `admin.spec.ts`          |      5 | Seksjonar og knappar på admin-sida, stadfesting og avbryting av APPLY og ROLLBACK, fana i tre appar. |
| `record-panels.spec.ts`  |      3 | Kontaktmodellpanelet på søknad, organisasjon og kontakt.                                             |
| `reports.spec.ts`        |      7 | Dei fem rapportane, dashboardet og at diagramma blir teikna.                                         |
| `portal-profile.spec.ts` |      3 | «Min profil»: ingenting vist før val, lagring for «Meg selv» og søk på organisasjon.                 |

Testane stadfestar aldri ei migreringskøyring. Dei trykkjer berre «Avbryt» i stadfestingsdialogen.
Profiltesten lagrar ei syntetisk privatadresse på testbrukaren.

### Skjermbilete

```bash
CM_DOC_SCREENSHOTS=1 npm run e2e:contact-model
```

Skjermbileta blir lagra i [skjermbilete/](skjermbilete/) og viser berre syntetiske data.

| Bilete                                                                      | Flate                                      |
| --------------------------------------------------------------------------- | ------------------------------------------ |
| [01-admin-kontaktmodell](skjermbilete/01-admin-kontaktmodell.png)           | Admin-sida for kontaktmodellen.            |
| [01b-admin-stadfest-rollback](skjermbilete/01b-admin-stadfest-rollback.png) | Stadfesting før tilbakerulling.            |
| [02-panel-soknad](skjermbilete/02-panel-soknad.png)                         | Panelet på søknaden.                       |
| [03-panel-organisasjon](skjermbilete/03-panel-organisasjon.png)             | Panelet på organisasjonen.                 |
| [04-panel-kontakt](skjermbilete/04-panel-kontakt.png)                       | Panelet på kontakten.                      |
| [05-dashboard](skjermbilete/05-dashboard.png)                               | Dashboardet «Aa-registeret Kontaktmodell». |
| [06-min-profil-vel-forst](skjermbilete/06-min-profil-vel-forst.png)         | «Min profil» før val.                      |
| [07-min-profil-meg-selv](skjermbilete/07-min-profil-meg-selv.png)           | «Min profil» med «Meg selv» valt.          |

## Kjende avgrensingar

- Portaltesten loggar inn som Experience-brukaren med «Log in to Experience as User». Altinn er
  ikkje kopla til i scratch, så organisasjonslista kan vere tom. Søketesten blir då hoppa over.
- Skjerma personar (klasse D) og delingsreglar må testast manuelt, sjå
  [testskript 8](manuelle-testskript.md#8-skjerma-person-og-deling).
- Rapportar og dashboard ligg i ein iframe. Testane les difor innhaldet inne i ramma.
