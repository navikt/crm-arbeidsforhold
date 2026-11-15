/**
 * Read-only integration monitor for the Arbeidsforhold Admin app.
 *
 * Lists recent P360 archive jobs and summarises recent Aa-registeret application logs per
 * source class. Queries run in user mode; log payloads are never queried and messages are
 * truncated. In a scratch org with the simulated P360 receiver deployed, jobs are linked to
 * their captured requests without a compile-time dependency on the scratch-only object.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
public with sharing class AAREG_AdminMonitorController {
    private static final Integer MAX_JOBS = 50;
    private static final Integer MAX_LOGS = 500;
    private static final Integer MESSAGE_LENGTH = 255;
    private static final String CAPTURE_OBJECT = 'P360ScratchCapture__c';
    private static final Set<String> ERROR_LEVELS = new Set<String>{ 'Error', 'Critical' };

    /**
     * Monitor result with explicit availability per data source.
     */
    public class Monitor {
        @AuraEnabled
        public Boolean jobsAvailable = false;
        @AuraEnabled
        public String jobsMessage;
        @AuraEnabled
        public List<JobRow> jobs = new List<JobRow>();
        @AuraEnabled
        public Boolean logsAvailable = false;
        @AuraEnabled
        public String logsMessage;
        @AuraEnabled
        public List<SourceSummary> sources = new List<SourceSummary>();
        @AuraEnabled
        public Boolean scratchCaptureAvailable = false;
    }

    /**
     * One P360 archive job.
     */
    public class JobRow {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String eventType;
        @AuraEnabled
        public Integer attempts;
        @AuraEnabled
        public Datetime nextAttempt;
        @AuraEnabled
        public Datetime leaseExpires;
        @AuraEnabled
        public Boolean leaseExpired = false;
        @AuraEnabled
        public String correlationId;
        @AuraEnabled
        public String lastErrorCode;
        @AuraEnabled
        public String lastErrorMessage;
        @AuraEnabled
        public Id applicationId;
        @AuraEnabled
        public Id decisionId;
        @AuraEnabled
        public Integer captureCount;
        @AuraEnabled
        public Datetime lastModified;
    }

    /**
     * Log activity for one source class in the last seven days.
     */
    public class SourceSummary {
        @AuraEnabled
        public String sourceClass;
        @AuraEnabled
        public Integer total = 0;
        @AuraEnabled
        public Integer errors = 0;
        @AuraEnabled
        public Datetime lastActivity;
        @AuraEnabled
        public Datetime lastErrorAt;
        @AuraEnabled
        public String lastErrorMessage;
    }

    /**
     * Returns recent P360 jobs and log activity that the current user can read.
     *
     * @return Monitor with explanations for any data source the user cannot read.
     * @since 2026-11
     */
    @AuraEnabled
    public static Monitor getMonitor() {
        Monitor monitor = new Monitor();
        loadJobs(monitor);
        loadLogSources(monitor);
        return monitor;
    }

    private static void loadJobs(Monitor monitor) {
        if (!Schema.SObjectType.P360_Archive_Job__c.isAccessible()) {
            monitor.jobsMessage = 'Du har ikkje lesetilgang til P360_Archive_Job__c. Be om permission set-et AAREG_Admin_Viewer.';
            return;
        }
        try {
            Datetime now = System.now();
            for (P360_Archive_Job__c job : [
                SELECT
                    Id,
                    Name,
                    Status__c,
                    Archive_Event_Type__c,
                    Attempt_Count__c,
                    Next_Attempt_Date__c,
                    Lease_Expires_Date__c,
                    Correlation_Id__c,
                    Last_Error_Code__c,
                    Last_Error_Message__c,
                    Application__c,
                    Application_Decision__c,
                    LastModifiedDate
                FROM P360_Archive_Job__c
                WITH USER_MODE
                ORDER BY LastModifiedDate DESC
                LIMIT :MAX_JOBS
            ]) {
                monitor.jobs.add(toRow(job, now));
            }
            monitor.jobsAvailable = true;
        } catch (QueryException error) {
            monitor.jobsMessage = 'Kunne ikkje lese P360-jobbar: ' + error.getMessage();
            return;
        }
        attachScratchCaptures(monitor);
    }

    private static JobRow toRow(P360_Archive_Job__c job, Datetime now) {
        JobRow row = new JobRow();
        row.id = job.Id;
        row.name = job.Name;
        row.status = job.Status__c;
        row.eventType = job.Archive_Event_Type__c;
        row.attempts = job.Attempt_Count__c == null ? 0 : job.Attempt_Count__c.intValue();
        row.nextAttempt = job.Next_Attempt_Date__c;
        row.leaseExpires = job.Lease_Expires_Date__c;
        row.leaseExpired =
            job.Status__c == 'In Progress' &&
            job.Lease_Expires_Date__c != null &&
            job.Lease_Expires_Date__c < now;
        row.correlationId = job.Correlation_Id__c;
        row.lastErrorCode = job.Last_Error_Code__c;
        row.lastErrorMessage = job.Last_Error_Message__c?.abbreviate(MESSAGE_LENGTH);
        row.applicationId = job.Application__c;
        row.decisionId = job.Application_Decision__c;
        row.lastModified = job.LastModifiedDate;
        return row;
    }

    private static void attachScratchCaptures(Monitor monitor) {
        Schema.SObjectType captureType = Schema.getGlobalDescribe().get(CAPTURE_OBJECT);
        if (captureType == null || !captureType.getDescribe().isAccessible() || monitor.jobs.isEmpty()) {
            return;
        }
        Set<String> sourceIds = new Set<String>();
        for (JobRow row : monitor.jobs) {
            if (row.applicationId != null) {
                sourceIds.add(row.applicationId);
            }
            if (row.decisionId != null) {
                sourceIds.add(row.decisionId);
            }
        }
        Map<String, Integer> counts = new Map<String, Integer>();
        try {
            for (
                SObject capture : Database.queryWithBinds(
                    'SELECT SourceRecordId__c FROM ' + CAPTURE_OBJECT + ' WHERE SourceRecordId__c IN :sourceIds',
                    new Map<String, Object>{ 'sourceIds' => sourceIds },
                    AccessLevel.USER_MODE
                )
            ) {
                String sourceId = (String) capture.get('SourceRecordId__c');
                counts.put(sourceId, (counts.containsKey(sourceId) ? counts.get(sourceId) : 0) + 1);
            }
        } catch (QueryException error) {
            return;
        }
        monitor.scratchCaptureAvailable = true;
        for (JobRow row : monitor.jobs) {
            Integer total = 0;
            for (Id sourceId : new List<Id>{ row.applicationId, row.decisionId }) {
                if (sourceId != null && counts.containsKey(String.valueOf(sourceId))) {
                    total += counts.get(String.valueOf(sourceId));
                }
            }
            row.captureCount = total;
        }
    }

    private static void loadLogSources(Monitor monitor) {
        if (!Schema.SObjectType.Application_Log__c.isAccessible()) {
            monitor.logsMessage = 'Du har ikkje lesetilgang til Application_Log__c. Be om permission set-et AAREG_Admin_Viewer.';
            return;
        }
        Map<String, SourceSummary> bySource = new Map<String, SourceSummary>();
        try {
            for (Application_Log__c log : [
                SELECT Source_Class__c, Log_Level__c, Log_Message__c, CreatedDate
                FROM Application_Log__c
                WHERE Application_Domain__c = 'AAREG' AND CreatedDate = LAST_N_DAYS:7
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT :MAX_LOGS
            ]) {
                String sourceClass = String.isBlank(log.Source_Class__c) ? '(ukjend kjelde)' : log.Source_Class__c;
                SourceSummary summary = bySource.get(sourceClass);
                if (summary == null) {
                    summary = new SourceSummary();
                    summary.sourceClass = sourceClass;
                    summary.lastActivity = log.CreatedDate;
                    bySource.put(sourceClass, summary);
                }
                summary.total++;
                if (ERROR_LEVELS.contains(log.Log_Level__c)) {
                    summary.errors++;
                    if (summary.lastErrorAt == null) {
                        summary.lastErrorAt = log.CreatedDate;
                        summary.lastErrorMessage = log.Log_Message__c?.abbreviate(MESSAGE_LENGTH);
                    }
                }
            }
        } catch (QueryException error) {
            monitor.logsMessage = 'Kunne ikkje lese loggar: ' + error.getMessage();
            return;
        }
        List<String> names = new List<String>(bySource.keySet());
        names.sort();
        for (String name : names) {
            monitor.sources.add(bySource.get(name));
        }
        monitor.logsAvailable = true;
    }
}
