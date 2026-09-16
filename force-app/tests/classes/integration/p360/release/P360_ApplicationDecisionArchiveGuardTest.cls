/**
 * Verifies the release permission and lock contract for P360 archive readiness.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Release Contract
 */
@IsTest
private class P360_ApplicationDecisionArchiveGuardTest {
    /**
     * Verifies that an authorized user can release a decision for archiving.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldAllowReleaseFlagToBeSetByAuthorizedUser() {
        User releaseUser = createReleaseUser();

        System.runAs(releaseUser) {
            Application_Decision__c decision = createDecision();
            update new Application_Decision__c(Id = decision.Id, Ready_For_P360_Archive__c = true);

            Application_Decision__c savedDecision = [
                SELECT Ready_For_P360_Archive__c
                FROM Application_Decision__c
                WHERE Id = :decision.Id
                LIMIT 1
            ];
            System.Assert.isTrue(
                savedDecision.Ready_For_P360_Archive__c,
                'Authorized release user must be able to set the release flag.'
            );
        }
    }

    /**
     * Verifies that a user without the release permission cannot release a decision.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldRejectReleaseFlagWhenUserLacksReleasePermission() {
        User standardUser = createStandardUser();

        System.runAs(standardUser) {
            Application_Decision__c decision = createDecision();
            try {
                update new Application_Decision__c(Id = decision.Id, Ready_For_P360_Archive__c = true);
                System.Assert.fail('User without release permission must not be able to set the release flag.');
            } catch (DmlException ex) {
                System.Assert.isTrue(
                    ex.getMessage().contains('Ready_For_P360_Archive__c'),
                    'Error should mention the release flag.'
                );
            }
        }
    }

    /**
     * Verifies that regular decision fields are locked after release.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldBlockRegularFieldChangesAfterRelease() {
        User releaseUser = createReleaseUser();

        System.runAs(releaseUser) {
            Application_Decision__c decision = createDecision();
            update new Application_Decision__c(Id = decision.Id, Ready_For_P360_Archive__c = true);

            Application_Decision__c toUpdate = [
                SELECT Id, Decision_description__c
                FROM Application_Decision__c
                WHERE Id = :decision.Id
                LIMIT 1
            ];
            toUpdate.Decision_description__c = 'Locked after release';

            try {
                update toUpdate;
                System.Assert.fail('Locked decision must reject regular field edits after release.');
            } catch (DmlException ex) {
                System.Assert.isTrue(
                    ex.getMessage().contains('lock') || ex.getMessage().contains('Ready_For_P360_Archive__c'),
                    'Lock violation should be surfaced to the caller.'
                );
            }
        }
    }

    /**
     * Verifies that the release signal cannot be reset after release.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldRejectResetAfterRelease() {
        User releaseUser = createReleaseUser();

        System.runAs(releaseUser) {
            Application_Decision__c decision = createDecision();
            update new Application_Decision__c(Id = decision.Id, Ready_For_P360_Archive__c = true);

            try {
                update new Application_Decision__c(Id = decision.Id, Ready_For_P360_Archive__c = false);
                System.Assert.fail('The release signal must not be reset.');
            } catch (DmlException error) {
                System.Assert.isTrue(error.getMessage().contains('one-way signal'));
            }
        }
    }

    /**
     * Verifies that P360 technical references remain writable after release.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldAllowTechnicalReferenceChangesAfterRelease() {
        User releaseUser = createReleaseProcessingUser();

        System.runAs(releaseUser) {
            Application_Decision__c decision = createDecision();
            update new Application_Decision__c(Id = decision.Id, Ready_For_P360_Archive__c = true);

            update new Application_Decision__c(
                Id = decision.Id,
                P360_Document_Id__c = 'document-id',
                P360_Document_Number__c = 'document-number',
                P360_File_Id__c = 'file-id'
            );

            Application_Decision__c savedDecision = [
                SELECT P360_Document_Id__c, P360_Document_Number__c, P360_File_Id__c
                FROM Application_Decision__c
                WHERE Id = :decision.Id
                LIMIT 1
            ];
            System.Assert.areEqual('document-id', savedDecision.P360_Document_Id__c);
            System.Assert.areEqual('document-number', savedDecision.P360_Document_Number__c);
            System.Assert.areEqual('file-id', savedDecision.P360_File_Id__c);
        }
    }

    /**
     * A released decision with an access request should create one idempotent document job.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldCreateDecisionDocumentJobAfterRelease() {
        User releaseUser = createReleaseProcessingUser();

        System.runAs(releaseUser) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            Application__c application = new Application__c(Access_Request__c = accessRequest.Id);
            insert application;
            Application_Decision__c decision = new Application_Decision__c(
                Application__c = application.Id,
                Decision_date__c = Date.today(),
                Decision_description__c = 'Approved for archive'
            );
            insert decision;

            System.Test.startTest();
            update new Application_Decision__c(Id = decision.Id, Ready_For_P360_Archive__c = true);
            System.Test.stopTest();

            P360_Archive_Job__c job = [
                SELECT Application_Decision__c, Access_Request__c, Archive_Event_Type__c, Status__c
                FROM P360_Archive_Job__c
                WHERE Application_Decision__c = :decision.Id
                LIMIT 1
            ];
            System.Assert.areEqual(decision.Id, job.Application_Decision__c);
            System.Assert.areEqual(accessRequest.Id, job.Access_Request__c);
            System.Assert.areEqual('DecisionDocument', job.Archive_Event_Type__c);
            System.Assert.areEqual('Pending', job.Status__c);
        }
    }

    private static User createReleaseUser() {
        User userRecord;
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            userRecord = P360_TestDataFactory.createMinimumAccessUser();
            grantDecisionAccess(userRecord);
            grantReleasePermission(userRecord);
            AAREG_TestDataFactory.assignPermissionSet(userRecord.Id, 'P360_Archive_Job_Processing');
        }

        return userRecord;
    }

    private static User createStandardUser() {
        User userRecord;
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            userRecord = P360_TestDataFactory.createMinimumAccessUser();
            grantDecisionAccess(userRecord);
        }
        return userRecord;
    }

    private static User createReleaseProcessingUser() {
        User userRecord;
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            userRecord = P360_TestDataFactory.createMinimumAccessUser();
            grantDecisionAccess(userRecord);
            grantReleasePermission(userRecord);
            AAREG_TestDataFactory.assignPermissionSet(userRecord.Id, 'P360_Archive_Job_Processing');
        }
        return userRecord;
    }

    private static void grantDecisionAccess(User userRecord) {
        AAREG_TestDataFactory.assignPermissionSet(userRecord.Id, 'AAREG_Arbeidsforhold_Saksbehandling');
    }

    private static void grantReleasePermission(User userRecord) {
        AAREG_TestDataFactory.assignPermissionSet(userRecord.Id, 'P360_Archive_Release');
    }

    private static Application__c createApplication() {
        Access_Request__c accessRequest = new Access_Request__c();
        insert accessRequest;
        Application__c application = new Application__c(Access_Request__c = accessRequest.Id);
        insert application;
        return application;
    }

    private static Application_Decision__c createDecision() {
        Application_Decision__c decision = new Application_Decision__c(
            Application__c = createApplication().Id,
            Decision_date__c = Date.today(),
            Decision_description__c = 'Approved for archive'
        );
        insert decision;
        return decision;
    }
}
