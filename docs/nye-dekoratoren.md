# NAV-dekoratøren Aa-registeret

Denne veiledningen beskriver hvordan NAVs nye header og footer
(Dekoratøren) tas i bruk på Experience Cloud-siden Aa-registret.

## 1. Kontroller komponenter og styling

- Kontroller at `crm-community-base` er installert, og at **Decorator Header** og **Decorator Footer** er tilgjengelige i Experience Builder.
- Gammel dekoratørstyling skal ikke brukes sammen med den nye Dekoratøren.
- I Aa-registeret kommer stylingløsningen fra et annet repository.
- Kontroller eksisterende oppsett før du endrer kode.

## 2. Kontroller CORS og CSP

### CORS

Dekoratøren har en streng CORS-policy og tillater vanligvis bare nettsider med domenenavn under `*.nav.no`.

Ved testing i Scratch Org eller Sandbox kan du:

- Slå av CORS-mekanismen i en egen testnettleser.
- Starte Chrome med `--disable-web-security`.
- Bruke en CORS-utvidelse i testnettleseren.
- Be teamet som eier Dekoratøren om å legge til ditt domene i CORS-whitelisten.

Bruk helst en separat testnettleser eller en midlertidig CORS-konfigurasjon for testing. Denne løsningen skal ikke brukes som permanent konfigurasjon.

Hvis domenet legges inn i CORS-policyen, må URL-en for både Experience-siden og Experience Builder legges inn.

### CSP

1. Gå til Experience Builder → Settings → Security & Privacy.
2. Kontroller at **Relaxed CSP** brukes.
3. Kontroller at **Lightning Locker** er deaktivert.
4. Godkjenn nødvendige **CSP Trusted Sites** for scripts på nettstedet.
5. Kontroller CSP-adressene som brukes i Dev- og produksjonsmiljøet.

Mange CSP-er kan bli blokkert automatisk og må godkjennes manuelt.

CSP-innstillinger for scripts må godkjennes for hvert Experience Cloud-nettsted som bruker Dekoratøren. Andre ressurser, som styles, bilder og lignende, kan være definert globalt for Salesforce-organisasjonen.

<img width="787" height="353" alt="CORS-policy" src="https://github.com/user-attachments/assets/579e3811-7cfe-4e07-a37c-9718f6683450" />

<img width="781" height="882" alt="CSP Trusted Sites" src="https://github.com/user-attachments/assets/837a0530-1f78-42fd-968b-d34354f2de4b" />


## 3. Kontroller ID-porten-oppsettet

Hvis oppsettet allerede finnes for nettstedet, gå videre til punkt 4.

### 3.1 Finn nettstedets Network ID

Kjør følgende SOQL-spørring mot Salesforce:

```sql
SELECT Id, Name FROM Network
```

### 3.2 Legg inn Network ID i `crm-community-base`

Legg inn NetworkId for Experience Cloud-siden på linje 79 i:

- [IdPortenSidController.cls på GitHub](https://github.com/navikt/crm-community-base/blob/7cf3dbb57253abe7cd0fc55aef2100baedd19da4/force-app/IdPorten/classes/IdPortenSidController.cls#L88-L97)

Kontroller at Network ID finnes i listen `communitiesUsingNewDecorator` i `IdPortenSidController.cls`.

Hvis ID-en mangler:

1. Legg til ID-en i `IdPortenSidController.cls`.
2. Deploy `crm-community-base` til aktuelle miljøer gjennom godkjent prosess.

### 3.3 Legg til Visualforce-sider


Kontroller at følgende sider finnes under **Site Visualforce Pages**:


- `NavLoginService`

- `IdPortenSid`



Legg dem til hvis de mangler.

<img width="824" height="464" alt="Visualforce-sider" src="https://github.com/user-attachments/assets/7b914905-4645-4405-8562-626f49cbc072" />


<img width="762" height="561" alt="Visualforce Pages" src="https://github.com/user-attachments/assets/1f3fb874-bbd2-422c-b09f-757e720bf99c" />



## 4. Bytt header og footer i Experience Builder


Endringen skal gjøres i Experience Cloud-temaet.



1. Åpne Experience Builder for Aa-registeret.

2. Dra **Decorator Header** til headerområdet i temaet.

3. Dra **Decorator Footer** til footerområdet i temaet.

4. Kontroller at temaet bruker én header og én footer.

5. Fjern **Global Community Header** og **Global Community Footer** hvis de fortsatt finnes i det aktuelle temaet eller layoutet.



Kontroller følgende sider etter at temaet er oppdatert:



- `home`

- `mineAvtaler`

- `agreementDetailFlex`

- `applicationDetailFlex`

- `mineMeldinger`

- `mineSøknader`

- `nyMelding`

- `nySøknadAaRegistret`

- `threadDetailFlex`



Kontroller at den gamle og den nye headeren eller footeren ikke vises samtidig.


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

- Det ikke vises en gammel eller en ny dekoratør samtidig.



## 8. Tillegg: Main Content – UU-krav


Dette er ikke en del av selve oppsettet av Dekoratøren, men et tiltak for universell utforming.


### 8.1 Legg til Main Content



1. Åpne aktuell side i Experience Builder.

2. Se etter **Main content** under **Page Structure**.

3. Hvis komponenten mangler, dra **Main content** fra Components til starten av hovedinnholdet.

4. Klikk **Publish**.



### 8.2 Test tastaturhoppet


Test med tastaturet at «Hopp til hovedinnhold» fungerer.


Komponenten **Main content** er usynlig og legger til en link i starten av Dekoratøren. Skjermlesere kan bruke linken for å gå direkte til sidens hovedinnhold. Komponenten påvirker ikke funksjonaliteten og er en del av UU-tiltaket.


## 9. Kilder

- [Experience Cloud – Confluence](https://confluence.adeo.no/spaces/PTC/pages/500537629/Experience+Cloud)

- [CORS-konfigurasjonen for Dekoratøren](https://github.com/navikt/nav-dekoratoren)

- [IdPortenSidController.cls på GitHub](https://github.com/navikt/crm-community-base/blob/7cf3dbb57253abe7cd0fc55aef2100baedd19da4/force-app/IdPorten/classes/IdPortenSidController.cls#L88-L97)
