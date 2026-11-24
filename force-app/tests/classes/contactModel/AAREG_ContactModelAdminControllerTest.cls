/**
 * Tests the administration controller for the Aa-register contact model.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 */
@IsTest
private class AAREG_ContactModelAdminControllerTest {
    private static final String ADMIN_PERMISSION_SET = 'AAREG_ContactModel_Admin';

    @IsTest
    static void administratorSeesFlagsKeyFiguresAndCanMigrate() {
        AAREG_ContactModelTestDataFactory.setShadowWrite(true);
        User administrator = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Admin', ADMIN_PERMISSION_SET);

        AAREG_ContactModelAdminController.Overview overview;
        System.runAs(administrator) {
            System.Test.startTest();
            overview = AAREG_ContactModelAdminController.getOverview();
            System.Test.stopTest();
        }

        System.Assert.isTrue(overview.canMigrate, 'The admin permission set grants the migrate permission');
        System.Assert.isFalse(overview.primaryAccountReady, 'No primary account yet');
        System.Assert.areEqual(6, overview.metrics.size(), 'All key figures');
        System.Assert.isFalse(overview.flags.isEmpty(), 'Flags are described');
        System.Assert.isTrue(overview.runs.isEmpty(), 'No runs yet');
    }

    @IsTest
    static void userWithoutPermissionSetIsRejected() {
        User caseHandler = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Plain', null);

        System.runAs(caseHandler) {
            try {
                AAREG_ContactModelAdminController.getOverview();
                System.Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException error) {
                System.Assert.isTrue(error.getMessage().contains(ADMIN_PERMISSION_SET), error.getMessage());
            }
        }
    }

    @IsTest
    static void setUpPrimaryAccountRequiresMigratePermission() {
        User caseHandler = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Plain', null);

        System.runAs(caseHandler) {
            try {
                AAREG_ContactModelAdminController.setUpPrimaryAccount();
                System.Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException error) {
                System.Assert.isTrue(error.getMessage().contains('AAREG_ContactModelMigrate'), error.getMessage());
            }
        }
    }

    @IsTest
    static void administratorCanSetUpPrimaryAccountAndStartPlan() {
        insert new AAREG_Default_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Default_Contact__c = '003000000000000AAA'
        );
        User administrator = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Admin', ADMIN_PERMISSION_SET);

        Id primaryAccountId;
        Id runId;
        System.runAs(administrator) {
            System.Test.startTest();
            primaryAccountId = AAREG_ContactModelAdminController.setUpPrimaryAccount();
            runId = AAREG_ContactModelAdminController.startRun(AAREG_ContactMigrationBatch.MODE_PLAN, null);
            System.Test.stopTest();
        }

        System.Assert.areEqual(AAREG_ContactModelService.getPrimaryAccountId(), primaryAccountId, 'Primary account');
        AAREG_Contact_Migration_Run__c run = [
            SELECT Mode__c, Status__c
            FROM AAREG_Contact_Migration_Run__c
            WHERE Id = :runId
            WITH SYSTEM_MODE
        ];
        System.Assert.areEqual(AAREG_ContactMigrationBatch.MODE_PLAN, run.Mode__c, 'PLAN run');
        System.Assert.areEqual('Completed', run.Status__c, 'The batch finished');
    }

    @IsTest
    static void invalidRunIsReportedAsReadableMessage() {
        User administrator = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Admin', ADMIN_PERMISSION_SET);

        System.runAs(administrator) {
            try {
                AAREG_ContactModelAdminController.startRun('DELETE', null);
                System.Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException error) {
                System.Assert.isTrue(error.getMessage().contains('Ukjend modus'), error.getMessage());
            }
        }
    }
}
