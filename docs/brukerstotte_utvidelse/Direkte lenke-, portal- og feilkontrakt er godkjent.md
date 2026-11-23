# Direkte lenke-, portal- og feilkontrakt er godkjent

**Status:** For avklaring — ikke godkjent før navigasjons-, tilgangs- og feilutfallene er fylt ut

Dette dokumentet skal gi én godkjent kontrakt for portalen, rollesider, direkte lenker, manglende tilgang, tekniske feil og sikker retur.

## Beslutningsregel

Portalen og en direkte lenke må gjennomføre samme serverkontroll:

1. Identifiser pålogget bruker på serveren.
2. Identifiser forventet rolle.
3. Identifiser gyldig organisasjons- eller personkontekst.
4. Hent servergodkjente capabilities.
5. Returnér `GRANTED`, `DENIED` eller `TECHNICAL_ERROR`.

Experience Cloud `pageAccess`, skjult navigasjon eller en synlig rolleknapp er ikke tilgangsvern alene.

## 1. Portal og rollesider

### URL-kontrakt

| Side/rolle                      | Stabil URL | Er aktiv? | Fallback ved manglende rolle | Beslutning |
| ------------------------------- | ---------- | --------- | ---------------------------- | ---------- |
| Hovedportal                     | Fyll ut    | Fyll ut   | Fyll ut                      | Uavklart   |
| Virksomhetsrepresentant         | Fyll ut    | Fyll ut   | Fyll ut                      | Uavklart   |
| Arbeidsgiver                    | Fyll ut    | Fyll ut   | Fyll ut                      | Uavklart   |
| Samarbeidspartner/fullmektig    | Fyll ut    | Fyll ut   | Fyll ut                      | Uavklart   |
| Privatperson/arbeidstaker       | Fyll ut    | Fyll ut   | Fyll ut                      | Uavklart   |
| Eksisterende brukerstøttebruker | Fyll ut    | Fyll ut   | Fyll ut                      | Uavklart   |

- [ ] Dagens Experience Cloud-URL er avklart som ny portal eller fallback.
- [ ] Rolle-sider har stabile, godkjente URLer/routing.
- [ ] Gamle eller ukjente URLer har en fast fallback.
- [ ] Ukjent rolle og deaktivert rolle har forskjellig behandling.
- [ ] URL-en brukes ikke som autorisasjonsbevis.

**Beslutning:**

### Rolleside

For hver rolleside må det avklares:

- hvilket `roleKey` siden bruker,
- hvilken konteksttype som kreves,
- hvilke capabilities som kan vises,
- hva som skjer uten kontekst,
- hva som skjer uten capability,
- hva som skjer ved teknisk kildefeil,
- hvordan brukeren kan komme tilbake til portalen.

**Beslutning:**

## 2. Direkte lenker

- [ ] Direkte lenke går gjennom serverkontroll før innhold vises.
- [ ] Direkte lenke bruker samme capability-beslutning som portalnavigasjon.
- [ ] Direkte lenke uten pålogging har godkjent login-/redirect-kontrakt.
- [ ] Direkte lenke uten gyldig rolle avvises sikkert.
- [ ] Direkte lenke uten gyldig kontekst avvises eller ber om ny kontekst.
- [ ] Direkte Apex-kall kontrollerer samme beslutning som lenken og UI.
- [ ] Manipulert rolle-, kontekst- eller record-ID gir ikke tilgang.

| Direkte lenke/situasjon              | Forventet serverutfall | Forventet brukerutfall                         |
| ------------------------------------ | ---------------------- | ---------------------------------------------- |
| Gyldig lenke og `GRANTED`            | `GRANTED`              | Vis godkjent side eller handling               |
| Gyldig lenke, men mangler capability | `DENIED`               | Returner til portalen med fast status          |
| Ugyldig eller ukjent rolle           | `DENIED`               | Vis fast, begrenset feil/meldingsvalg          |
| Deaktivert rolle                     | `DENIED`               | Vis fast status for ikke tilgjengelig tjeneste |
| Mangler pålogging                    | `DENIED`               | Login eller trygt redirect                     |
| Mangler gyldig kontekst              | `DENIED`               | Be om kontekstvalg eller avvis lenken          |
| Tilgangskilde svarer teknisk         | `TECHNICAL_ERROR`      | Egen retry-feilmelding                         |
| Manipulerte URL-parametere           | `DENIED`               | Ignorer parametere eller avvis lenken          |

**Beslutning:**

## 3. Login og retur

- [ ] Oppførsel uten pålogging er avklart.
- [ ] Siste tillatte returadresse finnes i en forhåndsgodkjent allow-list.
- [ ] Åpen redirect eller godtykkelig `returnUrl` er ikke tillatt.
- [ ] Redirect etter innlogging går tilbake til en godkjent portal-/rollekontekst.
- [ ] Tilgang kontrolleres på nytt etter innlogging.
- [ ] URL-parametere kan ikke inneholde personopplysninger.
- [ ] Brukeren kan bare sende kortvarige, faste statusverdier i redirect.

**Tillatt returområde:**

**Ikke-tillatt retur-/redirect-behandling:**

**Beslutning:**

## 4. Manglende tilgang

Avklar om manglende tilgang skal gi:

- [ ] Tilbakeføring til hovedportalen.
- [ ] Begrenset statuskode i URL.
- [ ] Fast brukerrettet melding.
- [ ] Valg av annen rolle.
- [ ] Instruks om å søke om eller få rettighet.
- [ ] Ingen tekniske eller personlige detaljer i URL eller melding.

| Intern statuskode       | Visning i portalen | Når brukes den?                                         |
| ----------------------- | ------------------ | ------------------------------------------------------- |
| `no-access`             | Fyll ut            | Mangler capability eller tilgang                        |
| `role-not-active`       | Fyll ut            | Rollen er deaktivert eller utilgjengelig                |
| `invalid-context`       | Fyll ut            | Mangler eller har ugyldig organisasjons-/personkontekst |
| `login-required`        | Fyll ut            | Pålogging kreves                                        |
| `unknown-role`          | Fyll ut            | Rollen finnes ikke                                      |
| Andre godkjente verdier | Fyll ut            | Fyll ut                                                 |

Ukjenne statusverdier skal ignoreres. Statusverdien må ikke gi tilgang.

**Beslutning:**

## 5. Teknisk feil

Skille teknisk kildefeil fra manglende tilgang.

- [ ] Timeout-/tilgjengelighetsfeil er avklart.
- [ ] `TECHNICAL_ERROR` vises med egen melding.
- [ ] Brukeren får tydelig retry-handling.
- [ ] Retry krever ny serverkontroll og må ikke bruke gammel beslutning.
- [ ] Feilmeldingen inneholder ikke Salesforce-ID, personopplysninger eller interne diagnoser.
- [ ] Teknisk feil loggeres på en sikker måte og gir driftsalarm der det kreves.
- [ ] Kildefeil eller tomt resultat er ikke det samme.

| Situasjon                                                     | Serverutfall                                 | Brukerutfall                         | Logging/drift |
| ------------------------------------------------------------- | -------------------------------------------- | ------------------------------------ | ------------- |
| Tilgangskilden svarer ikke                                    | `TECHNICAL_ERROR`                            | Vis retry-feilmelding                | Fyll ut       |
| Tilgangskilden returnerer ugyldig eller ufullstendig resultat | `TECHNICAL_ERROR` eller avvist input, avklar | Fyll ut                              | Fyll ut       |
| Kilden returnerer tomt resultat                               | Ikke automatisk teknisk feil                 | Vis relevant tom-/manglende tilstand | Fyll ut       |
| Salesforce eller Apex kaster teknisk feil                     | `TECHNICAL_ERROR`                            | Vis generell feil og retry           | Fyll ut       |
| Ukjent intern feil                                            | `TECHNICAL_ERROR`                            | Ingen tekniske detaljer              | Fyll ut       |

**Beslutning:**

## 6. Manglende rolle, deaktivert rolle og ukjent rolle

Avklar følgende som separate tilfeller:

- Brukeren har ingen rolle.
- Rollen er ukjent for serveren.
- Rollen finnes, men er deaktivert.
- Rollen finnes, men brukeren har ikke capability.
- Rollen finnes, men organisasjons-/personkontekst mangler.
- Rollen finnes, men valgt organisasjon er ikke godkjent.
- Rollen finnes, men rollen er utilgjengelig for denne enheten eller ingressen.

**Beslutning:**

## 7. Safe retur og begrenset statuskode

Kontrakten bør begrense retur til:

- forhåndsgodkjente portaler eller sider,
- én fast liste med interne statuskoder,
- ingen frie return-URL-er uten allow-list,
- ingen Salesforce-record-IDer eller persondata i URL,
- ingen automagisk tilgang eller godkjent capability i query parameters.

| URL-/redirect-felt          | Tillatt verdi                                          | Ikke-tillatt verdi                                   |
| --------------------------- | ------------------------------------------------------ | ---------------------------------------------------- |
| `role` eller rolleparameter | Fast servergodkjent rolle eller pageApiName fra server | Frivillig klientverdi som kan endre tilgang          |
| `context`                   | Servervaliderte organisasjons-/personreferanser        | Manipulert ID eller personopplysning                 |
| `message` eller status      | Fast godkjent intern statuskode                        | Teknisk detail, Salesforce-ID eller personopplysning |
| `returnUrl`                 | Fast allow-listet portalområde                         | Ekstern eller vilkårlig URL                          |

**Beslutning:**

## 8. Serverkontrakt

Serverkallet bør kunne returnere:

- status,
- rolle,
- konteksttype,
- godkjent context scope,
- liste over capabilities,
- fast feil-/statuskode der relevant,
- ingen personopplysninger i URL eller feilkontrakt.

Illustrativ kontrakt:

```text
{
  status: GRANTED | DENIED | TECHNICAL_ERROR,
  roleKey,
  contextType,
  capabilities,
  statusCode
}
```

Konkrett implementasjonsnavn og datatyper er ikke godkjent før teknisk modell er avklart:

**Beslutning:**

## 9. Kildematrise

| Situasjon             | Kilde for kontroll                      | Klientverdi relevant?                  | Servermå revalidere?      |
| --------------------- | --------------------------------------- | -------------------------------------- | ------------------------- |
| Portal-rolleside      | Server-/rolleaccessservice              | Bare rolle fra page configuration      | Ja                        |
| Direkte lenke         | Samme server-/rolleaccessservice        | URL-verdi bare som rolle-/konteksthint | Ja                        |
| Organisasjonskontekst | Godkjent organisasjons-/rettighetskilde | Valgt organisasjonsnummer              | Ja ved hvert kall         |
| Personkontekst        | Godkjent person-/selvkilde              | Ikke som autorisasjonsbevis            | Ja ved hvert kall         |
| Capability            | Servergodkjent effektiv tilgang         | Nei                                    | Ja ved hvert handlingkall |

**Beslutning:**

## 10. Testing

- [ ] Portalnavigasjon er testet for alle roller.
- [ ] Direkte lenke er testet for alle representative roller.
- [ ] Direkte lenke gir samme resultat som portalnavigasjon.
- [ ] Manglende capability gir `DENIED`.
- [ ] Manglende rolle, ukjent rolle og deaktivert rolle er skilt.
- [ ] Manglende pålogging gir godkjent login-/redirect-atferd.
- [ ] Teknisk kildefeil gir `TECHNICAL_ERROR` og retry.
- [ ] Tomt resultat er ikke teknisk feil.
- [ ] Manipulerte URL-verdier gir ikke tilgang.
- [ ] Ugyldig eller ekstern return URL avvises.
- [ ] Statusmeldinger i portalen kommer bare fra fast lovliste.
- [ ] Jest-tester dekker portal og feiltilstander.
- [ ] Apex-tester dekker positive, negative og tekniske scenarioer.
- [ ] Minimum-access external user brukes der relevant.
- [ ] Testene kjøres i godkjent ikke-produksjonsorg før verifisert uttalelse.

## 11. Godkjenning

| Område                           | Godkjent av | Dato | Referanse |
| -------------------------------- | ----------- | ---- | --------- |
| Portal og rolleleke              |             |      |           |
| Direkte lenke og redirect        |             |      |           |
| Manglende tilgang og statuskoder |             |      |           |
| Teknisk feil og retry            |             |      |           |
| Return URL og sikkerhet          |             |      |           |
| Security/personvern              |             |      |           |

## Endelig beslutning

- [ ] Portal- og direkte lenke bruker samme serverkontroll.
- [ ] Rolle, kontekst og capability er avklart.
- [ ] Manglende tilgang, teknisk feil og manglende rolle er skilt.
- [ ] Safe retur til portalen er avklart.
- [ ] Statuskoder og brukerrettede meldinger er godkjent.
- [ ] Login/redirect uten pålogging er avklart.
- [ ] Return URL og redirect-beskyttelse er avklart.
- [ ] Experience Cloud page visibility brukes ikke som eneste tilgangsvern.
- [ ] Jest- og Apex-testene dekker portal og direkte lenker.
- [ ] Ingen kode startes før gate er oppfylt.

**Referanse til godkjenning/issue/PR:**

**Godkjent dato:**
