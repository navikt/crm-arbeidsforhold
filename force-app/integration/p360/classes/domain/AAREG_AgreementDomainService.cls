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
     * @return Temporary domain context placeholder. TODO F3: Replace Object with typed context.
     * @throws P360_ContractException Until implementation is completed.
     */
    public Object getAgreementArchiveContext(Id agreementId) {
        throw new P360_ContractException(
            'AAREG_AgreementDomainService.getAgreementArchiveContext is not implemented yet. TODO F3.'
        );
    }
}
