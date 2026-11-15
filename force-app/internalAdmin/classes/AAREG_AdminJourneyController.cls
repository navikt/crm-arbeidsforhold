/**
 * Application journey for the Arbeidsforhold Admin app.
 *
 * Combines the application, tracked field changes, decisions, agreements, files, P360 jobs,
 * logs, email and threads into one chronological timeline. Each source is read in user mode.
 * Records on objects the user cannot read are counted, never shown; the count still respects
 * record sharing because the class runs with sharing. Payloads are never read.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
public with sharing class AAREG_AdminJourneyController {
    private static final Integer MAX_PER_SOURCE = 100;
    private static final Integer MESSAGE_LENGTH = 255;

    /**
     * The journey for one application.
     */
    public class Journey {
        @AuraEnabled
        public Id applicationId;
        @AuraEnabled
        public String applicationName;
        @AuraEnabled
        public List<Entry> entries = new List<Entry>();
        @AuraEnabled
        public List<String> missingSteps = new List<String>();
        @AuraEnabled
        public Integer hiddenCount = 0;
        @AuraEnabled
        public List<String> notes = new List<String>();
    }

    /**
     * One event on the timeline.
     */
    public class Entry implements Comparable {
        @AuraEnabled
        public Datetime timestamp;
        @AuraEnabled
        public String source;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String detail;
        @AuraEnabled
        public Id recordId;
        @AuraEnabled
        public Boolean dateOnly = false;

        Entry(Datetime timestamp, String source, String title, String detail, Id recordId) {
            this.timestamp = timestamp;
            this.source = source;
            this.title = title;
            this.detail = detail;
            this.recordId = recordId;
        }

        /**
         * Orders entries by timestamp, oldest first.
         *
         * @param other Entry to compare with.
         * @return Negative, zero or positive as for Comparable.
         */
        public Integer compareTo(Object other) {
            Datetime otherTime = ((Entry) other).timestamp;
            if (timestamp == otherTime) {
                return 0;
            }
            return timestamp < otherTime ? -1 : 1;
        }
    }

    /**
     * Returns the chronological journey for one application.
     *
     * @param applicationId Application__c record id.
     * @return Journey with entries, missing steps, hidden count and notes.
     * @throws AuraHandledException When the application cannot be read by the current user.
     * @since 2026-11
     */
    @AuraEnabled
    public static Journey getJourney(Id applicationId) {
        Application__c application = readApplication(applicationId);
        Journey journey = new Journey();
        journey.applicationId = application.Id;
        journey.applicationName = application.Name;

        addApplicationEvents(journey, application);
        addHistory(journey, applicationId);
        Integer decisions = addDecisions(journey, applicationId);
        addAgreements(journey, applicationId);
        addFiles(journey, applicationId);
        Boolean archivedByJob = addJobs(journey, applicationId);
        addLogs(journey, applicationId);
        addEmails(journey, applicationId);
        addThreads(journey, applicationId);

        if (application.ApplicationSubmittedDate__c == null) {
            journey.missingSteps.add('Sendt inn');
        }
        if (decisions == 0 && application.DecisionDate__c == null) {
            journey.missingSteps.add('Vedtak');
        }
        if (
            !archivedByJob &&
            application.AA_ApplicationArchivedDate__c == null &&
            application.AA_DecisionArchivedDate__c == null
        ) {
            journey.missingSteps.add('Arkivert i P360');
        }
        journey.notes.add('SMS blir knytt til henvendingar, ikkje til søknader, og er derfor ikkje med her.');
        journey.entries.sort();
        return journey;
    }

    private static Application__c readApplication(Id applicationId) {
        List<Application__c> applications;
        try {
            applications = [
                SELECT
                    Id,
                    Name,
                    CreatedDate,
                    Status__c,
                    ApplicationSubmittedDate__c,
                    DecisionDate__c,
                    AA_ApplicationArchivedDate__c,
                    AA_DecisionArchivedDate__c
                FROM Application__c
                WHERE Id = :applicationId
                WITH USER_MODE
                LIMIT 1
            ];
        } catch (QueryException error) {
            throw handled('Du har ikkje lesetilgang til søknader. Be om permission set-et AAREG_Admin_Viewer.');
        }
        if (applications.isEmpty()) {
            throw handled('Fann ikkje søknaden, eller han er ikkje delt med deg.');
        }
        return applications[0];
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }

    private static void addApplicationEvents(Journey journey, Application__c application) {
        String source = 'Application__c';
        journey.entries.add(
            new Entry(
                application.CreatedDate,
                source,
                'Søknad oppretta',
                'Status no: ' + application.Status__c,
                application.Id
            )
        );
        addDateEvent(journey, application.ApplicationSubmittedDate__c, 'Sendt inn', application.Id);
        addDateEvent(journey, application.DecisionDate__c, 'Vedtaksdato', application.Id);
        addTimeEvent(journey, application.AA_ApplicationArchivedDate__c, 'Søknad arkivert i P360', application.Id);
        addTimeEvent(journey, application.AA_DecisionArchivedDate__c, 'Vedtak arkivert i P360', application.Id);
    }

    private static void addDateEvent(Journey journey, Date value, String title, Id recordId) {
        if (value != null) {
            // Date-only steps are placed at the end of the day so they never precede same-day events with a time.
            Entry entry = new Entry(
                Datetime.newInstance(value, Time.newInstance(23, 59, 59, 0)),
                'Application__c',
                title,
                'Dato utan klokkeslett',
                recordId
            );
            entry.dateOnly = true;
            journey.entries.add(entry);
        }
    }

    private static void addTimeEvent(Journey journey, Datetime value, String title, Id recordId) {
        if (value != null) {
            journey.entries.add(new Entry(value, 'Application__c', title, null, recordId));
        }
    }

    private static void addHistory(Journey journey, Id applicationId) {
        try {
            List<Application__History> history = [
                SELECT Field, OldValue, NewValue, CreatedDate
                FROM Application__History
                WHERE ParentId = :applicationId
                WITH USER_MODE
                ORDER BY CreatedDate
                LIMIT :MAX_PER_SOURCE
            ];
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Application__c.fields.getMap();
            for (Application__History change : history) {
                if (change.Field == 'created') {
                    continue;
                }
                Schema.SObjectField field = fields.get(change.Field);
                String label = field == null ? change.Field : field.getDescribe().getLabel();
                journey.entries.add(
                    new Entry(
                        change.CreatedDate,
                        'Application__History',
                        'Endra ' + label,
                        displayValue(change.OldValue) + ' → ' + displayValue(change.NewValue),
                        applicationId
                    )
                );
            }
            if (history.isEmpty()) {
                journey.notes.add(
                    'Ingen sporte feltendringar enno. Feltsporing gjeld berre endringar etter at ho vart slått på.'
                );
            }
        } catch (QueryException error) {
            journey.notes.add('Feltendringar kunne ikkje lesast: ' + error.getMessage());
        }
    }

    private static String displayValue(Object value) {
        return value == null ? '(tom)' : String.valueOf(value);
    }

    private static Integer addDecisions(Journey journey, Id applicationId) {
        if (
            !countHiddenWhenUnreadable(
                journey,
                Schema.SObjectType.Application_Decision__c,
                'Application_Decision__c',
                'Application__c',
                applicationId
            )
        ) {
            return 0;
        }
        List<Application_Decision__c> decisions = [
            SELECT Id, Name, CreatedDate, Process_status__c
            FROM Application_Decision__c
            WHERE Application__c = :applicationId
            WITH USER_MODE
            ORDER BY CreatedDate
            LIMIT :MAX_PER_SOURCE
        ];
        for (Application_Decision__c decision : decisions) {
            journey.entries.add(
                new Entry(
                    decision.CreatedDate,
                    'Application_Decision__c',
                    'Vedtak ' + decision.Name,
                    'Prosess-status: ' + decision.Process_status__c,
                    decision.Id
                )
            );
        }
        return decisions.size();
    }

    private static void addAgreements(Journey journey, Id applicationId) {
        if (
            !countHiddenWhenUnreadable(
                journey,
                Schema.SObjectType.Agreement__c,
                'Agreement__c',
                'Application__c',
                applicationId
            )
        ) {
            return;
        }
        for (Agreement__c agreement : [
            SELECT Id, Name, CreatedDate, Status__c
            FROM Agreement__c
            WHERE Application__c = :applicationId
            WITH USER_MODE
            ORDER BY CreatedDate
            LIMIT :MAX_PER_SOURCE
        ]) {
            journey.entries.add(
                new Entry(
                    agreement.CreatedDate,
                    'Agreement__c',
                    'Avtale ' + agreement.Name,
                    'Status: ' + agreement.Status__c,
                    agreement.Id
                )
            );
        }
    }

    private static void addFiles(Journey journey, Id applicationId) {
        try {
            for (ContentDocumentLink link : [
                SELECT
                    ContentDocumentId,
                    ContentDocument.Title,
                    ContentDocument.FileExtension,
                    ContentDocument.CreatedDate
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :applicationId
                WITH USER_MODE
                LIMIT :MAX_PER_SOURCE
            ]) {
                journey.entries.add(
                    new Entry(
                        link.ContentDocument.CreatedDate,
                        'ContentDocument',
                        'Fil lasta opp',
                        link.ContentDocument.Title +
                        (link.ContentDocument.FileExtension == null ? '' : '.' + link.ContentDocument.FileExtension),
                        link.ContentDocumentId
                    )
                );
            }
        } catch (QueryException error) {
            journey.notes.add('Filer kunne ikkje lesast: ' + error.getMessage());
        }
    }

    private static Boolean addJobs(Journey journey, Id applicationId) {
        if (
            !countHiddenWhenUnreadable(
                journey,
                Schema.SObjectType.P360_Archive_Job__c,
                'P360_Archive_Job__c',
                'Application__c',
                applicationId
            )
        ) {
            return false;
        }
        String latestApplicationDocumentStatus;
        for (P360_Archive_Job__c job : [
            SELECT
                Id,
                Name,
                CreatedDate,
                Status__c,
                Archive_Event_Type__c,
                Attempt_Count__c,
                Correlation_Id__c,
                Last_Error_Code__c
            FROM P360_Archive_Job__c
            WHERE Application__c = :applicationId
            WITH USER_MODE
            ORDER BY CreatedDate, Id
            LIMIT :MAX_PER_SOURCE
        ]) {
            if (job.Archive_Event_Type__c == 'ApplicationDocument') {
                latestApplicationDocumentStatus = job.Status__c;
            }
            String detail =
                'Status: ' +
                job.Status__c +
                ', forsøk: ' +
                (job.Attempt_Count__c == null ? 0 : job.Attempt_Count__c.intValue()) +
                ', korrelasjons-ID: ' +
                job.Correlation_Id__c;
            if (String.isNotBlank(job.Last_Error_Code__c)) {
                detail += ', siste feil: ' + job.Last_Error_Code__c;
            }
            journey.entries.add(
                new Entry(
                    job.CreatedDate,
                    'P360_Archive_Job__c',
                    'P360-jobb ' + job.Archive_Event_Type__c,
                    detail,
                    job.Id
                )
            );
        }
        return latestApplicationDocumentStatus == 'Succeeded';
    }

    private static void addLogs(Journey journey, Id applicationId) {
        if (!Schema.SObjectType.Application_Log__c.isAccessible()) {
            journey.notes.add('Du har ikkje lesetilgang til Application_Log__c; loggar er ikkje med.');
            return;
        }
        Set<String> references = new Set<String>{
            String.valueOf(applicationId),
            String.valueOf(applicationId).left(15)
        };
        for (Application_Log__c log : [
            SELECT Id, Name, CreatedDate, Log_Level__c, Source_Class__c, Log_Message__c
            FROM Application_Log__c
            WHERE Referrence_ID__c IN :references
            WITH USER_MODE
            ORDER BY CreatedDate
            LIMIT :MAX_PER_SOURCE
        ]) {
            journey.entries.add(
                new Entry(
                    log.CreatedDate,
                    'Application_Log__c',
                    log.Log_Level__c + ' frå ' + log.Source_Class__c,
                    log.Log_Message__c?.abbreviate(MESSAGE_LENGTH),
                    log.Id
                )
            );
        }
    }

    private static void addEmails(Journey journey, Id applicationId) {
        try {
            for (EmailMessage email : [
                SELECT Id, Subject, MessageDate, Incoming
                FROM EmailMessage
                WHERE RelatedToId = :applicationId
                WITH USER_MODE
                ORDER BY MessageDate
                LIMIT :MAX_PER_SOURCE
            ]) {
                journey.entries.add(
                    new Entry(
                        email.MessageDate,
                        'EmailMessage',
                        email.Incoming ? 'E-post motteken' : 'E-post send',
                        email.Subject,
                        email.Id
                    )
                );
            }
        } catch (QueryException error) {
            journey.notes.add('E-post kunne ikkje lesast: ' + error.getMessage());
        }
    }

    private static void addThreads(Journey journey, Id applicationId) {
        try {
            for (Thread__c thread : [
                SELECT Id, Name, CreatedDate
                FROM Thread__c
                WHERE CRM_Related_Object__c = :applicationId
                WITH USER_MODE
                ORDER BY CreatedDate
                LIMIT :MAX_PER_SOURCE
            ]) {
                journey.entries.add(
                    new Entry(thread.CreatedDate, 'Thread__c', 'Dialog oppretta', thread.Name, thread.Id)
                );
            }
        } catch (QueryException error) {
            journey.notes.add('Dialogar kunne ikkje lesast: ' + error.getMessage());
        }
    }

    private static Boolean countHiddenWhenUnreadable(
        Journey journey,
        Schema.DescribeSObjectResult describe,
        String objectName,
        String lookupField,
        Id applicationId
    ) {
        if (describe.isAccessible()) {
            return true;
        }
        journey.hiddenCount += Database.countQueryWithBinds(
            'SELECT COUNT() FROM ' + objectName + ' WHERE ' + lookupField + ' = :applicationId',
            new Map<String, Object>{ 'applicationId' => applicationId },
            AccessLevel.SYSTEM_MODE
        );
        journey.notes.add('Du har ikkje lesetilgang til ' + objectName + '.');
        return false;
    }
}
