---
adr: 0007
tittel: Adresser i eige kontaktpunktobjekt, ikkje på ACR eller Contact
status: Foreslått
dato: 2026-11-23
---

# ADR-0007: Adresser i eige kontaktpunktobjekt, ikkje på ACR eller Contact

**Status:** Foreslått. Implementert bak brytarar som er av. Produksjonsaktivering krev godkjenning frå Team Platforce.
**Dato:** 2026-11-23
**Erstattar:** Punkt 3 og 4 i [ADR-0006](0006-kontaktmodell-ein-kontakt-acr-og-roller.md)
**Spesifikasjon:** [.github/specs/aareg-contact-model.md](../../.github/specs/aareg-contact-model.md)

## Kontekst

ADR-0006 la e-post og telefon per organisasjon på `AccountContactRelation` og privat adresse på `Contact`.
Begge objekta er delte med andre team. Kontrollen i scratch og SIT2 viser:

| Objekt                   | Intern deling        | Ekstern deling       |
| ------------------------ | -------------------- | -------------------- |
| `Contact`                | Private              | Private              |
| `AccountContactRelation` | Controlled by Parent | Controlled by Parent |
| `ContactPointEmail`      | Controlled by Parent | Controlled by Parent |

Den som kan sjå kontoen og kontakten, kan dermed sjå ACR. Delingsreglar, profilar og
permission set frå andre appar avgjer kven som ser adressene. Det kan vi ikkje styre åleine. Privatadressa og
adressa hos ein annan organisasjon må aldri bli synlege for ein organisasjon.

`ContactPointEmail` finst ikkje i SIT2. Det krev Individual og samtykkemodellen, og har same arva deling.

## Beslutning

1. Adresser blir lagra i det nye objektet `AAREG_Contact_Point__c`, med éi rad per kontekst:
    - `Context__c = Private` for personen i eigen regi.
    - `Context__c = Organization` og `Organization__c` for kvar organisasjon.
2. Objektet har **Private** deling både internt og eksternt. `Contact__c` er Lookup, ikkje master-detail,
   slik at objektet ikkje arvar delinga til Contact.
3. `Email__c` og `Phone__c` har `securityClassification = Confidential` og `complianceGroup = GDPR`.
4. Den unike nøkkelen `Context_Key__c` (`kontakt:organisasjon` eller `kontakt:PRIVATE`) sikrar éi adresse
   per kontekst og idempotente skrivingar.
5. ACR held berre ikkje-sensitive felt: `AAREG_Managed__c` og `AAREG_Altinn_Verified_At__c`.
   Contact held berre identitetsnøkkelen.
6. `RelatedContact__c.Contact_Point__c` viser kva kontaktpunkt adressa kom frå. `RelatedContact__c.Email__c`
   er framleis eit øyeblinksbilete ved innsending, så historikken er uendra når adressa blir endra.
7. Tilgangen er:
    - Permission set-et `AAREG_ContactModel_Admin` gir lesetilgang.
    - Portalen les berre gjennom controllerar som er avgrensa til eigen brukar og vald organisasjon.
    - Skrivinga skjer i systemmodus i `AAREG_ContactModelService`.
8. Adresser blir aldri brukte som fallback for ein annan kontekst.

## Well-Architected-grunngiving

- **Trusted, sikker:**
    - Eiga deling og eigen FLS, uavhengig av Contact og ACR.
    - Klassifisering gjer at feltet blir fanga opp av Data Detect, maskering i sandkasser og Shield-kryptering
      utan å påverke felt som andre team eig.
- **Trusted, compliant:**
    - Adresser kan slettast eller anonymiserast selektivt per kontekst, utan å endre kontakten eller relasjonen.
    - Krav om innsyn og sletting kan avgrensast til éitt objekt.
- **Trusted, reliable:** Unik nøkkel gjer skuggeskriving og migrering idempotent.
- **Easy:**
    - Éin stad å sjå alle adressene til ein person.
    - Rapportering per kontekst kan skje med standard rapporttypar.
    - Interne brukarar treng ikkje forstå ACR-delinga.
- **Adaptable:**
    - Adressemodellen kan bli endra, til dømes kopla til Person Account seinare, utan endringar i objekt som er delte med andre team.
    - Domenet held seg innanfor pakka.

**Tradeoff:** Det kjem eitt objekt og ein ekstra spørjing til. Det er akseptabelt fordi tilgangsstyringa elles ville
vore avhengig av delingsreglane til andre team for persondata.

## Alternativ vurdert

- **Felt på ACR (ADR-0006).** Forkasta:
    - Delinga er styrt av Account og Contact.
    - Maskering og selektiv sletting påverkar eit objekt som er delt med andre team.
    - Organisasjonar kan få innsyn via kontodelinga.
- **Privatadresse på Contact.** Forkasta. Contact er delt med andre appar og team.
- **Standardobjekta `ContactPointEmail` og `ContactPointPhone`.** Forkasta:
    - Dei er ikkje aktiverte i SIT2.
    - Dei krev Individual og samtykkemodellen.
    - Delinga er arva frå forelderen.
    - Dei kan vurderast på nytt dersom Nav innfører felles samtykkemodell.
- **Master-detail til Contact.** Forkasta. Delinga ville blitt arva frå Contact.

## Konsekvensar

- Felta `AAREG_Email__c` og `AAREG_Phone__c` på ACR og `AAREG_Private_Email__c` og `AAREG_Private_Phone__c`
  på Contact blir ikkje laga.
- Tenesta skriv kontaktpunkt per organisasjon ved innsending. Det private kontaktpunktet blir berre skrive frå
  «Min profil» (K6) og aldri avleidd frå ei organisasjonsadresse.
- Migrering (K4) og admin-visingar (K3) les adresser frå kontaktpunktobjektet.
- Skjerming (kode 6/7 og eigne tilsette) kan seinare avgrense tilgangen på dette objektet åleine.
