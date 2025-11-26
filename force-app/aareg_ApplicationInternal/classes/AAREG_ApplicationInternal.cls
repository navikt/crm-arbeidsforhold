public class AAREG_ApplicationInternal{
  /*
    * wrapperclass used by AAREG_ApplicationInternalController to send data to LWC
    **/
   @AuraEnabled public String SoknadsId{get;set;}
   @AuraEnabled public String SoknadsNavn{get;set;}
   @AuraEnabled public Boolean APITilgang{get;set;}
   @AuraEnabled public Boolean Uttrekk{get;set;}
   @AuraEnabled public Boolean WebTilgang{get;set;}
   @AuraEnabled public String KonsumentId{get;set;}
   @AuraEnabled public String KonsumentNavn{get;set;}
   @AuraEnabled public String KonsumentKontaktNavn{get;set;}
   @AuraEnabled public String KonsumentOrganisasjonsnummer{get;set;}
   @AuraEnabled public String KonsumentAdresse{get;set;}
   @AuraEnabled public String KonsumentPoststed{get;set;}
   @AuraEnabled public String KonsumentPostnummer{get;set;}
   @AuraEnabled public String KonsumentEpost{get;set;}
   @AuraEnabled public String OrganisasjonsType{get;set;}
   @AuraEnabled public Date SoknadLevert{get;set;} 
   @AuraEnabled public Date Svarfrist{get;set;}
   @AuraEnabled public Boolean Vilkaar{get;set;}
   @AuraEnabled public String DatabehandlerNavn{get;set;}
   @AuraEnabled public String DatabehandlerOrganisasjonsnummer{get;set;}
   
 }