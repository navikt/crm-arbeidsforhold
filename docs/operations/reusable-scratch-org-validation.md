# Manuell validering med gjenbrukbar scratch-org

Workflowen `[CI] Test reusable scratch org` er ein manuell prøve for å redusere
ventetida ved Salesforce-validering. Han køyrer berre frå `main` og endrar ikkje
den påkravde PR-valideringa.

Denne guiden er for ein **menneskeleg operatør**. Du skal både bruke terminalen
på di eiga maskin og GitHub i nettlesaren. Kvar del seier kvar du skal gjere
arbeidet. Kommandoane er for macOS med zsh eller Bash, ikkje PowerShell.

Har du allereie oppretta orgen og installert pakkane? Gjer steg 1–3, og gå
deretter til steg 6 for å registrere han i GitHub.

**Viktig:** Ein tidlegare versjon av guiden brukte `sf org display --verbose`
til å hente autentiseringa. Salesforce CLI 2.158.7 returnerer ein maskert verdi
der. Har du brukt den gamle kommandoen, køyr steg 6 på nytt før du testar.

## Oppsett

### 1. Sjekk føresetnadene

**Stad: terminalen på di eiga maskin.**

Du treng:

- Ei oppdatert lokal kopi av dette repoet og godkjend tilgang til Dev Hub-en
  som CI brukar. Ein produksjonstilknytt Dev Hub skal berre handterast av
  menneske, ikkje av agentar.
- Node.js 22, Salesforce CLI 2.158.7, `jq` og GitHub CLI (`gh`).
- Ein GitHub-konto som kan opprette og endre secrets og variablar i miljøet
  `ci-scratch-org`.
- Installasjonsnøkkelen `CRM_PACKAGE_KEY` frå teamet si godkjende
  secret-lagring. GitHub viser ikkje verdien av eit secret som alt er lagra.
  Kontakt ansvarleg i teamet dersom du ikkje har tilgang.

Opne repoet i VS Code med **File → Open Folder**, og opne ein terminal med
**Terminal → New Terminal**. Køyr:

```sh
ls sfdx-project.json
node --version
sf --version
jq --version
gh --version
gh auth status
```

Den første kommandoen skal skrive `sfdx-project.json`. Får du ein feil, står du
ikkje i repo-rota, eller så manglar eit verktøy. Stopp og rett det før du går
vidare; sjå [kom i gang-guiden](../kom-i-gang.md) for verktøyoppsett. Er du
ikkje logga inn i GitHub CLI, køyr `gh auth login` og følg dialogen for
`GitHub.com`.

GitHub-workflowen brukar `main`. Hent først siste referanse til `main`:

```sh
git fetch origin main
```

Kontroller deretter at filene som blir brukte i oppsettet, samsvarer med
`main`:

```sh
git diff --stat origin/main -- \
  sfdx-project.json config/project-scratch-def.json \
  bin/package-dependencies.js bin/package-dependency-report.js \
  scripts/ci-scratch-plan.cjs
```

Den siste kommandoen skal ikkje skrive noko. Viser han endringar, avklar korleis
du skal oppdatere den lokale kopien før du går vidare. Ikkje forkast lokale
endringar for å få kommandoen til å bli tom.

### 2. Opprett GitHub-miljøet

**Stad: GitHub i nettlesaren.**

1. Opne [navikt/crm-arbeidsforhold](https://github.com/navikt/crm-arbeidsforhold).
2. Vel **Settings → Environments**. Finst ikkje miljøet `ci-scratch-org`,
   vel **New environment** og opprett det med akkurat dette namnet.
3. Opne `ci-scratch-org`. Under **Deployment protection rules**, krev
   godkjenning frå ein ansvarleg reviewer før jobben får tilgang til secreta.

Dersom du ikkje kan sjå eller endre innstillingane, må ein repository-admin
gjere steget eller gi deg nødvendig tilgang.

Workflowen treng òg tilgang til dei eksisterande GitHub Actions-secreta
`CRM_PROD_SFDX_URL` for Dev Hub og `CRM_PACKAGE_KEY` for pakkeinstallasjon.
Dei kan vere oppretta på repository-, organisasjons- eller miljønivå. Avklar
med ansvarleg om workflowen manglar tilgang; ikkje kopier secret-verdiar til
kode, loggar eller chat.

### 3. Vel aliaset til scratch-orgen

**Stad: same terminal som i steg 1.**

Eit alias er eit lokalt namn Salesforce CLI brukar for å finne ein org.
`SCRATCH_ORG_ALIAS` er ein mellombels **terminalvariabel** som held dette
namnet. Han skal ikkje opprettast som secret eller variabel i GitHub.

Køyr denne linja dersom aliaset er `ci-reusable-scratch-org`:

```sh
SCRATCH_ORG_ALIAS=ci-reusable-scratch-org
```

Har du valt eit anna alias, byt ut `ci-reusable-scratch-org` med det aliaset.
Kommandoen gir ikkje noko svar; det er normalt. Behald terminalen open for dei
neste stega. Opnar du ein ny terminal, må du setje variabelen på nytt.

Du kan sjå lokale alias med:

```sh
sf alias list
```

Lista viser ikkje i seg sjølv kva org eit alias skal brukast til. Dersom
aliaset allereie er i bruk for ein annan org, vel eit nytt alias. Har du
allereie oppretta den dedikerte scratch-orgen og installert pakkane, gå til
steg 6.

### 4. Opprett scratch-orgen

**Stad: same terminal. Hopp over dette steget dersom du alt har oppretta orgen.**

Finn aliaset til den autoriserte Dev Hub-en som CI brukar. `sf alias list`
viser lokale alias, men du må avklare med teamet kva Dev Hub som er den rette.
Ikkje gjett dersom du er usikker.

I linja under må du byte ut `BYT_UT_MED_DIN_DEVHUB_ALIAS` med ditt faktiske
Dev Hub-alias før du køyrer henne:

```sh
DEVHUB_ALIAS=BYT_UT_MED_DIN_DEVHUB_ALIAS
```

`DEVHUB_ALIAS` er òg berre ein mellombels terminalvariabel. Opprett deretter
ein dedikert scratch-org:

```sh
(
  set -euo pipefail
  : "${SCRATCH_ORG_ALIAS:?Set SCRATCH_ORG_ALIAS som vist i steg 3}"
  : "${DEVHUB_ALIAS:?Set DEVHUB_ALIAS før du opprettar orgen}"
  sf org create scratch \
    --definition-file config/project-scratch-def.json \
    --duration-days 30 \
    --alias "$SCRATCH_ORG_ALIAS" \
    --target-dev-hub "$DEVHUB_ALIAS"
)
```

Vent til kommandoen er ferdig, og ta vare på org-ID-en som blir vist, slik at
du kan kontrollere han i steg 6. Scratch-orgen varer maksimalt 30 dagar.

Ikkje bruk `bin/create-scratch-org.sh` her. Det skriptet kan slette ein org med
same alias og deployer kjeldekode for ein vanleg utviklarorg. Denne orgen skal
vere dedikert til CI og berre ha avhengigheitspakkane installerte.

### 5. Installer pakkane

**Stad: same terminal.**

Har du hoppa over steg 4 fordi orgen finst frå før, set `DEVHUB_ALIAS` som
forklart i steg 4 før du held fram.

#### 5.1 Lag ein pakkeplan

Køyr:

```sh
CI_PACKAGE_PLAN_DIR="$(mktemp -d)" &&
  CI_PACKAGE_PLAN="$CI_PACKAGE_PLAN_DIR/plan.json"
```

Dette opprettar ei mellombels mappe og set to variablar i terminalen.
Planfila finst ikkje enno; ho blir oppretta av neste kommando. Ei ny mappe gjer
at ein tidlegare plan ikkje blir overskriven.

```sh
node bin/package-dependencies.js \
  --dev-hub "$DEVHUB_ALIAS" \
  --include-unreleased \
  --plan-file "$CI_PACKAGE_PLAN" \
  --report "$CI_PACKAGE_PLAN_DIR/dependencies-report.md" \
  < /dev/null
```

Kommandoen les pakkeinformasjon frå Dev Hub-en og lagar plan og rapportar i
den mellombelse mappa. Han installerer ikkje pakkar. Vent på meldinga
`Dependency preflight PASSED`. Feilar kontrollen, stopp og rett feilen før du
går vidare.

#### 5.2 Les inn installasjonsnøkkelen

Hent verdien til `CRM_PACKAGE_KEY` frå godkjend secret-lagring. Ikkje skriv
nøkkelen rett inn i ein kommando, ei fil, ein logg eller ein chat.

Brukar du standardterminalen **zsh** på macOS, køyr:

```zsh
read -rs "CRM_PACKAGE_KEY?Lim inn CRM_PACKAGE_KEY og trykk Enter: "
echo
```

Brukar du **Bash**, køyr i staden:

```bash
read -rsp 'Lim inn CRM_PACKAGE_KEY og trykk Enter: ' CRM_PACKAGE_KEY
echo
```

Lim inn nøkkelen når du får spørsmålet, og trykk Enter. Teikna blir ikkje viste.
Nøkkelen er no ein variabel i denne terminalen; han er ikkje lagra i GitHub
av denne kommandoen.

#### 5.3 Installer og kontroller

Køyr i same terminal:

```sh
CRM_PACKAGE_KEY="$CRM_PACKAGE_KEY" \
  node scripts/ci-scratch-plan.cjs install \
    sfdx-project.json "$CI_PACKAGE_PLAN" "$SCRATCH_ORG_ALIAS"
```

Kommandoen installerer pakkane i planrekkjefølgje og les deretter tilbake kva
som faktisk er installert. Vent til terminalen viser
`Installed package versions match the package plan.`. Manglande, feil eller
ekstra versjonar, eller feil ved innhenting, stoppar kommandoen.

Fjern nøkkelen frå terminalvariabelen etterpå, også dersom installasjonen
feila:

```sh
unset CRM_PACKAGE_KEY
```

Ved feil: stopp, les feilmeldinga og rett problemet før du registrerer orgen.

### 6. Registrer orgen i GitHub

**Stad: same terminal. Kommandoane under oppdaterer GitHub-miljøet.**

Køyr først denne kontrollen:

```sh
(
  set -euo pipefail
  : "${SCRATCH_ORG_ALIAS:?Set SCRATCH_ORG_ALIAS som vist i steg 3}"
  sf org display --target-org "$SCRATCH_ORG_ALIAS" --json |
    jq -er '.result | if .status == "Active" and (.id | type) == "string" and (.expirationDate | type) == "string" then "Org-ID: \(.id)\nUtløpsdato: \(.expirationDate)" else error("Aliaset peikar ikkje på ein aktiv scratch-org") end'
)
```

Samanlikn org-ID-en med ID-en du fekk då den dedikerte scratch-orgen vart
oppretta. Stopp dersom dei ikkje stemmer. Kommandoen kontaktar scratch-orgen og
Dev Hub-en som høyrer til han; operatøren må ha godkjend tilgang til begge.

**Kontroller òg konfigurasjonen før du held fram:** Fingeravtrykket nedanfor
blir rekna ut frå filene i repoet, ikkje frå den faktiske orgen. Orgen må vere
oppretta med den gjeldande `config/project-scratch-def.json` og API-versjonen i
`sfdx-project.json`. Har dei endra seg sidan orgen vart oppretta, eller er du
usikker, opprett ein ny org med steg 4–5. Ikkje oppdater fingeravtrykket for å
skjule at ein gammal org har feil konfigurasjon.

Blokka under opprettar eller oppdaterer desse fire verdiane i
**Settings → Environments → ci-scratch-org**:

| Namn                           | Type                 | Verdi                                                    |
| ------------------------------ | -------------------- | -------------------------------------------------------- |
| `CI_SCRATCH_ORG_AUTH_URL`      | Environment secret   | Autentiseringa til den dedikerte scratch-orgen           |
| `CI_SCRATCH_ORG_ID`            | Environment variable | Org-ID-en til same org                                   |
| `CI_SCRATCH_ORG_EXPIRATION`    | Environment variable | Utløpsdatoen i formatet `YYYY-MM-DD`                     |
| `CI_SCRATCH_ORG_CONFIG_SHA256` | Environment variable | Fingeravtrykket av scratch-definisjonen og API-versjonen |

Ikkje start workflowen medan du endrar registreringa. Kopier heile blokka og
køyr henne i terminalen frå repo-rota:

```sh
(
  set -euo pipefail
  : "${SCRATCH_ORG_ALIAS:?Set SCRATCH_ORG_ALIAS som vist i steg 3}"
  umask 077
  workdir="$(mktemp -d)"
  trap 'rm -f "$workdir/org.json" "$workdir/auth.json" "$workdir/auth-url"; rmdir "$workdir"' EXIT

  sf org display --target-org "$SCRATCH_ORG_ALIAS" --json > "$workdir/org.json"
  if ! jq -e '.result.status == "Active"' "$workdir/org.json" > /dev/null; then
    echo "Aliaset peikar ikkje på ein aktiv scratch-org." >&2
    exit 1
  fi
  org_id="$(jq -er '
    .result.id |
    if type == "string" and test("^[A-Za-z0-9]{15}([A-Za-z0-9]{3})?$")
    then . else error("Org-ID manglar eller har feil format") end
  ' "$workdir/org.json")"
  expiration="$(jq -er '
    .result.expirationDate |
    if type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")
    then . else error("Utløpsdato manglar eller har feil format") end
  ' "$workdir/org.json")"
  fingerprint="$(node scripts/ci-scratch-plan.cjs fingerprint sfdx-project.json config/project-scratch-def.json)"
  if ! printf '%s\n' "$fingerprint" | grep -Eq '^[0-9a-f]{64}$'; then
    echo "Fingeravtrykket manglar eller har feil format." >&2
    exit 1
  fi
  sf org auth show-sfdx-auth-url --target-org "$SCRATCH_ORG_ALIAS" --json > "$workdir/auth.json"
  jq -erj '
    .result.sfdxAuthUrl |
    if type == "string" and startswith("force://")
    then . else error("SFDX-auth-URL manglar eller har feil format") end
  ' "$workdir/auth.json" > "$workdir/auth-url"

  gh secret set CI_SCRATCH_ORG_AUTH_URL --env ci-scratch-org \
    --repo github.com/navikt/crm-arbeidsforhold < "$workdir/auth-url"
  gh variable set CI_SCRATCH_ORG_ID --env ci-scratch-org \
    --repo github.com/navikt/crm-arbeidsforhold --body "$org_id"
  gh variable set CI_SCRATCH_ORG_EXPIRATION --env ci-scratch-org \
    --repo github.com/navikt/crm-arbeidsforhold --body "$expiration"
  gh variable set CI_SCRATCH_ORG_CONFIG_SHA256 --env ci-scratch-org \
    --repo github.com/navikt/crm-arbeidsforhold --body "$fingerprint"
  echo "Secretet og dei tre variablane er oppdaterte."
)
```

Blokka kontrollerer verdiane før ho oppdaterer GitHub. Autentiseringa blir ikkje
skriven til skjermen: ho blir lagra i mellombelse filer som berre din brukar
har tilgang til, og filene blir sletta når blokka er ferdig. Dei fire
GitHub-oppdateringane skjer etter kvarandre, ikkje som éin transaksjon. Feilar
ei av dei, rett feilen og køyr heile blokka på nytt før du startar workflowen.

`sf org auth show-sfdx-auth-url` krev at orgen har autentisering med
refresh-token frå ein støtta, nettlesarbasert OAuth-innlogging. JWT-innlogging
gir ikkje ein slik URL. Dersom kommandoen feilar, må ein autorisert operatør
skaffe støtta autentisering før registreringa kan fullførast.

Kontroller at namnet på secretet og alle tre variablane finst:

```sh
gh secret list --env ci-scratch-org --repo github.com/navikt/crm-arbeidsforhold
gh variable list --env ci-scratch-org --repo github.com/navikt/crm-arbeidsforhold
```

Secret-lista viser berre namn og tidspunkt, ikkje secret-verdien. Variabellista
viser verdiane; kontroller at ID og dato høyrer til scratch-orgen.

<details>
<summary>Alternativ: legg inn dei tre variablane i nettlesaren</summary>

Køyr først denne blokka i terminalen for å lagre berre secretet, utan å vise
autentiseringsverdien:

```sh
(
  set -euo pipefail
  : "${SCRATCH_ORG_ALIAS:?Set SCRATCH_ORG_ALIAS som vist i steg 3}"
  umask 077
  auth_file="$(mktemp)"
  trap 'rm -f "$auth_file"' EXIT
  if ! sf org display --target-org "$SCRATCH_ORG_ALIAS" --json |
    jq -e '.result.status == "Active"' > /dev/null; then
    echo "Aliaset peikar ikkje på ein aktiv scratch-org." >&2
    exit 1
  fi
  sf org auth show-sfdx-auth-url --target-org "$SCRATCH_ORG_ALIAS" --json |
    jq -erj '.result.sfdxAuthUrl | if type == "string" and startswith("force://") then . else error("SFDX-auth-URL manglar eller har feil format") end' > "$auth_file"
  gh secret set CI_SCRATCH_ORG_AUTH_URL --env ci-scratch-org \
    --repo github.com/navikt/crm-arbeidsforhold < "$auth_file"
)
```

For å leggje inn variablane manuelt, opne
**Settings → Environments → ci-scratch-org → Environment variables**. Vel
**Add variable**, skriv namnet og lim inn resultatet av kommandoen for kvar
variabel. Rediger den eksisterande oppføringa dersom namnet alt finst.

`CI_SCRATCH_ORG_ID`:

```sh
sf org display --target-org "$SCRATCH_ORG_ALIAS" --json |
  jq -er '.result.id | select(type == "string" and length > 0)'
```

`CI_SCRATCH_ORG_EXPIRATION`:

```sh
sf org display --target-org "$SCRATCH_ORG_ALIAS" --json |
  jq -er '.result.expirationDate | select(type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))'
```

`CI_SCRATCH_ORG_CONFIG_SHA256`:

```sh
node scripts/ci-scratch-plan.cjs fingerprint sfdx-project.json config/project-scratch-def.json
```

</details>

## Køyring og fallback

### 7. Test workflowen

**Stad: GitHub i nettlesaren.**

1. Opne **Actions → [CI] Test reusable scratch org** i repoet.
2. Vel **Run workflow**, vel `main`, slå på `force_fresh` og start køyringa.
   Godkjenn miljøet via **Review deployments** dersom du blir bedt om det.
3. Opne jobben **Validate on reusable org or fresh fallback**. Under steget
   **Select reusable org or fresh fallback** skal meldinga innehalde
   `fresh validation: Fresh-org validation was requested.`. Vent til heile
   køyringa er ferdig, og kontroller at ho er grøn.
4. Start same workflow på nytt frå `main`, denne gongen med `force_fresh`
   avslått. Godkjenn miljøet om nødvendig.
5. I rutingssteget skal meldinga innehalde
   `reuse validation: CI scratch org matches the package plan.`. Kontroller òg
   at steget **Validate reusable org with tests and coverage** er køyrt og
   grønt.

Er køyringa raud, opne steget som feila og les feilmeldinga. Er køyringa grøn,
men viser `fresh` i staden for `reuse`, les grunnen i rutingssteget: då vart
det brukt ein ny fallback-org, ikkje den registrerte orgen.

Manglande registrering, utilgjengeleg org, endra scratch-konfigurasjon,
utløpsdato innan to dagar, eller manglande, utdaterte eller uventa installerte
pakkeversjonar sender køyringa til fallback. Fallbacken opprettar ein
éin-dagsorg, installerer den eksakte pakkeplanen, deployer `force-app`, køyrer
repoet sine Apex-testar og handhevar 85 % samla dekning. Workflowen prøver å
slette fallback-orgen etterpå, også ved feil; kontroller slettesteget.

Ein ugyldig pakkeplan, feil org-ID eller feil i metadata, Apex-testar eller
dekning feilar køyringa direkte; dei skal ikkje skjulast ved automatisk
fallback. Gjenbruksorgen blir serialisert mellom køyringar.

## Avgrensing og kontroll

Workflowen er berre for manuell utprøving frå `main`. Han endrar ikkje PR-krav
eller automatisk validering, og han krev ikkje GitHub App. Lokale
workflowkontraktar og plan-/rutinglogikk blir testa med:

```sh
npm run test:node
npm run prettier:check
```

Desse lokale testane verifiserer ikkje GitHub Environment-godkjenningar,
secrets, Salesforce CLI-autentisering eller ein faktisk org-deploy.

## Praktisk registrering og vedlikehald

Bruk ein dedikert scratch-org frå same Dev Hub som workflowen brukar. Ikkje
deploy hovudpakkens kjeldekode permanent til gjenbruksorgen: dry-run skal
validere mot ein org med avhengigheitene installerte. Fingeravtrykket fangar
endringar i scratch-definisjonen og API-versjonen, ikkje manuelle endringar i
orgen. Operatøren må derfor halde orgen rein og dedikert til denne workflowen.
Bruk berre syntetiske testdata, og ikkje kopla orgen til produksjonsintegrasjonar.

Workflowen kontrollerer at Dev Hub har ei aktiv scratch-org-registrering med
same ID og utløpsdato før innlogging. Kan dette ikkje stadfestast, bruker han
fallback. Om autentiseringa peikar på ein annan org-ID, feilar køyringa.
CLI-en må likevel autentisere før han kan lese den faktiske org-ID-en. Secretet
må derfor kontrollerast av ein menneskeleg operatør og berre innehalde
autentiseringa til den dedikerte scratch-orgen.

Workflowen fornyar ikkje orgen og oppdaterer ikkje pakkane automatisk. Ved
pakkeendringar kan operatøren lage ein ny plan og prøve installasjonen i steg 5
på den eksisterande orgen. Skriptet prøver å installere alle pakkane i planen,
ikkje berre dei som er endra. Dersom Salesforce ikkje tillèt installasjonen,
eller orgen inneheld ekstra pakkar, stopp og opprett ein ny dedikert org med
steg 4–5.

Ved utløp, eller når scratch-definisjonen eller API-versjonen er endra, opprett
ein ny org og køyr steg 6 for å oppdatere alle fire GitHub-verdiane. Vel eit
nytt lokalt alias dersom det gamle framleis er i bruk. Test først fallback og
deretter gjenbruk som vist i steg 7.

Gjenbruksruta brukar `RunLocalTests` i deploy-valideringa, medan fallback køyrer
repoet sine oppdaga testklassar etter deploy. At Salesforce køyrer nøyaktig
same testsett i dei to rutene, er ikkje verifisert utan ei faktisk org-køyring.
