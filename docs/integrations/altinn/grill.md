# Kritisk avklaringsrunde: Altinn-scenario

**Dato:** 2026-10-20  
**Metode:** Direkte gjennomgang av samtale, kode og repositorydokumentasjon.
`grill`-skill vart forsøkt lasta, men er ikkje tilgjengeleg. Dette dokumentet er
ikkje resultat frå ein køyrd skill, eit sikkerheitsreview eller ein org-test.

## Avklaringar frå brukaren

| Spørsmål                                          | Svar / konsekvens                                                                       |
| ------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Kva testar vi?                                    | Berre crm-arbeidsforhold si handtering av resultat; inga Altinn-integrasjonstesting     |
| Kven eig mock-val og data?                        | Konsumenten, ikkje den delte integrasjonspakka                                          |
| Må org-standard opprettast?                       | Nei; manglande record skal bety av, utan scenario-relatert feil                         |
| Kan vi bruke scenario i produksjon?               | Nei no; framtidig opning er eiga avgjerd, ikkje eit overstyringsflagg                   |
| Kva med andre miljø?                              | I utgangspunktet tillatne, med autorisering og kontroll på data/sideeffektar            |
| Byggje Admin-app eller administrasjonsteneste no? | Nei. Berre scenario-køyring og Setup; administrasjonstenesta kjem seinare               |
| Korleis skal scenario definerast?                 | Brukaren ønskjer enklast mogleg veg til framtidig Admin-app                             |
| Kva cache-alternativ?                             | Dokumenter både dynamisk oppfrisking og separate testbrukarar; vel seinare etter omfang |

## Spørsmål som utfordrar designet

### G01 - Er det nødvendig å endre integrasjonspakka?

Ikkje strengt nødvendig: konsumenten kunne brukt interfacet direkte og gjort
eigne casts. Føreslått additiv fasadekonstruktør bevarer den typa fasaden som
konsumentane brukar i dag og unngår spreidde casts. Kostnaden er ei ekstern
pakkeleveranse. Direkte interfacebruk er reservealternativ dersom pakkeeigar ikkje
kan levere, ikkje noko vi implementerer parallelt.

### G02 - Er dette ein global brytar som kan gi alle mock-rettar?

Nei. Føreslått policy krev faktisk brukarrecord og særskild permission.
Samanslegen hierarki-lesing kan arve org/profil true og er derfor utilstrekkeleg.
Ingen automatisk org-record blir oppretta ved installasjon.

### G03 - Kan ein administrator manipulere produksjonsoppsett i Setup?

Ein app kan ikkje nekte ein privilegert administrator å redigere Salesforce
Custom Settings generelt. Løftet er at scenario-runtime avviser aktivering i
produksjon, også etter slik redigering. Administrativ skrivesperre kan først
handhevast i ei framtidig app-eigd administrasjonsteneste.

### G04 - Kvifor ikkje berre bruke null som standard for alle feil?

Forventa fråvær skal bety av. Oppslagsfeil, ugyldig aktiv record og forbode miljø
skal derimot vere eksplisitte feil. Elles kan ein trudd mock-test gjere live-kall.
Ingen brei catch som returnerer live-tenesta.

### G05 - Gjer versjonerte filer ein framtidig Admin-app enkel?

Ja for å liste og tilordne faste scenario; ikkje automatisk for å redigere dei.
Forslaget er eit stabilt katalogformat og ein eigen lesar no. Editor, skrivbar
lagring og migrering kjem seinare dersom det blir eit behov. Dette er eit
føreslått minimum, ikkje godkjend detaljimplementasjon.

### G06 - Kan vi berre returnere Permit for ein ressurs vi ikkje kjenner?

Nei. Eksplisitt rettsmatrise per testidentitet, organisasjon og ressurs.
Ukjende kombinasjonar gir oppsettsfeil. Den eksisterande applikasjonen må framleis
velje brukerstøtte-fallback når søknadsrett er Deny.

### G07 - Blir all testing ufarleg av at Altinn er mocka?

Nei. Delingar og annan DML skjer framleis. E-post og andre callouts er uendra.
Isoler testdata og kontroller andre kanalar før UI-innsendingar. Produksjonssperra
gjelder heile den leverte scenario-bana, ikkje berre ein framtidig seed-knapp.

### G08 - Kva skjer med Permit-til-Deny?

UI kan vise avslag, medan tidlegare delingar finst. Vi karakteriserer dette
eksplisitt. Vi byggjer ikkje tilbakekalling inn i mocken eller påstår at dagens
kode har slik tilbakekalling.

### G09 - Kan testane likevel gi falsk tryggleik?

Ja, dersom provideren returnerer andre kontraktar enn live, berre testar
happy-path, eller skjuler forelda klientcache. Scenarioa skal merke realistiske
resultat kontra robustheitsinput, og observere applikasjonen sine faktiske utfall.
Eit funn i S05/S08 er ikkje grunn til å endre produktet utan ei eiga åtferdsavgjerd.

### G10 - Er eksisterande testar nok?

Nei. Dagens organisasjonstest brukar v2-bane, og brukerstøtte-fallback har eit
testflagg. Nye testar må bruke ulike svar for dei to ressursane og den faktiske
provider-wiringa. Rein Deny må bevise ingen nye delingar.

### G11 - Er alle avgjerder låste?

Nei. D01 om cache er eksplisitt open. Pakkeeigar/API-tilgang og
avhengigheitsleveranse må stadfestast. Planen er eit utkast med avhengigheitsgater,
ikkje løyve til deploy, installasjon eller pakkeutgiving.

## Kravkvalitet og readiness

- [x] Brukaravklaringar skilde frå designforslag.
- [x] To spesifikasjonar med unike REQ-001 til REQ-024.
- [x] Produksjonssperre, default-off og ugyldig aktiv konfigurasjon er skilde tilfelle.
- [x] Testdata, deling og andre kanalar er tekne med.
- [x] Admin-app og administrasjonsteneste er eksplisitt utsette.
- [x] Begge cache-alternativa har kostnad og avgrensingar.
- [ ] D01 er valt etter omfangsgjennomgang.
- [ ] Pakkeeigar og kompatibel API-leveranse er stadfesta.
- [ ] Detaljdesign og raud-sone-endringar er menneskeleg godkjende for implementering.

Planlegginga kan brukast til vidare prioritering. Heile funksjonen skal ikkje
merkast klar til implementering eller ferdig verifisert før dei opne gatene er lukka.
