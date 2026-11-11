# Åpne spørsmål og beslutninger som må tas før implementasjon

## 1. Hvilke brukergrupper skal faktisk støttes i første leveranse?

Det er nødvendig å avklare om første versjon skal støtte kun arbeidsgiver og samarbeidspartner, eller også privatperson. Dette påvirker både URL-mønsteret og tilgangsmodellen.

## 2. Skal brukergruppe være definert i en egen Apex-kontekstmodell?

Det anbefales ja, men dette må besluttes eksplisitt. En enkel modell er bedre enn en overordnet og generisk tilgangsramme.

## 3. Skal meldingsvisning være personbasert eller organisasjonsbasert per gruppe?

Dette er et sentralt beslutningspunkt. Det må fastsettes før kodeimplementasjon.

## 4. Er det nødvendig å støtte flere organisasjonsvalg per bruker?

Dagens modell er basert på `LastUsedOrganization__c`, som er enkel og praktisk for virksomhetsrepresentanter. For andre grupper må det avklares om samme mønster skal brukes, eller om personbasert kontekst er bedre.

## 5. Hva er ønsket oppførsel for brukere uten organisasjonskontekst?

For arbeidsgiver og privatperson må det bestemmes om de skal få tilgang til en egen "min side" uten organisasjonsvalg, eller om de skal få prompt om å velge personlig kontekst.

## 6. Er det behov for nye Custom Metadata eller permission set for ny brukergruppe?

Dette må avklares før implementasjon, fordi noen tilganger kan være mer naturlige å modellere som eksisterende roller eller Custom Metadata.

## 7. Skal dette ligge i samme LWC-komponent eller i flere delte komponenter?

Det anbefales å begrense antallet nye komponenter, og bruke eksisterende `aareg_home` som grunnlag. Men beslutningen om komponentstruktur må tas før kodestart.

## 8. Hvilke funksjoner som er "sinne" og hvilke som er "ikke tillatte"?

Dette bør dokumenteres som en matrise for hver brukergruppe. Det vil redusere risiko for feil i navigasjon og tilgang.

## 9. Hva er ønsket nivå for audit / tracking i dette første steget?

Dette prosjektet bør holde seg liten og AAREG-spesifikk. Før implementasjon må det bestemmes hvor mye historikk som faktisk trengs i prosessen, uten å bygge et generisk aktivitetsystem.

## 10. Vil dette være en isolert AAREG-løsning eller skal det dele logikk med andre områder?

Det anbefales å holde dette AAREG-spesifikt i første fase, slik at løsningen er enkel å forstå, vedlikeholde og auditere.
