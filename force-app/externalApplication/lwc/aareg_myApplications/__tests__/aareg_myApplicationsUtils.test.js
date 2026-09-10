import {
    buildDecisionUrl,
    resolveDecisionAvailability,
    updateApplicationsWithDecisionState
} from '../aareg_myApplicationsUtils';

describe('aareg_myApplicationsUtils', () => {
    it('resolves download state on load from decision PDF availability', async () => {
        const rows = [
            { Id: 'a01', Status__c: 'Avslag' },
            { Id: 'a02', Status__c: 'Avslag' },
            { Id: 'a03', Status__c: 'Venter på svar' }
        ];

        const getDecisionPDF = jest.fn(({ applicationId }) => {
            if (applicationId === 'a01') {
                return Promise.resolve('/sfc/servlet.shepherd/document/download/069');
            }
            if (applicationId === 'a02') {
                return Promise.resolve(null);
            }
            return Promise.reject(new Error('Should not be called for non-Avslag rows'));
        });

        const updated = await resolveDecisionAvailability(rows, getDecisionPDF);

        expect(getDecisionPDF).toHaveBeenCalledTimes(2);
        expect(updated).toEqual([
            {
                Id: 'a01',
                Status__c: 'Avslag',
                decisionUrl: '/sfc/servlet.shepherd/document/download/069',
                disableButton: false,
                disableApplication: true
            },
            {
                Id: 'a02',
                Status__c: 'Avslag',
                decisionUrl: null,
                disableButton: true,
                disableApplication: true
            },
            {
                Id: 'a03',
                Status__c: 'Venter på svar',
                decisionUrl: null,
                disableButton: true,
                disableApplication: false
            }
        ]);
    });

    it('keeps Avslag download enabled when URL exists', () => {
        const rows = [{ Id: 'a01', Status__c: 'Avslag', disableButton: false }];

        const updated = updateApplicationsWithDecisionState(rows, 'a01', '/sfc/servlet.shepherd/document/download/069');

        expect(updated[0].disableButton).toBe(false);
        expect(updated[0].decisionUrl).toBe('/sfc/servlet.shepherd/document/download/069');
    });

    it('disables download when URL is not returned', () => {
        const rows = [{ Id: 'a01', Status__c: 'Avslag', disableButton: false }];

        const updated = updateApplicationsWithDecisionState(rows, 'a01', null);

        expect(updated[0].disableButton).toBe(true);
        expect(updated[0].decisionUrl).toBeNull();
    });

    it('adds aaregisteret path for SIT2 community domain', () => {
        const url = buildDecisionUrl(
            'https://navdialog--sit2.sandbox.my.site.com',
            '/sfc/servlet.shepherd/document/download/069'
        );

        expect(url).toBe(
            'https://navdialog--sit2.sandbox.my.site.com/aaregisteret/sfc/servlet.shepherd/document/download/069'
        );
    });
});
