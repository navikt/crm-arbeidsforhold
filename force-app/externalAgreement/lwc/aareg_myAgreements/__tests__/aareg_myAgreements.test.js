import Aareg_myAgreements from 'c/aareg_myAgreements';
import getDecisionPDF from '@salesforce/apex/AAREG_MyAgreementsController.getDecisionPDF';

jest.mock('@salesforce/apex/AAREG_MyAgreementsController.getUsersAgreements', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_MyAgreementsController.endAgreement', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_MyAgreementsController.getDecisionPDF', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock(
    'c/breadcrumbs',
    () => {
        const { LightningElement } = require('lwc');
        return { default: class Breadcrumbs extends LightningElement {} };
    },
    { virtual: true }
);
jest.mock(
    'c/aareg_mainBanner',
    () => {
        const { LightningElement } = require('lwc');
        return { default: class MainBanner extends LightningElement {} };
    },
    { virtual: true }
);
jest.mock(
    'c/aareg_modal',
    () => {
        const { LightningElement } = require('lwc');
        return { default: class Modal extends LightningElement {} };
    },
    { virtual: true }
);
describe('c-aareg-my-agreements', () => {
    afterEach(() => {
        jest.clearAllMocks();
    });

    it('keeps download disabled when PDF is missing or lookup fails, and for ended agreements', async () => {
        getDecisionPDF.mockImplementation(({ agreementId }) => {
            if (agreementId === 'missingPdf') {
                return Promise.resolve(null);
            }
            if (agreementId === 'pdfLookupFails') {
                return Promise.reject(new Error('lookup failed'));
            }
            return Promise.resolve('/sfc/example.pdf');
        });

        const context = {
            selectedStatusFilter: 'Aktiv',
            statusFilterOptions: [],
            agreements: [],
            updateStatusFilterOptions: Aareg_myAgreements.prototype.updateStatusFilterOptions
        };

        await Aareg_myAgreements.prototype.processAgreements.call(context, [
            { avtaleId: 'missingPdf', avtaleNummer: 'A1', status: 'Aktiv' },
            { avtaleId: 'pdfLookupFails', avtaleNummer: 'A2', status: 'Aktiv' },
            { avtaleId: 'endedWithPdf', avtaleNummer: 'A3', status: 'Avsluttet' }
        ]);

        const agreementById = new Map(context.agreements.map((agreement) => [agreement.avtaleId, agreement]));
        expect(agreementById.get('missingPdf').disableDownloadDecision).toBe(true);
        expect(agreementById.get('pdfLookupFails').disableDownloadDecision).toBe(true);
        expect(agreementById.get('endedWithPdf').disableDownloadDecision).toBe(true);
    });
});
