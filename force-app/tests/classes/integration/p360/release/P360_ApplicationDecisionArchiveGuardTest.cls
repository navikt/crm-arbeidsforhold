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

    private static User createReleaseUser() {
        User userRecord;
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            userRecord = P360_TestDataFactory.createMinimumAccessUser();
            grantDecisionAccess(userRecord);
            grantReleasePermission(userRecord);
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
        Application__c application = new Application__c();
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
