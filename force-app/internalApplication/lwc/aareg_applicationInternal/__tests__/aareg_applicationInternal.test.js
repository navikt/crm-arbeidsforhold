import { createElement } from '@lwc/engine-dom';
import Aareg_applicationInternal from 'c/aareg_applicationInternal';

jest.mock(
    '@salesforce/apex/AAREG_ApplicationInternalController.getApplicationDetails',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

import getApplicationDetails from '@salesforce/apex/AAREG_ApplicationInternalController.getApplicationDetails';

const flushPromises = () => Promise.resolve().then(() => Promise.resolve());

describe('c-aareg-application-internal', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders a direct error message when application details cannot be loaded', async () => {
        getApplicationDetails.mockRejectedValue({ message: 'Request failed' });
        const element = createElement('c-aareg-application-internal', {
            is: Aareg_applicationInternal
        });

        document.body.appendChild(element);
        await flushPromises();

        expect(element.shadowRoot.textContent).toContain('Error: Request failed');
    });
});
