import { createElement } from 'lwc';
import AaregOrgSelector from 'c/aaregOrgSelector';

const ORGANIZATIONS = [
    { organizationNumber: '889640782', name: 'Arbeids- og velferdsetaten' },
    { organizationNumber: '974760673', name: 'Brønnøysundregistrene' },
    { organizationNumber: '990983666', name: 'Nav Oslo', parentName: 'Arbeids- og velferdsetaten' }
];

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

function mount(props = {}) {
    const element = createElement('c-aareg-org-selector', { is: AaregOrgSelector });
    Object.assign(element, { organizations: ORGANIZATIONS, includeSelf: true, ...props });
    document.body.appendChild(element);
    return element;
}

const input = (element) => element.shadowRoot.querySelector('input[role="combobox"]');
const options = (element) => [...element.shadowRoot.querySelectorAll('li[role="option"]')];

async function type(element, text) {
    const field = input(element);
    field.dispatchEvent(new CustomEvent('focus'));
    field.value = text;
    field.dispatchEvent(new CustomEvent('input'));
    await flush();
}

const key = async (element, name) => {
    input(element).dispatchEvent(new KeyboardEvent('keydown', { key: name }));
    await flush();
};

describe('c-aareg-org-selector', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('selects nothing automatically and lists «Meg selv» first', async () => {
        const element = mount();
        await flush();
        expect(element.shadowRoot.querySelector('[data-id="current"]').textContent).toContain('Ingen valgt');

        input(element).dispatchEvent(new CustomEvent('focus'));
        await flush();
        const listed = options(element);
        expect(listed[0].textContent).toContain('Meg selv');
        expect(listed).toHaveLength(4);
        expect(listed.every((option) => option.getAttribute('aria-selected') === 'false')).toBe(true);
    });

    it('searches on name', async () => {
        const element = mount();
        await type(element, 'brønnøy');

        const names = options(element).map((option) => option.dataset.value);
        expect(names).toEqual(['SELF', '974760673']);
    });

    it('searches on organization number with or without spaces', async () => {
        const element = mount();
        await type(element, '889 640');

        expect(options(element).map((option) => option.dataset.value)).toEqual(['SELF', '889640782']);
    });

    it('shows subunits with their parent', async () => {
        const element = mount();
        await type(element, 'oslo');

        expect(options(element)[1].textContent).toContain('Underenhet av Arbeids- og velferdsetaten');
    });

    it('explains when nothing matches', async () => {
        const element = mount();
        await type(element, 'finst ikkje');

        expect(element.shadowRoot.querySelector('.empty').textContent).toContain('Ingen treff');
    });

    it('can be operated with the keyboard and announces the choice', async () => {
        const element = mount();
        const handler = jest.fn();
        element.addEventListener('select', handler);
        await type(element, 'nav');

        expect(input(element).getAttribute('aria-activedescendant')).toBe(options(element)[0].id);
        await key(element, 'ArrowDown');
        await key(element, 'Enter');

        expect(handler).toHaveBeenCalledTimes(1);
        expect(handler.mock.calls[0][0].detail).toEqual({
            organizationNumber: '990983666',
            name: 'Nav Oslo',
            isSelf: false
        });
        const current = element.shadowRoot.querySelector('[data-id="current"]');
        expect(current.textContent).toContain('Nav Oslo');
        expect(current.textContent).toContain('Org.nr. 990 983 666');
        expect(input(element).getAttribute('placeholder')).toBe('Søk etter en annen virksomhet');
        expect(input(element).getAttribute('aria-expanded')).toBe('false');
    });

    it('reports «Meg selv» without an organization number', async () => {
        const element = mount();
        const handler = jest.fn();
        element.addEventListener('select', handler);
        input(element).dispatchEvent(new CustomEvent('focus'));
        await flush();
        options(element)[0].click();

        expect(handler.mock.calls[0][0].detail).toEqual({ organizationNumber: null, name: 'Meg selv', isSelf: true });
    });

    it('closes with Escape', async () => {
        const element = mount();
        await type(element, 'a');
        await key(element, 'Escape');

        expect(element.shadowRoot.querySelector('ul[role="listbox"]')).toBeNull();
    });
});
