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
        Application__c application = createApplication();

        Application_Decision__c decision = new Application_Decision__c(
            Application__c = application.Id,
            Decision_date__c = Date.today(),
            Agreement__c = null,
            Decision_description__c = 'Approved for archive'
        );
        insert decision;

        System.runAs(releaseUser) {
            decision.Ready_For_P360_Archive__c = true;
            update decision;

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
        User standardUser = P360_TestDataFactory.createMinimumAccessUser();
        grantDecisionAccess(standardUser);
        Application__c application = createApplication();

        Application_Decision__c decision = new Application_Decision__c(
            Application__c = application.Id,
            Decision_date__c = Date.today(),
            Decision_description__c = 'Approved for archive'
        );
        insert decision;

        System.runAs(standardUser) {
            decision.Ready_For_P360_Archive__c = true;
            try {
                update decision;
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
        Application__c application = createApplication();

        Application_Decision__c decision = new Application_Decision__c(
            Application__c = application.Id,
            Decision_date__c = Date.today(),
            Decision_description__c = 'Approved for archive'
        );
        insert decision;

        System.runAs(releaseUser) {
            decision.Ready_For_P360_Archive__c = true;
            update decision;
        }

        User standardUser = P360_TestDataFactory.createMinimumAccessUser();
        grantDecisionAccess(standardUser);
        System.runAs(standardUser) {
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
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - Salesforce'
            LIMIT 1
        ];

        User userRecord = new User(
            FirstName = 'P360',
            LastName = 'Release',
            Email = 'p360.release@example.com',
            Username = 'p360.release.' + System.currentTimeMillis() + '@example.com',
            Alias = 'p360rel',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Oslo',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id
        );
        insert userRecord;

        grantDecisionAccess(userRecord);
        grantReleasePermission(userRecord);

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
}
