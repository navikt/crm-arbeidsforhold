/**
 * 
 *
 * @param  RecordId from Application__c
 * @return List over codes related to application
 */


public class AAREG_CodeBaseListController {
@AuraEnabled
    public static List < ApplicationBasisCode__c > getCodeBaseList(Id recordId) {
        List<ApplicationBasisCode__c>codeList =[ SELECT Id, Name, Application__c,DecisionBasis__c, LegalBasisCounty__c, LegalBasisElectricitySupervision__c, LegalBasisMunicipality__c, LegalBasisPension__c, LegalBasisStateBusiness__c, LegalBasisStateGeneral__c, LegalBasisStateHealthAndSocial__c, LegalBasisStateLegal__c, LegalBasisStateMilitary__c, LegalBasisStateResearch__c, OrganizationType__c, OtherLegalBasis__c, OtherPurpose__c, PurposeCounty__c, PurposeElectricitySupervision__c, PurposeMunicipality__c, PurposePension__c, PurposeStateBusiness__c, PurposeStateGeneral__c, PurposeStateHealthAndSocial__c, PurposeStateLegal__c, PurposeStateMilitary__c, PurposeStateResearch__c  FROM ApplicationBasisCode__c WHERE Application__c=:recordId ];
        return codeList;

    }
}