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
     * @return Typed internal Application archive context.
     * @throws P360_ContractException When the application id is missing or no Application exists.
     */
    public AAREG_ApplicationArchiveContext getApplicationArchiveContext(Id applicationId) {
        if (applicationId == null) {
            throw new P360_ContractException('Application id is required.');
        }

        List<Application__c> applications = [
            SELECT Id
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];
        if (applications.isEmpty()) {
            throw new P360_ContractException('Application was not found.');
        }

        Application__c application = applications[0];
        AAREG_ApplicationArchiveContext context = new AAREG_ApplicationArchiveContext();
        context.applicationId = application.Id;
        return context;
    }
}
