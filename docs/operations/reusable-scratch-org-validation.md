# Manuell validering med gjenbrukbar scratch-org

Workflowen `[CI] Test reusable scratch org` er ein opt-in prøve for å redusere
ventetida ved Salesforce-validering. Han køyrer berre når han blir starta
manuelt frå `main`; den påkravde PR-valideringa er uendra.

Workflowen finn gjeldande pakkeversjonar frå `sfdx-project.json`, inkludert
beta-/unreleased-versjonar slik dagens CI gjer. Ein registrert scratch-org blir
berre brukt når org-ID, scratch-konfigurasjon, utløpsdato og installerte
pakkeversjonar stemmer. Deployen til gjenbruksorgen er ein dry-run.

## Oppsett

1. Opprett GitHub Environment `ci-scratch-org` og krev godkjenning frå ein
   ansvarleg reviewer før jobben får tilgang til miljøet sine secrets.
2. Registrer ein dedikert scratch-org som manuelt blir halden ved like. Opprett
   han frå `config/project-scratch-def.json` med ein autorisert Dev Hub. Planen
   kan genererast med:

    ```sh
    node bin/package-dependencies.js --include-unreleased --plan-file /tmp/ci-package-plan.json
    ```

    Installer deretter den kontrollerte planen på den dedikerte orgen. Set
    `CRM_PACKAGE_KEY` frå godkjend secret-lagring i miljøet før kommandoen; ikkje
    skriv nøkkelen i kommandoen eller loggen:

    ```sh
    node scripts/ci-scratch-plan.cjs install sfdx-project.json /tmp/ci-package-plan.json <scratch-org-alias>
    ```

3. Legg desse verdiane inn i `ci-scratch-org`:
    - Secret `CI_SCRATCH_ORG_AUTH_URL`: autentisering for den registrerte
      scratch-orgen.
    - Variable `CI_SCRATCH_ORG_ID`: org-ID frå den registrerte orgen.
    - Variable `CI_SCRATCH_ORG_EXPIRATION`: utløpsdato i `YYYY-MM-DD`-format.
    - Variable `CI_SCRATCH_ORG_CONFIG_SHA256`: fingeravtrykk av scratch-definisjon
      og Salesforce API-versjon. Generer det frå repo-rota:

        ```sh
        node scripts/ci-scratch-plan.cjs fingerprint sfdx-project.json config/project-scratch-def.json
        ```

4. Sikre at det eksisterande `CRM_PROD_SFDX_URL`-oppsettet for Dev Hub og
   `CRM_PACKAGE_KEY`-oppsettet for pakkeinstallasjon er tilgjengeleg for
   workflowen, slik det er for dagens CI.

## Køyring og fallback

Start workflowen manuelt frå `main`. Vel `force_fresh` for å hoppe over
gjenbruksorgen og teste den vanlege fallbacken.

Manglande registrering, utilgjengeleg org, endra scratch-konfigurasjon,
utløpsdato innan to dagar eller manglande/utdaterte pakkeversjonar sender
køyringa til ein ny scratch-org. Fallbacken bruker den same eksakte
pakkeplanen, deployer `force-app`, køyrer repoet sine Apex-testar og handhevar
85 % samla dekning. Den nye orgen blir sletta også når valideringa feilar.

Ein ugyldig pakkeplan, feil org-ID eller feil i metadata, Apex-testar eller
dekning feilar køyringa direkte; dei skal ikkje skjulast ved automatisk
fallback. Gjenbruksorgen blir serialisert mellom køyringar. Workflowen fornyar
ikkje eller oppdaterer den registrerte orgen; pakkar og registreringsverdiar må
haldast ved like manuelt. Dersom ei pakkeoppdatering ikkje er installert enno,
bruker køyringa fallback-org fram til den delte orgen er oppdatert.

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

For ein menneskeleg operatør, med `SCRATCH_ORG_ALIAS` sett til aliaset for den
dedikerte orgen, kan org-ID og utløpsdato hentast utan å skrive
autentiseringsdata til terminalen:

```sh
sf org display --target-org "$SCRATCH_ORG_ALIAS" --json | jq -er '.result.id'
sf org list --skip-connection-status --json |
  jq -r --arg alias "$SCRATCH_ORG_ALIAS" '.result.scratchOrgs[] | select(.alias == $alias) | .expirationDate'
```

Set GitHub Environment-variablane frå desse verdiane og fingeravtrykket ovanfor.
For å registrere autentiseringa utan å skrive ho ut eller leggje henne i
shell-historikken kan ein operatør bruke GitHub CLI frå repo-rota:

```sh
(
set -euo pipefail
umask 077
auth_json="$(mktemp)"
auth_url="$(mktemp)"
trap 'rm -f "$auth_json" "$auth_url"' EXIT
sf org display --target-org "$SCRATCH_ORG_ALIAS" --verbose --json > "$auth_json"
jq -er 'if (.result.sfdxAuthUrl | type) == "string" and (.result.sfdxAuthUrl | length) > 0 then .result.sfdxAuthUrl else error("SFDX auth URL is unavailable") end' "$auth_json" > "$auth_url"
gh secret set CI_SCRATCH_ORG_AUTH_URL --env ci-scratch-org < "$auth_url"
rm -f "$auth_json" "$auth_url"
trap - EXIT
)
```

Salesforce opplyser at `sfdxAuthUrl` krev ein støtta innloggingsmetode og ikkje
blir vist ved JWT-innlogging. Ikkje legg URL-en i loggar, kode eller kommentarar.
Ein produksjonstilknytt Dev Hub skal berre handterast av menneske, ikkje av
agentar, i tråd med org-reglane i repoet.

Ved pakkeendringar: generer ein ny plan, samanlikn han med `sf package installed
list --target-org "$SCRATCH_ORG_ALIAS"`, og installer eller oppgrader dei
manglande versjonane i planrekkjefølgje. Om ei nødvendig versjon ikkje kan
installerast på den eksisterande orgen, opprett ein ny dedikert scratch-org og
registrer nye verdiar. Ved utløp må orgen òg erstattast; workflowen fornyar han
ikkje. Prøv først med `force_fresh`, deretter med registrert org, og kontroller
rutinga i workflowloggen.

Gjenbruksruta brukar `RunLocalTests` i deploy-valideringa, medan fallback køyrer
repoet sine oppdaga testklassar etter deploy. At Salesforce køyrer nøyaktig
same testsett i dei to rutene, er ikkje verifisert utan ei faktisk org-køyring.
