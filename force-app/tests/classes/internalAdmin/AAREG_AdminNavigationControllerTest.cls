/**
 * Behaviour tests for the Arbeidsforhold Admin launchpad.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
@IsTest
private with sharing class AAREG_AdminNavigationControllerTest {
    private static Map<String, AAREG_AdminNavigationController.LaunchItem> itemsByKey(
        List<AAREG_AdminNavigationController.LaunchGroup> groups
    ) {
        Map<String, AAREG_AdminNavigationController.LaunchItem> items = new Map<String, AAREG_AdminNavigationController.LaunchItem>();
        for (AAREG_AdminNavigationController.LaunchGroup launchGroup : groups) {
            for (AAREG_AdminNavigationController.LaunchItem item : launchGroup.items) {
                items.put(item.key, item);
            }
        }
        return items;
    }

    @IsTest
    static void adminViewerCanOpenAreasButNotSetup() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        PermissionSet viewer = [SELECT Id FROM PermissionSet WHERE Name = 'AAREG_Admin_Viewer' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = minimumAccessUser.Id, PermissionSetId = viewer.Id);
        List<AAREG_AdminNavigationController.LaunchGroup> groups;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            groups = AAREG_AdminNavigationController.getLaunchpad();
            System.Assert.areEqual(0, Limits.getDmlStatements(), 'The launchpad must not write');
            System.Test.stopTest();
        }

        System.Assert.areEqual('aareg', groups[0].key, 'Aa-registeret is the first area');
        Map<String, AAREG_AdminNavigationController.LaunchItem> items = itemsByKey(groups);
        System.Assert.isTrue(items.get('object:Application__c').available, 'Viewer can open applications');
        System.Assert.isTrue(items.get('object:P360_Archive_Job__c').available, 'Viewer can open P360 jobs');
        System.Assert.isTrue(items.get('navItem:AAREG_Admin_Journey').available, 'Visible tab can be opened');
        System.Assert.isTrue(items.get('navItem:AAREG_Admin_Permissions').available, 'Permission overview is visible');
        AAREG_AdminNavigationController.LaunchItem setup = items.get('url:/lightning/setup/PermSets/home');
        System.Assert.isFalse(setup.available, 'Setup needs View Setup');
        System.Assert.isTrue(setup.reason.contains('View Setup'), 'Reason explains the missing permission');
    }

    @IsTest
    static void minimumAccessUserGetsReasonsInsteadOfBrokenLinks() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        List<AAREG_AdminNavigationController.LaunchGroup> groups;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            groups = AAREG_AdminNavigationController.getLaunchpad();
            System.Test.stopTest();
        }

        Map<String, AAREG_AdminNavigationController.LaunchItem> items = itemsByKey(groups);
        AAREG_AdminNavigationController.LaunchItem application = items.get('object:Application__c');
        System.Assert.isFalse(application.available, 'Minimum access cannot read applications');
        System.Assert.isNotNull(application.reason, 'A reason is given');
        System.Assert.isFalse(items.get('app:AAREG_support').available, 'Apps without access are disabled');
        System.Assert.isFalse(items.get('navItem:AAREG_Admin_Journey').available, 'Hidden tabs are disabled');
    }

    @IsTest
    static void tabGrantsMatchPermissionSetMetadata() {
        Map<String, Set<String>> actual = new Map<String, Set<String>>();
        for (String tabName : AAREG_AdminNavigationController.TAB_PERMISSION_SETS.keySet()) {
            actual.put(tabName, new Set<String>());
        }
        System.Test.startTest();
        for (PermissionSetTabSetting setting : [
            SELECT Name, Parent.Name
            FROM PermissionSetTabSetting
            WHERE
                Name IN :AAREG_AdminNavigationController.TAB_PERMISSION_SETS.keySet()
                AND Parent.IsOwnedByProfile = FALSE
                AND Parent.Name LIKE 'AAREG_%'
        ]) {
            actual.get(setting.Name).add(setting.Parent.Name);
        }
        System.Test.stopTest();

        System.Assert.areEqual(
            AAREG_AdminNavigationController.TAB_PERMISSION_SETS,
            actual,
            'The launchpad tab grants must match the permission set metadata'
        );
    }
}
