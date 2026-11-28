import { createElement } from 'lwc';
import AaregTextField from 'c/aaregTextField';

const flush = () => Promise.resolve();

async function mount(props) {
    const element = createElement('c-aareg-text-field', { is: AaregTextField });
    Object.assign(element, { label: 'E-post', type: 'email', required: true, ...props });
    document.body.appendChild(element);
    await flush();
    return element;
}

describe('c-aareg-text-field', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('shows the missing-value message and marks the input invalid', async () => {
        const element = await mount({ messageWhenValueMissing: 'Skriv inn e-postadressa.' });

        expect(element.reportValidity()).toBe(false);
        await flush();

        const input = element.shadowRoot.querySelector('input');
        expect(input.getAttribute('aria-invalid')).toBe('true');
        expect(element.shadowRoot.querySelector('.navds-error-message').textContent).toBe('Skriv inn e-postadressa.');
    });

    it('rejects a malformed e-mail address and accepts a valid one', async () => {
        const element = await mount({ value: 'ikkje-epost', messageWhenTypeMismatch: 'Ugyldig.' });
        expect(element.reportValidity()).toBe(false);

        const input = element.shadowRoot.querySelector('input');
        input.value = 'meg@example.com';
        input.dispatchEvent(new CustomEvent('input'));
        await flush();

        expect(element.reportValidity()).toBe(true);
        await flush();
        expect(element.shadowRoot.querySelector('.navds-error-message')).toBeNull();
    });

    it('reports the new value to the parent on change', async () => {
        const element = await mount();
        const handler = jest.fn();
        element.addEventListener('change', handler);

        const input = element.shadowRoot.querySelector('input');
        input.value = 'ny@example.com';
        input.dispatchEvent(new CustomEvent('change'));

        expect(element.value).toBe('ny@example.com');
        expect(handler.mock.calls[0][0].detail).toEqual({ value: 'ny@example.com' });
    });
});
