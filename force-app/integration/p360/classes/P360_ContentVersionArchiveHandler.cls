/**
 * @description Creates P360 attachment jobs for new ContentVersion records published to applications.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Archive Job
 */
public with sharing class P360_ContentVersionArchiveHandler {
    /**
     * @description Creates one idempotent attachment job per application-linked ContentVersion.
     *
     * @param versions Newly inserted ContentVersion records.
     */
    public static void afterInsert(List<ContentVersion> versions) {
        Map<Id, ContentVersion> applicationVersionsById = new Map<Id, ContentVersion>();
        Set<Id> applicationIds = new Set<Id>();
        for (ContentVersion version : versions) {
            if (version.FirstPublishLocationId == null) {
                continue;
            }
            if (version.FirstPublishLocationId.getSObjectType() != Application__c.SObjectType) {
                continue;
            }
            applicationVersionsById.put(version.Id, version);
            applicationIds.add(version.FirstPublishLocationId);
        }

        if (applicationIds.isEmpty()) {
            return;
        }

        Map<Id, Application__c> applicationsById = new Map<Id, Application__c>(
            [
                SELECT Id, Access_Request__c
                FROM Application__c
                WHERE Id IN :applicationIds
            ]
        );
        for (ContentVersion version : applicationVersionsById.values()) {
            Application__c application = applicationsById.get(version.FirstPublishLocationId);
            if (application?.Access_Request__c == null) {
                continue;
            }
            P360_ArchiveJobService.getOrCreateApplicationAttachmentJob(
                application.Access_Request__c,
                application.Id,
                version.Id,
                'ApplicationAttachment:' + version.Id
            );
        }
    }
}
