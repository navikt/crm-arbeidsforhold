/**
 * Provides the legal basis and access-type codes for an Aa-registeret application,
 * used to populate the code base list on the application record page.
 *
 * @author Ann Kristin Olsen
 * @author Jordan Mathews
 * @since May 2021
 * @group AAREG Code Base List
 */
public with sharing class AAREG_CodeBaseListController {
    /**
     * Retrieves the application basis codes linked to the given application record.
     *
     * @param recordId Id of the Application record whose basis codes should be retrieved.
     * @return The ApplicationBasisCode__c records for the application. Empty if none exist.
     */
    @AuraEnabled
    public static List<ApplicationBasisCode__c> getCodeBaseList(Id recordId) {
        List<ApplicationBasisCode__c> codes = [
            SELECT
                Id,
                Name,
                Application__c,
                ProcessingBasis__c,
                LegalBasisCounty__c,
                LegalBasisElectricitySupervision__c,
                LegalBasisMunicipality__c,
                LegalBasisPension__c,
                LegalBasisState__c,
                OrganizationType__c,
                OtherLegalBasis__c,
                OtherPurpose__c,
                PurposeCounty__c,
                PurposeElectricitySupervision__c,
                PurposeMunicipality__c,
                PurposePension__c,
                PurposeState__c,
                Extraction_Access__c,
                Online_Access__c,
                API_Access__c
            FROM ApplicationBasisCode__c
            WHERE Application__c = :recordId
        ];
        return codes;
    }
}
