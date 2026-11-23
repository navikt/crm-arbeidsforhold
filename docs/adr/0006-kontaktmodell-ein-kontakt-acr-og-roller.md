---
adr: 0006
tittel: Éin kontakt per person, ACR for organisasjonar og roller på RelatedContact
status: Foreslått
dato: 2026-11-23
---

# ADR-0006: Éin kontakt per person, ACR for organisasjonar og roller på RelatedContact

**Status:** Foreslått. Blir implementert bak brytarar som er av. Produksjonsaktivering krev godkjenning frå Team Platforce.
**Dato:** 2026-11-23
**Spesifikasjon:** [.github/specs/aareg-contact-model.md](../../.github/specs/aareg-contact-model.md)
**Bakgrunn:** [docs/architecture/kontaktmodell](../architecture/kontaktmodell/README.md)

## Kontekst

I dag blir det oppretta ein ny kontakt for kvar ny kombinasjon av e-post og organisasjon. Same person
kan derfor finnast mange gonger, og ein endra e-postadresse gir ein ny person. Andre roller på
søknaden er fritekst på `RelatedContact__c` utan kopling til ein kontakt.

## Beslutning

1. Ein varig Aa-register-kontakt per innlogga person. Identiteten er portalbrukaren sin `User.Id` i det unike
   feltet `Contact.AAREG_Identity_Key__c`.
2. Kontakten har ein teknisk primærkonto. Organisasjonane personen representerer, er indirekte ACR-rader.
   Dette følgjer [ADR-0002](0002-accountcontactrelation-for-personkontoer.md).
3. E-post og telefon per organisasjon blir lagra på ACR i eigne `AAREG_`-felt. `Roles` blir ikkje brukt.
   Aa-registeret endrar berre rader med `AAREG_Managed__c = true`.
4. Privat e-post og telefon ligg på kontakten. Adressa blir vald etter kontekst, utan fallback.
5. `RelatedContact__c` blir koplingsobjektet mellom kontakt og søknad, med rolle og ein unik deltakingnøkkel.
6. Alt nytt ligg bak `Feature_Flag__mdt`-brytarar som blir lesne av ein gate som sperrer ved feil. Den gamle modellen blir
   skriven vidare til opprydningsfasen, så tilbakerulling er å slå av brytaren.
7. Migreringa tek JSON-backup før kvar endring, koplar berre sikre tilfelle og kan rullast tilbake per køyring.

## Alternativ vurdert

- **Eige kontaktpunktobjekt for adresser.** Forkasta. Det gir eit ekstra objekt med same livssyklus som ACR.
  Vi vurderer det på nytt om Team Platforce ikkje godtek domenefelt på ACR.
- **Nytt junction-objekt i staden for `RelatedContact__c`.** Forkasta. Det gir to kjelder for same roller.
- **Samanslåing på e-post.** Forkasta. Lik e-post er ikkje bevis på at det er same person.

## Konsekvensar

- Positivt: éin person, tydelege roller, adresse per organisasjon og standard rapportering på ACR.
- Negativt: Contact og ACR er delte med andre team. Duplikatreglar og triggerar frå andre team må
  takast omsyn til, og domenefelta må ikkje påverke andre appar.
- Skuggeskrivinga køyrer i systemmodus. Inndata er avgrensa til Id-ar som serveren har utleidd.
- Skjerming (kode 6/7 og eigne tilsette) og kopling til Person Account er eigne avgjerder.
