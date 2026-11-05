import { createElement } from 'lwc';
import Aareg_applicationBasis from 'c/aareg_applicationBasis';

describe('c-aareg-application-basis', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('disables access type checkboxes when the form is read-only', () => {
        const element = createElement('c-aareg-application-basis', {
            is: Aareg_applicationBasis
        });

        element.record = {
            uuid: 'test-uuid',
            API_Access__c: true,
            Extraction_Access__c: false,
            Online_Access__c: false,
            PurposeMunicipality__c: 'Test formål',
            LegalBasisMunicipality__c: 'Test hjemmel'
        };
        element.readOnly = true;
        element.organizationType = 'Municipality';
        element.legalBasisOptions = [];
        element.purposeData = { values: [], controllerValues: {} };

        document.body.appendChild(element);

        const apiCheckbox = element.shadowRoot.querySelector('[data-id="API_Access__c"]');
        const onlineCheckbox = element.shadowRoot.querySelector('[data-id="Online_Access__c"]');

        expect(apiCheckbox.disabled).toBe(true);
        expect(onlineCheckbox.disabled).toBe(true);
    });
});
