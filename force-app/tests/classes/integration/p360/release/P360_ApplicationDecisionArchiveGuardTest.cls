/**
 * Verifies the release permission and lock contract for P360 archive readiness.
 *
 * @since 2026-09
 * @group P360 Release Contract
 */
@IsTest
private class P360_ApplicationDecisionArchiveGuardTest {
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
