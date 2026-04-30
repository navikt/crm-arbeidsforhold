/**
 * Domain service skeleton for Application-related Aa-registeret archive data.
 * Must not know about P360 DTOs or transport details.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group AAREG P360 Domain
 */
public with sharing class AAREG_ApplicationDomainService {
    /**
     * Loads and validates Application data needed by the archive use case.
     *
     * @param applicationId Salesforce Application record id.
     * @return Temporary domain context placeholder. TODO F3: Replace Object with typed context.
     * @throws P360_ContractException Until implementation is completed.
     */
    public Object getApplicationArchiveContext(Id applicationId) {
        throw new P360_ContractException(
            'AAREG_ApplicationDomainService.getApplicationArchiveContext is not implemented yet. TODO F3.'
        );
    }
}
