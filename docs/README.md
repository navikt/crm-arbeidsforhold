# Dokumentasjon

Denne mappa inneheld teknisk dokumentasjon for `crm-arbeidsforhold` og Aa-registeret Salesforce-løysinga.

Dokumentasjonen er organisert etter dokumenttype og ansvar. Start i området som passar spørsmålet ditt, og følg lenkene vidare til detaljdokumentasjonen.

## Dokumentasjonskart

| Område               | Innhald                                                                                         | Inngang                                         |
| -------------------- | ----------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Arkitektur           | Overordna arkitektur, lagdeling, repositorystruktur og tekniske designval                       | [Arkitektur og design](architecture/README.md)  |
| ADR                  | Architecture Decision Records med kontekst, vurderte alternativ og konsekvensar                 | [ADR-register](adr/README.md)                   |
| Integrasjonar        | Adapterar, klientar, DTO-ar, mapping, auth, retry, logging og integrasjonsspesifikke kontraktar | [Integrasjonar](integrations/README.md)         |
| Domene               | Domenemodell, forretningsomgrep og domenereglar                                                 | [Domenedokumentasjon](domain/README.md)         |
| Brukarflater         | Dokumentasjon for Experience Cloud, interne flater og andre brukarflater                        | [Brukarflater](surfaces/README.md)              |
| Kontekst             | Spegla Jira-/Confluence-kontekst og prosjektspesifikke arbeidsnotat                             | [P360-kontekst](context/p360/jira/README.md)    |
| Utviklingsstandardar | Spegla oversikt over standardar og lenker til operativ fasit                                    | [Utviklingsstandardar](utviklingsstandarder.md) |

## P360

P360-dokumentasjonen ligg under [integrations/p360](integrations/p360/README.md). Viktige repo-eigde dokument er:

- [P360 dependency injection og adapterval](integrations/p360/di-og-adapterval.md)
- [P360 datamodell og asynkron arkiveringsjobb](architecture/p360-data-model-og-arkiveringsjob.md)
- [P360 SIF RPC-operasjonar og kontraktsstatus](integrations/p360/sif-rpc-operasjonar.md)
- [P360 SIF API-kontraktar](integrations/p360/sif-api-kontrakter.md)

## Kjeldehierarki

- ADR-ar er repoet si normative kjelde for arkitekturbeslutningar.
- Tekniske arkitektur- og integrasjonsdokument utan `speilkopi: ja` er repo-eigde.
- Dokument med `speilkopi: ja` er kopierte frå Confluence og skal ikkje endrast her utan at kjelda blir oppdatert.
- Jira- og Confluence-speil er arbeidskontekst, ikkje ein erstatning for godkjende tekniske beslutningar.
- GitHub Issues er kjelde for arbeidsoppgåver og opne avklaringar.

## Dokumentasjonsprinsipp

Dokumentasjonen skal:

- skilje mellom vedtekne val, foreslåtte retningar og opne spørsmål;
- vise kva som er verifisert i kode eller Salesforce-org;
- unngå credentials, tokens, cookies, persondata og miljøspesifikke hemmelegheiter;
- lenke til næraste detaljdokument i staden for å kopiere same innhald fleire stader;
- beskrive avgrensingar og framtidig migrering når eksisterande kontraktar blir vidareførte.

Sjå også [README.md i repo-roten](../README.md) for oppsett, lokal validering og overordna prosjektinformasjon.
