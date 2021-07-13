public with sharing class AAREG_MyApplicationsController {
    @AuraEnabled(cacheable=true)
    public static List<Application__c> getUsersApplications(String userId) {
        String lastUsedOrganiation = [SELECT Id, lastUsedOrganization__c FROM User WHERE ID = :userid]
        .LastUsedOrganization__c;
        return [
            SELECT Id, Name, toLabel(Status__c), ApplicationSubmittedDate__c
            FROM Application__c
            WHERE OrganizationNumber__c = :lastUsedOrganiation
        ];
    }
}
