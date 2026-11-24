# Operatørrettleiing for kontaktmodellen

Operatørskriptet `scripts/contact-model.cjs` arbeider berre mot den verifiserte scratch-orgen
`crm-arbeidsforhold`. Det stoppar dersom `AAREG_SCRATCH_ORG_ID` manglar eller ikkje stemmer med
målet. Det kan ikkje brukast mot SIT2 eller produksjon.

```bash
npm run contact-model -- <modus> [argument]
```

| Modus                   | Gjer                                                                                          |
| ----------------------- | --------------------------------------------------------------------------------------------- |
| `status`                | Viser brytarane, dei fem siste køyringane og tal på kontaktpunkt og deltakingar.              |
| `setup`                 | Tildeler `AAREG_ContactModel_Admin` og `AAREG_ContactModel_Pilot` og set opp primærkontoen.   |
| `seed`                  | Lagar syntetiske personar, portalbrukarar og søknader for klassane A–E.                       |
| `flags off\|pilot\|all` | Set alle fem brytarane i scratch. Repoet held alltid brytarane av.                            |
| `phase <fase>`          | Set brytarprofilen for ein utrullingsfase: `dark`, `shadow`, `pilot`, `broad` eller `switch`. |
| `plan`                  | Klassifiserer søknadene utan å endre data.                                                    |
| `apply`                 | Koplar klasse A og tek backup av alle verdiar som blir endra.                                 |
| `verify`                | Kontrollerer at siste APPLY framleis stemmer.                                                 |
| `rollback`              | Set tilbake verdiane frå siste APPLY.                                                         |

Køyringane `plan`, `apply`, `verify` og `rollback` ventar til batchen er ferdig, i opptil ti
minutt, og skriv ut resultatet per klasse.

## Første oppsett

```bash
sf project deploy start --source-dir force-app --target-org crm-arbeidsforhold
npm run contact-model -- setup
npm run contact-model -- seed
npm run contact-model -- flags pilot
npm run contact-model -- status
```

«Min profil» ligg i Experience-nettstaden, som ikkje blir deploya med `force-app`. Sjå
[Deploy av nettstaden](#deploy-av-nettstaden).

## Brytarar

| Omfang  | Verknad                                                                    |
| ------- | -------------------------------------------------------------------------- |
| `off`   | Gammal modell. Ingenting nytt blir vist eller skrive.                      |
| `pilot` | Berre brukarar med løyvet `AAREG_ContactModel_Pilot` ser den nye modellen. |
| `all`   | Alle brukarar ser den nye modellen.                                        |

Brytarane er Custom Metadata (`Feature_Flag__mdt`) og er stengde dersom posten manglar. Rekkjefølgja
for utrulling står i [spesifikasjonen](../../../../.github/specs/aareg-contact-model.md). Profilen per fase og
tilbakerullinga står i [runbooken for utrulling](../utrulling.md).

## Migrering og tilbakerulling

Same handlingar finst på admin-sida «Kontaktmodell» i appane Arbeidsforhold Admin, Aa-registeret
Kontaktmodell, Aa-registeret – Søknad og Aa-registeret – Brukerstøtte. Admin-sida krev stadfesting før
APPLY og ROLLBACK.

1. `plan`: Kontroller fordelinga på klassar. Berre klasse A blir kopla automatisk.
2. `apply`: Backup av gamle verdiar blir lagra per rad i `AAREG_Contact_Migration_Item__c`.
3. `verify`: Avvik skal vere 0.
4. Ved feil: `rollback`. Kontroller med `status` at `rolledBack` er lik `linked` frå APPLY.

Rapportane og dashboardet «Aa-registeret Kontaktmodell» viser køyringar, klassar, saker til
manuell vurdering, kontaktpunkt og roller.

## Deploy av nettstaden

`force-app/unpackagable/experiences` er utelaten i `.forceignore`. Hent bundlen frå orgen, legg til
sidefilene og deploy i metadataformat:

```bash
mkdir -p /tmp/cmsite && cd /tmp/cmsite
sf project retrieve start --metadata ExperienceBundle:Aa_registret1 \
  --target-metadata-dir . --unzip --target-org crm-arbeidsforhold
# Kopier routes/minProfil.json og views/minProfil.json inn i bundlen.
sf project deploy start --metadata-dir <utpakka mappe> --target-org crm-arbeidsforhold
sf community publish --name "Aa-registret" --target-org crm-arbeidsforhold
```

Sida blir då tilgjengeleg på `/aaregisteret/s/min-profil`.

## Kjende fallgruver

| Symptom                                            | Årsak og tiltak                                                                                                  |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `seed` feilar på `CreatedById` eller `CreatedDate` | Audit-felta må vere slått på. `seed` gjer dette sjølv via Setup. Køyr på nytt.                                   |
| `seed` feilar på portalbrukarar                    | Seed-brukarane bruker High Volume Customer Portal-lisensen. Kontroller at det finst ledige lisensar.             |
| «Set opp primærkonto» blir vist på admin-sida      | `setup` er ikkje køyrd.                                                                                          |
| VERIFY og ROLLBACK er grå                          | Vel ei fullført APPLY-køyring i nedtrekkslista først.                                                            |
| Brytarane er av etter ein deploy                   | Deploy av `force-app` tek med brytarpostane frå repoet, som er av. Køyr `flags pilot` eller `flags all` på nytt. |
| Profilsida seier «ikkje tilgjengeleg»              | `AAREG_ContactModel_Profile` er av, eller brukaren manglar pilotløyvet.                                          |
| Organisasjonslista er tom i scratch                | Altinn er ikkje kopla til. «Meg selv» kan framleis testast.                                                      |
