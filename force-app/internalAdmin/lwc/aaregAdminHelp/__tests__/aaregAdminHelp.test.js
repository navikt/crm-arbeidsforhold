import { createElement } from 'lwc';
import AaregAdminHelp from 'c/aaregAdminHelp';

const DOCS_BASE = 'https://github.com/navikt/crm-arbeidsforhold/blob/main/docs/';

describe('c-aareg-admin-help', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('lists the admin guide, architecture, flows, P360 scratch guide and test plan as new-tab links', () => {
        const element = createElement('c-aareg-admin-help', { is: AaregAdminHelp });
        document.body.appendChild(element);

        const links = Array.from(element.shadowRoot.querySelectorAll('a'));
        expect(links.map((link) => link.getAttribute('href'))).toEqual([
            `${DOCS_BASE}surfaces/aareg-admin-app.md`,
            `${DOCS_BASE}architecture/hele-loysinga.md`,
            `${DOCS_BASE}architecture/aareg-flow-katalog.md`,
            `${DOCS_BASE}integrations/p360/scratch-brukarguide.md`,
            `${DOCS_BASE}testing/aaregisteret-scenario-testplan.md`
        ]);
        links.forEach((link) => {
            expect(link.target).toBe('_blank');
            expect(link.rel).toBe('noopener noreferrer');
            expect(link.textContent.trim().length).toBeGreaterThan(0);
        });
    });

    it('explains that the test lab is started from VS Code and only works in scratch', () => {
        const element = createElement('c-aareg-admin-help', { is: AaregAdminHelp });
        document.body.appendChild(element);

        const text = element.shadowRoot.textContent;
        expect(text).toContain('npm run admin:scratch -- seed');
        expect(text).toContain('scratch');
    });
});
