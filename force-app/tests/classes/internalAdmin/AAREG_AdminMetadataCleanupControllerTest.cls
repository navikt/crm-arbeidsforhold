/**
 * Behaviour tests for the Arbeidsforhold Admin metadata cleanup overview.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
@IsTest
private with sharing class AAREG_AdminMetadataCleanupControllerTest {
    private static final String EXISTING_CLASS = 'AAREG_AdminMetadataCleanupController';
    private static final String MISSING_CLASS = 'AAREG_RemovedLongAgoForCleanupTest';

    private static String inventory(List<Map<String, Object>> removed, Map<String, Object> repository) {
        return JSON.serialize(
            new Map<String, Object>{
                'commit' => 'abc123def456',
                'committedAt' => '2026-11-25T01:00:00+01:00',
                'repositoryUrl' => 'https://github.com/navikt/crm-arbeidsforhold',
                'ownedPrefixes' => new List<String>{ 'AAREG', 'P360' },
                'removed' => removed,
                'repository' => repository
            }
        );
    }

    private static Map<String, Object> removed(String type, String name) {
        return new Map<String, Object>{
            'type' => type,
            'name' => name,
            'path' => 'force-app/x/' + name,
            'commit' => 'fedcba987654',
            'removedOn' => '2026-09-14',
            'subject' => 'Remove ' + name
        };
    }

    private static AAREG_Cleanup_Guide__mdt guide(String type, String name, String status) {
        return (AAREG_Cleanup_Guide__mdt) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'DeveloperName' => 'Guide',
                    'Metadata_Type__c' => type,
                    'Component_Name__c' => name,
                    'Status__c' => status,
                    'Reason__c' => 'Replaced by a newer component.',
                    'Runbook_Url__c' => 'https://example.com/runbook'
                }
            ),
            AAREG_Cleanup_Guide__mdt.class
        );
    }

    private static AAREG_AdminMetadataCleanupController.Item find(
        AAREG_AdminMetadataCleanupController.Overview overview,
        String key
    ) {
        for (AAREG_AdminMetadataCleanupController.Item item : overview.items) {
            if (item.key == key) {
                return item;
            }
        }
        System.Assert.fail('Missing item ' + key);
        return null;
    }

    private static User createViewer() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User viewer = new User(
            FirstName = 'Aareg',
            LastName = 'Opprydding',
            Email = 'aareg.cleanup.test@example.com',
            Username = 'aareg.cleanup.test.' + System.currentTimeMillis() + '@example.com',
            Alias = 'aclean',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Oslo',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id
        );
        insert viewer;
        insert new PermissionSetAssignment(
            AssigneeId = viewer.Id,
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'AAREG_Admin_Viewer' LIMIT 1]
            .Id
        );
        return viewer;
    }

    @IsTest
    static void removedComponentsAreCheckedAgainstTheOrg() {
        AAREG_AdminMetadataCleanupController.inventoryOverride = inventory(
            new List<Map<String, Object>>{
                removed('ApexClass', EXISTING_CLASS),
                removed('ApexClass', MISSING_CLASS),
                removed('CustomField', 'Account.Name'),
                removed('CustomField', 'Account.Removed_For_Cleanup_Test__c'),
                removed('Layout', 'Account-Old Layout')
            },
            new Map<String, Object>()
        );
        AAREG_AdminMetadataCleanupController.guideOverride = new List<AAREG_Cleanup_Guide__mdt>();
        AAREG_AdminMetadataCleanupController.Overview overview;

        System.runAs(createViewer()) {
            System.Test.startTest();
            overview = AAREG_AdminMetadataCleanupController.getOverview();
            System.Test.stopTest();
        }

        System.Assert.areEqual('present', find(overview, 'ApexClass:' + EXISTING_CLASS).state, 'Class still in org');
        System.Assert.areEqual('absent', find(overview, 'ApexClass:' + MISSING_CLASS).state, 'Class gone from org');
        System.Assert.areEqual('present', find(overview, 'CustomField:Account.Name').state, 'Field still in org');
        System.Assert.areEqual(
            'absent',
            find(overview, 'CustomField:Account.Removed_For_Cleanup_Test__c').state,
            'Field gone from org'
        );
        AAREG_AdminMetadataCleanupController.Item layout = find(overview, 'Layout:Account-Old Layout');
        System.Assert.areEqual('manual', layout.state, 'Layouts cannot be read with SOQL');
        System.Assert.isNotNull(layout.guidance, 'Manual items explain where to look');
        System.Assert.areEqual(2, overview.presentCount, 'Two components need cleanup');
        System.Assert.areEqual(2, overview.absentCount, 'Two components are gone');
        System.Assert.areEqual(1, overview.manualCount, 'One component must be checked by hand');
        System.Assert.areEqual(
            'https://github.com/navikt/crm-arbeidsforhold/commit/fedcba987654',
            find(overview, 'ApexClass:' + MISSING_CLASS).commitUrl,
            'Each removal links to its commit'
        );
    }

    @IsTest
    static void cleanupGuideAddsDeprecatedComponentsAndEnrichesRemovals() {
        AAREG_AdminMetadataCleanupController.inventoryOverride = inventory(
            new List<Map<String, Object>>{ removed('ApexClass', MISSING_CLASS) },
            new Map<String, Object>()
        );
        AAREG_AdminMetadataCleanupController.guideOverride = new List<AAREG_Cleanup_Guide__mdt>{
            guide('ApexClass', MISSING_CLASS, 'Scheduled_Deletion'),
            guide('ApexClass', EXISTING_CLASS, 'Deprecated')
        };

        System.Test.startTest();
        AAREG_AdminMetadataCleanupController.Overview overview = AAREG_AdminMetadataCleanupController.getOverview();
        System.Test.stopTest();

        AAREG_AdminMetadataCleanupController.Item scheduled = find(overview, 'ApexClass:' + MISSING_CLASS);
        System.Assert.areEqual('Scheduled_Deletion', scheduled.stage, 'Guide status overrides the generated stage');
        System.Assert.areEqual('2026-09-14', scheduled.removedOn, 'Removal details are kept');
        System.Assert.areEqual('https://example.com/runbook', scheduled.runbookUrl, 'Runbook comes from the guide');
        AAREG_AdminMetadataCleanupController.Item deprecated = find(overview, 'ApexClass:' + EXISTING_CLASS);
        System.Assert.areEqual('Deprecated', deprecated.stage, 'Deprecated components are listed while in source');
        System.Assert.areEqual('present', deprecated.state, 'Deprecated component exists in org');
    }

    @IsTest
    static void ownedComponentsMissingFromSourceAreReportedAsOrphans() {
        AAREG_AdminMetadataCleanupController.inventoryOverride = inventory(
            new List<Map<String, Object>>(),
            new Map<String, Object>{ 'ApexClass' => new List<String>{ EXISTING_CLASS } }
        );
        AAREG_AdminMetadataCleanupController.guideOverride = new List<AAREG_Cleanup_Guide__mdt>();

        System.Test.startTest();
        AAREG_AdminMetadataCleanupController.Overview overview = AAREG_AdminMetadataCleanupController.getOverview();
        System.Test.stopTest();

        Set<String> orphanKeys = new Set<String>();
        for (AAREG_AdminMetadataCleanupController.Orphan orphan : overview.orphans) {
            orphanKeys.add(orphan.key);
        }
        System.Assert.isFalse(orphanKeys.contains('ApexClass:' + EXISTING_CLASS), 'Classes in source are not orphans');
        System.Assert.isTrue(
            orphanKeys.contains('ApexClass:AAREG_AdminNavigationController'),
            'Owned classes missing from the source inventory are orphans'
        );
    }

    private static AAREG_Cleanup_Environment__mdt environment(
        String developerName,
        String kind,
        String sandboxName,
        Boolean required,
        Integer sortOrder
    ) {
        return (AAREG_Cleanup_Environment__mdt) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'DeveloperName' => developerName,
                    'MasterLabel' => developerName,
                    'Org_Kind__c' => kind,
                    'Sandbox_Name__c' => sandboxName,
                    'Required_For_Archive__c' => required,
                    'Sort_Order__c' => sortOrder
                }
            ),
            AAREG_Cleanup_Environment__mdt.class
        );
    }

    private static AAREG_Cleanup_Verification__mdt verification(String environmentName, String type, String name) {
        return (AAREG_Cleanup_Verification__mdt) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'DeveloperName' => 'Verification',
                    'Environment__r' => new Map<String, Object>{ 'DeveloperName' => environmentName },
                    'Metadata_Type__c' => type,
                    'Component_Name__c' => name,
                    'Verified_On__c' => '2026-11-20',
                    'Verified_By__c' => 'navikt/crm-arbeidsforhold',
                    'Evidence_Url__c' => 'https://github.com/navikt/crm-arbeidsforhold/pull/1'
                }
            ),
            AAREG_Cleanup_Verification__mdt.class
        );
    }

    private static void useEnvironments(List<AAREG_Cleanup_Verification__mdt> verifications) {
        AAREG_AdminMetadataCleanupController.environmentOverride = new List<AAREG_Cleanup_Environment__mdt>{
            environment('Production', 'Production', null, true, 40),
            environment('SIT2', 'Sandbox', 'sit2', true, 10),
            environment('UAT', 'Sandbox', 'uat', false, 30)
        };
        AAREG_AdminMetadataCleanupController.verificationOverride = verifications;
    }

    @IsTest
    static void componentVerifiedInEveryRequiredEnvironmentIsArchived() {
        String partlyVerified = 'AAREG_PartlyVerifiedForCleanupTest';
        AAREG_AdminMetadataCleanupController.inventoryOverride = inventory(
            new List<Map<String, Object>>{ removed('ApexClass', MISSING_CLASS), removed('ApexClass', partlyVerified) },
            new Map<String, Object>()
        );
        AAREG_AdminMetadataCleanupController.guideOverride = new List<AAREG_Cleanup_Guide__mdt>();
        useEnvironments(
            new List<AAREG_Cleanup_Verification__mdt>{
                verification('SIT2', 'ApexClass', MISSING_CLASS),
                verification('Production', 'ApexClass', MISSING_CLASS),
                verification('SIT2', 'ApexClass', partlyVerified)
            }
        );
        AAREG_AdminMetadataCleanupController.Overview overview;

        System.runAs(createViewer()) {
            System.Test.startTest();
            overview = AAREG_AdminMetadataCleanupController.getOverview();
            System.Test.stopTest();
        }

        AAREG_AdminMetadataCleanupController.Item archived = find(overview, 'ApexClass:' + MISSING_CLASS);
        System.Assert.isTrue(archived.archived, 'Verified in SIT2 and production, so the component is archived');
        System.Assert.areEqual(2, archived.verifications.size(), 'Both verifications are shown');
        System.Assert.areEqual('SIT2', archived.verifications[0].environment, 'Verifications follow sort order');
        System.Assert.areEqual('2026-11-20', archived.verifications[0].verifiedOn, 'The verification date is shown');
        AAREG_AdminMetadataCleanupController.Item pending = find(overview, 'ApexClass:' + partlyVerified);
        System.Assert.isFalse(pending.archived, 'Production is still missing');
        System.Assert.areEqual(1, overview.archivedCount, 'One component is archived');
        System.Assert.areEqual(1, overview.absentCount, 'Archived components are not counted as open');
        System.Assert.areEqual(
            new List<String>{ 'SIT2', 'UAT', 'Production' },
            new List<String>{
                overview.environments[0].name,
                overview.environments[1].name,
                overview.environments[2].name
            },
            'Environments are listed from development to production'
        );
    }

    @IsTest
    static void verifiedComponentThatExistsAgainIsShownAsReappeared() {
        AAREG_AdminMetadataCleanupController.inventoryOverride = inventory(
            new List<Map<String, Object>>{ removed('ApexClass', EXISTING_CLASS) },
            new Map<String, Object>()
        );
        AAREG_AdminMetadataCleanupController.guideOverride = new List<AAREG_Cleanup_Guide__mdt>();
        useEnvironments(
            new List<AAREG_Cleanup_Verification__mdt>{
                verification('SIT2', 'ApexClass', EXISTING_CLASS),
                verification('Production', 'ApexClass', EXISTING_CLASS)
            }
        );

        System.Test.startTest();
        AAREG_AdminMetadataCleanupController.Overview overview = AAREG_AdminMetadataCleanupController.getOverview();
        System.Test.stopTest();

        AAREG_AdminMetadataCleanupController.Item item = find(overview, 'ApexClass:' + EXISTING_CLASS);
        System.Assert.isFalse(item.archived, 'A component that exists in the org is never hidden');
        System.Assert.isTrue(item.reappeared, 'The overview warns that a verified deletion no longer holds');
        System.Assert.areEqual(1, overview.presentCount, 'The component needs cleanup again');
    }

    @IsTest
    static void currentSandboxIsMatchedToItsEnvironment() {
        AAREG_AdminMetadataCleanupController.inventoryOverride = inventory(
            new List<Map<String, Object>>{ removed('ApexClass', MISSING_CLASS) },
            new Map<String, Object>()
        );
        AAREG_AdminMetadataCleanupController.guideOverride = new List<AAREG_Cleanup_Guide__mdt>();
        useEnvironments(new List<AAREG_Cleanup_Verification__mdt>());
        AAREG_AdminMetadataCleanupController.orgKindOverride = 'Sandbox';
        AAREG_AdminMetadataCleanupController.sandboxNameOverride = 'SIT2';

        System.Test.startTest();
        AAREG_AdminMetadataCleanupController.Overview sit2 = AAREG_AdminMetadataCleanupController.getOverview();
        AAREG_AdminMetadataCleanupController.sandboxNameOverride = 'dev1';
        AAREG_AdminMetadataCleanupController.Overview unknown = AAREG_AdminMetadataCleanupController.getOverview();
        AAREG_AdminMetadataCleanupController.orgKindOverride = 'Production';
        AAREG_AdminMetadataCleanupController.Overview production = AAREG_AdminMetadataCleanupController.getOverview();
        System.Test.stopTest();

        System.Assert.areEqual('SIT2', sit2.currentEnvironment, 'Sandbox name matches case-insensitively');
        System.Assert.isTrue(sit2.environments[0].isCurrent, 'The current environment is marked');
        System.Assert.isTrue(
            find(sit2, 'ApexClass:' + MISSING_CLASS).readyToVerify,
            'An absent component without verification here can be verified'
        );
        System.Assert.isNull(unknown.currentEnvironment, 'An unmapped sandbox has no environment');
        System.Assert.areEqual('dev1', unknown.sandboxName, 'The sandbox name is shown so it can be mapped');
        System.Assert.isFalse(find(unknown, 'ApexClass:' + MISSING_CLASS).readyToVerify, 'Nothing to export');
        System.Assert.areEqual('Production', production.currentEnvironment, 'Production matches by org kind');
    }

    @IsTest
    static void unreadableInventoryGivesAHandledError() {
        AAREG_AdminMetadataCleanupController.inventoryOverride = 'not json';

        System.Test.startTest();
        try {
            AAREG_AdminMetadataCleanupController.getOverview();
            System.Assert.fail('An unreadable inventory must fail');
        } catch (AuraHandledException error) {
            System.Assert.isNotNull(error.getMessage(), 'The error explains what is missing');
        }
        System.Test.stopTest();
    }
}
