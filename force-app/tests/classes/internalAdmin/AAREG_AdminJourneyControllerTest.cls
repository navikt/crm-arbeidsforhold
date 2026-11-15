/**
 * Behaviour tests for the Arbeidsforhold Admin application journey.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
@IsTest
private with sharing class AAREG_AdminJourneyControllerTest {
    private static Application__c insertApplication(Date submitted) {
        Access_Request__c accessRequest = new Access_Request__c();
        insert accessRequest;
        Application__c application = new Application__c(
            Access_Request__c = accessRequest.Id,
            ApplicationSubmittedDate__c = submitted
        );
        insert application;
        return application;
    }

    private static Set<String> sources(AAREG_AdminJourneyController.Journey journey) {
        Set<String> result = new Set<String>();
        for (AAREG_AdminJourneyController.Entry entry : journey.entries) {
            result.add(entry.source);
        }
        return result;
    }

    @IsTest
    static void journeyCombinesRelatedRecordsInChronologicalOrder() {
        Application__c application = insertApplication(System.today());
        insert new Application_Decision__c(Application__c = application.Id);
        insert new P360_Archive_Job__c(
            Idempotency_Key__c = 'journey-1',
            Status__c = 'Failed',
            Archive_Event_Type__c = 'ApplicationDocument',
            Application__c = application.Id,
            Access_Request__c = application.Access_Request__c,
            Attempt_Count__c = 1,
            Correlation_Id__c = 'corr-journey',
            Last_Error_Code__c = 'P360_TIMEOUT'
        );

        System.Test.startTest();
        AAREG_AdminJourneyController.Journey journey = AAREG_AdminJourneyController.getJourney(application.Id);
        System.Test.stopTest();

        Set<String> found = sources(journey);
        System.Assert.isTrue(found.contains('Application__c'), 'Application events are included');
        System.Assert.isTrue(found.contains('Application_Decision__c'), 'Decisions are included');
        System.Assert.isTrue(found.contains('P360_Archive_Job__c'), 'P360 jobs are included');
        for (Integer i = 1; i < journey.entries.size(); i++) {
            System.Assert.isTrue(
                journey.entries[i - 1].timestamp <= journey.entries[i].timestamp,
                'Entries must be chronological'
            );
        }
        Boolean jobDetailShown = false;
        for (AAREG_AdminJourneyController.Entry entry : journey.entries) {
            jobDetailShown = jobDetailShown || (entry.detail != null && entry.detail.contains('corr-journey'));
        }
        System.Assert.isTrue(jobDetailShown, 'Job correlation id is part of the journey');
    }

    @IsTest
    static void missingStepsAreShownAsNotRecorded() {
        Application__c application = insertApplication(null);

        System.Test.startTest();
        AAREG_AdminJourneyController.Journey journey = AAREG_AdminJourneyController.getJourney(application.Id);
        System.Test.stopTest();

        System.Assert.isTrue(journey.missingSteps.contains('Sendt inn'), 'Unsubmitted application shows missing step');
        System.Assert.isTrue(journey.missingSteps.contains('Vedtak'), 'Missing decision is shown');
        System.Assert.isTrue(journey.missingSteps.contains('Arkivert i P360'), 'Missing archive is shown');
    }

    @IsTest
    static void succeededArchiveJobCountsAsArchivedAndDateOnlyStepFollowsSameDayEvents() {
        Application__c application = insertApplication(System.today());
        insert new P360_Archive_Job__c(
            Idempotency_Key__c = 'journey-archived',
            Status__c = 'Succeeded',
            Archive_Event_Type__c = 'ApplicationDocument',
            Application__c = application.Id,
            Access_Request__c = application.Access_Request__c,
            Attempt_Count__c = 1,
            Correlation_Id__c = 'corr-archived'
        );

        System.Test.startTest();
        AAREG_AdminJourneyController.Journey journey = AAREG_AdminJourneyController.getJourney(application.Id);
        System.Test.stopTest();

        System.Assert.isFalse(journey.missingSteps.contains('Arkivert i P360'), 'Succeeded job means archived');
        Integer createdIndex;
        Integer submittedIndex;
        for (Integer i = 0; i < journey.entries.size(); i++) {
            AAREG_AdminJourneyController.Entry entry = journey.entries[i];
            if (entry.title == 'Søknad oppretta') {
                createdIndex = i;
            } else if (entry.title == 'Sendt inn') {
                submittedIndex = i;
                System.Assert.isTrue(entry.dateOnly, 'Submitted date has no time of day');
            }
        }
        System.Assert.isTrue(submittedIndex > createdIndex, 'Date-only step must not precede same-day creation');
    }

    @IsTest
    static void onlySucceededApplicationDocumentJobCountsAsArchived() {
        Application__c application = insertApplication(System.today());
        insert new P360_Archive_Job__c(
            Idempotency_Key__c = 'journey-attachment-only',
            Status__c = 'Succeeded',
            Archive_Event_Type__c = 'ApplicationAttachment',
            Application__c = application.Id,
            Access_Request__c = application.Access_Request__c,
            Attempt_Count__c = 1,
            Correlation_Id__c = 'corr-attachment'
        );

        System.Test.startTest();
        AAREG_AdminJourneyController.Journey journey = AAREG_AdminJourneyController.getJourney(application.Id);
        System.Test.stopTest();

        System.Assert.isTrue(
            journey.missingSteps.contains('Arkivert i P360'),
            'An archived attachment alone does not mean the application is archived'
        );
    }

    @IsTest
    static void openResubmissionArchiveIsShownAsNotArchived() {
        Application__c application = insertApplication(System.today());
        insert new P360_Archive_Job__c(
            Idempotency_Key__c = 'journey-first-submission',
            Status__c = 'Succeeded',
            Archive_Event_Type__c = 'ApplicationDocument',
            Application__c = application.Id,
            Access_Request__c = application.Access_Request__c,
            Attempt_Count__c = 1,
            Correlation_Id__c = 'corr-first'
        );
        insert new P360_Archive_Job__c(
            Idempotency_Key__c = 'journey-second-submission',
            Status__c = 'Pending',
            Archive_Event_Type__c = 'ApplicationDocument',
            Application__c = application.Id,
            Access_Request__c = application.Access_Request__c,
            Attempt_Count__c = 0,
            Correlation_Id__c = 'corr-second'
        );

        System.Test.startTest();
        AAREG_AdminJourneyController.Journey journey = AAREG_AdminJourneyController.getJourney(application.Id);
        System.Test.stopTest();

        System.Assert.isTrue(
            journey.missingSteps.contains('Arkivert i P360'),
            'The latest submission is not archived while its job is still open'
        );
    }

    @IsTest
    static void userWithoutAccessGetsExplanation() {
        Application__c application = insertApplication(System.today());
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        String message;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            try {
                AAREG_AdminJourneyController.getJourney(application.Id);
            } catch (AuraHandledException error) {
                message = error.getMessage();
            }
            System.Test.stopTest();
        }

        System.Assert.isNotNull(message, 'Unreadable application must be explained');
    }
}
