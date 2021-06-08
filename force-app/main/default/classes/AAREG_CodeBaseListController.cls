public with sharing class AAREG_CodeBaseListController {
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
        PurposeState__c
      FROM ApplicationBasisCode__c
      WHERE Application__c = :recordId
    ];
    return codes;    
  }
}