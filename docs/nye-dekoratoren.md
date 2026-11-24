# NAV-dekoratøren – Aa-registeret

Denne veiledningen beskriver hvordan NAVs nye header og footer (**Dekoratøren**) tas i bruk på Experience Cloud-siden for Aa-registeret.

- **Ansvarlig team:** Team Arbeidsforhold
- **Sist oppdatert:** 11/2026

---

## Før du starter (Forutsetninger)

Sørg for at du har følgende på plass før du begynner:
- [ ] Tilgang til **Experience Builder** og **Setup** i aktuelt Salesforce-miljø.
- [ ] Tilgang til repositoryet for Aa-registeret (`crm-arbeidsforhold`) samt `crm-community-base`.
- [ ] Oversikt over gammel styling i eget styling-repository: `[sett inn lenke til styling-repo]`.

---

## 1. Kontroller komponenter og styling

Før du gjør endringer i koden, må du kontrollere det eksisterende oppsettet:

- Kontroller at pakken `crm-community-base` er installert, og at komponentene **Decorator Header** og **Decorator Footer** er tilgjengelige i Experience Builder.
- Påse at gammel dekoratørstyling fra `[navn på styling-repo]` ikke brukes sammen med den nye Dekoratøren.
- Kontroller eksisterende oppsett i koden før du gjør endringer.

---

## 2. Kontroller CORS og CSP

### CORS
Dekoratøren har en streng CORS-policy og tillater som standard kun nettsider under `*.nav.no`.

Ved lokal utvikling eller testing i Scratch Org/Sandbox kan du midlertidig omgå dette på én av følgende måter:
- Starte Chrome med flagget `--disable-web-security`
- Bruke en CORS-utvidelse i nettleseren

> [!WARNING]
> Bruk helst en separat testnettleser for dette. Deaktivering av CORS må **aldri** brukes som en permanent løsning. Dersom et testdomene legges inn i selve CORS-policyen, må URL-en for både **Experience-siden** og **Experience Builder** registreres.

### CSP (Content Security Policy)
CSP-innstillinger for scripts må godkjennes for hvert enkelt Experience Cloud-nettsted som bruker Dekoratøren (andre ressurser som styles og bilder kan være definert globalt for org-en).

1. Gå til **Experience Builder → Settings → Security & Privacy**.
2. Kontroller at **Relaxed CSP** er valgt, slik at Dekoratøren kan laste eksterne scripts.
3. Kontroller at **Lightning Locker** er deaktivert.
4. Godkjenn nødvendige **CSP Trusted Sites** for scripts på nettstedet (flere av disse blir blokkert automatisk og må godkjennes manuelt). Aktuelle domener inkluderer blant annet:
   - `https://www.nav.no`
   - `https://dekoratoren.ekstern.dev.nav.no` *(for testmiljøer)*
   - `[eventuelle andre domener fra Confluence-listen]`

<img width="787" height="353" alt="CORS-policy" src="https://github.com/user-attachments/assets/579e3811-7cfe-4e07-a37c-9718f6683450" />
<img width="781" height="882" alt="CSP Trusted Sites" src="https://github.com/user-attachments/assets/837a0530-1f78-42fd-968b-d34354f2de4b" />

---

## 3. Kontroller ID-porten-oppsettet

*Dersom ID-porten allerede er satt opp for nettstedet, kan du gå rett til [punkt 4](#4-bytt-header-og-footer-i-experience-builder).*

### 3.1 Finn nettstedets Network ID
Kjør følgende SOQL-spørring mot Salesforce for å finne riktig ID:

```sql
SELECT Id, Name FROM Network
```

### 3.2 Legg inn Network ID i `crm-community-base`
Åpne [IdPortenSidController.cls på GitHub](https://github.com/navikt/crm-community-base/blob/7cf3dbb57253abe7cd0fc55aef2100baedd19da4/force-app/IdPorten/classes/IdPortenSidController.cls#L88-L97) og kontroller at nettstedets `NetworkId` ligger i listen `communitiesUsingNewDecorator` (rundt linje 88–97).

Hvis ID-en mangler:
1. Legg til `NetworkId` i `IdPortenSidController.cls`.
2. Deploy `crm-community-base` til de aktuelle miljøene gjennom godkjent prosess.

Dette sikrer at ID-porten-oppsettet fungerer med den nye Dekoratøren for det aktuelle community-nettstedet.

### 3.3 Kontroller Visualforce-sider
Gå til **Site Visualforce Pages** for nettstedet og kontroller at følgende to sider er lagt til (legg dem til hvis de mangler, da de kreves for innloggingsflyten gjennom ID-porten):
- `NavLoginService`
- `IdPortenSid`

<img width="824" height="464" alt="Visualforce-sider" src="https://github.com/user-attachments/assets/7b914905-4645-4405-8562-626f49cbc072" />
<img width="762" height="561" alt="Visualforce Pages" src="https://github.com/user-attachments/assets/1f3fb874-bbd2-422c-b09f-757e720bf99c" />

---

## 4. Bytt header og footer i Experience Builder

Endringene gjøres direkte i Experience Cloud-temaet:

1. Åpne **Experience Builder** for Aa-registeret.
2. Dra **Decorator Header** inn i headerområdet i temaet.
3. Dra **Decorator Footer** inn i footerområdet i temaet.
4. Fjern **Global Community Header** og **Global Community Footer** hvis de fortsatt ligger i temaet eller layoutet.
5. Kontroller at temaet kun bruker **én** header og **én** footer.

### Sider som må kontrolleres etter oppdatering
Gå gjennom følgende sider og påse at gammel og ny header/footer ikke vises samtidig:
- [ ] `home`
- [ ] `mineAvtaler`
- [ ] `agreementDetailFlex`
- [ ] `applicationDetailFlex`
- [ ] `mineMeldinger`
- [ ] `mineSøknader`
- [ ] `nyMelding`
- [ ] `nySøknadAaRegistret`
- [ ] `threadDetailFlex`

> [!IMPORTANT]
> **Git og `.forceignore`:** Før du kjører *retrieve* av Experience Cloud-endringene, må `**/experiences` og `**/README.md` midlertidig fjernes fra `.forceignore`. Husk å legge dem tilbake i `.forceignore` så snart retrieve er fullført og endringene er kontrollert.

---

## 5. Konfigurer miljø og deployment

I **Decorator Header** i Experience Builder setter du:
- **Environment:** `Dev` (for testmiljøer) eller `Prod` (for produksjon).
- **Context:** Velg `[f.eks. arbeidsgiver / privatperson]` for Aa-registeret.

Riktig miljøinnstilling er kritisk – dersom produksjon laster `Dev`-konfigurasjon (eller omvendt), vil det føre til feil med innlogging, CORS, CSP og navigasjon. Under produksjonsdeploy vil variabelen `HEADER_ENV_REPLACER` automatisk bytte ut `"Dev"` med produksjonsverdien når `DEPLOY_DESTINATION=PROD`.

### 5.1 Plassering av Experience Cloud-metadata
Repositoryet har en workflow ([Helper Deployment](https://github.com/navikt/crm-arbeidsforhold/blob/decorator/.github/workflows/documentation/helper_deployment.md)) som automatisk deployer metadata fra:

```text
force-app/unpackagable-with-auto-deploy
```

Hele **ExperienceBundle** (inkludert views, themes og configurations) må flyttes hit samlet, slik at Salesforce-strukturen forblir intakt. Eller i andre ord; det er ikke bare view-filene som skal flyttes men hele ExperienceBundle flyttes til force-app/unpackagable-with-auto-deploy/, inkludert tilhørende views, themes og configurations.
Se eventuelt Salesforces artikkel om [Troubleshoot Experience Cloud metadata deployment](https://help.salesforce.com/s/articleView?id=005317315&type=1) ved behov.

### 5.2 Oppsett i `sfdx-project.json`
Ved deployment fra Git må alle relevante `views/*.json`-filer legges inn under `replacements` i `sfdx-project.json` for å sikre miljøbytte ved produksjonsdeploy:

```json
"replacements": [
  {
    "filename": "force-app/unpackagable-with-auto-deploy/experiences/Aa_registret1/views/home.json",
    "stringToReplace": "\"Dev\"",
    "replaceWithEnv": "HEADER_ENV_REPLACER",
    "replaceWhenEnv": [
      {
        "env": "DEPLOY_DESTINATION",
        "value": "PROD"
      }
    ]
  }
]
```
*(Gjenta blokken over for hver aktulle filer, `views/*.json`-filer, som skal bruke produksjonsmiljøet).*

---

## 6. Publiser

Klikk **Publish** i Experience Builder for å aktivere endringene.

---

## 7. Test med TestID i SIT2

1. Åpne Aa-registerets SIT2-URL.
2. Logg inn via ID-porten med **TestID**.

**Verifiser at:**
- [ ] Ny header og footer vises på alle aktuelle sider.
- [ ] Navigasjonen fungerer som forventet etter innlogging.
- [ ] Dekoratøren ikke blokkeres av CORS eller CSP i nettleserkonsollen.
- [ ] Gammel og ny dekoratør ikke vises samtidig.

---

## 8. Tillegg: Main Content (UU-krav)

Dette er ikke påkrevd for at selve Dekoratøren skal fungere, men er et viktig tiltak for universell utforming (UU).

Komponenten **Main content** er usynlig og oppretter en snarvei («Hopp til hovedinnhold») øverst i Dekoratøren slik at skjermlesere og tastaturbrukere kan hoppe rett til hovedinnholdet.

1. Åpne aktuell side i **Experience Builder** og se under **Page Structure**.
2. Hvis komponenten mangler, dra **Main content** fra *Components*-panelet til starten av hovedinnholdet.
3. Klikk **Publish**.
4. **Test:** Bruk `Tab`-tasten på tastaturet for å verifisere at lenken «Hopp til hovedinnhold» dukker opp og fungerer.

---

## 9. Feilsøking og vanlige feil

- **Dekoratøren dukker ikke opp på siden:** Åpne utviklerverktøy i nettleseren (F12) og sjekk konsollen for CSP- eller CORS-feil. Kontroller også at **Lightning Locker** er deaktivert under *Security & Privacy*.
- **Innlogging feiler eller havner i en loop:** Kontroller at nettstedets `NetworkId` er lagt inn i `IdPortenSidController.cls` og deployet, samt at `NavLoginService` og `IdPortenSid` ligger under *Site Visualforce Pages*.
- **Test-banner / Dev-miljø vises i produksjon:** Sjekk at alle aktuelle `views/*.json`-filer er lagt til i `replacements`-listen i `sfdx-project.json`.
- **Endringer fra Experience Builder blir ikke med i Git:** Kontroller at du midlertidig har fjernet `**/experiences` fra `.forceignore` før du kjører `sf project retrieve start`.

---

## 10. Kilder
- [Experience Cloud – Confluence](https://confluence.adeo.no/spaces/PTC/pages/500537629/Experience+Cloud)

- [CORS-konfigurasjonen for Dekoratøren](https://github.com/navikt/nav-dekoratoren)

- [IdPortenSidController.cls på GitHub](https://github.com/navikt/crm-community-base/blob/7cf3dbb57253abe7cd0fc55aef2100baedd19da4/force-app/IdPorten/classes/IdPortenSidController.cls#L88-L97)
