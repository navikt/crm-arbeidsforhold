import { buildDecisionUrl, updateApplicationsWithDecisionState } from '../aareg_myApplicationsUtils';

describe('aareg_myApplicationsUtils', () => {
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
