/**
 * Tests classification of submitted applications into migration classes A to E.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 */
@IsTest
private class AAREG_ContactMigrationClassifierTest {
    @IsTest
    static void portalSubmissionWithUniqueAddressIsSafe() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Trygg AS');
        User portalUser = AAREG_ContactModelTestDataFactory.createPortalUser('Trygg', 'synthA');
        Application__c application = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            portalUser,
            organization,
            'kari@trygg.example'
        );

        AAREG_ContactMigrationClassifier.Result result = classify(application.Id);

        System.Assert.areEqual(AAREG_ContactMigrationClassifier.CLASS_A, result.migrationClass, result.reason);
        System.Assert.areEqual(portalUser.Id, result.submitterUserId, 'Submitter is the portal user');
    }

    @IsTest
    static void internallyCreatedApplicationHasNoReliableSubmitter() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Intern AS');
        Application__c application = AAREG_ContactModelTestDataFactory.createApplication(
            organization,
            'x@intern.example'
        );

        AAREG_ContactMigrationClassifier.Result result = classify(application.Id);

        System.Assert.areEqual(AAREG_ContactMigrationClassifier.CLASS_B, result.migrationClass, result.reason);
        System.Assert.isNull(result.submitterUserId, 'No submitter');
    }

    @IsTest
    static void applicationWithoutOrganizationIsNotLinked() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        User portalUser = AAREG_ContactModelTestDataFactory.createPortalUser('Utan', 'synthB');
        Application__c application = new Application__c(Email__c = 'utan@example.com', Casehandler_Status__c = 'New');
        System.runAs(portalUser) {
            insert as system application;
        }

        System.Assert.areEqual(
            AAREG_ContactMigrationClassifier.CLASS_B,
            classify(application.Id).migrationClass,
            'Missing organization is class B'
        );
    }

    @IsTest
    static void sharedAddressNeedsManualReview() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Delt AS');
        User first = AAREG_ContactModelTestDataFactory.createPortalUser('Første', 'synthC1');
        User second = AAREG_ContactModelTestDataFactory.createPortalUser('Andre', 'synthC2');
        Application__c application = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            first,
            organization,
            'post@delt.example'
        );
        AAREG_ContactModelTestDataFactory.createSubmittedApplication(second, organization, 'POST@delt.example');

        System.Assert.areEqual(
            AAREG_ContactMigrationClassifier.CLASS_C,
            classify(application.Id).migrationClass,
            'Shared mailbox is class C, case-insensitive'
        );
    }

    @IsTest
    static void shieldedPersonIsNeverLinkedAutomatically() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Skjerma AS');
        User portalUser = AAREG_ContactModelTestDataFactory.createPortalUser('Skjerma', 'synthD');
        AAREG_ContactModelTestDataFactory.shieldPerson(portalUser);
        Application__c application = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            portalUser,
            organization,
            'skjerma@example.com'
        );

        System.Assert.areEqual(
            AAREG_ContactMigrationClassifier.CLASS_D,
            classify(application.Id).migrationClass,
            'Shielded person is class D'
        );
    }

    @IsTest
    static void existingLinkToAnotherContactIsAConflict() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Konflikt AS');
        User portalUser = AAREG_ContactModelTestDataFactory.createPortalUser('Konflikt', 'synthE');
        Application__c application = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            portalUser,
            organization,
            'konflikt@example.com'
        );
        Contact other = new Contact(LastName = 'Annan', AccountId = organization.Id);
        insert as system other;
        insert as system new RelatedContact__c(
            Application__c = application.Id,
            Contact__c = other.Id,
            Role__c = AAREG_ContactModelService.ROLE_SUBMITTER
        );

        System.Assert.areEqual(
            AAREG_ContactMigrationClassifier.CLASS_E,
            classify(application.Id).migrationClass,
            'Conflicting submitter is class E'
        );
    }

    @IsTest
    static void minimumAccessUserCanClassifyWithoutWriting() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Les AS');
        Application__c application = AAREG_ContactModelTestDataFactory.createApplication(
            organization,
            'les@example.com'
        );
        List<Application__c> applications = query(application.Id);
        User reader = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Lesar', null);

        Map<Id, AAREG_ContactMigrationClassifier.Result> results;
        System.Test.startTest();
        System.runAs(reader) {
            results = AAREG_ContactMigrationClassifier.classify(applications);
        }
        System.Test.stopTest();

        System.Assert.areEqual(1, results.size(), 'One result');
        System.Assert.areEqual(
            0,
            [SELECT COUNT() FROM Contact WHERE AAREG_Identity_Key__c != NULL WITH SYSTEM_MODE],
            'No writes'
        );
    }

    private static AAREG_ContactMigrationClassifier.Result classify(Id applicationId) {
        System.Test.startTest();
        Map<Id, AAREG_ContactMigrationClassifier.Result> results = AAREG_ContactMigrationClassifier.classify(
            query(applicationId)
        );
        System.Test.stopTest();
        return results.get(applicationId);
    }

    private static List<Application__c> query(Id applicationId) {
        return [
            SELECT Id, Account__c, Email__c, CreatedById, CreatedBy.ContactId
            FROM Application__c
            WHERE Id = :applicationId
            WITH SYSTEM_MODE
        ];
    }
}
