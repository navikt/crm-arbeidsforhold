# P360: scratch-kontrakttest og interne val

På `P360Test` finst eit separat testmottak for å undersøkje søknadsflyten
utan ein P360-server. [Scratch-guiden](scratch-brukarguide.md) forklarer
føresetnader og bruk. Den
[opphavlege arbeidsrapporten med testresultat](../../archive/p360/scratch-kontrakttest-og-interne-val-2026-11-15.md)
er bevart som historisk evidens.

## Kva testmottaket kan vise

- `P360_ScratchRpcClient` implementerer den eksisterande RPC-grensa og er
  plassert under [scratch-verktøya på `P360Test`](https://github.com/navikt/crm-arbeidsforhold/tree/807fdcf12f3f281beb780173d0db427cf7fa0142/scripts/scratch/p360/), utanfor
  produktpakken.
- Mottaket kan kontrollere og lagre avgrensa syntetiske førespurnader for
  sak og dokument. Les den konkrete kvitteringa når filinnhald eller
  sak-/dokumentkopling skal verifiserast; `Succeeded` åleine er ikkje nok.
- Testen går gjennom lokal Salesforce-kode og ein simulert mottakar. Han
  verifiserer ikkje faktisk P360-teneste, autentisering, kodeverk, eksterne
  rettar eller den endelege SIF-kontrakten.
- Mottaket lagrar i same Salesforce-transaksjon og etterliknar ikkje alle
  eksterne commit-/rollback- og timeoutforhold.

## Gjeldande kodegrenser

Søknadsjobben byggjer eit tekstsamandrag og siste versjon av dei filene som
er lenkja når workeren les. Det er ikkje eit lagra brukarutval eller eit frose
komplett innsendingssett. Open jobb blir gjenbrukt, medan ein seinare jobb
etter terminal status kan få ny nøkkel. Sjå
[teknisk oversikt](teknisk-oversikt.md) og
[vedleggsdesign](vedleggsutval-og-innsendingsidentitet-design.md).

Førebels serialisering og små inline-filer er ein lokal teststrategi, ikkje
godkjend filtransport eller ei garantert P360-grense. Ekte HTTP-klient,
ukjent-eksternt-utfall/recovery og vidare filstrategi står att.

## Kva skal registrerast?

Før ei ny køyring, stadfest mål og sideeffektar som beskrive i
[verifikasjonsplanen](inngangar-og-verifikasjonsplan.md). Registrer scenario,
dato, mål, commit/pakkeversjon, forventning, faktisk resultat, sanitert
evidens og opprydding. Ikkje legg førespurnadsinnhald, persondata eller
credentials i repoet. Historisk `PASS` er ikkje ein ny test.
