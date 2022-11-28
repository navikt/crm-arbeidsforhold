# crm-arbeidsforhold
Denne pakken inneholder Salesforce metadata som støtter arbeidet NAV gjør rundt Aa-registeret. Løsningen er utviklet av Team Arbeidsforhold og omfatter blant annet Experience Cloud, support og dialogløsningen fra NKS, søknader og avtaler.

## Avhengigheter

Pakken har flere avhengigheter. Sjekk [sfdx-project.json](https://github.com/navikt/crm-arbeidsforhold/blob/master/sfdx-project.json) filen for å se en oversikt over alle avhengigheter.

## Komme i gang

1. Salesforce DX-bruker. Kontakt #crm-plattform-team på Slack om du ikke har dette
2. Installer Salesforce DX CLI (SFDX)
   - Last ned fra [Salesforce.com](https://developer.salesforce.com/tools/sfdxcli)
   - Eller benytt npm: `npm install sfdx-cli --global`
3. Klon dette repoet ([GitHub Desktop](https://desktop.github.com) anbefales for ikke-utviklere)
4. Installer [SSDX](https://github.com/navikt/ssdx)
   - Med SSDX kan du lage scratch orger og gjøre deklarative endringer (gjøre endringer i nettleseren på Salesforce, altså ikke-utvikling)
   - **Trenger du ikke verktøy utvikling kan du stoppe her**
5. Installer [VS Code](https://code.visualstudio.com) (anbefalt)
6. Installer [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
7. Installer [AdoptOpenJDK](https://adoptopenjdk.net) (kun versjon 8 eller 11)
8. Åpne VS Code Settings og søk etter `salesforcedx-vscode-apex`
9. Under `Java Home`, legg inn følgende:
   - macOS: `/Library/Java/JavaVirtualMachines/adoptopenjdk-11.jdk/Contents/Home`
   - Windows: `C:\\Program Files\\AdoptOpenJDK\\jdk-11.0.3.7-hotspot` (merk at versjonsnummer kan endre seg)
