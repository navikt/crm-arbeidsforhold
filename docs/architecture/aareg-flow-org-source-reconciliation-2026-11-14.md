# Flow-kjelder mot scratch-org — teljingsavstemming

**Status:** eksakt DeveloperName-avstemming fullført innanfor org-spørringa sitt
filter.  
**Kontrollert:** 2026-11-14 mot lokal Flow-kjelde og eit godkjent, read-only
oppslag mot scratch-orgen `crm-arbeidsforhold`.

## Resultat

Det oppgitte avviket mellom 37 lokale Flow-filer og 36 Flow-definisjonar frå
org-spørringa kjem av ulikt søkjeomfang. Namneavstemminga stadfestar at dei 36
lokale `AAREG...`-filene svarar éin-til-éin til dei 36 org-radene:

- Lokal katalog har 37 filer. 35 har `<status>Active</status>` og to har
  `<status>Obsolete</status>`.
- 36 av filnamna startar med `AAREG`; den eine andre fila heiter
  `updateApplicationStatusOnCasehandlerStatusAdditionalInformationRequired`.
- Org-spørringa 2026-11-14 filtrerte med
  `DeveloperName LIKE 'AAREG_%'`, ikkje alle Flow-definisjonar. I SOQL er `_`
  eit jokerteikn for eitt teikn og `%` for null eller fleire teikn. Filteret
  omfattar dermed dei 36 lokale `AAREG...`-namna, også
  `AAREGApplicationAfterInsertPopulateApplicationFields`, som ikkje har
  understrek etter `AAREG`.
- Org-resultatet hadde dei same 36 `DeveloperName`-verdiane som dei 36 lokale
  filbasenamna innanfor filteret; ingen manglande eller ekstra namn vart funne.
- 34 org-rader har `ActiveVersionId` sett, og i alle 34 er
  `ActiveVersionId = LatestVersionId`. Dei svarar til 34 lokale `Active`-filer.
- Dei to org-radene utan `ActiveVersionId` er
  `AAREG_deactivateAccess` og `AAREG_getObjectTypeName`; begge lokale filer er
  merkte `Obsolete`, og org-radene har `LatestVersionId` sett.

Det lokale filnamnet utanfor filteret,
`updateApplicationStatusOnCasehandlerStatusAdditionalInformationRequired`,
er ikkje kontrollert mot org i dette oppslaget. Ikkje trekk slutning om
org-tilstand eller aktiv status for denne fila frå resultatet over.

## Attståande evidensgap

Følgjande står att før full Flow-runtime-verifikasjon:

- Org-status for den eine lokale fila utanfor `AAREG_%`-filteret.
- Om dei aktive versjonane oppfører seg som kjelda tilseier; dette oppslaget
  testa ikkje Flow-køyring.
- Om skjermflytar er bundne til venta Lightning Actions/sider.

Ingen av desse punkta kan konkluderast frå `FlowDefinition`-namn og
versjonspeikarar åleine.

## Kjelder

- [Flow-katalog](./aareg-flow-katalog.md): tidlegare breiare org-kontroll
  2026-11-13, dokumentert som 37 definisjonar med 35 aktive og to inaktive.
- [Scratch-org-snapshot 2026-11-14](./aaregisteret-scratch-org-snapshot-2026-11-14.md):
  avgrensa spørring på `AAREG_%`, 36 rader, 34 aktive versjonar og to null.
- [Flow-diagram](./aareg-flow-diagrammer.md): eksisterande prosessdiagram og
  avgrensingar.
- [GitHub Issue #1182](https://github.com/navikt/crm-arbeidsforhold/issues/1182):
  oppfølging av org-observasjonar og evidensgrenser.
