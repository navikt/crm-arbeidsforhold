# Utrulling og tilbakerulling av kontaktmodellen

Runbook for [K10 #1235](https://github.com/navikt/crm-arbeidsforhold/issues/1235). Krava står i
[spesifikasjonen](../../../.github/specs/aareg-contact-model.md#9-utrulling), og skjerminga i
[ADR-0008](../../adr/0008-skjerming-i-kontaktmodellen.md).

## Ansvar og godkjenning

| Miljø                        | Kven utfører          | Godkjenning                                                   |
| ---------------------------- | --------------------- | ------------------------------------------------------------- |
| Scratch `crm-arbeidsforhold` | Utviklar eller agent  | Ingen ny godkjenning. Verifiser org-ID-en først.              |
| SIT2                         | Utviklar              | Eksplisitt godkjenning av mål og handling før kvar operasjon. |
| Produksjon                   | Menneske, aldri agent | Team Platforce godkjenner metadataendringar og verifiserer.   |
| Fase 2 i produksjon (skugge) | Team Arbeidsforhold   | Tryggleiksansvarleg har godkjent ADR-0008.                    |

## Fasar

Kvar fase har ein fast brytarprofil. Å gå tilbake betyr å setje profilen til førre fase. Den gamle modellen blir
skriven heilt til fase 7, så ingen fase krev datamigrering for å rullast tilbake.

| Fase         | `ShadowWrite` | `OrgSelector`, `Profile`, `ContextAddress` | `LegacyMatchingOff` | Kommando i scratch        |
| ------------ | ------------- | ------------------------------------------ | ------------------- | ------------------------- |
| 1 Mørk       | av            | av                                         | av                  | `phase dark`              |
| 2 Skugge     | alle          | av                                         | av                  | `phase shadow`            |
| 3 Migrering  | alle          | av                                         | av                  | `plan`, `apply`, `verify` |
| 4 Pilot      | alle          | pilot                                      | av                  | `phase pilot`             |
| 5 Brei       | alle          | alle                                       | av                  | `phase broad`             |
| 6 Skifte     | alle          | alle                                       | alle                | `phase switch`            |
| 7 Opprydding | Eiga sak      | Eiga sak                                   | Eiga sak            | Ingen                     |

Kommandoane blir køyrde med `npm run contact-model -- <kommando>` og
`AAREG_SCRATCH_ORG_ID=<verifisert org-ID>`. Skriptet stoppar på alle andre org-ar. I SIT2 og produksjon blir
`Feature_Flag__mdt`-postane endra i Setup eller med ein godkjend deploy av berre dei fem postane, med same verdiar
som i tabellen. «Pilot» betyr `Required_Custom_Permission__c = AAREG_ContactModelPilot`, som blir gitt med
permission set `AAREG_ContactModel_Pilot`.

Brytarane for inngangsportalen (`EntryPortal`, `RoleEmployer`, `RolePartner` og `RolePrivate`) følgjer kolonna
`OrgSelector`, `Profile`, `ContextAddress`. Sjå [inngangsportal.md](inngangsportal.md).

## Før kvar fase

- [ ] `npm run contact-model -- status` (eller dashboardet «Aa-registeret Kontaktmodell») er lagra som evidens.
- [ ] Førre fase har gått minst éi veke utan nye feil frå `AAREG_ContactModel*`-klassane i applikasjonsloggen.
- [ ] Tilbakerullingssteget for fasen er lese og forstått.
- [ ] Brukarstøtta er orientert om fasar som endrar portalen (4, 5 og 6).

## 1 Mørk

1. Deploy pakka. Alle brytarar er av i repoet.
2. Kontroller at søknad, innsending og stadfesting fungerer som før.

Tilbake: ingen endring er gjord i data.

## 2 Skugge

1. Set profilen `shadow`.
2. Følg dashboardet: domenekontaktar, ACR og deltakingar aukar ved innsending.
3. Kontroller at skjerma personar ikkje får data (testskript 8).

Tilbake: set `dark`. Data som er skriven, blir verande og påverkar ikkje gammal modell.

## 3 Migrering

1. Køyr `plan` og les fordelinga på klasse A–E i rapporten «Migreringsrader per klasse».
2. Ta stilling til klasse B, C og E i rapporten «Søknader til manuell vurdering». Ingen av dei blir endra automatisk.
3. Køyr `apply`. Backup av gamle verdiar blir lagra per rad før endring.
4. Køyr `verify`. Avvik skal vere 0.

Tilbake: `rollback` på siste APPLY. Kontroller at `rolledBack` er lik `linked`.

## 4 Pilot

1. Tildel permission set `AAREG_ContactModel_Pilot` til utvalde portalbrukarar.
2. Set profilen `pilot`.
3. Pilotbrukarane vel rolle og organisasjon før søknaden, har «Min profil» og får stadfesting til adressa for
   organisasjonen.

Tilbake: set `shadow`. Pilotbrukarane får den gamle flyten att ved neste sidelasting.

## 5 Brei

1. Set profilen `broad`.
2. Følg talet på førespurnader til brukarstøtta om organisasjonsval og adresser.

Tilbake: set `pilot` eller `shadow`.

## 6 Skifte

1. Set profilen `switch`. Innsending koplar no domenekontakten og opprettar ikkje lenger ein kontakt per e-post.
2. Skjerma personar følgjer framleis den gamle koplinga (ADR-0008).

Tilbake: set `broad`. Den gamle koplinga per e-post er straks i bruk igjen.

## 7 Opprydding

Eiga sak med eigen runbook. Ho skal liste alle API-namn som blir sletta eller endra, gamle og nye namn,
godkjenningar, skript, tilbakerulling og verifisering. Rekkjefølgja er:

1. Scratch: utfør og verifiser.
2. SIT2: etter eksplisitt godkjenning, verifiser slettinga.
3. Produksjon: Team Platforce godkjenner, utfører og verifiserer.

Den gamle koplinga kan berre avgrensast til skjerma personar, ikkje fjernast (ADR-0008).

## Kjende opne punkt

- `AAREG_createSupportContact` (førespurnader til brukarstøtta) brukar framleis den gamle kontaktkoplinga. Eiga
  oppfølging.
- Rolla frå start-steget (arbeidsgivar eller samarbeidspartnar) blir ikkje lagra. Det finst ikkje noko felt for
  henne på søknaden. Domeneavgjerd står att.
