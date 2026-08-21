import { createElement } from '@lwc/engine-dom';
import Aareg_home from 'c/aareg_home';

describe('c-aareg-home', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        sessionStorage.clear();
    });

    it('uses the lowercase usertype page state value for employer users', () => {
        const element = createElement('c-aareg-home', {
            is: Aareg_home
        });

        document.body.appendChild(element);
        element.init = jest.fn();

        element.handlePageRef({
            state: {
                usertype: 'Employer'
            }
        });

        expect(element.selectedUserType).toBe('Employer');
        expect(element.representsPrivatePerson).toBe(true);
    });
});
