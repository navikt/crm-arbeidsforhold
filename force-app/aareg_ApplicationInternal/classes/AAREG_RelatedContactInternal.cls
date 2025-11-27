public with sharing class AAREG_RelatedContactInternal {
    /*
     * wrapperclass used by AAREG_ApplicationInternalController to send data to LWC
     **/
  @AuraEnabled public String KontaktId{get;set;}
  @AuraEnabled public String KontaktNavn{get;set;}
  @AuraEnabled public String KontaktEpost{get;set;}
  @AuraEnabled public String KontaktTelefon{get;set;}
  @AuraEnabled public Boolean AvtaleVarsel{get;set;}
  @AuraEnabled public Boolean EndringsVarsel{get;set;}
  @AuraEnabled public Boolean FeilmeldingsVarsel{get;set;}
  @AuraEnabled public Boolean SikkerhetsVarsel{get;set;}
  @AuraEnabled public String SoknadsId{get;set;}
}