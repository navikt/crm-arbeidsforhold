public with sharing class AAREG_ApplicationDecisionController {
    @AuraEnabled
    public static List<AAREG_ApplicationDecision> getApplicationDecision(Id recordId) {
      List<AAREG_ApplicationDecision> decisionWrapperTempList = new List<AAREG_ApplicationDecision>();
     
      List<Application_Decision__c> decision = [
            SELECT Id, Name, CreatedDate, Application__c,Status__c 
            FROM Application_Decision__c
            WHERE Application__c = :recordId
            LIMIT 1
        ];
    
        if (decision != null) {
            for(Application_Decision__c app : decision){
                AAREG_ApplicationDecision tempList = new AAREG_ApplicationDecision();
                templist.VedtaksNr = app.Name;
                tempList.VedtaksId = app.Id;
                tempList.Status = app.Status__c;
                tempList.SoknadsId = app.Application__c;
                decisionWrapperTempList.add(tempList);
            }
        }
    
       
      return decisionWrapperTempList;
      }
    
}