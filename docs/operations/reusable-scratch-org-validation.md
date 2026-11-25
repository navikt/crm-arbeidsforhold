# Manuell validering med gjenbrukbar scratch-org

Workflowen `[CI] Test reusable scratch org` er ein opt-in prøve for å redusere
ventetida ved Salesforce-validering. Han køyrer berre når han blir starta
manuelt frå `main`; den påkravde PR-valideringa er uendra.

Workflowen finn gjeldande pakkeversjonar frå `sfdx-project.json`, inkludert
beta-/unreleased-versjonar slik dagens CI gjer. Ein registrert scratch-org blir
berre brukt når org-ID, scratch-konfigurasjon, utløpsdato og den eksakte mengda
installerte pakkeversjonar stemmer med planen. Deployen til gjenbruksorgen er ein
dry-run.

## Oppsett

1. Opprett GitHub Environment `ci-scratch-org` og krev godkjenning frå ein
   ansvarleg reviewer før jobben får tilgang til miljøet sine secrets.
2. Registrer ein dedikert scratch-org som manuelt blir halden ved like. Ein
   autorisert operatør opprettar han frå repo-rota, mot same Dev Hub som
   workflowen brukar. Vel eit eige alias og bruk 30 dagar, som er maksimal
   levetid for ein scratch-org:

    ```sh
    sf org create scratch \
      --definition-file config/project-scratch-def.json \
      --duration-days 30 \
      --alias ci-reusable-scratch-org \
      --target-dev-hub YOUR_DEVHUB_ALIAS
    ```

    Erstatt `YOUR_DEVHUB_ALIAS` med aliasen til den autoriserte Dev Hub-en.
    Bruk eit anna scratch-org-alias dersom `ci-reusable-scratch-org` allereie
    er i bruk.

    Ikkje bruk `bin/create-scratch-org.sh` for denne orgen. Det skriptet
    slettar eventuell org med same alias, installerer avhengigheitene og køyrer
    etterstega for ein vanleg utviklarorg, inkludert deploy av kjeldekode.
    Gjenbruksorgen skal berre ha avhengigheitspakkane; workflowen validerer
    `force-app` som ein dry-run.

    Planen for avhengigheitspakkane kan genererast med:

    ```sh
    node bin/package-dependencies.js --include-unreleased --plan-file /tmp/ci-package-plan.json
    ```

    Installer deretter den kontrollerte planen på den dedikerte orgen. Set
    `CRM_PACKAGE_KEY` frå godkjend secret-lagring i miljøet før kommandoen; ikkje
    skriv nøkkelen i kommandoen eller loggen:

    ```sh
    node scripts/ci-scratch-plan.cjs install sfdx-project.json /tmp/ci-package-plan.json <scratch-org-alias>
    ```

3. Ein menneskeleg operatør registrerer verdiane i GitHub under
   **Settings → Environments → ci-scratch-org**. Legg `CI_SCRATCH_ORG_AUTH_URL`
   under **Environment secrets**, og dei tre andre verdiane under
   **Environment variables**. For kommandoane nedanfor må operatøren ha
   tilgang til orgen med Salesforce CLI, ha `jq` og GitHub CLI installert, og
   vere innlogga i GitHub CLI med tilgang til å oppdatere miljøet.

    Set først aliaset frå steg 2 i terminalen, frå repo-rota. Bruk det faktiske
    aliaset dersom du valde eit anna:

    ```sh
    SCRATCH_ORG_ALIAS=ci-reusable-scratch-org
    ```

    - **Secret `CI_SCRATCH_ORG_AUTH_URL`:** Salesforce CLI hentar
      `sfdxAuthUrl` frå den oppretta scratch-orgen. Kommandoane under lagrar
      han direkte som environment-secret utan å vise URL-en i terminalen:

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

        Kontroller at aliaset peikar på den dedikerte scratch-orgen før du
        lagrar secretet. `sfdxAuthUrl` krev ein støtta innloggingsmetode og
        blir ikkje vist ved JWT-innlogging. Dersom verdien ikkje er tilgjengeleg,
        må operatøren skaffe ei støtta autentisering før registreringa kan
        fullførast. Ikkje legg URL-en i loggar, kode eller kommentarar.

    - **Variable `CI_SCRATCH_ORG_ID`:** Hent org-ID-en frå Salesforce CLI og
      kopier resultatet til environment-variabelen:

        ```sh
        sf org display --target-org "$SCRATCH_ORG_ALIAS" --json | jq -er '.result.id | select(type == "string" and length > 0)'
        ```

    - **Variable `CI_SCRATCH_ORG_EXPIRATION`:** Hent utløpsdatoen frå den
      lokale lista over scratch-orgar og kopier resultatet, i formatet
      `YYYY-MM-DD`, til environment-variabelen:

        ```sh
        sf org list --skip-connection-status --json |
          jq -er --arg alias "$SCRATCH_ORG_ALIAS" '.result.scratchOrgs[] | select(.alias == $alias) | .expirationDate | select(type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))'
        ```

        Dersom kommandoen ikkje gir ein dato, kontroller aliaset og at orgen
        finst i Salesforce CLI-lista før du held fram.

    - **Variable `CI_SCRATCH_ORG_CONFIG_SHA256`:** Generer fingeravtrykket av
      scratch-definisjonen og Salesforce API-versjonen frå repo-rota, og kopier
      resultatet til environment-variabelen:

        ```sh
        node scripts/ci-scratch-plan.cjs fingerprint sfdx-project.json config/project-scratch-def.json
        ```

4. Sikre at det eksisterande `CRM_PROD_SFDX_URL`-oppsettet for Dev Hub og
   `CRM_PACKAGE_KEY`-oppsettet for pakkeinstallasjon er tilgjengeleg for
   workflowen, slik det er for dagens CI.

## Køyring og fallback

Start workflowen manuelt frå `main`. Vel `force_fresh` for å hoppe over
gjenbruksorgen og teste den vanlege fallbacken.

Etter pakkeinstallasjon hentar installasjonskommandoen dei installerte
versjonane frå orgen og samanliknar dei med planen. Manglande, feil eller ekstra
versjonar, eller feil ved innhenting, stoppar kommandoen med ein feilmelding.
Dette gjeld både manuell installasjon og fallback før deploy og testar.

Manglande registrering, utilgjengeleg org, endra scratch-konfigurasjon,
utløpsdato innan to dagar, eller manglande, utdaterte eller uventa installerte
pakkeversjonar sender køyringa til ein ny scratch-org. Fallbacken bruker den same eksakte
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
