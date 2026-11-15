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
    static void seededJobsCanNeverBeClaimedByTheArchiveWorker() {
        for (String scenario : AAREG_AdminTestLab.SCENARIOS.keySet()) {
            AAREG_AdminTestLab.seed(scenario);
        }

        System.Test.startTest();
        Integer claimable = [
            SELECT COUNT()
            FROM P360_Archive_Job__c
            WHERE Status__c = 'Pending' OR (Status__c = 'Failed' AND Next_Attempt_Date__c <= :System.now())
        ];
        System.Test.stopTest();

        System.Assert.areEqual(0, claimable, 'Seeded jobs must not match the claim query, so nothing reaches P360');
    }

    @IsTest
    static void resetDeletesOnlyMarkedRecords() {
        Account unmarked = new Account(Name = 'Ikkje testlab');
        insert unmarked;
        Access_Request__c unmarkedRequest = new Access_Request__c();
        insert unmarkedRequest;
        insert new Application__c(Account__c = unmarked.Id, Access_Request__c = unmarkedRequest.Id);
        AAREG_AdminTestLab.seed('p360-feila');
        AAREG_AdminTestLab.seed('soknad-ny');

        System.Test.startTest();
        Map<String, Object> result = AAREG_AdminTestLab.reset();
        System.Test.stopTest();

        System.Assert.areEqual(
            2,
            (Integer) ((Map<String, Integer>) result.get('deleted')).get('Application__c'),
            'Both marked applications'
        );
        System.Assert.areEqual(1, [SELECT COUNT() FROM Application__c], 'Unmarked application remains');
        System.Assert.areEqual(1, [SELECT COUNT() FROM Account], 'Unmarked account remains');
        System.Assert.areEqual(0, [SELECT COUNT() FROM P360_Archive_Job__c], 'Marked job is deleted');
    }

    @IsTest
    static void resetKeepsUnmarkedRecordsLinkedToMarkedRecords() {
        Id withManualJob = (Id) AAREG_AdminTestLab.seed('p360-feila').get('applicationId');
        Id plainMarked = (Id) AAREG_AdminTestLab.seed('soknad-ny').get('applicationId');
        Map<Id, Application__c> seeded = new Map<Id, Application__c>(
            [SELECT Account__c, Access_Request__c FROM Application__c WHERE Id IN (:withManualJob, :plainMarked)]
        );
        Account ordinaryAccount = new Account(Name = 'Ordinary employer');
        insert ordinaryAccount;
        Application__c sharingAccessRequest = new Application__c(
            Account__c = ordinaryAccount.Id,
            Access_Request__c = seeded.get(plainMarked).Access_Request__c
        );
        insert sharingAccessRequest;
        P360_Archive_Job__c manualJob = new P360_Archive_Job__c(
            Idempotency_Key__c = 'manual-not-testlab',
            Correlation_Id__c = 'manual-not-testlab',
            Status__c = 'Manual Review',
            Archive_Event_Type__c = 'ApplicationDocument',
            Application__c = withManualJob,
            Access_Request__c = seeded.get(withManualJob).Access_Request__c
        );
        insert manualJob;

        System.Test.startTest();
        AAREG_AdminTestLab.reset();
        System.Test.stopTest();

        System.Assert.areEqual(
            new Set<Id>{ withManualJob, sharingAccessRequest.Id },
            new Map<Id, Application__c>([SELECT Id FROM Application__c]).keySet(),
            'Applications outside the test lab and applications with unmarked jobs remain'
        );
        System.Assert.areEqual(
            new Set<Id>{ manualJob.Id },
            new Map<Id, P360_Archive_Job__c>([SELECT Id FROM P360_Archive_Job__c]).keySet(),
            'Only marked jobs are deleted'
        );
        System.Assert.areEqual(
            new Set<Id>{ seeded.get(withManualJob).Access_Request__c, seeded.get(plainMarked).Access_Request__c },
            new Map<Id, Access_Request__c>([SELECT Id FROM Access_Request__c]).keySet(),
            'Access requests still used by a remaining application are kept'
        );
        System.Assert.areEqual(
            new Set<Id>{ seeded.get(withManualJob).Account__c, ordinaryAccount.Id },
            new Map<Id, Account>([SELECT Id FROM Account]).keySet(),
            'Only test lab accounts without remaining applications are deleted'
        );
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
            System.Test.startTest();
            try {
                AAREG_AdminTestLab.seed('soknad-ny');
            } catch (Exception error) {
                refused = true;
            }
            System.Test.stopTest();
        }

        System.Assert.isTrue(refused, 'Seeding runs in user mode and respects object access');
        System.Assert.areEqual(0, [SELECT COUNT() FROM Application__c], 'Nothing is written');
    }
}
