import { LightningElement } from 'lwc';

const DOCS_BASE = 'https://github.com/navikt/crm-arbeidsforhold/blob/main/docs/';

const LINKS = [
    {
        key: 'admin',
        label: 'Brukarguide for Arbeidsforhold Admin',
        description: 'Kva kvar side viser, testlaben og tilgang.',
        path: 'surfaces/aareg-admin-app.md'
    },
    {
        key: 'architecture',
        label: 'Heile løysinga',
        description: 'Arkitektur, integrasjonar og datamodell.',
        path: 'architecture/hele-loysinga.md'
    },
    {
        key: 'flows',
        label: 'Flow-katalogen',
        description: 'Alle Flow-ar og kva dei utløyser.',
        path: 'architecture/aareg-flow-katalog.md'
    },
    {
        key: 'p360',
        label: 'P360 i scratch',
        description: 'Simulert P360-mottak og kvitteringar.',
        path: 'integrations/p360/scratch-brukarguide.md'
    },
    {
        key: 'testplan',
        label: 'Scenario-testplan',
        description: 'Steg for steg med forventa resultat.',
        path: 'testing/aaregisteret-scenario-testplan.md'
    }
];

export default class AaregAdminHelp extends LightningElement {
    links = LINKS.map((link) => ({ ...link, url: DOCS_BASE + link.path }));
}
