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

Berre `Synthetic Community Test User` kan logge inn i portalen i scratch. Seed-brukarane har ei lisens utan
portaltilgang og finst berre for migreringa. Opne kontakten «Synthetic Community Test User» og vel
«Log in to Experience as User». Forsida opnar seg.

| #    | Steg                                                  | Forventa resultat                                                               | OK  |
| ---- | ----------------------------------------------------- | ------------------------------------------------------------------------------- | --- |
| 6.0  | Sjå på forsida før og etter at du vel ein virksomhet. | Flisa «Min profil» blir vist i begge tilfelle. Med `Profile` av er flisa borte. | ☐   |
| 6.0b | Trykk på «Min profil».                                | `/aaregisteret/s/min-profil` opnar seg.                                         | ☐   |

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

Stadfesting til kontekstadressa blir testa i [testskript 10](#10-stadfesting-til-adressa-for-organisasjonen).

## 8. Skjerma person og deling

For 8.4, 8.5, 8.7 og 8.8 skjermar du testbrukaren mellombels, og fjernar skjerminga att etterpå:

```bash
sf apex run --target-org crm-arbeidsforhold -f scripts/scratch/contactModel/shield-test-user.apex
sf apex run --target-org crm-arbeidsforhold -f scripts/scratch/contactModel/unshield-test-user.apex
```

| #   | Steg                                                                                       | Forventa resultat                                                                | OK  |
| --- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------- | --- |
| 8.1 | Køyr PLAN og opne rapporten for manuell vurdering.                                         | Den syntetiske skjerma personen ligg i klasse D og blir ikkje kopla.             | ☐   |
| 8.2 | Logg inn som portalbrukar A og prøv å opne kontaktpunktet til portalbrukar B via URL.      | Ingen tilgang.                                                                   | ☐   |
| 8.3 | Logg inn som saksbehandlar utan admin-løyve og søk etter kontaktpunkt.                     | Berre kontaktpunkt saksbehandlaren har tilgang til etter delingsreglane.         | ☐   |
| 8.4 | Logg inn som den skjerma testbrukaren og opne forsida og `/aaregisteret/s/min-profil`.     | Flisa «Min profil» er borte, og profilen er ikkje tilgjengeleg.                  | ☐   |
| 8.5 | Send inn ein søknad som den skjerma brukaren.                                              | Søknaden blir lagra som før. Ingen domenekontakt, ACR eller kontaktpunkt.        | ☐   |
| 8.6 | Opne panelet på ein organisasjon der ein person er blitt skjerma etter innsending.         | Namnet er «Skjerma person», adressene er skjulte og har inga lenkje.             | ☐   |
| 8.7 | Med `phase pilot`: opne `/aaregisteret/s/ny-soknad-aa-registret` som den skjerma brukaren. | Det gamle søknadsskjemaet blir vist, utan rolle-steget og organisasjonsveljaren. | ☐   |
| 8.8 | Skjerm ein person som alt har domenekontakt, og send inn ein ny søknad som han.            | Stadfestinga går via den gamle kontaktkoplinga, ikkje til kontaktpunktet.        | ☐   |

## 9. Forsida: vel rolle

Set `phase pilot` og logg inn som pilotbrukaren. Opne `/aaregisteret/s/`.

| #    | Steg                                               | Forventa resultat                                                                                                                                          | OK  |
| ---- | -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | --- |
| 9.1  | Sjå på forsida før du vel noko.                    | «Aa-registeret» med rollene Arbeidsgiver, Samarbeidspartner og Privatperson. Ingen tenester er viste.                                                      | ☐   |
| 9.2  | Vel «Privatperson».                                | `/privatperson` med «Rolle: Privatperson / arbeidstaker», «Du trenger ikke velge virksomhet», «Min profil» og «Flere tjenester for privatpersoner kommer». | ☐   |
| 9.3  | Trykk «Bytt rolle», og vel «Arbeidsgiver».         | `/arbeidsgiver` med «Rolle: Arbeidsgiver», søkbar veljar og «Oppdater liste». Ingen virksomheit er vald, og ingen tenester er viste.                       | ☐   |
| 9.4  | Søk på namn og deretter på organisasjonsnummer.    | Lista blir filtrert på begge.                                                                                                                              | ☐   |
| 9.5  | Vel ei virksomheit med tilgang i Altinn.           | Tilgangen blir sjekka med ein gong. Veljaren viser virksomheita, og berre tenestene rolla gir blir viste i to kolonnar.                                    | ☐   |
| 9.6  | Opne «Ny søknad».                                  | Søknadsskjemaet opnar direkte for virksomheita du valde. Søknaden spør ikkje etter rolle.                                                                  | ☐   |
| 9.7  | Vel ei virksomheit der rolla er fjerna i Altinn.   | Melding om manglande tilgang. Ingen tenester blir viste.                                                                                                   | ☐   |
| 9.8  | Opne `/aaregisteret/s/?type=employer&org=<orgnr>`. | Går rett til rollesida for arbeidsgivar, og tilgangen blir kontrollert.                                                                                    | ☐   |
| 9.9  | Opne `/aaregisteret/s/?c__message=no-access`.      | Fast melding: «Du har ikke tilgang til denne siden. Velg en annen rolle.»                                                                                  | ☐   |
| 9.10 | Set `phase shadow` og last forsida på nytt.        | Dagens forside blir vist, utan rolleval.                                                                                                                   | ☐   |

9.4–9.7 krev SIT2 eller ein Altinn-stub.

## 10. Stadfesting til adressa for organisasjonen

Set `phase pilot`. Lagre ei privatadresse og ei adresse for organisasjonen i «Min profil» først.

| #    | Steg                                                                    | Forventa resultat                                                                                       | OK  |
| ---- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | --- |
| 10.1 | Send inn ein søknad for organisasjonen med ei ny e-postadresse.         | Stadfestinga i `EmailQueue__c` går til den nye adressa. Kontaktpunktet for organisasjonen er oppdatert. | ☐   |
| 10.2 | Opne «Min profil» og vel «Meg selv».                                    | Privatadressa er uendra og har ikkje fått stadfestinga.                                                 | ☐   |
| 10.3 | Set `phase switch` og send inn ein ny søknad med ei anna e-postadresse. | Søknaden blir kopla til domenekontakten. Det blir ikkje oppretta ein ny kontakt for e-posten.           | ☐   |
| 10.4 | Set `phase broad` og send inn igjen.                                    | Den gamle koplinga per e-post er i bruk att.                                                            | ☐   |

## 11. Utrulling og tilbakerulling

Følg [runbooken](../utrulling.md). Køyr `npm run contact-model -- status` etter kvart steg.

| #    | Steg                                   | Forventa resultat                                                                     | OK  |
| ---- | -------------------------------------- | ------------------------------------------------------------------------------------- | --- |
| 11.1 | `phase dark`                           | Alle fem brytarane er `off`. Portalen og innsending er som før.                       | ☐   |
| 11.2 | `phase shadow` og send inn ein søknad. | `ShadowWrite` er `all`. Talet på deltakingar aukar. Portalen er uendra.               | ☐   |
| 11.3 | `phase pilot`                          | Dei tre portalbrytarane er `pilot`. Berre pilotbrukaren ser rolle-steget og profilen. | ☐   |
| 11.4 | `phase broad`                          | Dei tre portalbrytarane er `all`.                                                     | ☐   |
| 11.5 | `phase switch`                         | `LegacyMatchingOff` er `all`.                                                         | ☐   |
| 11.6 | `phase shadow`                         | Tilbake til skugge. Portalen er som før, data frå tidlegare fasar er urørte.          | ☐   |

## 12. Navigasjon og brødsmulesti

Set `phase pilot` og logg inn som pilotbrukaren. Opne `/aaregisteret/s/`.

| #     | Steg                                                                                            | Forventa resultat                                                                                                           | OK  |
| ----- | ----------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | --- |
| 12.1  | Sjå på forsida.                                                                                 | Ingen brødsmulesti.                                                                                                         | ☐   |
| 12.2  | Vel «Privatperson».                                                                             | Stien viser «Forside › Privatperson / arbeidstaker». Siste ledd er ikkje ei lenkje.                                         | ☐   |
| 12.3  | Opne «Min profil».                                                                              | Stien viser «Forside › Privatperson / arbeidstaker › Min profil», på linje med overskrifta.                                 | ☐   |
| 12.4  | Trykk «Privatperson / arbeidstaker» i stien.                                                    | Tilbake på rollesida.                                                                                                       | ☐   |
| 12.5  | Trykk «Bytt rolle», vel «Arbeidsgiver» og ei virksomheit. Opne «Mine søknader» og ein søknad.   | Stien viser «Forside › Arbeidsgiver › Mine søknader › Søknad». Ingen namn på virksomheita.                                  | ☐   |
| 12.6  | Trykk «Arbeidsgiver» i stien.                                                                   | Rollesida opnar med same virksomheit vald, og tilgangen blir sjekka på nytt.                                                | ☐   |
| 12.7  | Gjer vindauget smalare enn 480px.                                                               | Stien blir erstatta av «Tilbake til {forrige side}».                                                                        | ☐   |
| 12.8  | Ctrl-/Cmd-klikk på eit panel.                                                                   | Sida opnar i ny fane.                                                                                                       | ☐   |
| 12.9  | Naviger med tastatur og skjermlesar.                                                            | «Brødsmulesti» blir lese opp som navigasjon, og siste ledd som gjeldande side.                                              | ☐   |
| 12.10 | Opne «Mine meldinger» og ei melding.                                                            | Berre éin sti: «Forside › Rolle › Mine meldinger › Melding». Ingen «Hjem» eller «Min side».                                 | ☐   |
| 12.11 | Set `phase shadow` og last ei underside på nytt.                                                | Ingen ny brødsmulesti. Den gamle stien er tilbake, og sida er som før.                                                      | ☐   |
| 12.12 | Vel «Arbeidsgiver» og ei virksomheit. Opne «Mine søknader», «Mine avtaler» og «Mine meldinger». | Kontekstlinja under stien viser «Arbeidsgiver for {namn} · Org.nr. {nummer}» på alle sidene, med same namn som i veljaren.  | ☐   |
| 12.13 | Trykk «Bytt virksomhet» i kontekstlinja.                                                        | Rollesida opnar med virksomheita vald i den grøne «Valgt»-boksen. Søkjefeltet fyller kortet.                                | ☐   |
| 12.14 | Gå til «Forside», vel «Arbeidsgiver» på nytt utan å velje virksomheit.                          | Same virksomheit er framleis vald, og tilgangen blir sjekka på nytt.                                                        | ☐   |
| 12.15 | Opne «Min profil» frå rollesida.                                                                | Profilen startar med same virksomheit vald. For privatperson startar han med «Meg selv».                                    | ☐   |
| 12.16 | Vel «Privatperson» og opne «Min profil».                                                        | Kontekstlinja seier «Du bruker tjenesten på egne vegne» og har «Bytt rolle».                                                | ☐   |
| 12.17 | Opne «Mine søknader», ein søknad, «Ny søknad» og ei melding.                                    | Tittelen (til dømes «Aa-registeret - Henvendelse») står som stor overskrift under stien og kontekstlinja. Ingen blå banner. | ☐   |
| 12.18 | Set `phase shadow` og last same sider på nytt.                                                  | Det blå banneret er tilbake øvst, og stien og kontekstlinja er borte.                                                       | ☐   |

12.5–12.6 og 12.12–12.15 krev SIT2 eller ein Altinn-stub. I scratch blir dei dekte av Playwright med syntetiske virksomheiter.

## 13. Listevisningar og postsider

Opne appen «Arbeidsforhold Admin» eller «Aa-registeret Kontaktmodell».

| #    | Steg                                                                      | Forventa resultat                                                                                                                                                                                   | OK  |
| ---- | ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- |
| 13.1 | Opne fana «Aa-register Contact Points» og listevelgaren.                  | Seks listevisningar: All Contact Points, Private Contact Points, Organization Contact Points, Contact Points Missing Email, Org Context Missing Organization og Contact Points Changed Last 7 Days. | ☐   |
| 13.2 | Vel «All Contact Points».                                                 | Kolonnane Contact, Context, Organization, Email, Phone og Last Modified.                                                                                                                            | ☐   |
| 13.3 | Vel «Contact Points Missing Email» og «Org Context Missing Organization». | Berre kontaktpunkt utan e-post, og berre organisasjonskontaktpunkt utan organisasjon. Begge bør vere tomme etter ei rein migrering.                                                                 | ☐   |
| 13.4 | Opne eit kontaktpunkt.                                                    | Toppfeltet viser kontakt, kontekst, organisasjon, e-post og telefon. Seksjonane Contact Point, Address og System Information. «Participations» til høgre.                                           | ☐   |
| 13.5 | Opne fana «Contact Migration Runs» og listevelgaren.                      | Seks listevisningar: All Migration Runs, Queued and Running Migration Runs, Migration Runs With Failures, Migration Runs With Deviations, Apply and Rollback Runs og Migration Runs Last 30 Days.   | ☐   |
| 13.6 | Opne ei APPLY-køyring.                                                    | Seksjonane Run, Timeline, Results, Classification, Summary og System Information. «Items» og «Follow-up Runs» til høgre.                                                                            | ☐   |
| 13.7 | Opne ei rad under «Items».                                                | Postsida viser klasse, handling, søknad og grunn.                                                                                                                                                   | ☐   |

## 14. Snarvegar, løyve og brukarar

Opne appen «Arbeidsforhold Admin» som ein brukar med `AAREG_Admin_Viewer`.

| #    | Steg                                                                   | Forventa resultat                                                                                                                | OK  |
| ---- | ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | --- |
| 14.1 | Opne startsida.                                                        | «Snarvegar» øvst med seks grupper. Snarvegar du ikkje har tilgang til, er grå og forklarer kvifor.                               | ☐   |
| 14.2 | Skriv «p360» i søkjefeltet.                                            | Berre P360-snarvegane står att.                                                                                                  | ☐   |
| 14.3 | Vel «Søknader», gå tilbake og vel «Brukarstøtte» under andre appar.    | Lista over søknader blir opna. Deretter blir appen «Aa-registeret – Brukerstøtte» opna.                                          | ☐   |
| 14.4 | Opne fana «Løyve og brukarar» og vel eit løyve.                        | Detaljane viser målgruppe, forklaring, tilrådde kombinasjonar, objekttilgang og custom permissions.                              | ☐   |
| 14.5 | Filtrer på målgruppa «Integrasjonsbrukar».                             | Berre integrasjonsløyva står att.                                                                                                | ☐   |
| 14.6 | Logg inn som ein brukar med berre `AAREG_Admin_Viewer`.                | Fana «Interne brukarar» manglar. I staden står det at løyvesettet «AAREG Admin Access Overview» trengst.                         | ☐   |
| 14.7 | Logg inn med `AAREG_Admin_Access_Overview` og opne «Interne brukarar». | Tabell med status, profil, løyve, siste innlogging og tal på problem.                                                            | ☐   |
| 14.8 | Vel ein saksbehandlar.                                                 | Problema blir forklarte. Effektiv tilgang viser kvart hovudobjekt og kva løyve som gir tilgangen. «Opne brukaren i Setup» finst. | ☐   |

## Avslutning

- [ ] `npm run contact-model -- status` er lagra som vedlegg.
- [ ] Avvik er registrerte med lenkje til issue.
- [ ] Brytarane er sette tilbake til ønskt omfang.
