/**
 * Verifies the metadata contract for asynchronous P360 archive jobs.
 *
 * @since 2026-09
 * @group P360 Archive Job
 */
@IsTest
private class P360_ArchiveJobMetadataTest {
    @IsTest
    static void archiveJobExposesRequiredContractFields() {
        User minimumAccessUser = createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            Schema.SObjectType archiveJobType = Schema.getGlobalDescribe().get('P360_Archive_Job__c');
            System.Assert.isNotNull(archiveJobType, 'The P360 archive job object must exist.');

            Map<String, Schema.SObjectField> fields = archiveJobType.getDescribe().fields.getMap();
            for (
                String fieldName : new List<String>{
                    'Access_Request__c',
                    'Archive_Event_Type__c',
                    'Status__c',
                    'Idempotency_Key__c',
                    'Correlation_Id__c'
                }
            ) {
                System.Assert.isTrue(fields.containsKey(fieldName), 'Missing required archive job field: ' + fieldName);
            }

            System.Assert.areEqual(
                Schema.DisplayType.REFERENCE,
                fields.get('Access_Request__c').getDescribe().getType(),
                'Access_Request__c must be a lookup field.'
            );
            System.Assert.isTrue(
                fields.get('Idempotency_Key__c').getDescribe().isUnique(),
                'Idempotency_Key__c must be unique.'
            );

            assertFieldsExist('Access_Request__c', new List<String>{ 'P360_Case_Id__c', 'P360_Case_Number__c' });
            assertFieldsExist(
                'Application__c',
                new List<String>{ 'P360_Document_Id__c', 'P360_Document_Number__c', 'P360_File_Id__c' }
            );
            assertFieldsExist(
                'Application_Decision__c',
                new List<String>{ 'P360_Document_Id__c', 'P360_Document_Number__c', 'P360_File_Id__c' }
            );
            assertFieldsExist(
                'Agreement__c',
                new List<String>{ 'P360_Document_Id__c', 'P360_Document_Number__c', 'P360_File_Id__c' }
            );
        }
    }

    private static void assertFieldsExist(String objectName, List<String> fieldNames) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        System.Assert.isNotNull(objectType, 'The object must exist: ' + objectName);

        Map<String, Schema.SObjectField> fields = objectType.getDescribe().fields.getMap();
        for (String fieldName : fieldNames) {
            System.Assert.isTrue(
                fields.containsKey(fieldName),
                'Missing P360 reference field ' + objectName + '.' + fieldName
            );
        }
    }

    private static User createMinimumAccessUser() {
        Profile minimumAccessProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - Salesforce'
            LIMIT 1
        ];

        User minimumAccessUser = new User(
            FirstName = 'P360',
            LastName = 'Archive Job Tester',
            Email = 'p360.archive.job@example.com',
            Username = 'p360.archive.job.' + System.currentTimeMillis() + '@example.com',
            Alias = 'p360job',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Oslo',
            EmailEncodingKey = 'UTF-8',
            ProfileId = minimumAccessProfile.Id
        );

        insert minimumAccessUser;
        return minimumAccessUser;
    }
}
