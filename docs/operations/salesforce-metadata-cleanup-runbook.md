# Runbook: Salesforce-metadataopprydding

Status: vedteken teknisk sjekkliste for denne oppryddinga. Org-gjennomforing er ikkje utført som del av denne endringa.

Operativ godkjenning, eigar og endringsvindu skal registrerast i Confluence og GitHub Issue/PR for kvar org. Dette dokumentet skal ikkje innehalde org-ID-ar, credentials, secrets eller persondata.

## Formal

Denne runbooken skal brukast nar metadata er fjerna frå repoet, men framleis kan liggje i ein eller fleire Salesforce-orgar. Ei vanleg source deploy slettar ikkje automatisk metadata som ikkje lenger finst i source tree. Sletting i org krev ein eksplisitt destructive deployment og kontrollert verifikasjon.

## Metadata som er fjerna i denne endringa

| Metadata type | Full name                         | Repo path                                                                | Grunngjeving                                                                                                                                   | Org-handling                                                                                         |
| ------------- | --------------------------------- | ------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `ApexClass`   | `AAREG_CheckObjectTypeNamingTest` | `force-app/utility/classes/AAREG_CheckObjectTypeNamingTest.cls`          | Redundant testklasse for same invocable action. Testen godtok bade suksess og exception, og hadde derfor ingen paaleggeleg kontraktsassertion. | Vurder og verifiser sletting per org. Ikkje slett produksjonsklassen `AAREG_checkObjectTypeNameche`. |
| `ApexClass`   | `AAREG_CheckObjectTypeNamingTest` | `force-app/utility/classes/AAREG_CheckObjectTypeNamingTest.cls-meta.xml` | Metadatafil for klassen over.                                                                                                                  | Blir sletta saman med Apex-klassen i destructive deployment.                                         |

Den bevarte testen er `AAREG_checkObjectTypeNamecheTest.cls`. Produksjonsklassen `AAREG_checkObjectTypeNameche.cls` blir ikkje sletta. Flow-actionen `AAREG_checkObjectTypeNameche` og permission-set-referansane skal vere uendra.

## Forhandskontroll

1. Opprett eller oppdater ei GitHub Issue med:
    - målorg og miljø;
    - metadata som skal slettast;
    - grunn og avhengigheitskontroll;
    - godkjenningar, endringsvindu og rollback-eigar.
2. Få eksplisitt godkjenning for kvar org. Produksjon krev separat godkjenning frå deployment-/driftseigar.
3. Verifiser at `AAREG_CheckObjectTypeNamingTest` ikkje er referert frå Flow, Apex, permission sets, package manifest eller CI-konfigurasjon.
4. Verifiser at produksjonsklassen `AAREG_checkObjectTypeNameche` framleis er referert der han skal vere, mellom anna frå:
    - `AAREG_getObjectTypeName.flow-meta.xml`;
    - `AAREG_Arbeidsforhold_Saksbehandling.permissionset-meta.xml`;
    - `AAREG_CommunityPermission.permissionset-meta.xml`.
5. Hent metadata frå målorgen eller bruk Salesforce Setup/Metadata API til å kontrollere at `AAREG_CheckObjectTypeNamingTest` faktisk finst der. Ikkje anta at repo-statusen er lik org-statusen.
6. Ta vare på deploy-resultat og relevant metadata-/dependency-inventar i Issue/PR. Ikkje lagre credentials eller persondata.

## Destructive deployment

Lag ei mellombels pakke utanfor repoets produksjonskatalog, eller bruk teamet si godkjende deploymekanisme:

`destructiveChangesPost.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>AAREG_CheckObjectTypeNamingTest</members>
        <name>ApexClass</name>
    </types>
    <version>66.0</version>
</Package>
```

Koyr alltid ein dry-run/deploy preview mot eksplisitt vald sandbox forst. Bruk ikkje `--target-org` med ein ukjend eller implisitt default-org. Eksempel på kommandoform, som skal tilpassast godkjend lokal deployprosess:

```bash
sf project deploy start \
  --manifest manifest/package.xml \
  --post-destructive-changes path/to/destructiveChangesPost.xml \
  --target-org <approved-sandbox-alias> \
  --dry-run
```

Etter godkjend preview kan same pakke deployast til sandbox med `--target-org <approved-sandbox-alias>`. Produksjon krev ny eksplisitt godkjenning og eksplisitt produksjonsalias; ikkje gjenbruk sandbox-kommandoen utan ny kontroll.

## Verifikasjon etter deploy

1. Kontroller at deployen er `Succeeded` og lagre deploy-ID og testresultat i Issue/PR.
2. Kontroller at `AAREG_CheckObjectTypeNamingTest` ikkje lenger finst i målorgen.
3. Kontroller at `AAREG_checkObjectTypeNameche` framleis finst og er aktiv.
4. Kontroller at Flow `AAREG_getObjectTypeName` framleis kan referere til invocable actionen.
5. Kontroller at begge relevante permission sets framleis kan referere til produksjonsklassen.
6. Køyr den bevarte Apex-testen `AAREG_checkObjectTypeNamecheTest` i ein godkjend ikkje-produksjonsorg. For produksjon skal verifikasjonen følgje teamet si godkjende release- og smoke-testprosess.
7. Dokumenter resultatet separat for kvar org: målorg, tidspunkt, deploy-ID, status, testar og eventuelle avvik.

## Feil og rollback

Sletting av ein Apex-testklasse påverkar normalt ikkje produksjonsruntime, men ein feil deploy skal likevel stoppast og eskalerast. Rollback er å gjenopprette den sletta klassen og metadatafila frå Git commit før slettinga, og deploye henne som ein vanleg ApexClass. Ikkje prøv å rulle tilbake ved å endre produksjonsklassen eller Flow-kontrakten.

Dersom kontrollen finn referansar til den sletta testklassen, stopp destructive deployment. Gjenopprett klassen i ei eiga endring, fjern eller migrer referansen med godkjend plan, og oppdater denne loggen.

## Logg per org

Kopier denne tabellen inn i Issue/PR eller Confluence-operasjonssaka for kvar målorg:

| Felt                                   | Verdi                                       |
| -------------------------------------- | ------------------------------------------- |
| Målorg og miljø                        |                                             |
| Godkjend av                            |                                             |
| Endringsvindu                          |                                             |
| Metadata sletta                        | `ApexClass/AAREG_CheckObjectTypeNamingTest` |
| Preview/deploy-ID                      |                                             |
| Deploy-status                          |                                             |
| Etterkontroll utført av                |                                             |
| Runtime-/Flow-/permission-set-kontroll |                                             |
| Apex-testresultat                      |                                             |
| Avvik og oppfølging                    |                                             |

## Avgrensing

Denne runbooken dokumenterer berre testklassen som er fjerna i commit `193bd400`. Han dokumenterer ikkje sletting av `AAREG_checkObjectTypeNameche`, andre Apex-klasser, Flow, permission sets eller data. Slike slettingar krev eigne metadata-linjer, dependency-kontrollar og godkjenning.
