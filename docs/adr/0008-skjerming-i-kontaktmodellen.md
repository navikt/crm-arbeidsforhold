---
adr: 0008
tittel: Skjerma personar blir haldne utanfor kontaktmodellen
status: Foreslått
dato: 2026-11-24
---

# ADR-0008: Skjerma personar blir haldne utanfor kontaktmodellen

**Status:** Foreslått. Implementert bak brytarane for kontaktmodellen. Krev godkjenning frå tryggleiksansvarleg før
produksjon.
**Dato:** 2026-11-24
**Byggjer på:** [ADR-0006](0006-kontaktmodell-ein-kontakt-acr-og-roller.md) og
[ADR-0007](0007-kontaktpunkt-i-eige-objekt.md)
**Spesifikasjon:** [.github/specs/aareg-contact-model.md](../../.github/specs/aareg-contact-model.md)
**Issue:** [K9 #1234](https://github.com/navikt/crm-arbeidsforhold/issues/1234)

## Kontekst

Kontaktmodellen samlar éin varig kontakt per person, med ACR til organisasjonar, kontaktpunkt per kontekst og
deltaking med rolle på søknader. Ho gjer det lettare å sjå samanhengen mellom ein person og fleire organisasjonar.
For personar med strengt fortruleg eller fortruleg adresse (kode 6 og 7) og for Nav-tilsette er nettopp ei slik
samanstilling ein risiko.

Opplysninga om skjerming ligg på `Person__c` (`INT_Confidential__c` og `INT_IsNavEmployee__c`) og blir nådd frå
portalbrukaren via `User.Contact.Account.CRM_Person__r`. Delingsreglane for `Person__c` og personkontoen blir styrte
av andre team. Kontaktmodellen kan ikkje sjølv garantere at alle som ser ein kontakt eller eit kontaktpunkt, òg har
lov til å sjå at personen er skjerma.

## Beslutning

1. Ein person er skjerma når `INT_Confidential__c` er `STRENGT_FORTROLIG`, `STRENGT_FORTROLIG_UTLAND` eller
   `FORTROLIG`, eller når `INT_IsNavEmployee__c` er sann. Regelen ligg éin stad:
   `AAREG_ContactModelShielding`.
2. For skjerma personar blir det ikkje oppretta eller oppdatert domenekontakt, ACR, kontaktpunkt eller deltaking.
   Skuggeskrivinga hoppar over dei, og `ensureContactForUser` kastar unntak.
3. Innsending frå skjerma personar følgjer alltid den gamle modellen. Mottakarresolveren (K8) sjekkar skjerming ved
   kvar innsending og gir tomt resultat. Dette gjeld òg personar som har ein domenekontakt frå før dei blei skjerma.
   Flowen brukar då den gamle kontaktkoplinga sjølv når `LegacyMatchingOff` er på.
4. «Min profil» og start-steget med rolle og organisasjon (K5) er ikkje tilgjengelege for skjerma personar.
   `getSettings` melder begge som avslått, så søknaden startar i det gamle skjemaet. Serverkalla for profilen og
   organisasjonsveljaren avviser førespurnaden.
5. Migreringa set skjerma personar i klasse D. Dei blir aldri kopla automatisk.
6. Kontaktmodellpanelet maskerer namn, e-post og telefon og fjernar lenkjer for kontaktar som er blitt skjerma etter
   at data vart oppretta. Dette er forsvar i djupna, ikkje hovudkontrollen.
7. Kontrollen er fail-closed: ein feil i oppslaget skal gi gammal oppførsel, ikkje ny modell.
8. Klassen er `without sharing` fordi han må lese `Person__c` uavhengig av kven som sender inn. Han returnerer berre
   Id-ar og ja/nei, aldri feltverdiar.

## Alternativer vurdert

| Alternativ                                                      | Vurdering                                                                                                                |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Ta skjerma personar med og stole på delingsreglane              | Avvist. Delinga blir styrt av andre team, og samanstillinga er sjølve risikoen.                                          |
| Ta dei med, men med eigne private objekt og ein eigen tilgang   | Avvist for no. Krev eigen tilgangsmodell, saksbehandlarrutinar og godkjenning. Kan vurderast når behovet er dokumentert. |
| Kopiere skjermingsflagget til `Contact` eller kontaktpunktet    | Avvist. Kopien kan bli utdatert, og flagget i seg sjølv er ei sensitiv opplysning.                                       |
| **Halde dei utanfor kontaktmodellen og bruke den gamle flyten** | **Valt.** Minst ny eksponering. Den gamle flyten er allereie i bruk for desse personane.                                 |

## Konsekvenser

- Skjerma personar får ikkje «Min profil» og ikkje éin samla kontakt. Dei får same oppleving som i dag.
- Den gamle kontaktkoplinga kan ikkje fjernast heilt i oppryddingsfasen så lenge skjerma personar brukar ho. Ho må
  avgrensast til denne gruppa.
- Ein person som blir skjerma etter at data er oppretta, har framleis data i kontaktmodellen. Panelet maskerer, men
  rapportane «Kontaktpunkt per kontekst» og «Deltakingar per rolle» kan vise data til brukarar med admin-løyve.
  Dette er restrisikoen.
- Testar finst i `AAREG_ContactModelShieldingTest`, `AAREG_ContactModelRecipientTest` og
  `AAREG_ContactMigrationClassifierTest`.

## Oppfølging

- Godkjenning frå tryggleiksansvarleg før `ShadowWrite` blir slått på i produksjon.
- Eiga sak: jobb som fjernar eller anonymiserer kontaktmodelldata for personar som blir skjerma seinare, og
  filtrering av rapportane.
- Verifisering i SIT2 med syntetiske, skjerma testpersonar etter eksplisitt godkjenning.
