/**
 * Provides the case handler Tasks linked to an access request record.
 *
 * @author Ann Kristin Olsen
 * @since August 2026
 * @group AAREG Internal Application
 */
public with sharing class AAREG_AccessRequestTasksController {
    /**
     * Retrieves the Tasks linked to the given access request, newest first. Result is
     * cacheable (`cacheable=true`); the calling LWC must invoke `refreshApex()` to
     * force a refresh after the underlying data changes.
     *
     * @param accessRequestId Id of the access request record. Returns an empty list if null.
     * @return The linked Task records, ordered by creation date descending.
     * @throws AuraHandledException If the running user cannot access the Task object.
     */
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
