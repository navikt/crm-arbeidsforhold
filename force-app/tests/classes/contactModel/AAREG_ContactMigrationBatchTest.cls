/**
 * Tests the contact model migration modes PLAN, APPLY, VERIFY and ROLLBACK.
 *
 * Most tests run the batch phases inline so several modes can be checked in one transaction.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 */
@IsTest
private class AAREG_ContactMigrationBatchTest {
    @IsTest
    static void planClassifiesAndChangesNothing() {
        Fixture fixture = new Fixture();

        Id runId = runInline(AAREG_ContactMigrationBatch.MODE_PLAN, null);

        AAREG_Contact_Migration_Run__c run = getRun(runId);
        System.Assert.areEqual('Completed', run.Status__c, run.Summary__c);
        System.Assert.areEqual(1, run.Class_A__c, 'One safe application');
        System.Assert.areEqual(1, run.Class_B__c, 'One internal application');
        System.Assert.areEqual(0, run.Linked__c, 'PLAN links nothing');
        System.Assert.areEqual(0, countDomainContacts(), 'No contacts created');
        System.Assert.areEqual(
            AAREG_ContactMigrationClassifier.CLASS_A,
            getItem(runId, fixture.safe.Id).Class__c,
            'Item per application'
        );
    }

    @IsTest
    static void applyLinksOnlyClassAAndRecordsWhatItCreated() {
        Fixture fixture = new Fixture();

        Id runId = runInline(AAREG_ContactMigrationBatch.MODE_APPLY, null);

        AAREG_Contact_Migration_Item__c safeItem = getItem(runId, fixture.safe.Id);
        System.Assert.areEqual('Linked', safeItem.Action__c, safeItem.Reason__c);
        AAREG_ContactMigrationBatch.CreatedRecords created = (AAREG_ContactMigrationBatch.CreatedRecords) JSON.deserialize(
            safeItem.Created_Records__c,
            AAREG_ContactMigrationBatch.CreatedRecords.class
        );
        System.Assert.areEqual(1, created.contacts.size(), 'Contact recorded');
        System.Assert.areEqual(1, created.relations.size(), 'Relation recorded');
        System.Assert.areEqual(1, created.contactPoints.size(), 'Contact point recorded');
        System.Assert.areEqual(1, created.participations.size(), 'Participation recorded');
        System.Assert.isNotNull(safeItem.Backup__c, 'Backup written');

        System.Assert.areEqual('None', getItem(runId, fixture.internal.Id).Action__c, 'Class B untouched');
        System.Assert.areEqual(
            1,
            [
                SELECT COUNT()
                FROM RelatedContact__c
                WHERE Application__c = :fixture.safe.Id AND Role__c = :AAREG_ContactModelService.ROLE_SUBMITTER
                WITH SYSTEM_MODE
            ],
            'Submitter linked'
        );
        System.Assert.areEqual(
            0,
            [SELECT COUNT() FROM RelatedContact__c WHERE Application__c = :fixture.internal.Id WITH SYSTEM_MODE],
            'Class B gets no participation'
        );
        System.Assert.areEqual(1, getRun(runId).Linked__c, 'Count of linked');
    }

    @IsTest
    static void verifyConfirmsAppliedLinks() {
        new Fixture();
        Id applyRunId = runInline(AAREG_ContactMigrationBatch.MODE_APPLY, null);

        Id verifyRunId = runInline(AAREG_ContactMigrationBatch.MODE_VERIFY, applyRunId);

        AAREG_Contact_Migration_Run__c run = getRun(verifyRunId);
        System.Assert.areEqual(1, run.Total__c, 'Verifies the linked item only');
        System.Assert.areEqual(0, run.Deviations__c, run.Summary__c);
    }

    @IsTest
    static void verifyReportsDeviationWhenLinkIsGone() {
        Fixture fixture = new Fixture();
        Id applyRunId = runInline(AAREG_ContactMigrationBatch.MODE_APPLY, null);
        delete as system [SELECT Id FROM RelatedContact__c WHERE Application__c = :fixture.safe.Id WITH SYSTEM_MODE];

        Id verifyRunId = runInline(AAREG_ContactMigrationBatch.MODE_VERIFY, applyRunId);

        System.Assert.areEqual(1, getRun(verifyRunId).Deviations__c, 'Missing participation is a deviation');
    }

    @IsTest
    static void rollbackRemovesEverythingApplyCreated() {
        Fixture fixture = new Fixture();
        Id applyRunId = runInline(AAREG_ContactMigrationBatch.MODE_APPLY, null);

        Id rollbackRunId = runInline(AAREG_ContactMigrationBatch.MODE_ROLLBACK, applyRunId);

        System.Assert.areEqual(0, countDomainContacts(), 'Contact removed');
        System.Assert.areEqual(
            0,
            [SELECT COUNT() FROM AccountContactRelation WHERE AAREG_Managed__c = TRUE WITH SYSTEM_MODE],
            'Relation removed'
        );
        System.Assert.areEqual(
            0,
            [SELECT COUNT() FROM AAREG_Contact_Point__c WITH SYSTEM_MODE],
            'Contact points removed'
        );
        System.Assert.areEqual(
            0,
            [SELECT COUNT() FROM RelatedContact__c WHERE Application__c = :fixture.safe.Id WITH SYSTEM_MODE],
            'Participation removed'
        );
        System.Assert.areEqual('Rolled Back', getItem(applyRunId, fixture.safe.Id).Action__c, 'Source item marked');
        System.Assert.areEqual(1, getRun(rollbackRunId).Rolled_Back__c, 'Rollback counted');
    }

    @IsTest
    static void rollbackKeepsContactUsedElsewhere() {
        Fixture fixture = new Fixture();
        Id applyRunId = runInline(AAREG_ContactMigrationBatch.MODE_APPLY, null);
        Account other = AAREG_ContactModelTestDataFactory.createOrganization('Seinare AS');
        Application__c later = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            fixture.portalUser,
            other,
            'kari@seinare.example'
        );
        AAREG_ContactModelService.recordSubmissions(new Map<Id, Id>{ later.Id => fixture.portalUser.Id });

        runInline(AAREG_ContactMigrationBatch.MODE_ROLLBACK, applyRunId);

        System.Assert.areEqual(1, countDomainContacts(), 'Contact still used by a later submission');
        System.Assert.areEqual(
            1,
            [SELECT COUNT() FROM RelatedContact__c WHERE Application__c = :later.Id WITH SYSTEM_MODE],
            'Later participation kept'
        );
    }

    @IsTest
    static void startRunExecutesAsBatch() {
        new Fixture();
        AAREG_ContactMigrationBatch.bypassPermissionCheck = true;

        System.Test.startTest();
        Id runId = AAREG_ContactMigrationBatch.startRun(AAREG_ContactMigrationBatch.MODE_PLAN, null);
        System.Test.stopTest();

        AAREG_Contact_Migration_Run__c run = getRun(runId);
        System.Assert.areEqual('Completed', run.Status__c, run.Summary__c);
        System.Assert.areEqual(2, run.Total__c, 'Both submitted applications');
        System.Assert.isNotNull(run.Batch_Job_Id__c, 'Job recorded');
    }

    @IsTest
    static void startRunRequiresMigratePermission() {
        User reader = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Utan', null);

        System.Test.startTest();
        System.runAs(reader) {
            assertRejected(AAREG_ContactMigrationBatch.MODE_PLAN, null, 'AAREG_ContactModelMigrate');
        }
        System.Test.stopTest();
    }

    @IsTest
    static void startRunRejectsConcurrentRunsAndBadSources() {
        AAREG_ContactMigrationBatch.bypassPermissionCheck = true;
        AAREG_Contact_Migration_Run__c plan = new AAREG_Contact_Migration_Run__c(
            Mode__c = 'PLAN',
            Status__c = 'Completed'
        );
        insert as system plan;

        System.Test.startTest();
        assertRejected('DELETE', null, 'Ukjend modus');
        assertRejected(AAREG_ContactMigrationBatch.MODE_ROLLBACK, plan.Id, 'APPLY');
        insert as system new AAREG_Contact_Migration_Run__c(Mode__c = 'PLAN', Status__c = 'Running');
        assertRejected(AAREG_ContactMigrationBatch.MODE_PLAN, null, 'i gang');
        System.Test.stopTest();
    }

    private class Fixture {
        User portalUser;
        Application__c safe;
        Application__c internal;

        Fixture() {
            AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
            Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Migrering AS');
            portalUser = AAREG_ContactModelTestDataFactory.createPortalUser('Migrering', 'synthM');
            safe = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
                portalUser,
                organization,
                'kari@migrering.example'
            );
            internal = new Application__c(
                Account__c = organization.Id,
                Email__c = 'intern@migrering.example',
                Casehandler_Status__c = 'New'
            );
            insert as system internal;
        }
    }

    private static Id runInline(String mode, Id sourceRunId) {
        AAREG_Contact_Migration_Run__c run = new AAREG_Contact_Migration_Run__c(
            Mode__c = mode,
            Status__c = 'Queued',
            Source_Run__c = sourceRunId
        );
        insert as system run;
        AAREG_ContactMigrationBatch batch = new AAREG_ContactMigrationBatch(run.Id, mode, sourceRunId);
        List<SObject> scope = mode == AAREG_ContactMigrationBatch.MODE_PLAN ||
            mode == AAREG_ContactMigrationBatch.MODE_APPLY
            ? (List<SObject>) new List<Application__c>()
            : (List<SObject>) new List<AAREG_Contact_Migration_Item__c>();
        Database.QueryLocatorIterator records = batch.start(null).iterator();
        while (records.hasNext()) {
            scope.add(records.next());
        }
        if (!scope.isEmpty()) {
            batch.execute(null, scope);
        }
        batch.finish(null);
        return run.Id;
    }

    private static void assertRejected(String mode, Id sourceRunId, String expectedMessage) {
        try {
            AAREG_ContactMigrationBatch.startRun(mode, sourceRunId);
            System.Assert.fail('Expected rejection: ' + expectedMessage);
        } catch (AAREG_ContactMigrationBatch.MigrationException error) {
            System.Assert.isTrue(error.getMessage().contains(expectedMessage), error.getMessage());
        }
    }

    private static AAREG_Contact_Migration_Run__c getRun(Id runId) {
        return [
            SELECT
                Status__c,
                Summary__c,
                Total__c,
                Class_A__c,
                Class_B__c,
                Linked__c,
                Deviations__c,
                Rolled_Back__c,
                Batch_Job_Id__c
            FROM AAREG_Contact_Migration_Run__c
            WHERE Id = :runId
            WITH SYSTEM_MODE
        ];
    }

    private static AAREG_Contact_Migration_Item__c getItem(Id runId, Id applicationId) {
        return [
            SELECT Class__c, Action__c, Reason__c, Backup__c, Created_Records__c
            FROM AAREG_Contact_Migration_Item__c
            WHERE Run__c = :runId AND Application__c = :applicationId
            WITH SYSTEM_MODE
        ];
    }

    private static Integer countDomainContacts() {
        return [SELECT COUNT() FROM Contact WHERE AAREG_Identity_Key__c != NULL WITH SYSTEM_MODE];
    }
}
