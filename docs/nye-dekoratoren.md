# NAV-dekoratøren – Aa-registeret

Denne veiledningen beskriver hvordan NAVs nye header og footer
(Dekoratøren) tas i bruk på Experience Cloud-siden Aa-registret.

## 1. Kontroller komponenter og styling

- Kontroller at `crm-community-base` er installert, og at Decorator Header og Decorator Footer er tilgjengelige i Experience Builder.
- Gammel dekoratørstyling skal ikke brukes sammen med den nye Dekoratøren.
- Bruk Designsystemet V2 eller `navStyling` ved behov.
- I Aa-registeret kommer stylingløsningen fra et annet repository.
- Kontroller eksisterende oppsett før du endrer kode.

## 2. Kontroller CORS og CSP

### CORS

- Dekoratøren tillater normalt domener under `nav.no`.
- Ved testing i Scratch Org eller Sandbox kan en CORS-utvidelse brukes midlertidig i en egen testnettleser.
- For varig tilgang må både Experience- og Builder-domenet tillates.
- Se den gjeldende CORS-konfigurasjonen.

### CSP

1. Gå til Experience Builder → Settings → Security & Privacy.
2. Kontroller at Relaxed CSP brukes.
3. Kontroller at Lightning Locker er deaktivert, i tråd med gjeldende sikkerhetskrav.
4. Godkjenn nødvendige CSP Trusted Sites for scripts på nettstedet.
5. Bruk oversikten over adresser for Dev og Prod.

## 3. Kontroller ID-porten-oppsettet

Hvis oppsettet allerede finnes for nettstedet, gå videre til punkt 4.

### 3.1 Finn nettstedets Network ID

Kjør følgende SOQL-spørring:

```sql
SELECT Id, Name FROM Network

### 3.2 Legg inn Network ID i `crm-community-base`

Legg inn NetworkId for Experience Cloud-siden på linje 79 i:

- [IdPortenSidController.cls på GitHub](https://github.com/navikt/crm-community-base/blob/master/force-app/IdPorten/classes/IdPortenSidController.cls)

Kontroller at Network ID finnes i listen `communitiesUsingNewDecorator` i `IdPortenSidController.cls`.

Hvis ID-en mangler:

1. Legg til ID-en i `IdPortenSidController.cls`.
2. Deploy `crm-community-base` til aktuelle miljøer gjennom godkjent prosess.

### 3.3 Legg til Visualforce-sider

Kontroller at følgende sider finnes under **Site Visualforce Pages**:

- `NavLoginService`
- `IdPortenSid`

Legg dem til hvis de mangler.

## 4. Bytt header og footer i Experience Builder

Åpne Aa-registeret i Experience Builder, og gå gjennom følgende sider:

- `home`
- `mineAvtaler`
- `agreementDetailFlex`
- `applicationDetailFlex`
- `mineMeldinger`
- `mineSøknader`
- `nyMelding`
- `nySøknadAaRegistret`
- `threadDetailFlex`

På hver aktuell side:

1. Fjern **Global Community Header** der den finnes.
2. Fjern **Global Community Footer** der den finnes.
3. Dra **Decorator Header** til toppen av siden.
4. Dra **Decorator Footer** til bunnen av siden.
5. Kontroller at siden har én header og én footer.

## 5. Velg miljø

På **Decorator Header** angir du:

- **Environment:** `Dev` i testmiljø og `Prod` i produksjon.
- **Context:** Velg riktig kontekst for siden.

Ved deployment fra Git skal aktuelle `views/*.json`-filer være oppført i `replacements` i `sfdx-project.json`.

Produksjonsoppsettet bruker `HEADER_ENV_REPLACER` når `DEPLOY_DESTINATION=PROD`, forutsatt at deployment-pipelinen håndterer disse innstillingene.

## 6. Publiser

Klikk **Publish** i Experience Builder.

## 7. Test med TestID i SIT2

1. Åpne Aa-registerets SIT2-URL.
2. Logg inn via ID-porten med TestID.

Kontroller at:

- Ny header og footer vises på alle aktuelle sider.
- Navigasjonen fungerer etter innlogging.
- Dekoratøren ikke blokkeres av CORS eller CSP.

**Merk:** TestID velger ikke miljø automatisk. Bruk SIT2-URL-en for å teste SIT2.

## 8. Tillegg: Main Content – UU-krav

Dette er ikke en del av selve oppsettet av Dekoratøren, men et tiltak for universell utforming.

### 8.1 Legg til Main Content

1. Åpne aktuell side i Experience Builder og se etter **Main content** under **Page Structure**.
2. Hvis komponenten mangler, dra **Main content** fra Components til starten av hovedinnholdet.
3. Klikk **Publish**.

### 8.2 Test tastaturhoppet

Test med tastaturet at «Hopp til hovedinnhold» fungerer.

Komponenten **Main content** er usynlig og gjør det mulig å hoppe direkte til sidens hovedinnhold.