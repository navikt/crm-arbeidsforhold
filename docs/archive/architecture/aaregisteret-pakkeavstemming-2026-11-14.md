# Aa-registeret: oppfølging av pakkeavstemming

> **Arkivert kjeldegjennomgang:** Funna gjeld den undersøkte arbeidskopien på datoen nedanfor.

**Kontrollert:** 2026-11-14 frå lokal manifest-, dokumentasjons- og
`force-app/`-kjelde. **Status:** dei 11 tidlegare uavklarte direkte
avhengnadene er framleis ikkje klassifiserte som brukte eller ubrukte.
Dette dokumentet legg til søkedekning utan å endre den eksisterande
[pakkekallsite-matrisa](../../architecture/aaregisteret-pakkekallsite-matrise.md).

## Resultat

Den lokale gjennomgangen søkte i `force-app/` etter API-namna som den
[pakkeoversikta](../../architecture/pakkeavhengigheiter.md) brukar som orienterande døme, og
kontrollerte Flow XML for komponent-, action- og extension-referansar.
Desse eksakte søka gav ingen treff for dei 11 pakkane nedanfor.

| Direkte pakke                  | Søkta eksempel på API-/metadata-namn                                 | Resultat i `force-app/`                                                             | Tolkingsgrense                                                                                                                                                               |
| ------------------------------ | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `custom-permission-helper`     | `CustomPermissionHelper`, `CustomPermissionHelperStub`               | Ingen direkte produkt-/metadata-treff                                               | Indirekte kjeldeavhengnad via `feature-toggle` er dokumentert i [P360-planen](../p360/inngangar-og-verifikasjonsplan-2026-11-14.md); dette er ikkje eit direkte produktkall. |
| `record-type-cache`            | `RecordTypeCache`, `RecordTypeSelector`                              | Ingen treff                                                                         | Salesforce sin standard RecordType API og eventuell dynamisk lookup er ikkje det same som direkte bruk av denne pakka.                                                       |
| `crm-platform-reporting`       | `ReportingData__c`, `AmplitudeHelper`                                | Ingen treff                                                                         | Generiske analyse-/eventnamn kan krevje eigne metadata- eller runtime-spor.                                                                                                  |
| `crm-shared-flowComponents`    | `fcFlowRecordNavigator`, `fcFlowNextScreenNavigator`                 | Ingen treff; Flow `extensionName`-søk fann berre standard `flowruntime`-komponentar | Flow-søket dekkjer ikkje alle org-byggde sider eller dynamisk konfigurasjon.                                                                                                 |
| `crm-platform-access-control`  | `UsersSelector`, `DefaultRecordOwner__c`, `crmPersonSharingRerunner` | Ingen treff                                                                         | Manglande namnetreff er ikkje bevis på at installerte automatiseringar ikkje nyttar pakka.                                                                                   |
| `crm-thread-view`              | `crmThreadViewFormattedDate`, `crmThreadViewMessageContainer`        | Ingen treff                                                                         | Dynamisk Experience Cloud-komposisjon og komponentreferansar i org er ikkje verifiserte.                                                                                     |
| `crm-shared-timeline`          | `Timeline_Validator`, `TimelineParent__mdt`                          | Ingen treff                                                                         | Andre generiske tidslinjesymbol kan ha andre API-namn.                                                                                                                       |
| `crm-community-base`           | `IdPortenAuthUtil`, `IdPortenTokenRefreshController`                 | Ingen treff                                                                         | Dette sporet avklarar ikkje innloggings-/callback- eller pakkeavhengnader i installert org.                                                                                  |
| `crm-journal-utilities`        | `Journal_Entry__c`, `CRM_Sak`, `CRM_AvsenderMottaker`                | Ingen treff                                                                         | Ingen journalbruk er påvist i dei søkte repo-eigde områda.                                                                                                                   |
| `crm-shared-user-notification` | `UN_TmsEventApiInnboks`, `un_UsernotificationStatus`                 | Ingen treff                                                                         | Varsling kan gå gjennom andre API-ar eller metadata.                                                                                                                         |
| `crm-platform-oppgave`         | `NavTask__c`, `CRM_DueDateUtility`, `crmOppgaveSyncher`              | Ingen treff                                                                         | Generiske `Task`-records eller indirekte Flow-/pakkeoppførsel er ikkje utelukka.                                                                                             |

Dei lokale README-ane gir pakkeoversikt og eksempel på API-ar; dei stadfestar
ikkje at desse er komplette søkeord. Søk utan treff gir difor statusen
**uavklart**, ikkje **ubrukt**. Pakkeavhengnader kan òg vere til stades for
transitiv kompilering, installasjonsrekkjefølgje eller metadata som ikkje
ligg i repoet.

## Manifest mot datert versjonsrapport

`sfdx-project.json` har 19 direkte Salesforce-pakkar. Versjonsseriane er
`LATEST`-veljarar og er ikkje eksakt installert versjon. Det tidlegare
versjonsbiletet i [pakkeoversikta](../../architecture/pakkeavhengigheiter.md) er datert
2026-10-24. Ei samanlikning viser at `crm-platform-integration` står som
`0.176.0.LATEST` i dette biletet, men `0.177.0.LATEST` i noverande manifest.
Dette er berre ein skilnad mellom to lokale kjelder; ingen installert
pakkeversjon er kontrollert i denne arbeidsrunden.

Den fullstendige erklærte dependency-lista og npm-verktøytreet er samla i
[dependency-map](https://github.com/navikt/crm-arbeidsforhold/blob/807fdcf12f3f281beb780173d0db427cf7fa0142/.github/modernize/assessment/engines/facts/dependency-map.md).
Dei 8/19 konkrete direkte referansane og avgrensingane deira står framleis i
[kallsite-matrisa](../../architecture/aaregisteret-pakkekallsite-matrise.md).

## Neste kjelde for å avklare dei 11

1. Be pakkeeigar stadfeste om kvar deklarasjon er kravd for direkte API-bruk,
   transitiv kompilering/installasjon, eksisterande org-metadata eller
   historisk kompatibilitet.
2. Dersom eigarskap framleis er uklart, kartlegg kvar pakke sine faktiske
   installerte API-/metadataavhengnader i eit godkjent ikkje-produksjonsmål.
   Eit slikt org-oppslag er ikkje utført her.
3. Ikkje fjern eller endre `dependencies`/`packageAliases` frå manifestet før
   konsekvens, rollback og package-eigarskap er dokumentert og godkjent.
