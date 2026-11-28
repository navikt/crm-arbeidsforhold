---
applyTo: "**"
---

# Agentisk utvikling i crm-arbeidsforhold

## Nav-prinsipp

Følg Nav sine Copilot-prinsipp frå [navikt/copilot](https://github.com/navikt/copilot):

- Bruk små, fokuserte endringar og eksisterande mønster.
- Start med deterministisk, lokal validering før breiare undersøking.
- Bevar utviklarens forståing: forklar arkitekturval, tradeoffs og raud-sone-logikk.
- Be om avklaring ved uklare krav og stopp før handlingar som krev menneskeleg godkjenning.
- Ver tydeleg på kva som er verifisert, kva som er blokkert, og kva som berre er ei antaking.

## TDD-gate

Ved ny funksjonalitet eller feilretting skal agenten bruke red-green-refactor i vertikale skiver:

1. Avklar krav, observabel åtferd og testseam før kode.
2. Skriv ein test som uttrykkjer åtferda og køyr han slik at han feilar, når testmiljøet støttar dette.
3. Skriv minste implementasjon som gjer testen grøn.
4. Køyr same fokuserte test etter kvar endring.
5. Refaktorer først når åtferdstesten er grøn, og køyr testen på nytt.
6. Køyr relevant breiare validering før arbeidet blir kalla ferdig.

For Apex må agenten skilje mellom lokal Jest-validering og org-avhengig Apex-validering. Dersom ein Apex-test ikkje kan kompilerast eller køyrast utan ein autentisert org, skal agenten dokumentere dette og aldri hevde at testen er grøn.

## Før og etter kode

Før endring:

- Finn næraste implementasjon, test og gjeldande instruks.
- Identifiser om fila ligg i hovudpakkja eller ei pakke-eigd referansemappe.
- Klassifiser arbeidet som grøn sone eller raud sone. Kjernelogikk, tilgang, personvern, autentisering og arkitektur krev ekstra menneskeleg gjennomgang.

Etter endring:

- Vis kva test eller validering som blei køyrd.
- Forklar arkitekturval og viktige tradeoffs kort.
- Marker kode som utviklaren må forstå særleg grundig.
- Køyr security-review før commit, push eller pull request når endringa rører secrets, auth, tilgang, persondata, callouts, metadata-tilgang eller GitHub Actions.

## Menneskeleg kontroll

Agenten kan arbeide i eksisterande `crm-arbeidsforhold` scratch-org utan ny brukargodkjenning, inkludert lesing, preview, retrieval, Apex-testar/-skript, pakkeinstallasjon, deploy, publisering og endring/sletting av data eller metadata. Verifiser før handling at eksplisitt mål er rett scratch-org; aliasnamnet åleine er ikkje bevis. Org-oppretting/-erstatting, pakkeoppretting/-promotering, endring av CI/auth og live eksterne integrasjonar krev framleis eksplisitt godkjenning. Agenten skal ikkje finne på org-alias, Salesforce-ID-ar, installasjonsnøklar eller avhengigheitsversjonar.

Før kvar agentkommando mot ein annan ikkje-produksjonsorg skal brukaren
stadfeste eksakt mål og handling på nytt, og agenten skal forklare den tekniske
grunnen. Tidlegare godkjenning eller autentisering gir ikkje løyve til neste
operasjon utanfor det autoriserte scratch-orget.
Agentar skal aldri aksessere produksjon, heller ikkje ein produksjonstilknytt
Dev Hub eller etter godkjenning. Avtal menneskeleg utføring i staden.
Team Platforce må godkjenne menneskelege produksjonsmetadataendringar og utfører
produksjonsverifikasjon og sletting.

For Salesforce-utvikling i dette repoet:

- Bruk Salesforce CLI 2.158.7 installert på macOS-verten, og målrett som standard scratch-orgen `crm-arbeidsforhold`.
- Køyr autentiserte Salesforce CLI-kommandoar gjennom den støtta terminalmekanismen i VS Code-verten. Respekter native verktøygodkjenningar; scratch-unntaket omgår ikkje tryggleikskontrollar og krev ikkje ei ekstra godkjenning i samtalen. Ikkje køyr dei i `cplt`, som ikkje har tilgang til vertens autentisering. Stopp dersom den godkjende verts-terminalen ikkje er tilgjengeleg.
- Ikkje endre Salesforce-autentisering, krypteringsinnstillingar, Keychain-element eller credential-filer.
- Etter endringar i Apex eller metadata skal relevante testar og valideringar køyrast. Metadata-deploy til verifisert `crm-arbeidsforhold` scratch-org krev ikkje ny brukargodkjenning; andre ikkje-produksjonsmål krev fersk mål-/handlingsgodkjenning.
- Bruk aldri produksjon. Bruk av andre orgar enn `crm-arbeidsforhold` krev eksplisitt godkjenning og må vere ikkje-produksjon.

Team Arbeidsforhold eig repoet og produktet; `@navikt/crm-arbeidsforhold` er
GitHub-teamet for bidragsytarar og review. Manuelle endringssteg krev runbook
med ansvar, revisjon, godkjenning og evidens. Metadataopprydding skal verifiserast
i SIT2 etter godkjenning. Følg dei fullstendige org-reglane i `AGENTS.md`.
