# Manuelle testskript for kontaktmodellen

Køyr skripta i scratch-orgen `crm-arbeidsforhold` etter [første oppsett](operatorrettleiing.md#første-oppsett).
Bruk berre syntetiske data. Kryss av når forventa resultat stemmer, og noter avvik med skjermbilete.

| Felt   | Verdi |
| ------ | ----- |
| Testar |       |
| Dato   |       |
| Org-ID |       |
| Commit |       |

## 1. Brytarar av og på

| #   | Steg                                                                      | Forventa resultat                                              | OK  |
| --- | ------------------------------------------------------------------------- | -------------------------------------------------------------- | --- |
| 1.1 | `npm run contact-model -- flags off`, deretter `status`.                  | Alle fem brytarane viser `off`.                                | ☐   |
| 1.2 | Opne «Min profil» i portalen som testbrukaren.                            | «Profilsida er ikkje tilgjengeleg for deg enno.»               | ☐   |
| 1.3 | `npm run contact-model -- flags pilot`.                                   | `status` viser `pilot` for alle fem.                           | ☐   |
| 1.4 | Opne «Min profil» på nytt som pilotbrukaren.                              | Organisasjonsveljaren blir vist.                               | ☐   |
| 1.5 | Fjern løyvet `AAREG_ContactModel_Pilot` frå testbrukaren og last på nytt. | Profilsida er ikkje tilgjengeleg. Tildel løyvet igjen etterpå. | ☐   |

## 2. Migrering frå admin-sida

Opne appen **Aa-registeret Kontaktmodell** og fana **Kontaktmodell**.

| #   | Steg                                                                 | Forventa resultat                                                                              | OK  |
| --- | -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | --- |
| 2.1 | Sjå på sida.                                                         | Seksjonane Nøkkeltal, Brytarar, Migrering og Siste køyringar. «Set opp primærkonto» er skjult. | ☐   |
| 2.2 | Trykk «Planlegg (PLAN)» og «Start køyringa».                         | Melding om start. Ny PLAN-køyring med fordeling på klasse A–E. Ingen data endra.               | ☐   |
| 2.3 | Trykk «Migrer klasse A (APPLY)» og så «Avbryt».                      | Dialogen lukkar seg. Inga ny køyring.                                                          | ☐   |
| 2.4 | Trykk «Migrer klasse A (APPLY)» og «Start køyringa».                 | APPLY blir fullført. «Kopla» er lik talet på klasse A i PLAN.                                  | ☐   |
| 2.5 | Kontroller at VERIFY og ROLLBACK er grå før du vel ei APPLY-køyring. | Knappane er deaktiverte.                                                                       | ☐   |
| 2.6 | Vel APPLY-køyringa frå 2.4 og køyr «Verifiser (VERIFY)».             | Avvik er 0.                                                                                    | ☐   |
| 2.7 | Vel same APPLY-køyring og køyr «Rull tilbake (ROLLBACK)».            | Dialogen åtvarar om tilbakerulling. «Rulla tilbake» er lik «Kopla» frå 2.4.                    | ☐   |
| 2.8 | Opne ein søknad som var kopla i 2.4.                                 | Koplinga til domenekontakten er fjerna.                                                        | ☐   |
| 2.9 | Køyr APPLY på nytt.                                                  | Same tal blir kopla igjen. Migreringa kan gjentakast.                                          | ☐   |

## 3. Panelet på søknad, organisasjon og kontakt

| #   | Steg                                   | Forventa resultat                                                                     | OK  |
| --- | -------------------------------------- | ------------------------------------------------------------------------------------- | --- |
| 3.1 | Opne ein klasse A-søknad.              | «Kontaktmodell» viser «x av y deltakingar er kopla» og tabellen «Roller på søknader». | ☐   |
| 3.2 | Trykk på domenekontakten i tabellen.   | Kontaktsida opnar seg og panelet viser rollene til kontakten.                         | ☐   |
| 3.3 | Opne organisasjonen til søknaden.      | Seksjonen «Personar med tilknyting (ACR)» viser kontaktane.                           | ☐   |
| 3.4 | Opne ein klasse B-, C- eller E-søknad. | Panelet viser at deltakinga ikkje er kopla. Ingen data er endra.                      | ☐   |

## 4. Rapportar og dashboard

| #   | Steg                                                               | Forventa resultat                                                                                                             | OK  |
| --- | ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- | --- |
| 4.1 | Opne kvar av dei fem rapportane i mappa for kontaktmodellen.       | Migreringskøyringar, rader per klasse, manuell vurdering, kontaktpunkt per kontekst og deltakingar per rolle opnar utan feil. | ☐   |
| 4.2 | Opne dashboardet «Aa-registeret Kontaktmodell» og trykk «Refresh». | Alle komponentane viser data. Tala stemmer med `status`.                                                                      | ☐   |
| 4.3 | Sjå på «Til manuell vurdering (C, D, E)».                          | Fargen skiftar ved brytepunkta 1 og 20 (grøn, gul, raud).                                                                     | ☐   |

## 5. Fana i alle appane

| #   | Steg                                                                               | Forventa resultat                                        | OK  |
| --- | ---------------------------------------------------------------------------------- | -------------------------------------------------------- | --- |
| 5.1 | Opne Arbeidsforhold Admin, Aa-registeret – Søknad og Aa-registeret – Brukerstøtte. | Fana «Kontaktmodell» finst i alle tre.                   | ☐   |
| 5.2 | Logg inn som saksbehandlar utan `AAREG_ContactModel_Admin`.                        | Admin-sida og migreringsknappane er ikkje tilgjengelege. | ☐   |

## 6. «Min profil» i portalen

Logg inn som testbrukaren via «Log in to Experience as User» og opne `/aaregisteret/s/min-profil`.

| #   | Steg                                                             | Forventa resultat                                                                                            | OK  |
| --- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | --- |
| 6.1 | Sjå på sida før du vel noko.                                     | «Ingen opplysningar blir viste før du har valt …». Inga adresse er synleg.                                   | ☐   |
| 6.2 | Vel «Meg selv».                                                  | Skjemaet for privat adresse blir vist.                                                                       | ☐   |
| 6.3 | Lagre med tom e-post.                                            | «Skriv inn e-postadressa.»                                                                                   | ☐   |
| 6.4 | Lagre med ugyldig e-post, til dømes `abc`.                       | «Skriv inn ei gyldig e-postadresse.»                                                                         | ☐   |
| 6.5 | Lagre ei gyldig syntetisk adresse.                               | Stadfesting blir vist. Ny eller oppdatert rad i Aa-register Contact Points med kontekst `Private`.           | ☐   |
| 6.6 | Skriv namn eller organisasjonsnummer i søkefeltet.               | Lista blir filtrert på både namn og nummer.                                                                  | ☐   |
| 6.7 | Vel ein organisasjon der brukaren har rolle i Altinn.            | Skjemaet for organisasjonsadressa blir vist, tomt dersom ingen adresse finst. Privatadressa blir ikkje vist. | ☐   |
| 6.8 | Vel ein organisasjon der rolla er fjerna i Altinn.               | Åtvaring. Inga adresse blir vist eller kan endrast.                                                          | ☐   |
| 6.9 | Endre adressa for ein organisasjon og gå tilbake til «Meg selv». | Privatadressa er uendra.                                                                                     | ☐   |

Altinn er ikkje kopla til i scratch. 6.6–6.9 krev SIT2 eller ein Altinn-stub.

## 7. Innsending i skuggemodus

| #   | Steg                                                                      | Forventa resultat                                                      | OK  |
| --- | ------------------------------------------------------------------------- | ---------------------------------------------------------------------- | --- |
| 7.1 | Slå på brytarane (`flags all`) og send inn ein søknad som portalbrukaren. | Søknaden blir lagra som før. Deltakinga får rolle og domenekontakt.    | ☐   |
| 7.2 | Kontroller organisasjonen til søknaden.                                   | ACR finst mellom domenekontakten og organisasjonen.                    | ☐   |
| 7.3 | Endre adressa for organisasjonen i «Min profil» etter innsending.         | `Email__c` på deltakinga er uendra. Historikken blir ikkje skriven om. | ☐   |

Varsel til kontekstadressa (`AAREG_ContactModel_ContextAddress`) er ikkje kopla til
utsendingane enno og blir testa når den delen er bygd.

## 8. Skjerma person og deling

| #   | Steg                                                                                  | Forventa resultat                                                        | OK  |
| --- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ | --- |
| 8.1 | Køyr PLAN og opne rapporten for manuell vurdering.                                    | Den syntetiske skjerma personen ligg i klasse D og blir ikkje kopla.     | ☐   |
| 8.2 | Logg inn som portalbrukar A og prøv å opne kontaktpunktet til portalbrukar B via URL. | Ingen tilgang.                                                           | ☐   |
| 8.3 | Logg inn som saksbehandlar utan admin-løyve og søk etter kontaktpunkt.                | Berre kontaktpunkt saksbehandlaren har tilgang til etter delingsreglane. | ☐   |

## Avslutning

- [ ] `npm run contact-model -- status` er lagra som vedlegg.
- [ ] Avvik er registrerte med lenkje til issue.
- [ ] Brytarane er sette tilbake til ønskt omfang.
