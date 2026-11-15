/**
 * Behaviour tests for the Arbeidsforhold Admin integration monitor.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
@IsTest
private with sharing class AAREG_AdminMonitorControllerTest {
    private static Id accessRequestId;

    private static P360_Archive_Job__c job(String key, String status) {
        if (accessRequestId == null) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            accessRequestId = accessRequest.Id;
        }
        return new P360_Archive_Job__c(
            Access_Request__c = accessRequestId,
            Idempotency_Key__c = key,
            Status__c = status,
            Archive_Event_Type__c = 'ApplicationDocument',
            Attempt_Count__c = 0,
            Correlation_Id__c = 'corr-' + key
        );
    }

    private static AAREG_AdminMonitorController.JobRow findJob(AAREG_AdminMonitorController.Monitor monitor, Id jobId) {
        for (AAREG_AdminMonitorController.JobRow row : monitor.jobs) {
            if (row.id == jobId) {
                return row;
            }
        }
        System.Assert.fail('Missing job ' + jobId);
        return null;
    }

    @IsTest
    static void failedJobShowsAttemptsCorrelationAndTruncatedError() {
        P360_Archive_Job__c failed = job('monitor-failed', 'Failed');
        failed.Attempt_Count__c = 3;
        failed.Correlation_Id__c = 'corr-123';
        failed.Last_Error_Code__c = 'P360_TIMEOUT';
        failed.Last_Error_Message__c = 'x'.repeat(400);
        insert failed;

        System.Test.startTest();
        AAREG_AdminMonitorController.Monitor monitor = AAREG_AdminMonitorController.getMonitor();
        System.Test.stopTest();

        AAREG_AdminMonitorController.JobRow row = findJob(monitor, failed.Id);
        System.Assert.isTrue(monitor.jobsAvailable, 'Admin should read jobs');
        System.Assert.areEqual(3, row.attempts, 'Attempts should be shown');
        System.Assert.areEqual('corr-123', row.correlationId, 'Correlation id should be shown');
        System.Assert.areEqual('P360_TIMEOUT', row.lastErrorCode, 'Error code should be shown');
        System.Assert.isTrue(row.lastErrorMessage.length() <= 255, 'Error message should be truncated');
    }

    @IsTest
    static void inProgressJobWithPastLeaseIsFlaggedAsExpired() {
        P360_Archive_Job__c stuck = job('monitor-stuck', 'In Progress');
        stuck.Lease_Expires_Date__c = System.now().addMinutes(-5);
        P360_Archive_Job__c running = job('monitor-running', 'In Progress');
        running.Lease_Expires_Date__c = System.now().addMinutes(30);
        insert new List<P360_Archive_Job__c>{ stuck, running };

        System.Test.startTest();
        AAREG_AdminMonitorController.Monitor monitor = AAREG_AdminMonitorController.getMonitor();
        System.Test.stopTest();

        System.Assert.isTrue(findJob(monitor, stuck.Id).leaseExpired, 'Past lease should be flagged');
        System.Assert.isFalse(findJob(monitor, running.Id).leaseExpired, 'Future lease is not expired');
    }

    @IsTest
    static void logSourcesAreSummarisedWithoutPayload() {
        insert new List<Application_Log__c>{
            new Application_Log__c(
                Application_Domain__c = 'AAREG',
                Source_Class__c = 'AAREG_AltinnService',
                Log_Level__c = 'Error',
                Log_Message__c = 'Altinn svarte 500',
                Pay_Load__c = 'SECRET-PAYLOAD'
            ),
            new Application_Log__c(
                Application_Domain__c = 'AAREG',
                Source_Class__c = 'AAREG_AltinnService',
                Log_Level__c = 'Info',
                Log_Message__c = 'OK'
            )
        };

        System.Test.startTest();
        AAREG_AdminMonitorController.Monitor monitor = AAREG_AdminMonitorController.getMonitor();
        System.Test.stopTest();

        AAREG_AdminMonitorController.SourceSummary altinn;
        for (AAREG_AdminMonitorController.SourceSummary source : monitor.sources) {
            if (source.sourceClass == 'AAREG_AltinnService') {
                altinn = source;
            }
        }
        System.Assert.isNotNull(altinn, 'Source class should be summarised');
        System.Assert.areEqual(2, altinn.total, 'All entries are counted');
        System.Assert.areEqual(1, altinn.errors, 'Only error entries are counted as errors');
        System.Assert.areEqual('Altinn svarte 500', altinn.lastErrorMessage, 'Latest error is shown');
        System.Assert.isFalse(JSON.serialize(monitor).contains('SECRET-PAYLOAD'), 'Payload must never be exposed');
    }

    @IsTest
    static void minimumAccessUserGetsExplanationInsteadOfData() {
        insert job('monitor-private', 'Failed');
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        AAREG_AdminMonitorController.Monitor monitor;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            monitor = AAREG_AdminMonitorController.getMonitor();
            System.Test.stopTest();
        }

        System.Assert.isFalse(monitor.jobsAvailable, 'Jobs are not readable without permission');
        System.Assert.isNotNull(monitor.jobsMessage, 'The user gets an explanation');
        System.Assert.isTrue(monitor.jobs.isEmpty(), 'No job data leaks');
    }
}
