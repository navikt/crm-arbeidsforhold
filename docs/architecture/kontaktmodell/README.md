# Kontaktmodell for Aa-registeret

Éin varig kontakt per person. Kontakten er knytt til organisasjonar med ACR og til søknader med
rolle. Ho har éi privat e-postadresse og éi adresse per organisasjon, utan fallback mellom dei.

## Gjeldande dokument

| Dokument                                                              | Innhald                                                   |
| --------------------------------------------------------------------- | --------------------------------------------------------- |
| [Spesifikasjon](../../../.github/specs/aareg-contact-model.md)        | Avgjerder, datamodell, brytarar, krav, migrering og test. |
| [ADR-0006](../../adr/0006-kontaktmodell-ein-kontakt-acr-og-roller.md) | Arkitekturavgjerda og alternativa.                        |
| [ADR-0007](../../adr/0007-kontaktpunkt-i-eige-objekt.md)              | Adresser i eige kontaktpunktobjekt.                       |
| [ADR-0008](../../adr/0008-skjerming-i-kontaktmodellen.md)             | Skjerma personar blir haldne utanfor kontaktmodellen.     |
| [Utrulling](utrulling.md)                                             | Fasar, brytarprofilar, sjekkliste og tilbakerulling.      |
| [Produksjonsisolering](produksjonsisolering.md)                       | Vilkår for å installere i produksjon med brytarane av.    |
| [Inngangsportal](inngangsportal.md)                                   | Rolleval på forsida, rollesider og tilgangskontroll.      |
| [Claude-brief](claude-brief.md)                                       | Grunnlag for wireframes og diagram.                       |
| [Testing](testing/README.md)                                          | Automatiske testar, operatørrettleiing og testskript.     |

Spesifikasjonen gjeld føre alt anna i denne mappa.

## Avgjort 23. november 2026

- Rolle først, på forsida: «Arbeidsgiver», «Samarbeidspartner» eller «Privatperson». Søknaden og dei andre
  tenestene har ikkje eige rolleval. Sjå [inngangsportal.md](inngangsportal.md).
- Deretter søkbar organisasjonsveljar på namn og organisasjonsnummer, fylt frå Altinn.
- E-post per organisasjon blir lagra på ACR i eigne `AAREG_`-felt.
- Alt nytt ligg bak brytarar, og den gamle modellen blir skriven vidare til opprydninga.

## Arkiv

[arkiv/](arkiv/README.md) inneheld analysar, vurderingar og skisser som ligg til grunn for
avgjerdene. Dei er ikkje oppdaterte etter avgjerdene og skal lesast som historikk.
