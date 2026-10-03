/**
 * Domain service skeleton for Agreement-related Aa-registeret archive data.
 * Must not know about P360 DTOs or transport details.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group AAREG P360 Domain
 */
public with sharing class AAREG_AgreementDomainService {
    /**
     * Loads and validates Agreement data needed by the archive use case.
     *
     * @param agreementId Salesforce Agreement record id.
     * @return Typed internal Agreement archive context.
     * @throws P360_ContractException When the agreement id is missing or no Agreement exists.
     */
    public AAREG_AgreementArchiveContext getAgreementArchiveContext(Id agreementId) {
        if (agreementId == null) {
            throw new P360_ContractException('Agreement id is required.');
        }

        List<Agreement__c> agreements = [
            SELECT Id
            FROM Agreement__c
            WHERE Id = :agreementId
            LIMIT 1
        ];
        if (agreements.isEmpty()) {
            throw new P360_ContractException('Agreement was not found.');
        }

        AAREG_AgreementArchiveContext context = new AAREG_AgreementArchiveContext();
        context.agreementId = agreements[0].Id;
        return context;
    }
}
