---
title: Heilskapleg gjennomgang av Arbeidsforhold / Aa-registeret
status: proposed
---

# Spec: heilskapleg produkt-, org- og testoversikt

## Formål

Etablere eit kjelde- og evidensforankra kunnskapsgrunnlag for heile Arbeidsforhold/Aa-registeret-løysinga. Resultatet skal gjere det mogleg for produkt, utvikling, test og drift å forstå kva produktet gjer, korleis delane heng saman, kva som faktisk finst i scratch-org-en, korleis alle relevante scenario blir testa, og kva som må avklarast eller rettast.

## Aktørar og scope

- **Produkt- og utviklingsteam:** treng ei samanhengande oversikt over funksjonar, domene, kjelde, avhengnader og opne tiltak.
- **Testarar og saksbehandlarar:** treng scenario med føresetnader, konkrete steg, venta resultat, testdata og verifikasjon.
- **Plattform- og integrasjonseigarar:** treng tydelege kontraktsgrenser, organisasjonstilstand, eigarskap og uavklarte avhengnader.

Gjennomgangen omfattar `force-app/`, Salesforce-metadata og testar, Experience Cloud-flater, Flow, integrasjonar, deklarerte dependency-pakkar og scratch-org-en `crm-arbeidsforhold`. Dependency-kjelder blir undersøkte som read-only referansar; eigarskap og kva produktet faktisk brukar skal kartleggjast.

## Krav

### REQ-001 — Komplett kjelde- og funksjonsinventar

Kartlegg alle produktområde og observerbare funksjonar frå brukarflate, Apex, Flow, metadata, integrasjon, schedulering og relevante test-/fixture-kjelder. Knyt kvar funksjon til kjelder og merk om ho er verifisert i kjelde, test eller org.

### REQ-002 — Dependency-oversikt

Kartlegg alle direkte deklarerte pakkeavhengnader, relevante transitive samband, installert scratch-org-status når han er godkjend undersøkt, eigarskap, kva produktet brukar, og kva som ikkje kan konkluderast frå lokal referansekjelde.

### REQ-003 — Scratch-org-runtime-evidens

Samanlikn kjelde og avgrensa runtime-tilstand i `crm-arbeidsforhold`, inkludert aktive Flow-versjonar, relevante feature flags, schedulering, dependency-installasjon og aggregerte tilgangs-/konfigurasjonstilstandar. Verifiser eksplisitt mål og scratch-type før handling; arbeid i eksisterande `crm-arbeidsforhold` scratch-org krev ikkje ny brukargodkjenning. Andre ikkje-produksjonsorg krev fersk mål-/handlingsgodkjenning etter `AGENTS.md`. Ingen produksjonsorg, credential-data, secrets eller unødvendige person-/forretningsrecordar skal lesast.

### REQ-004 — Ende-til-ende funksjonar og scenario

Dokumenter dei samanhengande arbeidsflytane for organisasjons- og tilgangskontroll, søknad/utkast/vedlegg, behandling/avgjerd, avtale/distribusjonstilgang, dialog/støtte/varsling, filer, planlagde jobbar, Altinn og P360. Ta med normalbaner, roller/tilgang, negative grenser, feil, retry/asynkronitet og operasjonelle randtilfelle.

### REQ-005 — Syntetisk testdatastrategi

Definer deterministisk, isolert og syntetisk testdata for alle scenario. Skil mellom lokale Jest/Apex-testdata, godkjend scratch-org-data og eksterne mock-/kontrakttestar. Ikkje bruk reelle personopplysningar, credentials, produksjonsdata eller live-integrasjon utan eiga godkjenning.

### REQ-006 — Stegvis testplan

For kvart scenario dokumenter føresetnader, testaktør/tilgang, miljø, testdataoppsett, nøyaktige handlingar i rekkjefølgje, venta UI-/record-/integrasjonsresultat, negative/feilutfall, venting/polling for asynkrone steg, evidens som skal fangast, opprydding og testtype.

### REQ-007 — Funn, avgjerder og tiltak

Samle manglande funksjonalitet, feil, sikkerheits-/personvernpunkt, dokumentasjonsgap, driftsrisiko og teknisk gjeld i eit prioritert register med evidens, påverknad, eigar/avgjerdsbehov, avhengnader, akseptansekriterium og GitHub Issue. Gjenbruk eksisterande P360-arbeid i staden for å opprette duplikat.

### REQ-008 — Trygg dokumentasjonsopprydding

Klassifiser dokumentasjon som gjeldande, utdatert, overlappande, historisk eller Confluence-spegel. Bevar original og kjeldepeikar før eventuell flytting til `docs/archive/`. Ikkje flytt eller rediger dokument merkte `speilkopi: ja` utan at Confluence-kjelda blir oppdatert. Metadata-sletting eller -omdøyping krev separat runbook, dependency-kontroll, rollback og godkjenning.

### REQ-009 — Samla og vedlikehalden leveranse

Lever ein navigerbar dokumentasjonspakke med tydelege evidensstatusar og relative lenker. GitHub Issues skal vere arbeidskjelda for deloppgåver, eigarar, status, avklaringar og akseptanse. Eksisterande Issues skal lenkjast og haldast framfor å dupliserast.

## Forventa dokumentasjonspakke

- Éi inngangsside med produktoversikt og lenkjer til detaljar.
- Kjelde-/funksjonskart, datamodell, arbeidsflytar og systemgrenser.
- Dependency-/pakkeoversikt med eigarskaps- og evidensstatus.
- Scratch-org-snapshot med dato, metode, avgrensingar og kjelde/org-avvik; utan sensitivt innhald.
- Komplett funksjons-/scenariooversikt med rolle, tilstand, resultat og testbevis.
- Testdatastrategi og scenario-for-scenario stegvis testplan.
- Prioritert funn-/tiltaksregister og trygg arkiveringslogg.
- Peikarar til autoritative Issues, ADR-ar, integrasjonsdokument og eventuelle Confluence-runbooks.

## Akseptansekriterium

- [ ] Kvar observerbar produktfunksjon i scope er skildra og knytt til kjelde og verifikasjonsstatus.
- [ ] Alle direkte dependencies er klassifiserte; dependency-eigde kjelder er ikkje endra.
- [ ] Dei 37 kjende Flow-definisjonane og relevante Apex-/LWC-/metadata-/integrasjonsbaner er dekte utan å anta at kjeldestatus beviser org-køyring.
- [ ] Scratch-org-funn kan sporast til godkjend mål, dato, kommando og resultat; ingen produksjon eller sensitiv record-data er brukt.
- [ ] Kvart scenario har steg-for-steg-handlingar og målbare venta resultat, samt testdata, tilgang, feilbaner og opprydding.
- [ ] Teststrategien skil lokale, org-avhengige og eksterne valideringar og markerer kva som faktisk er køyrt.
- [ ] Kvart prioritert funn har evidens, neste handling/avgjerd og Issue utan duplikat av aktivt arbeid.
- [ ] Ingen eksisterande dokument, Salesforce-metadata eller data er sletta/flytta før klassifisering, eigarskap, originalbevaring, lenkekontroll, godkjenning og rollback-plan er dokumentert.
- [ ] Dokumentasjonspakka har fungerande relative lenkjer, tydeleg navigasjon og eksplisitte uverifiserte/foreslåtte statusar.

## Avgrensingar og styring

- Ingen produksjonstilgang eller produksjonsverifikasjon for agentar.
- Verifiser at eksplisitt mål er eksisterande `crm-arbeidsforhold` scratch-org; der trengst ikkje ny brukargodkjenning. Andre ikkje-produksjonsorg krev fersk mål-/handlingsgodkjenning.
- Ingen deploy, pakkeinstallasjon, autentiseringsendring, flaggaktivering eller live Altinn/P360-kall som del av denne kartlegginga.
- Ingen endring i dependency-eigd mappe utan eksplisitt eigargodkjenning.
- Eventuelle produktkodefiks blir separate Issues/PR-ar etter evidens, prioritering, menneskeleg review og relevante testar.
- Jira/Confluence er framleis kjelda for sine eigne prosess-/statusdata; repo-dokumentasjon skal ikkje stille spegle eller overskrive slike kjelder.
