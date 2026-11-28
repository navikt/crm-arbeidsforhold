# Arkiv: pilot for gjenbrukbar scratch-org

> **Historisk dokumentasjon:** Piloten er avslutta. Ikkje bruk stega under
> til dagens CI-drift; sjå [gjeldande driftsguide](../../operations/reusable-scratch-org-validation.md).
> Teksten er henta frå steg 8–10 i guiden ved commit `3efda1e4`.

### 8. Følg ein PR gjennom piloten

**Stad: GitHub i nettlesaren.**

Piloten startar automatisk når `[PR] Validate` startar for ein open PR som:

- kjem frå ein branch i dette repoet, ikkje frå ein fork
- har `main` som mål og ikkje er eit utkast
- inneheld endringar som krev Salesforce-validering

Du treng ikkje starte piloten manuelt. Dersom PR-en ikkje oppfyller krava,
hoppar piloten over Salesforce-jobben. Den vanlege PR-valideringa køyrer
framleis som før.

Piloten vel berre Apex-testklassar frå repoet. Gjenbruksruta bruker
`RunSpecifiedTests` i deploy-valideringa; fallback deployer først og køyrer
deretter dei same oppdaga klassane. Finst det ingen repo-testklassar, feilar
begge rutene i piloten i staden for å rapportere ein grøn test.

1. Opne repoet på GitHub. Vel **Actions → [CI] Reusable scratch org PR pilot**.
   Opne køyringa som starta etter at PR-en vart oppretta eller oppdatert.
2. Vent til jobben **Select and inspect PR** er ferdig. På **Summary**-sida
   finn du lenke til PR-en, merge-commit-en som skal validerast, og lenke til
   den tilhøyrande **Original PR validation**.
3. Kontroller PR-en, endringane og commit-en før du gir tilgang til miljøet.
   Vel **Review deployments**, merk `ci-scratch-org` og vel
   **Approve and deploy**. Du må vere ein av dei som kan godkjenne miljøet.
   Er du usikker på kva som blir køyrt, ikkje godkjenn.
4. Opne jobben **Run parallel Salesforce pilot / Validate PR …** og steget
   **Select reusable org or fresh fallback**. Meldinga seier om køyringa
   brukar `reuse` eller `fresh`, og kvifor.
5. Vent til både piloten og **Original PR validation** er ferdige. Ein grøn
   pilot med `fresh` betyr at fallback vart brukt, ikkje at gjenbruk vart testa.
   Den vanlege PR-valideringa er framleis den påkravde kontrollen.

Køyringane deler same kø for gjenbruksorgen; ei køyring kan derfor måtte
vente på ei anna køyring eller på miljøgodkjenning. Feilar piloten, opne det
raude steget for feilen. Ikkje tolk ein feil i piloten som at den vanlege
PR-valideringa er erstatta. Ved omkøyring av `[PR] Validate`, kontroller at ei
ny pilotkøyring faktisk blir starta og at lenka på **Summary** peikar på rett
forsøk.

GitHub kan opprette fleire pilotar for same forsøk av den vanlege
valideringa. Ein aktiv pilot får fullføre; av duplikata som ventar på same
forsøk, blir berre det nyaste ståande i køen. Når den aktive piloten har
køyrt Salesforce-valideringa, hoppar duplikatet over ho, også om den første
valideringa feila.

Ein eldre PR-versjon kan framleis vente i den felles orgkøen når PR-en eller
`main` har endra seg. Når piloten får tur, sjekkar han versjonen på nytt og
hoppar over utdaterte versjonar utan miljøgodkjenning eller tilgang til
Salesforce. Endrar PR-en seg medan miljøgodkjenninga ventar, feilar piloten
etter godkjenninga, før orgtilgang. Ei ny omkøyring av den vanlege
valideringa er eit eige forsøk.

### 9. Samanlikn dei faktiske testane

**Stad: først GitHub i nettlesaren, deretter terminalen på di eiga maskin.**

1. Opne pilotkøyringa frå steg 8. Kopier talet etter `/actions/runs/` i
   nettadressa. Dette er **pilot-run-ID-en**.
2. På **Summary**, opne lenka **Original PR validation**. Kopier talet etter
   `/actions/runs/` i nettadressa der. Dette er **baseline-run-ID-en**.
   Kopier ikkje talet etter `/attempts/`; riktig forsøk er lagra av piloten.
3. Vent til begge køyringane er grøne. Samanlikninga krev både det ordinære
   `apex-tests`-artefaktet og pilotartefaktet. Pilotartefaktet blir lagra i
   sju dagar; samanlikn før eitt av artefakta er utløpt.
4. Opne repoet i VS Code og vel **Terminal → New Terminal**. Du treng ein
   lokal kopi som inneheld `scripts/ci-pr-evidence.cjs`, Node.js 22, GitHub CLI
   og `unzip`. Sjekk frå repo-rota:

    ```sh
    ls scripts/ci-pr-evidence.cjs
    node --version
    gh auth status
    unzip -v
    ```

    Manglar skriptet, oppdater den lokale kopien til `main` etter at
    pilot-workflowen er fletta. Ikkje forkast lokale endringar. Er du ikkje
    logga inn med ein konto som kan lese Actions-køyringane, køyr
    `gh auth login` og følg dialogen.

5. Kopier og køyr heile blokka under. Lim inn **baseline-run-ID-en** først og
   **pilot-run-ID-en** etterpå, og trykk Enter etter kvar verdi:

    ```sh
    printf 'Baseline-run-ID frå Original PR validation: '
    read -r BASELINE_RUN_ID
    printf 'Pilot-run-ID frå Reusable scratch org PR pilot: '
    read -r PILOT_RUN_ID
    node scripts/ci-pr-evidence.cjs compare "$BASELINE_RUN_ID" "$PILOT_RUN_ID"
    ```

Resultatet blir skrive som JSON:

- `comparable: true` betyr at checkout-commitane og dei valde pakkeversjonane
  samsvarar. Er verdien `false`, viser `reasons` kvifor resultata ikkje er
  samanliknbare.
- `sameMethods: true` betyr at dei registrerte Apex-testmetodane samsvarar.
  `baselineOnly` og `pilotOnly` viser metodar som berre finst i éi køyring.
- `recordedMethods` er talet på registrerte metodar; `reportedTestsRun` er
  Salesforce sitt oppsummerte tal. Dei kan vere ulike. `skipped: null` betyr
  at resultatet ikkje oppgir talet på hoppa-over testar, ikkje at det er null.
- `sameCoverageComponents` viser om begge resultata har dekningsrader for
  dei same Apex-klassane og triggerane. Er verdien `false`, viser
  `baselineCoverageOnly` og `pilotCoverageOnly` forskjellane; då kan
  dekningstala ikkje samanliknast direkte.
- `baselineCoverage` og `pilotCoverage` viser dekte linjer, totalt tal og
  prosent for komponentane Salesforce rapporterte.

Skriptet les Actions-loggar og artefakt via GitHub CLI. Den ordinære
testfila kan innehalde identitetsfelt; skriptet kopierer dei ikkje til
rapporten og slettar dei mellombelse filene sine etterpå. Ikkje del heile
testfila eller rå loggar i chat. Dersom eit seinare forsøk har erstatta
`apex-tests`-artefaktet, avviser skriptet samanlikninga i staden for å blande
resultat frå ulike forsøk.

### 10. Samanlikn begge rutene med eigne test-PR-ar

**Stad: GitHub i nettlesaren, deretter terminalen frå steg 9.**

Dette krev at pilotendringa er fletta til `main`, og at gjenbruksorgen er
registrert og tilgjengeleg. Lag to PR-ar som berre er til testing. Dei skal
ikkje flettast til `main`.

1. Lag ein PR for gjenbruk:
    - Opne fila `.forceignore` frå `main` på GitHub og vel blyanten for å
      redigere. Legg inn ei tom linje mellom `# profiles` og skiljelinja under.
      Ikkje endre nokon av reglane i fila.
    - Vel **Commit changes**, opprett ei ny grein og start ein PR mot `main`.
      PR-en må ikkje vere ein draft.
    - Følg steg 8. Kontroller at rutingssteget viser
      `reuse validation: CI scratch org matches the package plan.`. Viser det
      `fresh`, har denne PR-en ikkje testa gjenbruk.
2. Lag ein separat PR for fallback:
    - Gå tilbake til `main` på GitHub. Opne
      `config/project-scratch-def.json` og vel blyanten for å redigere.
      Byt om rekkefølgja på linjene med `country` og `language`, utan å endre
      verdiane eller komma. JSON-innhaldet er då det same, men fila får eit
      anna fingeravtrykk.
    - Vel **Commit changes**, opprett ei ny grein og start ein PR mot `main`.
      PR-en må ikkje vere ein draft.
    - Følg steg 8. Kontroller at rutingssteget viser
      `fresh validation: Scratch configuration changed.`.
3. Vent til begge køyringane for kvar PR er ferdige. Køyr samanlikninga i
   steg 9 for kvar av dei to PR-ane, med run-ID-ane som høyrer saman.
   Kontroller at `comparable`, `sameMethods` og `sameCoverageComponents` alle
   er `true`, og samanlikn dekningstala. Undersøk eventuelle forskjellar før
   vidare utrulling.
4. Ta vare på samanlikningsresultata utan rå loggar eller testfiler. Lukk
   test-PR-ane etter at alle køyringane er ferdige; ikkje flett dei.
