import { createElement } from 'lwc';
import AaregAdminAccessDiagnosis from 'c/aaregAdminAccessDiagnosis';
import getDiagnosis from '@salesforce/apex/AAREG_AdminAccessDiagnosisController.getDiagnosis';

jest.mock('@salesforce/apex/AAREG_AdminAccessDiagnosisController.getDiagnosis', () => ({ default: jest.fn() }), {
    virtual: true
});

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

describe('c-aareg-admin-access-diagnosis', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows profile, permission sets, custom permissions and object explanations', async () => {
        getDiagnosis.mockResolvedValue({
            userName: 'Test Brukar',
            profileName: 'Minimum Access - Salesforce',
            permissionSets: ['AAREG_Admin_Viewer'],
            customPermissions: [{ apiName: 'P360_Archive_Release', granted: false, explanation: 'Frigje vedtak.' }],
            objects: [
                {
                    apiName: 'Application__c',
                    label: 'Søknad',
                    canRead: true,
                    canCreate: false,
                    canEdit: false,
                    explanation: 'Lesetilgang kjem frå: AAREG_Admin_Viewer.'
                }
            ]
        });
        const element = createElement('c-aareg-admin-access-diagnosis', { is: AaregAdminAccessDiagnosis });
        document.body.appendChild(element);
        await flush();

        const text = element.shadowRoot.textContent;
        expect(text).toContain('Minimum Access - Salesforce');
        expect(text).toContain('AAREG_Admin_Viewer');
        expect(text).toContain('P360_Archive_Release');
        expect(text).toContain('Lesetilgang kjem frå: AAREG_Admin_Viewer.');
        expect(text).toContain('Denne sida gir aldri tilgang');
    });
});
