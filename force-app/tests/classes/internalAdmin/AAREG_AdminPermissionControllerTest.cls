/**
 * Behaviour tests for the Arbeidsforhold Admin permission and user overview.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
@IsTest
private with sharing class AAREG_AdminPermissionControllerTest {
    private static Integer userCounter = 0;

    private static User createInternalUser(String lastName) {
        userCounter++;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User internalUser = new User(
            FirstName = 'Aareg',
            LastName = lastName,
            Email = 'aareg.admin.test@example.com',
            Username = 'aareg.admin.test.' + userCounter + '.' + System.currentTimeMillis() + '@example.com',
            Alias = 'aadm' + userCounter,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Oslo',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id
        );
        insert internalUser;
        return internalUser;
    }

    private static void assign(User assignee, List<String> permissionSetNames) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : [SELECT Id FROM PermissionSet WHERE Name IN :permissionSetNames]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = assignee.Id, PermissionSetId = permissionSet.Id));
        }
        System.Assert.areEqual(permissionSetNames.size(), assignments.size(), 'All permission sets exist');
        insert assignments;
    }

    private static User createOverviewUser() {
        User administrator = createInternalUser('Oversikt');
        assign(administrator, new List<String>{ 'AAREG_Admin_Viewer', 'AAREG_Admin_Access_Overview' });
        return administrator;
    }

    private static AAREG_AdminPermissionController.UserSummary findUser(
        List<AAREG_AdminPermissionController.UserSummary> users,
        Id userId
    ) {
        for (AAREG_AdminPermissionController.UserSummary summary : users) {
            if (summary.userId == userId) {
                return summary;
            }
        }
        System.Assert.fail('Missing user ' + userId);
        return null;
    }

    private static Boolean hasIssue(AAREG_AdminPermissionController.UserSummary summary, String level, String text) {
        for (AAREG_AdminPermissionController.Issue issue : summary.issues) {
            if (issue.level == level && issue.message.contains(text)) {
                return true;
            }
        }
        return false;
    }

    @IsTest
    static void catalogExplainsArbeidsforholdPermissionsWithLiveGrants() {
        User minimumAccessUser = createInternalUser('Lesar');
        assign(minimumAccessUser, new List<String>{ 'AAREG_Admin_Viewer' });
        List<AAREG_AdminPermissionController.PermissionEntry> catalog;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            catalog = AAREG_AdminPermissionController.getCatalog();
            System.Assert.areEqual(0, Limits.getDmlStatements(), 'The catalog must not write');
            System.Test.stopTest();
        }

        Map<String, AAREG_AdminPermissionController.PermissionEntry> byName = new Map<String, AAREG_AdminPermissionController.PermissionEntry>();
        for (AAREG_AdminPermissionController.PermissionEntry entry : catalog) {
            byName.put(entry.apiName, entry);
            System.Assert.isTrue(
                entry.apiName.startsWith('AAREG_') || entry.apiName.startsWith('P360_'),
                'Only the Arbeidsforhold family is listed: ' + entry.apiName
            );
        }
        AAREG_AdminPermissionController.PermissionEntry viewer = byName.get('AAREG_Admin_Viewer');
        System.Assert.isTrue(viewer.documented, 'The viewer permission set has a guide');
        System.Assert.areEqual('Administrator', viewer.audienceLabel, 'Audience is translated');
        System.Assert.isTrue(viewer.directAssignees >= 1, 'Active assignment is counted');
        System.Assert.isFalse(viewer.objects.isEmpty(), 'Object access is read live from the org');

        AAREG_AdminPermissionController.PermissionEntry integration = byName.get('P360_Integration_User');
        System.Assert.areEqual('Løyvesettgruppe', integration.kind, 'Groups are listed as groups');
        System.Assert.isTrue(integration.members.contains('P360_Archive_Job_Processing'), 'Group members are listed');
        System.Assert.isTrue(
            byName.get('P360_Archive_Job_Processing').memberOf.contains('P360_Integration_User'),
            'Members point back to the group'
        );
    }

    @IsTest
    static void viewerWithoutOverviewPermissionCannotListOtherUsers() {
        User minimumAccessUser = createInternalUser('Utan');
        assign(minimumAccessUser, new List<String>{ 'AAREG_Admin_Viewer' });
        Boolean canView;
        String message;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            canView = AAREG_AdminPermissionController.canViewUsers();
            try {
                AAREG_AdminPermissionController.getUsers();
            } catch (AuraHandledException error) {
                message = error.getMessage();
            }
            System.Test.stopTest();
        }

        System.Assert.isFalse(canView, 'Viewer alone may not see other users');
        System.Assert.isTrue(
            message.contains('AAREG_Admin_Access_Overview'),
            'The error names the missing permission set'
        );
    }

    @IsTest
    static void overviewShowsInternalUserMissingRecommendedPermission() {
        User supportUser = createInternalUser('Stotte');
        assign(supportUser, new List<String>{ 'AAREG_Arbeidsforhold_Support_Read_Only' });
        User administrator = createOverviewUser();
        List<AAREG_AdminPermissionController.UserSummary> users;

        System.runAs(administrator) {
            System.Test.startTest();
            users = AAREG_AdminPermissionController.getUsers();
            System.Assert.areEqual(0, Limits.getDmlStatements(), 'The user overview must not write');
            System.Test.stopTest();
        }

        AAREG_AdminPermissionController.UserSummary summary = findUser(users, supportUser.Id);
        System.Assert.areEqual('warning', summary.status, 'Missing companion is a warning');
        System.Assert.isTrue(
            hasIssue(summary, 'warning', 'AAREG_Arbeidsforhold_Support'),
            'The missing companion permission is named'
        );
        System.Assert.isTrue(hasIssue(summary, 'warning', 'aldri logga inn'), 'Never logged in is reported');
        System.Assert.areEqual('Brukarstøtte', summary.assignments[0].audienceLabel, 'Assignment audience is shown');
    }

    @IsTest
    static void userAccessExplainsWhichPermissionGrantsEachObject() {
        User viewerUser = createInternalUser('Tilgang');
        assign(viewerUser, new List<String>{ 'AAREG_Admin_Viewer' });
        User administrator = createOverviewUser();
        AAREG_AdminPermissionController.UserAccess access;

        System.runAs(administrator) {
            System.Test.startTest();
            access = AAREG_AdminPermissionController.getUserAccess(viewerUser.Id);
            System.Test.stopTest();
        }

        AAREG_AdminPermissionController.ObjectGrant application;
        for (AAREG_AdminPermissionController.ObjectGrant grant : access.objects) {
            if (grant.apiName == 'Application__c') {
                application = grant;
            }
        }
        System.Assert.isTrue(application.canRead, 'Viewer grants read on applications');
        System.Assert.isFalse(application.canEdit, 'Viewer does not grant edit');
        System.Assert.isFalse(application.sources.isEmpty(), 'The granting source is listed');
        System.Assert.isTrue(access.sources.size() >= 2, 'Profile and permission set are both sources');
    }

    @IsTest
    static void userAccessRejectsIdsThatAreNotInternalUsers() {
        User administrator = createOverviewUser();
        String message;

        System.runAs(administrator) {
            try {
                AAREG_AdminPermissionController.getUserAccess(UserInfo.getOrganizationId());
            } catch (AuraHandledException error) {
                message = error.getMessage();
            }
        }

        System.Assert.isTrue(message.contains('intern brukar'), 'Unknown IDs are rejected');
    }

    @IsTest
    static void portalAndTestPermissionsOnInternalUsersAreFlagged() {
        Map<String, AAREG_Permission_Guide__mdt> guides = new Map<String, AAREG_Permission_Guide__mdt>{
            'AAREG_CommunityPermission' => new AAREG_Permission_Guide__mdt(
                Permission_Name__c = 'AAREG_CommunityPermission',
                Audience__c = 'Portal'
            ),
            'AAREG_AltinnScenarioUser' => new AAREG_Permission_Guide__mdt(
                Permission_Name__c = 'AAREG_AltinnScenarioUser',
                Audience__c = 'Test'
            ),
            'AAREG_NADA' => new AAREG_Permission_Guide__mdt(
                Permission_Name__c = 'AAREG_NADA',
                Audience__c = 'Integration'
            ),
            'AAREG_Arbeidsforhold_Support' => new AAREG_Permission_Guide__mdt(
                Permission_Name__c = 'AAREG_Arbeidsforhold_Support',
                Audience__c = 'Support'
            )
        };
        AAREG_AdminPermissionController.UserSummary summary = new AAREG_AdminPermissionController.UserSummary();
        summary.isActive = true;
        summary.lastLogin = Datetime.now();

        System.Test.startTest();
        AAREG_AdminPermissionController.evaluate(summary, new Set<String>(guides.keySet()), guides, true);
        System.Test.stopTest();

        System.Assert.areEqual('error', summary.status, 'A test permission in production is an error');
        System.Assert.isTrue(hasIssue(summary, 'warning', 'portalbrukarar'), 'Portal permission is flagged');
        System.Assert.isTrue(hasIssue(summary, 'warning', 'integrasjonsbrukarar'), 'Mixed integration use is flagged');
        System.Assert.isTrue(hasIssue(summary, 'error', 'testmiljø'), 'Test permission is flagged');
    }

    @IsTest
    static void inactiveUserWithPermissionsIsReportedWithoutLoginWarnings() {
        AAREG_AdminPermissionController.UserSummary summary = new AAREG_AdminPermissionController.UserSummary();
        summary.isActive = false;

        System.Test.startTest();
        AAREG_AdminPermissionController.evaluate(
            summary,
            new Set<String>(),
            new Map<String, AAREG_Permission_Guide__mdt>(),
            false
        );
        System.Test.stopTest();

        System.Assert.areEqual(1, summary.issues.size(), 'Only the inactive issue is reported');
        System.Assert.isTrue(hasIssue(summary, 'warning', 'Inaktiv'), 'Inactive user is flagged');
    }
}
