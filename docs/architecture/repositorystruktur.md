---
tittel: Repositorystruktur for Aa-registeret Salesforce-pakken
status: UTKAST
kilde: Confluence — Repositorystruktur for Aa-registeret Salesforce-pakken (PDF-eksport)
hentet: 2026-09-08
speilkopi: ja
---

# Repositorystruktur for Aa-registeret Salesforce-pakken

**Status:** UTKAST

## Formål

Dette dokumentet definerer repositorystrukturen for Aa-registeret Salesforce-pakken `crm-arbeidsforhold`.

Målet er å ha ein struktur som gjer det lett å forstå kva som høyrer saman funksjonelt, samtidig som strukturen fungerer med eksisterande unlocked package, Salesforce DX, CI/CD og etablerte namnestandardar.

Dokumentet er generelt for Aa-registeret-pakken. P360-integrasjonen blir brukt som konkret eksempel fordi han både har Apex, objects, custom metadata, credentials, permission sets og potensielt brukarflater/flows knytt til arkivering.

## Kontekst

Aa-registeret-løysinga blir levert som ei unlocked package:

```text
crm-arbeidsforhold
```

I `sfdx-project.json` peikar pakken på:

```text
force-app
```

som package directory.

Det betyr at alt som ligg under `force-app` kan vere ein del av same package, sjølv om vi organiserer innhaldet i fleire funksjonsmapper.

Repoet har allereie ein funksjonsbasert praksis under `force-app`. Denne avgjerda formaliserer retninga, men justerer namngiving og struktur slik at foldernamn uttrykkjer ansvar og eigarskap, ikkje historiske eller personlege namneval.

## Problem

Standard Salesforce DX-struktur med alt under `force-app/main/default` fungerer greitt for små prosjekt, men blir svakare når ein pakke inneheld fleire funksjonsområde.

Dersom metadata berre blir organisert etter metadata-type, får vi til dømes:

```text
force-app/main/default/classes/
force-app/main/default/lwc/
force-app/main/default/objects/
force-app/main/default/flows/
```

Då blir funksjonell samanheng spreidd over mange globale mapper.

For Aa-registeret ønskjer vi heller at funksjonsområde skal vere den primære organiseringa.

Samtidig må vi skilje mellom tre ulike typar eigarskap:

```text
domain/       = Aa-registeret sitt eige forretningsdomene
integration/  = system-til-system-integrasjonar
surfaces/     = brukarflater, delt i interne og eksterne flater
tests/        = testkode og teststøtte
```

Med interne og eksterne flater meiner vi ikkje interne og eksterne system. Vi meiner:

```text
surfaces/internal = brukarflater for NAV-tilsette
surfaces/external = brukarflater for kundar/konsumentar
```

Integrasjonar er integrasjonar, uavhengig av om systemet vi snakkar med er internt eller eksternt.

## Arkitekturmål

Repositorystrukturen skal støtte:

- éi unlocked package for Aa-registeret no
- funksjonsbasert organisering under `force-app`
- samling av metadata som høyrer til same funksjon
- tydeleg skilje mellom domene, integrasjonar og brukarflater
- tydeleg skilje mellom interne og eksterne brukarflater
- tydeleg skilje mellom felles integrasjonsgrunnlag og konkrete integrasjonar
- vidareføring av lagdelinga frå F1 for P360-integrasjonen
- tydeleg skilje mellom produksjonskode og testkode
- enkel navigering for utviklarar
- enkel kodegjennomgang
- trygg vidareutvikling når pakken får fleire funksjonar
- kompatibilitet med eksisterande CI/CD og package build
- enklare framtidig splitting i fleire Salesforce unlocked packages dersom behovet oppstår

## Ikkje-mål

Strukturen skal ikkje:

- splitte `crm-arbeidsforhold` i fleire unlocked packages no
- innføre fleire package directories for produksjonsmetadata i denne fasen
- krevje `main/default` for nye funksjonsmapper
- bruke `aareg_` som prefiks på folderar, sidan heile pakken er Aa-registeret
- bruke lange foldernamn som `ApplicationAgreement` dersom `agreement` er dekkjande
- bruke folderstruktur til å beskrive datarelasjonar meir enn eigarskap
- flytte alt inn i P360 berre fordi P360 bruker data frå andre område
- gjere `integration/common` til ei dumping-sone
- blande teststøtte inn i produksjonskode
- endre namnestandard for Apex eller metadata
- etablere ein endeleg pakkestrategi for framtidig oppdeling

Strukturen skal likevel gjere ei framtidig splitting enklare ved at metadata alt er gruppert etter eigarskap og funksjonsområde.

## Prinsipp

### 1. `force-app` er package directory

`force-app` held fram som package directory for `crm-arbeidsforhold`.

Funksjonsmapper under `force-app` er intern organisering i same package.

Vi skal ikkje innføre dette no:

```text
force-app/p360/main/default
force-app/application/main/default
force-app/agreement/main/default
```

Det ville indikert separate package directories og er ikkje nødvendig for dagens behov.

### 2. Foldernamn skal beskrive eigarskap

Foldernamn skal vere korte, stabile og forståelege.

Vi brukar:

```text
application
agreement
decision
```

ikkje:

```text
aareg_ApplicationInternal
aareg_ApplicationAgreementInternal
aareg_ApplicationDecisionInternal
```

Heile pakken er Aa-registeret, så `aareg_` i foldernamn gir lite verdi.

Folderar skal ikkje prøve å modellere alle relasjonar mellom objekt. `agreement` held som eigarskap sjølv om avtale heng saman med application. `decision` held som eigarskap sjølv om vedtak heng saman med application.

### 3. Domene, integrasjon og brukarflater er ulike aksar

Vi skil mellom:

```text
domain/
integration/
surfaces/
tests/
```

Dette gjer at P360 ikkje blir blanda med interne brukarflater, og at Application ikkje blir blanda med P360 berre fordi P360 treng Application-data.

### 4. Integrasjonar ligg under `integration`

System-til-system-integrasjonar skal liggje under:

```text
force-app/integration
```

Eksempel:

```text
force-app/integration/p360
force-app/integration/altinn
force-app/integration/brreg
```

P360-integrasjonen er ein integrasjon og skal derfor liggje under `integration/p360`.

### 5. Brukarflater ligg under `surfaces`

Brukarflater skal liggje under:

```text
force-app/surfaces
```

Vi skil mellom:

```text
force-app/surfaces/internal
force-app/surfaces/external
```

`internal` er flater for NAV-tilsette.

`external` er flater for kundar/konsumentar.

Dette betyr at ein LWC som viser arkiveringsstatus til ein saksbehandlar normalt høyrer heime under intern brukarflate, ikkje under sjølve P360-integrasjonen.

### 6. Metadata-type-mapper inni funksjonsområdet

Inni eit funksjonsområde brukar vi metadata-type-mapper.

Eksempel for P360-integrasjonen:

```text
force-app/integration/p360/classes
force-app/integration/p360/objects
force-app/integration/p360/customMetadata
force-app/integration/p360/permissionsets
force-app/integration/p360/namedCredentials
force-app/integration/p360/externalCredentials
```

Eksempel for intern arkiveringsflate:

```text
force-app/surfaces/internal/archive/lwc
force-app/surfaces/internal/archive/flows
force-app/surfaces/internal/archive/flexipages
force-app/surfaces/internal/archive/permissionsets
```

### 7. Apex kan ha intern lagdeling

Apex-kode kan delast vidare etter teknisk ansvar.

For P360-integrasjonen bruker vi denne lagdelinga:

```text
classes/
  orchestration/
  domain/
  adapter/
  client/
  mapper/
  contract/
    dto/
  exception/
```

Dette vidarefører F1-prinsippa om klare grenser mellom use case-styring, domene, mapping, adapter, transport og kontrakt.

### 8. Felles integrasjonsgrunnlag ligg i `integration/common`

Felles integrasjonsbyggesteinar skal liggje i:

```text
force-app/integration/common
```

Dette området skal berre innehalde komponentar som er generelle for fleire integrasjonar.

Eksempel:

- correlation context
- felles loggkontekst
- generelle integration exceptions
- generelle transport/configuration/mapping exceptions

P360-spesifikk kode skal ikkje liggje i `common`.

### 9. Testkode skal vere skild frå produksjonskode

Testkode, fakes, mocks, builders og test helpers skal liggje under:

```text
force-app/tests
```

Teststrukturen skal spegle hovudstrukturen der det gir verdi.

Produksjonskode skal ikkje avhenge av noko under `tests`.

### 10. Folderstruktur erstattar ikkje namnestandard

Folderstruktur hjelper oss å finne filer. Namnestandard hjelper oss å forstå eigarskap når metadata lever i Salesforce sitt felles metadataunivers.

Regel:

- `AAREG_` kan brukast for Aa-registeret-spesifikke Apex-klasser og metadata der det gir meining
- `P360_` brukast for P360-spesifikke Apex-klasser og metadata
- generelle integrasjonsklassar utan domenetilknyting kan vere utan domeneprefiks
