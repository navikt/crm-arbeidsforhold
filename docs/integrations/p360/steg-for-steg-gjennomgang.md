# P360-integrasjonen steg for steg

Start med [kodegjennomgangen](kodegjennomgang.md) for gjeldande kjelde på
`P360Test`, og [teknisk oversikt](teknisk-oversikt.md) for status og
avgrensingar. Den meir detaljerte
[tidlegare gjennomgangen](../../archive/p360/steg-for-steg-gjennomgang-tidlegare.md)
er bevart som historisk forklaring, ikkje som status for den nye flyten.

## Bruk av exceptions

Workeren klassifiserer `P360_IntegrationException`: retrybare feil med forsøk
att går til `Failed`, medan permanente eller uttømde feil går til
`Manual Review`. Loggkonteksten hentar korrelasjons-ID frå jobben; full
ende-til-ende-propagering og ekstern recovery er eigne verifikasjonspunkt.
Sjå [workeren](https://github.com/navikt/crm-arbeidsforhold/blob/807fdcf12f3f281beb780173d0db427cf7fa0142/force-app/integration/p360/classes/job/P360_ArchiveJobWorker.cls)
og [den historiske forklaringa](../../archive/p360/steg-for-steg-gjennomgang-tidlegare.md#bruk-av-exceptions).
