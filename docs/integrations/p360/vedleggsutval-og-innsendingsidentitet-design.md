---
tittel: P360 vedleggsutval og innsendingsidentitet
status: designforslag
---

# P360 vedleggsutval og innsendingsidentitet

**Beslutningsstatus:** Produktregelen for vidareføring av vedlegg er avklart.
Modell, Salesforce-kontrakt og ekstern P360-representasjon er framleis forslag
og må godkjennast før implementering. Dokumentet viser kjeldeanalyse, ikkje
org-verifisert åtferd.

## Avklart produktåtferd

Ved ny innsending etter krav om meir informasjon skal eit komplett nytt
dokumentsett arkiverast. Brukaren stadfesta denne standarden for vedleggsutvalet:

- Vedlegg som var markerte som gjeldande, blir førte vidare.
- Nye vedlegg blir markerte som gjeldande som standard.
- Brukaren kan endre utvalet før innsending.

«Siste ContentVersion per valt ContentDocument ved innsending» er eit godt
arbeidsutgangspunkt, men er ikkje stadfesta som endeleg P360-kontrakt.

## Kjeldeåtferd i repoet

- [Søknadsskjemaet](../../../force-app/externalApplication/lwc/aareg_application/aareg_application.js)
  les éi ny fil inn i `fileData` og sender berre denne fila til
  `saveAsDraft` eller `processApplication`.
- [Skjemamarkupen](../../../force-app/externalApplication/lwc/aareg_application/aareg_application.html)
  viser tidlegare vedlegg gjennom `c-record-files-with-sharing` med
  `is-get-all="true"` og `is-delete-option="false"`. Forelderen får ikkje eit
  filutval frå denne komponenten. Ingen lokal komponentimplementasjon vart
  funnen i repoet.
- [AAREG_ApplicationController](../../../force-app/externalApplication/classes/AAREG_ApplicationController.cls)
  opprettar `ContentVersion` utan eksplisitt `FirstPublishLocationId`, og
  opprettar `ContentDocumentLink` etterpå. Innsending utan nye fildata
  opprettar ikkje ein ny filversjon i denne controlleren.
- [P360_ContentVersionArchiveHandler](../../../force-app/integration/p360/classes/P360_ContentVersionArchiveHandler.cls)
  opprettar vedleggsjobb berre når ein ny `ContentVersion` blir sett inn med
  `FirstPublishLocationId` direkte på `Application__c` og prosesseringsporten er
  open. Dette er ikkje same inngang som portalopplastinga.
- [P360_ArchiveJobService](../../../force-app/integration/p360/classes/job/P360_ArchiveJobService.cls)
  og [P360_IdempotencyKey](../../../force-app/integration/p360/classes/job/P360_IdempotencyKey.cls)
  identifiserer søknadsdokument per søknad og vedlegg per søknad og
  ContentVersion. Dei skil ikkje same filsett i to ulike innsendingar.

Desse funna er statisk kjeldeanalyse. Dei dokumenterer ikkje effektiv
org-konfigurasjon, P360-transport eller ekstern arkiveringsåtferd.

## Føreslått kontrakt

1. **Stabil policy i Custom Metadata.** Metadata kan styre stabile reglar, til
   dømes tillatne/obligatoriske dokumentkategoriar og standardval per
   søknadstype. Metadata skal ikkje lagre kva konkrete filer ein brukar har
   valt; det er runtime-data.
2. **Vedvarande utvalsstatus.** Søknadsflata viser tidlegare vedlegg med status
   for om dei er gjeldande. Førre gjeldande utval blir ført vidare, nye vedlegg
   blir valde som gjeldande, og brukaren kan endre dette før innsending.
3. **Frose innsendingssett.** Ved ei akseptert innsending blir eit nytt,
   uforanderleg innsendingssett oppretta. Det inneheld søknadsidentiteten og
   nøyaktig éin vald `ContentVersion` per valt `ContentDocument`. Endringar i
   søknaden eller nye filversjonar etter innsending endrar ikkje det gamle
   settet.
4. **Skil innsending frå retry.** Ei ny innsending får ny stabil identitet,
   sjølv om filane har same versjonar som før. Retry av same innsending bruker
   same identitet, frosne sett og idempotensnøklar. Ein tilfeldig ny nøkkel per
   forsøk er ikkje tilstrekkeleg.
5. **Arkiver berre frå snapshot.** P360-mapping og jobboppretting skal lese det
   frosne settet, ikkje den seinare, muterbare søknads- eller fillista.
   Salesforce-transaksjonen skal opprette snapshot og interne jobbar; ekstern
   transport skal skje asynkront.

```mermaid
flowchart TD
    A["Utkast eller krav om meir informasjon"] --> B["Vis gjeldande vedlegg"]
    B --> C["Førre utval blir vidareført"]
    D["Nytt vedlegg"] --> E["Vel som gjeldande som standard"]
    C --> F["Brukar endrar utval"]
    E --> F
    F --> G["Innsending"]
    G --> H["Frys vald ContentVersion per fil"]
    H --> I["Opprett nytt innsendingssett"]
    I --> J["Opprett P360-jobbar for settet"]
    J --> K["Retry bruker same sett og identitet"]
    A --> L["Ei seinare ny innsending"]
    L --> B
```

### Caller-kontrakt som må realiserast

- Innsendingsgrensa må få den valde fillista frå brukarflata og validere at
  kvar fil framleis høyrer til søknaden og er tillaten av gjeldande policy.
- Serveren må slå opp og fryse aktuell `ContentVersion` for kvar vald fil på
  innsendingstidspunktet. Manglande, utilgjengelege eller ugyldige val skal gi
  ein synleg feil; dei skal ikkje droppast stille.
- Innsendingen må opprette eitt identitetsberande snapshot og arkivjobbar som
  peikar på det. Delvis feil må ikkje presenterast som samla arkivsuksess.
- Utvalsstatus må overleve navigasjon og lagring av utkast. Konkret
  Salesforce-recordmodell, CRUD/FLS, sharing og migrering av eksisterande
  vedlegg er ikkje avgjort.
- Kvar unik innsending må kunne skiljast frå retry også etter timeout eller
  tapt svar. Nøyaktig request-token-/resume-mekanisme må avklarast og testast.
- Gjeldande kode oppdaterer søknaden på staden. Om sjølve søknadsinnhaldet skal
  frysast som data, P360-dokumentmetadata eller ei anna representasjon, krev
  godkjend mapping og ligg utanfor denne avgjerda.

## Designval

| Alternativ                                                          | Fordelar / trade-off                                                                                                                                                                       |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Brukarstyrt utval, med vidareføring og nye filer valde som standard | Synleggjer kva som inngår, handterer gamle og nye vedlegg, og reduserer risikoen for å arkivere utdaterte filer. Krev lagring av utvalsstatus og eit snapshot per innsending. **Tilrådd.** |
| Automatisk arkivering av alle filer etter Custom Metadata-reglar    | Mindre brukarinteraksjon og enklare portalflate, men metadata kan ikkje uttrykkje den konkrete, endrande fillista for éi søknad. Risiko for at irrelevante eller utdaterte filer blir med. |

Custom Metadata bør difor avgrensast til stabile reglar og standardval.
Faktisk filval høyrer til søknadsdata og det frosne innsendingssettet.

## Testkrav for ei seinare TDD-slice

1. Lagre utkast med fleire vedlegg; kontroller at dei kan visast og at
   gjeldande-status overlever navigasjon.
2. Send inn; kontroller at kvar vald fil får gjeldande `ContentVersion` fryst,
   og at fråvalde filer ikkje er med.
3. Opprett ein ny versjon av ei vald fil etter innsending; kontroller at det
   første settet framleis peikar på den opphavlege versjonen.
4. Send inn etter krav om meir informasjon; kontroller at førre utval blir
   vidareført, nye vedlegg er valde som standard, og brukarendringar blir tekne
   med i eit komplett nytt sett.
5. Retry same innsending etter eit simulert timeout/ukjent svar; kontroller at
   same snapshot og jobbar blir gjenbrukte, utan eit tredje sett.
6. Køyr ein ny innsending med same filer; kontroller at ho får ny identitet og
   ikkje blir forveksla med retry.
7. Test ugyldig eller fråkopla fil, manglande `ContentVersion`, tomt utval når
   policy krev vedlegg, delvis jobbfeil og manglande tilgang.
8. Test servergrensa under ein minimumstilgangsbrukar når åtferda ikkje krev
   privilegert tilgang. LWC-testen skal kontrollere at endringar i utval og
   innsending blir sende gjennom same offentlege brukargrense.

Ingen av desse testane er køyrde for dette designnotatet.

## Opne avgjerder

- Nøyaktig Salesforce-modell for gjeldande utval og immutable snapshot, og
  eigarskap mellom søknadsdomenet og P360-jobbmetadata.
- Korleis same innsending blir funnen att ved retry etter timeout eller
  sideoppfrisking.
- Kategoriar, filtypar, obligatoriske dokument og metadatareglar per
  søknadstype.
- P360/SIF-kontrakt for eit nytt komplett sett, dokumentversjonar,
  duplikatidentitet og lagring av resultatreferansar.
- Kva søknadsdata P360 skal motta saman med vedlegga.
- Endeleg dataminimerings-, tilgangs- og retention-vurdering.

Sjå òg [inngangar og verifikasjonsplan](inngangar-og-verifikasjonsplan.md) og
[P360 datamodell og arkiveringsjobb](../../architecture/p360-data-model-og-arkiveringsjob.md).
