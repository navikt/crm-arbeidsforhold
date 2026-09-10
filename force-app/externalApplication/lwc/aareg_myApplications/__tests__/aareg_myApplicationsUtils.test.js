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

        const getDecisionPDFs = jest.fn(() =>
            Promise.resolve({
                a01: '/sfc/servlet.shepherd/document/download/069'
            })
        );

        const updated = await resolveDecisionAvailability(rows, getDecisionPDFs);

        expect(getDecisionPDFs).toHaveBeenCalledTimes(1);
        expect(getDecisionPDFs).toHaveBeenCalledWith({ applicationIds: ['a01', 'a02'] });
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

    it('disables Avslag downloads when bulk lookup fails', async () => {
        const rows = [{ Id: 'a01', Status__c: 'Avslag' }];
        const getDecisionPDFs = jest.fn(() => Promise.reject(new Error('PDF lookup failed')));

        const updated = await resolveDecisionAvailability(rows, getDecisionPDFs);

        expect(getDecisionPDFs).toHaveBeenCalledWith({ applicationIds: ['a01'] });
        expect(updated).toEqual([
            {
                Id: 'a01',
                Status__c: 'Avslag',
                decisionUrl: null,
                disableButton: true,
                disableApplication: true
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
