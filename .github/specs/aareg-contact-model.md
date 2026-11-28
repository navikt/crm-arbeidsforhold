# Spesifikasjon: kontaktmodell for Aa-registeret

**Status:** Retning valt 23. november 2026. Avgjerder: [ADR-0006](../../docs/adr/0006-kontaktmodell-ein-kontakt-acr-og-roller.md).
**Bakgrunn:** [docs/architecture/kontaktmodell](../../docs/architecture/kontaktmodell/README.md).
**Eigar:** Team Arbeidsforhold. Team Platforce godkjenner endringar i produksjon.

## 1. Mål

Éin varig Aa-register-kontakt per innlogga person. Kontakten er knytt til organisasjonar med
`AccountContactRelation` (ACR) og til søknader med rolle på `RelatedContact__c`. Kontakten har éi
privat e-postadresse og éi adresse per organisasjon. Det finst ingen fallback mellom adressene.

Løysinga skal kunne slåast på gradvis og rullast tilbake utan tap av data.

## 2. Ikkje mål i denne leveransen

- Endring av `User.ContactId`, `User.Email`, Person Account eller KRR.
- Automatisk samanslåing av kontaktar på e-post eller namn.
- Sletting av eksisterande kontaktar eller `RelatedContact__c`-rader.
- Bruk av `AccountContactRelation.Roles`. Feltet er delt med andre team.

## 3. Avgjerder

| ID  | Avgjerd                                                                                                                                                          |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D1  | Flyten startar med rolle («Som arbeidsgiver», «Som samarbeidspartner», «Som privatperson»), deretter søkbar organisasjonsveljar.                                 |
| D2  | Organisasjonsveljaren er ein søkbar combobox (namn og org.nr.) bygd som LWC etter ARIA-mønsteret, fylt frå Altinn, aldri frå ACR.                                |
| D3  | Adresser blir lagra i `AAREG_Contact_Point__c` (Private deling), éi rad per kontekst ([ADR-0007](../../docs/adr/0007-kontaktpunkt-i-eige-objekt.md)). ACR held berre `AAREG_Managed__c` og `AAREG_Altinn_Verified_At__c`. |
| D4  | Domenekontaktane har ein teknisk primærkonto. Id-en ligg i `AAREG_Default_Settings__c.Contact_Model_Account_Id__c` og blir sett av oppsettskommandoen.           |
| D5  | Identiteten er portalbrukaren sin `User.Id`, lagra i det unike feltet `Contact.AAREG_Identity_Key__c`. Ingen endring på `User`.                                  |
| D6  | `RelatedContact__c` blir utvida med `Contact__c`, `Role__c`, `Participation_Key__c` (unik) og `Contact_Point__c`.                                                |
| D7  | Skuggeskriving skjer asynkront i ein Queueable i systemmodus med berre serverutleidde verdiar. Feil blir logga og stoppar aldri innsendinga.                      |
| D8  | Brytarane er `Feature_Flag__mdt`-rader lesne gjennom `AAREG_ContactModelGate`, som sperrer når noko manglar eller er av. Pilotbrukarar får ein custom permission. |
| D9  | Migreringa skriv backup før kvar endring og kan rullast tilbake per køyring. Berre klasse A (sikker) blir kopla automatisk.                                      |
| D10 | Drift skjer i fana «Kontaktmodell» i appen Arbeidsforhold Admin, med rapportar og dashboard.                                                                     |
| D11 | Skjerma personar (kode 6/7 og Nav-tilsette) blir haldne heilt utanfor kontaktmodellen og følgjer den gamle flyten ([ADR-0008](../../docs/adr/0008-skjerming-i-kontaktmodellen.md)). |
| D12 | Adressa som blir skriven inn i ein søknad, blir den nye adressa for same organisasjon. Andre kontekstar, inkludert privatadressa, blir ikkje endra.            |
| D13 | Rolla frå start-steget blir ikkje lagra. Søknaden har ikkje noko felt for henne, og domeneavgjerda står att.                                                    |

## 4. Datamodell

| Objekt og felt                                    | Type                   | Formål                                                                 |
| ------------------------------------------------- | ---------------------- | ---------------------------------------------------------------------- |
| `Contact.AAREG_Identity_Key__c`                   | Text(18), unik, ext.id | Portalbrukar-Id. Éin domenekontakt per innlogga person.                |
| `AccountContactRelation.AAREG_Managed__c`         | Checkbox               | Rada er oppretta eller teken over av Aa-registeret.                    |
| `AccountContactRelation.AAREG_Altinn_Verified_At__c` | DateTime            | Sist stadfesta mot Altinn.                                             |
| `AAREG_Contact_Point__c`                          | Objekt, Private        | Éi adresse per kontekst. Lookup til Contact, ikkje master-detail.      |
| `AAREG_Contact_Point__c.Context__c`               | Picklist               | `Private` eller `Organization`.                                        |
| `AAREG_Contact_Point__c.Organization__c`          | Lookup(Account)        | Organisasjonen. Tom for privat adresse.                                |
| `AAREG_Contact_Point__c.Email__c` / `Phone__c`    | Email / Phone          | Klassifisert Confidential, GDPR.                                       |
| `AAREG_Contact_Point__c.Context_Key__c`           | Text(40), unik, ext.id | `<kontakt-Id>:<organisasjon-Id>` eller `<kontakt-Id>:PRIVATE`.        |
| `RelatedContact__c.Contact__c`                    | Lookup(Contact)        | Domenekontakten.                                                       |
| `RelatedContact__c.Role__c`                       | Picklist               | `Submitter`, `NotificationContact`.                                    |
| `RelatedContact__c.Participation_Key__c`          | Text(80), unik         | `<kontekst-Id>:<kontakt-Id>:<rolle>`. Hindrar duplikat ved samtidigheit. |
| `RelatedContact__c.Contact_Point__c`              | Lookup(Contact Point)  | Kontaktpunktet som gav adressa. `Email__c` er øyeblinksbilete.         |
| `AAREG_Contact_Migration_Run__c`                  | Objekt                 | Éi køyring: modus, status, tal per klasse.                             |
| `AAREG_Contact_Migration_Item__c`                 | Objekt, master-detail  | Éi kjeldepost: klasse, handling, JSON-backup, resultat.                |

## 5. Brytarar

| Flagg                                     | Omfang                | Verknad når på                                                           |
| ----------------------------------------- | --------------------- | ------------------------------------------------------------------------ |
| `AAREG_ContactModel_ShadowWrite`          | Globalt               | Innsending skriv domenekontakt, ACR, kontaktpunkt og deltaking i tillegg til gammal modell. |
| `AAREG_ContactModel_OrgSelector`          | Pilot eller globalt   | Søkbar organisasjonsveljar i portalen og «Min profil».                   |
| `AAREG_ContactModel_Profile`              | Pilot eller globalt   | «Min profil» med privat adresse og adresse per organisasjon.             |
| `AAREG_ContactModel_ContextAddress`       | Pilot eller globalt   | Varsel blir sende til adressa for konteksten, utan fallback.             |
| `AAREG_ContactModel_LegacyMatchingOff`    | Globalt               | Den gamle kontaktkoplinga på e-post blir slått av.                       |

Regel: Eit flagg er på for ein brukar når `Is_Enabled__c` er sann og anten
`Required_Custom_Permission__c` er tom, eller brukaren har custom permissionen som står der.
Pilotflagga brukar `AAREG_ContactModelPilot`. Manglande rad eller feil gir «av».
LWC hentar status utan cache.

Tilbakerulling: Den gamle modellen blir skriven heilt til opprydningsfasen. Å slå av eit flagg er
derfor alltid nok til å gå tilbake. Data frå den nye modellen blir verande og kan fjernast med
migreringa sin `ROLLBACK`.

## 6. Krav

| ID     | Krav                                                                                                                                  | Fase |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------- | ---- |
| REQ-01 | Med alle flagg av skal åtferda vere uendra.                                                                                           | K1   |
| REQ-02 | Gate sperrer når flagg manglar, er av, eller krev ein permission brukaren ikkje har.                                                   | K1   |
| REQ-03 | Ved innsending blir éin domenekontakt per portalbrukar oppretta eller gjenbrukt.                                                       | K2   |
| REQ-04 | Éi ACR-rad og eitt kontaktpunkt per kontakt og organisasjon blir oppretta eller oppdatert med adressa frå søknaden. Ikkje-forvalta ACR-rader blir ikkje endra. Privat adresse blir aldri avleidd. | K2   |
| REQ-05 | Éi `Submitter`-deltaking per søknad og kontakt, idempotent ved ny innsending.                                                          | K2   |
| REQ-06 | Feil i skuggeskrivinga blir logga og påverkar ikkje innsendinga.                                                                       | K2   |
| REQ-07 | Admin-fana viser flaggstatus, nøkkeltal og køyringar, og kan starte plan, migrering, verifisering og tilbakerulling for dei som har løyve. | K3   |
| REQ-08 | Rapportar og dashboard viser domenekontaktar, deltakingar per rolle og migreringsklassar.                                             | K3   |
| REQ-09 | Migreringa klassifiserer A–E og endrar ingenting i `PLAN`.                                                                             | K4   |
| REQ-10 | `APPLY` lagrar JSON-backup før endring og koplar berre klasse A.                                                                       | K4   |
| REQ-11 | `ROLLBACK` fjernar det køyringa oppretta og set tilbake endra felt frå backup.                                                         | K4   |
| REQ-12 | `VERIFY` stemmer av tal mot køyringa og rapporterer avvik.                                                                             | K4   |
| REQ-13 | Rolle blir vald på forsida (inngangsportalen), deretter søkbar veljar på namn og org.nr. utan automatisk val. Søknaden har ikkje eige rolleval. | K5   |
| REQ-14 | «Min profil» viser berre «Meg selv» før organisasjon er valt og kontrollert i Altinn.                                                  | K6   |
| REQ-15 | Mottakar blir vald etter kontekst. Manglar adressa, må brukaren oppgi ho. Ingen fallback.                                              | K8   |

## 7. Migreringsklassar

| Klasse | Kjelde                                                                        | Handling          |
| ------ | ----------------------------------------------------------------------------- | ----------------- |
| A      | Søknad med organisasjon der `CreatedById` er ein portalbrukar (`User.ContactId` er sett). `createdByUser__c` er ein formel og blir ikkje brukt. | Kople automatisk. |
| B      | Søknad utan sikker portalbrukar, eller varslingskontakt utan innlogging.      | Uavklart. Ingen endring. |
| C      | E-postadressa blir brukt av fleire ulike portalbrukarar (felles adresse).     | Ingen endring.    |
| D      | Skjerma person. Krev eiga avklaring (K9).                                     | Ingen endring.    |
| E      | Konflikt, til dømes ulik kontakt allereie kopla.                              | Ingen endring.    |

Klasse D følgjer [ADR-0008](../../docs/adr/0008-skjerming-i-kontaktmodellen.md): skjerma personar blir aldri kopla.

Køyringa blir starta frå admin-fana eller med `node scripts/contact-model.cjs <kommando>`. Skriptet
nektar andre org-ar enn den verifiserte scratch-orgen utan eksplisitt `--target-org`.

## 8. Tilgang og sikkerheit

- Portalbrukarar får inga direkte tilgang til domenekontaktar, kontaktpunkt, ACR-felt eller migreringsobjekta.
- Skuggeskrivinga brukar systemmodus, men berre med Id-ar utleidde på serveren: innlogga brukar og
  søknaden brukaren nettopp sende inn.
- `AAREG_ContactModel_Admin` gir lesetilgang, inkludert kontaktpunkt, og løyvet `AAREG_ContactModelMigrate` for å starte køyringar.
- Migreringsbackup kan innehalde personopplysningar (namn og e-post). Objekta er private, og
  backup skal slettast etter avtalt lagringstid.
- Skjerma personar får ingen data i kontaktmodellen, og panelet maskerer personar som blir skjerma seinare
  ([ADR-0008](../../docs/adr/0008-skjerming-i-kontaktmodellen.md)).

## 9. Utrulling

1. Mørk: deploy med alle flagg av.
2. Skugge: `ShadowWrite` på. Følg dashboardet.
3. Migrering: `PLAN`, så `APPLY` for klasse A, så `VERIFY`.
4. Pilot: pilotflagga for utvalde brukarar.
5. Brei: pilotflagga globalt.
6. Skifte: `LegacyMatchingOff` på.
7. Opprydding: eiga sak med runbook og Team Platforce-godkjenning.

Brytarprofil, kommandoar, sjekkliste og tilbakerulling per fase står i
[runbooken for utrulling](../../docs/architecture/kontaktmodell/utrulling.md).

## 10. Test

- Apex: gate, skuggeskriving (ny, gjenbruk, ny innsending, feil), migrering (plan, apply, verify,
  rollback) og admin-kontrollar, med `System.runAs` minimumsbrukar der det gjeld.
- Jest: admin-fana og organisasjonsveljaren.
- Scratch: deploy og ende-til-ende-innsending med flagget på og av.
- Apex for K5, K8 og K9: start-steget, mottakarresolveren gjennom flowen og skjerming.
- Playwright: start-steget for ny søknad, «Min profil», panel, admin-fana, rapportar og dashboard.
