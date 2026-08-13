public with sharing class AAREG_AccessRequestTasksController {
    @AuraEnabled(cacheable=true)
    public static List<Task> getTasks(Id accessRequestId) {
        if (accessRequestId == null) {
            return new List<Task>();
        }

        if (!Schema.sObjectType.Task.isAccessible()) {
            throw new AuraHandledException('Du har ikke tilgang til Task.');
        }

        return [
            SELECT Id, Subject, Description, Type, AAREG_AccessRequest__c, CreatedDate
            FROM Task
            WHERE AAREG_AccessRequest__c = :accessRequestId
            ORDER BY CreatedDate DESC
        ];
    }
}