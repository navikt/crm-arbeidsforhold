import { createElement } from '@lwc/engine-dom';
import LinkPanel from 'c/linkPanel';

describe('c-link-panel', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('does not render an unread badge when unread count is zero', () => {
        const element = createElement('c-link-panel', {
            is: LinkPanel
        });
        element.unreadCount = 0;

        document.body.appendChild(element);

        expect(element.shadowRoot.querySelector('.slds-badge')).toBeNull();
    });

    it('renders the unread count when messages are unread', () => {
        const element = createElement('c-link-panel', {
            is: LinkPanel
        });
        element.unreadCount = 3;

        document.body.appendChild(element);

        expect(element.shadowRoot.querySelector('.slds-badge').textContent).toBe('3');
    });
});
