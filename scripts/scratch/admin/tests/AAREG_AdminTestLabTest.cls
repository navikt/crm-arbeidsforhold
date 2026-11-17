@IsTest
private class AAREG_AdminTestLabTest {
    @IsTest
    static void everyScenarioCreatesMarkedSyntheticRecordsWithoutCallouts() {
        System.Test.startTest();
        for (String scenario : AAREG_AdminTestLab.SCENARIOS.keySet()) {
            AAREG_AdminTestLab.seed(scenario);
        }
        Integer callouts = Limits.getCallouts();
        System.Test.stopTest();

        System.Assert.areEqual(0, callouts, 'The test lab never calls out');
        Map<String, Object> inspection = AAREG_AdminTestLab.inspect();
        List<Object> applications = (List<Object>) inspection.get('applications');
        System.Assert.areEqual(
            AAREG_AdminTestLab.SCENARIOS.size(),
            applications.size(),
            'One application per scenario'
        );
        for (Account account : [SELECT Name FROM Account]) {
            System.Assert.isTrue(account.Name.startsWith(AAREG_AdminTestLab.PREFIX), 'Every account is marked');
        }
        Map<String, Integer> jobsByStatus = new Map<String, Integer>();
        for (P360_Archive_Job__c job : [SELECT Status__c, Idempotency_Key__c FROM P360_Archive_Job__c]) {
            System.Assert.isTrue(job.Idempotency_Key__c.startsWith('AAREG-TESTLAB-'), 'Every job is marked');
            jobsByStatus.put(
                job.Status__c,
                (jobsByStatus.containsKey(job.Status__c) ? jobsByStatus.get(job.Status__c) : 0) + 1
            );
        }
        System.Assert.areEqual(
            new Set<String>{ 'Succeeded', 'Failed', 'Manual Review', 'In Progress' },
            jobsByStatus.keySet(),
            'The P360 scenarios cover the monitor statuses'
        );
    }

    @IsTest
    static void seededApplicationAndAccessRequestRemainLinkedToTheSyntheticAccount() {
        Id applicationId = (Id) AAREG_AdminTestLab.seed('soknad-ny').get('applicationId');
        Application__c application = [
            SELECT Account__c, Access_Request__r.Account__c
            FROM Application__c
            WHERE Id = :applicationId
            WITH USER_MODE
        ];

        System.Assert.isNotNull(application.Account__c, 'The synthetic application must keep its account');
        System.Assert.areEqual(
            application.Account__c,
            application.Access_Request__r.Account__c,
            'The access request must refer to the same synthetic account'
        );
    }

    @IsTest
    static void seededJobsAreNotClaimedWhenArchiveProcessingIsEnabled() {
        User processingUser = P360_TestDataFactory.grantPermissionSetToRunningUser('P360_Archive_Job_Processing');
        System.runAs(processingUser) {
            for (String scenario : AAREG_AdminTestLab.SCENARIOS.keySet()) {
                AAREG_AdminTestLab.seed(scenario);
            }
            Id applicationId = (Id) AAREG_AdminTestLab.seed('soknad-ny').get('applicationId');
            Application__c application = [
                SELECT Access_Request__c
                FROM Application__c
                WHERE Id = :applicationId
                WITH USER_MODE
            ];
            P360_Archive_Job__c pendingControl = new P360_Archive_Job__c(
                Idempotency_Key__c = 'claim-control',
                Correlation_Id__c = 'claim-control',
                Status__c = 'Pending',
                Archive_Event_Type__c = 'ApplicationDocument',
                Application__c = applicationId,
                Access_Request__c = application.Access_Request__c
            );
            insert as user pendingControl;
            P360_TestDataFactory.setArchiveProcessingEnabled(true);

            System.Test.startTest();
            List<Id> claimed = P360_ArchiveJobClaimService.claimNextBatch(100);
            System.Test.stopTest();

            System.Assert.areEqual(
                new Set<Id>{ pendingControl.Id },
                new Set<Id>(claimed),
                'The claim service must pick up the control job but none of the synthetic scenarios'
            );
        }
    }

    @IsTest
    static void unknownScenarioIsRejected() {
        Boolean rejected = false;
        try {
            AAREG_AdminTestLab.seed('production');
        } catch (IllegalArgumentException error) {
            rejected = true;
        }
        System.Assert.isTrue(rejected, 'Only named scenarios can be seeded');
        System.Assert.areEqual(0, [SELECT COUNT() FROM Account], 'Nothing is written');
    }

    @IsTest
    static void userWithoutCreateAccessCannotSeed() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        Boolean refused = false;

        System.runAs(minimumAccessUser) {
            System.Assert.isFalse(
                Schema.sObjectType.Account.isCreateable(),
                'The user must lack account create access'
            );
            System.Test.startTest();
            try {
                AAREG_AdminTestLab.seed('soknad-ny');
            } catch (DmlException error) {
                refused = true;
            }
            System.Test.stopTest();
        }

        System.Assert.isTrue(refused, 'Seeding runs in user mode and respects object access');
        System.Assert.areEqual(0, [SELECT COUNT() FROM Application__c], 'Nothing is written');
    }
}
