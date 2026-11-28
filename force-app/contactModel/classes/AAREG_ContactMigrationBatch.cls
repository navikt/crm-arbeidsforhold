/**
 * Runs the Aa-register contact model migration in four modes.
 *
 * PLAN classifies submitted applications and changes nothing. APPLY writes a backup and links class A only.
 * VERIFY reconciles an APPLY run. ROLLBACK removes what an APPLY run created and restores the backup.
 * Every mode writes one item per handled application so the result can be reported and audited.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see .github/specs/aareg-contact-model.md
 */
public with sharing class AAREG_ContactMigrationBatch implements Database.Batchable<SObject>, Database.Stateful {
    /** Classifies only. */
    public static final String MODE_PLAN = 'PLAN';
    /** Links class A with backup. */
    public static final String MODE_APPLY = 'APPLY';
    /** Reconciles an APPLY run. */
    public static final String MODE_VERIFY = 'VERIFY';
    /** Reverts an APPLY run. */
    public static final String MODE_ROLLBACK = 'ROLLBACK';
    /** Custom permission required to start a run. */
    public static final String MIGRATE_PERMISSION = 'AAREG_ContactModelMigrate';

    private static final String STATUS_QUEUED = 'Queued';
    private static final String STATUS_RUNNING = 'Running';
    private static final String STATUS_COMPLETED = 'Completed';
    private static final String STATUS_FAILED = 'Failed';
    private static final String ACTION_NONE = 'None';
    private static final String ACTION_LINKED = 'Linked';
    private static final String ACTION_FAILED = 'Failed';
    private static final String ACTION_VERIFIED = 'Verified';
    private static final String ACTION_DEVIATION = 'Deviation';
    private static final String ACTION_ROLLED_BACK = 'Rolled Back';
    private static final Integer BATCH_SIZE = 50;
    private static final Integer REASON_LENGTH = 255;

    @TestVisible
    private static Boolean bypassPermissionCheck = false;

    private final Id runId;
    private final String mode;
    private final Id sourceRunId;

    /**
     * Creates a batch for an existing run record.
     *
     * @param runId Run record.
     * @param mode Run mode.
     * @param sourceRunId APPLY run for VERIFY and ROLLBACK, otherwise null.
     */
    public AAREG_ContactMigrationBatch(Id runId, String mode, Id sourceRunId) {
        this.runId = runId;
        this.mode = mode;
        this.sourceRunId = sourceRunId;
    }

    /**
     * Validates the request, creates a run record and starts the batch.
     *
     * @param mode PLAN, APPLY, VERIFY or ROLLBACK.
     * @param sourceRunId Completed APPLY run for VERIFY and ROLLBACK; ignored for PLAN and APPLY.
     * @return Id of the new run record.
     * @throws MigrationException When the user lacks permission, the mode is unknown, another run is active,
     *         the primary account is missing for APPLY, or the source run is not a completed APPLY run.
     */
    public static Id startRun(String mode, Id sourceRunId) {
        if (!bypassPermissionCheck && !FeatureManagement.checkPermission(MIGRATE_PERMISSION)) {
            throw new MigrationException('Du manglar løyvet ' + MIGRATE_PERMISSION + '.');
        }
        if (mode != MODE_PLAN && mode != MODE_APPLY && mode != MODE_VERIFY && mode != MODE_ROLLBACK) {
            throw new MigrationException('Ukjend modus: ' + mode);
        }
        if (
            [
                SELECT COUNT()
                FROM AAREG_Contact_Migration_Run__c
                WHERE Status__c IN (:STATUS_QUEUED, :STATUS_RUNNING)
                WITH SYSTEM_MODE
            ] > 0
        ) {
            throw new MigrationException('Ei anna køyring er i gang. Vent til ho er ferdig.');
        }
        if (mode == MODE_APPLY && AAREG_ContactModelService.getPrimaryAccountId() == null) {
            throw new MigrationException('Primærkontoen for kontaktmodellen er ikkje sett opp.');
        }
        Id source = null;
        if (mode == MODE_VERIFY || mode == MODE_ROLLBACK) {
            source = requireApplyRun(sourceRunId);
        }

        AAREG_Contact_Migration_Run__c run = new AAREG_Contact_Migration_Run__c(
            Mode__c = mode,
            Status__c = STATUS_QUEUED,
            Source_Run__c = source
        );
        insert as system run;
        Id jobId = Database.executeBatch(new AAREG_ContactMigrationBatch(run.Id, mode, source), BATCH_SIZE);
        run.Batch_Job_Id__c = jobId;
        update as system run;
        return run.Id;
    }

    /**
     * Marks the run as running and returns the records to handle.
     *
     * @param context Batch context.
     * @return Submitted applications for PLAN and APPLY, linked items of the source run otherwise.
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        update as system new AAREG_Contact_Migration_Run__c(
            Id = runId,
            Status__c = STATUS_RUNNING,
            Started_At__c = System.now()
        );
        if (mode == MODE_PLAN || mode == MODE_APPLY) {
            return Database.getQueryLocator(
                [
                    SELECT Id, Account__c, Email__c, CreatedById, CreatedBy.ContactId
                    FROM Application__c
                    WHERE Casehandler_Status__c != NULL
                    ORDER BY CreatedDate
                ],
                AccessLevel.SYSTEM_MODE
            );
        }
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    Application__c,
                    Application__r.CreatedById,
                    Application__r.Account__c,
                    Class__c,
                    Backup__c,
                    Created_Records__c
                FROM AAREG_Contact_Migration_Item__c
                WHERE Run__c = :sourceRunId AND Action__c = :ACTION_LINKED
                ORDER BY Name
            ],
            AccessLevel.SYSTEM_MODE
        );
    }

    /**
     * Handles one chunk.
     *
     * @param context Batch context.
     * @param scope Applications or source items.
     */
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        if (mode == MODE_PLAN) {
            insert as system planItems((List<Application__c>) scope);
        } else if (mode == MODE_APPLY) {
            insert as system applyItems((List<Application__c>) scope);
        } else if (mode == MODE_VERIFY) {
            insert as system verifyItems((List<AAREG_Contact_Migration_Item__c>) scope);
        } else {
            rollbackItems((List<AAREG_Contact_Migration_Item__c>) scope);
        }
    }

    /**
     * Writes counts and the final status.
     *
     * @param context Batch context.
     */
    public void finish(Database.BatchableContext context) {
        AAREG_Contact_Migration_Run__c run = new AAREG_Contact_Migration_Run__c(
            Id = runId,
            Completed_At__c = System.now()
        );
        Map<String, Integer> classCounts = countBy('Class__c');
        Map<String, Integer> actionCounts = countBy('Action__c');
        run.Class_A__c = classCounts.get(AAREG_ContactMigrationClassifier.CLASS_A) ?? 0;
        run.Class_B__c = classCounts.get(AAREG_ContactMigrationClassifier.CLASS_B) ?? 0;
        run.Class_C__c = classCounts.get(AAREG_ContactMigrationClassifier.CLASS_C) ?? 0;
        run.Class_D__c = classCounts.get(AAREG_ContactMigrationClassifier.CLASS_D) ?? 0;
        run.Class_E__c = classCounts.get(AAREG_ContactMigrationClassifier.CLASS_E) ?? 0;
        run.Linked__c = actionCounts.get(ACTION_LINKED) ?? 0;
        run.Failed__c = actionCounts.get(ACTION_FAILED) ?? 0;
        run.Deviations__c = actionCounts.get(ACTION_DEVIATION) ?? 0;
        run.Rolled_Back__c = actionCounts.get(ACTION_ROLLED_BACK) ?? 0;
        Integer total = 0;
        for (Integer count : actionCounts.values()) {
            total += count;
        }
        run.Total__c = total;

        Integer jobErrors = 0;
        if (context?.getJobId() != null) {
            for (AsyncApexJob job : [
                SELECT NumberOfErrors
                FROM AsyncApexJob
                WHERE Id = :context.getJobId()
                WITH SYSTEM_MODE
            ]) {
                jobErrors = job.NumberOfErrors ?? 0;
            }
        }
        run.Status__c = jobErrors > 0 ? STATUS_FAILED : STATUS_COMPLETED;
        run.Summary__c = summary(run, jobErrors);
        update as system run;
    }

    private List<AAREG_Contact_Migration_Item__c> planItems(List<Application__c> applications) {
        List<AAREG_Contact_Migration_Item__c> items = new List<AAREG_Contact_Migration_Item__c>();
        for (
            AAREG_ContactMigrationClassifier.Result result : AAREG_ContactMigrationClassifier.classify(applications)
                .values()
        ) {
            items.add(newItem(result, ACTION_NONE, result.reason));
        }
        return items;
    }

    private List<AAREG_Contact_Migration_Item__c> applyItems(List<Application__c> applications) {
        Map<Id, Application__c> applicationById = new Map<Id, Application__c>(applications);
        List<AAREG_Contact_Migration_Item__c> items = new List<AAREG_Contact_Migration_Item__c>();
        List<AAREG_ContactMigrationClassifier.Result> safe = new List<AAREG_ContactMigrationClassifier.Result>();
        for (
            AAREG_ContactMigrationClassifier.Result result : AAREG_ContactMigrationClassifier.classify(applications)
                .values()
        ) {
            if (result.migrationClass == AAREG_ContactMigrationClassifier.CLASS_A) {
                safe.add(result);
            } else {
                items.add(newItem(result, ACTION_NONE, result.reason));
            }
        }
        if (safe.isEmpty()) {
            return items;
        }
        try {
            items.addAll(linkSafely(safe, applicationById));
        } catch (Exception chunkError) {
            for (AAREG_ContactMigrationClassifier.Result result : safe) {
                try {
                    items.addAll(
                        linkSafely(new List<AAREG_ContactMigrationClassifier.Result>{ result }, applicationById)
                    );
                } catch (Exception itemError) {
                    items.add(newItem(result, ACTION_FAILED, itemError.getMessage()));
                }
            }
        }
        return items;
    }

    private List<AAREG_Contact_Migration_Item__c> linkSafely(
        List<AAREG_ContactMigrationClassifier.Result> safe,
        Map<Id, Application__c> applicationById
    ) {
        Savepoint savepoint = Database.setSavepoint();
        try {
            return link(safe, applicationById);
        } catch (Exception error) {
            Database.rollback(savepoint);
            throw error;
        }
    }

    private List<AAREG_Contact_Migration_Item__c> link(
        List<AAREG_ContactMigrationClassifier.Result> safe,
        Map<Id, Application__c> applicationById
    ) {
        Map<Id, Id> userIdByApplication = new Map<Id, Id>();
        Set<String> identityKeys = new Set<String>();
        Set<Id> organizationIds = new Set<Id>();
        for (AAREG_ContactMigrationClassifier.Result result : safe) {
            userIdByApplication.put(result.applicationId, result.submitterUserId);
            identityKeys.add(result.submitterUserId);
            organizationIds.add(applicationById.get(result.applicationId).Account__c);
        }

        Snapshot before = new Snapshot(identityKeys, organizationIds, userIdByApplication.keySet());
        AAREG_ContactModelService.recordSubmissions(userIdByApplication);
        Snapshot after = new Snapshot(identityKeys, organizationIds, userIdByApplication.keySet());

        Set<Id> attributed = new Set<Id>();
        List<AAREG_Contact_Migration_Item__c> items = new List<AAREG_Contact_Migration_Item__c>();
        for (AAREG_ContactMigrationClassifier.Result result : safe) {
            Id organizationId = applicationById.get(result.applicationId).Account__c;
            Id contactId = after.contactIdByIdentityKey.get(result.submitterUserId);
            String contextKey = AAREG_ContactModelService.contextKey(contactId, organizationId);
            String participationKey = AAREG_ContactModelService.participationKey(
                result.applicationId,
                contactId,
                AAREG_ContactModelService.ROLE_SUBMITTER
            );

            CreatedRecords created = new CreatedRecords();
            created.participations.addAll(
                newIds(
                    before.participationByKey.get(participationKey),
                    after.participationByKey.get(participationKey),
                    attributed
                )
            );
            created.contactPoints.addAll(
                newIds(before.contactPointByKey.get(contextKey), after.contactPointByKey.get(contextKey), attributed)
            );
            created.relations.addAll(
                newIds(before.relationIdByKey.get(contextKey), after.relationIdByKey.get(contextKey), attributed)
            );
            created.contacts.addAll(
                newIds(before.contactIdByIdentityKey.get(result.submitterUserId), contactId, attributed)
            );

            Backup backup = new Backup();
            backup.contactPoint = before.contactPointByKey.get(contextKey);
            backup.participation = before.participationByKey.get(participationKey);

            AAREG_Contact_Migration_Item__c item = newItem(result, ACTION_LINKED, result.reason);
            item.Created_Records__c = JSON.serialize(created);
            item.Backup__c = JSON.serialize(backup, true);
            items.add(item);
        }
        return items;
    }

    private static List<Id> newIds(Object beforeValue, Object afterValue, Set<Id> attributed) {
        Id afterId = idOf(afterValue);
        if (afterId == null || idOf(beforeValue) != null || attributed.contains(afterId)) {
            return new List<Id>();
        }
        attributed.add(afterId);
        return new List<Id>{ afterId };
    }

    private static Id idOf(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof SObject) {
            return ((SObject) value).Id;
        }
        return (Id) value;
    }

    private List<AAREG_Contact_Migration_Item__c> verifyItems(List<AAREG_Contact_Migration_Item__c> sourceItems) {
        Set<String> identityKeys = new Set<String>();
        Set<Id> organizationIds = new Set<Id>();
        Set<Id> applicationIds = new Set<Id>();
        for (AAREG_Contact_Migration_Item__c source : sourceItems) {
            identityKeys.add(source.Application__r.CreatedById);
            organizationIds.add(source.Application__r.Account__c);
            applicationIds.add(source.Application__c);
        }
        Snapshot current = new Snapshot(identityKeys, organizationIds, applicationIds);

        List<AAREG_Contact_Migration_Item__c> items = new List<AAREG_Contact_Migration_Item__c>();
        for (AAREG_Contact_Migration_Item__c source : sourceItems) {
            Id contactId = current.contactIdByIdentityKey.get(source.Application__r.CreatedById);
            String deviation = null;
            if (contactId == null) {
                deviation = 'Domenekontakten manglar.';
            } else {
                String contextKey = AAREG_ContactModelService.contextKey(contactId, source.Application__r.Account__c);
                RelatedContact__c participation = current.participationByKey.get(
                    AAREG_ContactModelService.participationKey(
                        source.Application__c,
                        contactId,
                        AAREG_ContactModelService.ROLE_SUBMITTER
                    )
                );
                if (participation == null) {
                    deviation = 'Innsendardeltakinga manglar.';
                } else if (!current.relationIdByKey.containsKey(contextKey)) {
                    deviation = 'Organisasjonstilknytinga (ACR) manglar.';
                } else if (
                    !current.contactPointByKey.containsKey(contextKey) || participation.Contact_Point__c == null
                ) {
                    deviation = 'Kontaktpunktet manglar eller er ikkje kopla til deltakinga.';
                }
            }
            items.add(
                new AAREG_Contact_Migration_Item__c(
                    Run__c = runId,
                    Application__c = source.Application__c,
                    Class__c = source.Class__c,
                    Action__c = deviation == null ? ACTION_VERIFIED : ACTION_DEVIATION,
                    Reason__c = deviation == null ? 'Stemmer med APPLY-køyringa.' : deviation
                )
            );
        }
        return items;
    }

    private void rollbackItems(List<AAREG_Contact_Migration_Item__c> sourceItems) {
        List<Id> participationIds = new List<Id>();
        List<Id> contactPointIds = new List<Id>();
        List<Id> relationIds = new List<Id>();
        Set<Id> contactIds = new Set<Id>();
        List<AAREG_Contact_Point__c> restoredPoints = new List<AAREG_Contact_Point__c>();
        List<RelatedContact__c> restoredParticipations = new List<RelatedContact__c>();

        for (AAREG_Contact_Migration_Item__c source : sourceItems) {
            if (String.isNotBlank(source.Created_Records__c)) {
                CreatedRecords created = (CreatedRecords) JSON.deserialize(
                    source.Created_Records__c,
                    CreatedRecords.class
                );
                participationIds.addAll(created.participations);
                contactPointIds.addAll(created.contactPoints);
                relationIds.addAll(created.relations);
                contactIds.addAll(created.contacts);
            }
            if (String.isNotBlank(source.Backup__c)) {
                Backup backup = (Backup) JSON.deserialize(source.Backup__c, Backup.class);
                if (backup.contactPoint != null) {
                    restoredPoints.add(
                        new AAREG_Contact_Point__c(
                            Id = backup.contactPoint.Id,
                            Email__c = backup.contactPoint.Email__c,
                            Phone__c = backup.contactPoint.Phone__c
                        )
                    );
                }
                if (backup.participation != null) {
                    restoredParticipations.add(
                        new RelatedContact__c(
                            Id = backup.participation.Id,
                            Email__c = backup.participation.Email__c,
                            Contact_Point__c = backup.participation.Contact_Point__c
                        )
                    );
                }
            }
        }

        Database.delete(participationIds, false, AccessLevel.SYSTEM_MODE);
        Database.update(restoredParticipations, false, AccessLevel.SYSTEM_MODE);
        Database.update(restoredPoints, false, AccessLevel.SYSTEM_MODE);
        Database.delete(contactPointIds, false, AccessLevel.SYSTEM_MODE);
        Database.delete(relationIds, false, AccessLevel.SYSTEM_MODE);
        Database.delete(new List<Id>(removableContacts(contactIds)), false, AccessLevel.SYSTEM_MODE);

        List<AAREG_Contact_Migration_Item__c> rollbackItems = new List<AAREG_Contact_Migration_Item__c>();
        for (AAREG_Contact_Migration_Item__c source : sourceItems) {
            source.Action__c = ACTION_ROLLED_BACK;
            rollbackItems.add(
                new AAREG_Contact_Migration_Item__c(
                    Run__c = runId,
                    Application__c = source.Application__c,
                    Class__c = source.Class__c,
                    Action__c = ACTION_ROLLED_BACK,
                    Reason__c = 'Fjerna det APPLY oppretta og sette tilbake backup.'
                )
            );
        }
        update as system sourceItems;
        insert as system rollbackItems;
    }

    private static Set<Id> removableContacts(Set<Id> contactIds) {
        Set<Id> removable = new Set<Id>(contactIds);
        if (contactIds.isEmpty()) {
            return removable;
        }
        for (RelatedContact__c participation : [
            SELECT Contact__c
            FROM RelatedContact__c
            WHERE Contact__c IN :contactIds
            WITH SYSTEM_MODE
        ]) {
            removable.remove(participation.Contact__c);
        }
        for (AAREG_Contact_Point__c point : [
            SELECT Contact__c
            FROM AAREG_Contact_Point__c
            WHERE Contact__c IN :contactIds
            WITH SYSTEM_MODE
        ]) {
            removable.remove(point.Contact__c);
        }
        return removable;
    }

    private AAREG_Contact_Migration_Item__c newItem(
        AAREG_ContactMigrationClassifier.Result result,
        String action,
        String reason
    ) {
        return new AAREG_Contact_Migration_Item__c(
            Run__c = runId,
            Application__c = result.applicationId,
            Class__c = result.migrationClass,
            Action__c = action,
            Reason__c = reason?.abbreviate(REASON_LENGTH)
        );
    }

    private Map<String, Integer> countBy(String fieldName) {
        Map<String, Integer> counts = new Map<String, Integer>();
        String query =
            'SELECT ' +
            fieldName +
            ' value, COUNT(Id) total FROM AAREG_Contact_Migration_Item__c WHERE Run__c = :runId GROUP BY ' +
            fieldName;
        for (
            SObject row : Database.queryWithBinds(
                query,
                new Map<String, Object>{ 'runId' => runId },
                AccessLevel.SYSTEM_MODE
            )
        ) {
            counts.put((String) row.get('value'), (Integer) row.get('total'));
        }
        return counts;
    }

    private String summary(AAREG_Contact_Migration_Run__c run, Integer jobErrors) {
        List<String> parts = new List<String>{ mode + ': ' + run.Total__c + ' rader.' };
        if (mode == MODE_PLAN || mode == MODE_APPLY) {
            parts.add(
                'A=' +
                    run.Class_A__c +
                    ', B=' +
                    run.Class_B__c +
                    ', C=' +
                    run.Class_C__c +
                    ', D=' +
                    run.Class_D__c +
                    ', E=' +
                    run.Class_E__c +
                    '.'
            );
        }
        if (mode == MODE_APPLY) {
            parts.add('Kopla: ' + run.Linked__c + '. Feila: ' + run.Failed__c + '.');
        }
        if (mode == MODE_VERIFY) {
            parts.add('Avvik: ' + run.Deviations__c + '.');
        }
        if (mode == MODE_ROLLBACK) {
            parts.add('Rulla tilbake: ' + run.Rolled_Back__c + '.');
        }
        if (jobErrors > 0) {
            parts.add('Batchfeil: ' + jobErrors + '. Sjå Apex Jobs.');
        }
        return String.join(parts, ' ');
    }

    private static Id requireApplyRun(Id sourceRunId) {
        if (sourceRunId == null) {
            throw new MigrationException('Vel ei APPLY-køyring.');
        }
        List<AAREG_Contact_Migration_Run__c> runs = [
            SELECT Id, Mode__c, Status__c
            FROM AAREG_Contact_Migration_Run__c
            WHERE Id = :sourceRunId
            WITH SYSTEM_MODE
        ];
        if (runs.isEmpty() || runs[0].Mode__c != MODE_APPLY || runs[0].Status__c != STATUS_COMPLETED) {
            throw new MigrationException('Kjeldekøyringa må vere ei fullført APPLY-køyring.');
        }
        return runs[0].Id;
    }

    /**
     * Current state of the records APPLY can create, read in system mode.
     */
    private class Snapshot {
        private final Map<Id, Id> contactIdByIdentityKey = new Map<Id, Id>();
        private final Map<String, Id> relationIdByKey = new Map<String, Id>();
        private final Map<String, AAREG_Contact_Point__c> contactPointByKey = new Map<String, AAREG_Contact_Point__c>();
        private final Map<String, RelatedContact__c> participationByKey = new Map<String, RelatedContact__c>();

        private Snapshot(Set<String> identityKeys, Set<Id> organizationIds, Set<Id> applicationIds) {
            for (Contact contact : [
                SELECT Id, AAREG_Identity_Key__c
                FROM Contact
                WHERE AAREG_Identity_Key__c IN :identityKeys
                WITH SYSTEM_MODE
            ]) {
                contactIdByIdentityKey.put(Id.valueOf(contact.AAREG_Identity_Key__c), contact.Id);
            }
            Set<Id> contactIds = new Set<Id>(contactIdByIdentityKey.values());
            if (!contactIds.isEmpty()) {
                for (AccountContactRelation relation : [
                    SELECT Id, AccountId, ContactId
                    FROM AccountContactRelation
                    WHERE ContactId IN :contactIds AND AccountId IN :organizationIds
                    WITH SYSTEM_MODE
                ]) {
                    relationIdByKey.put(
                        AAREG_ContactModelService.contextKey(relation.ContactId, relation.AccountId),
                        relation.Id
                    );
                }
                for (AAREG_Contact_Point__c point : [
                    SELECT Id, Context_Key__c, Email__c, Phone__c
                    FROM AAREG_Contact_Point__c
                    WHERE Contact__c IN :contactIds AND Organization__c IN :organizationIds
                    WITH SYSTEM_MODE
                ]) {
                    contactPointByKey.put(point.Context_Key__c, point);
                }
            }
            for (RelatedContact__c participation : [
                SELECT Id, Participation_Key__c, Email__c, Contact_Point__c
                FROM RelatedContact__c
                WHERE
                    Application__c IN :applicationIds
                    AND Role__c = :AAREG_ContactModelService.ROLE_SUBMITTER
                    AND Participation_Key__c != NULL
                WITH SYSTEM_MODE
            ]) {
                participationByKey.put(participation.Participation_Key__c, participation);
            }
        }
    }

    /**
     * Ids created by APPLY for one item.
     */
    public class CreatedRecords {
        /** Created participations. */
        public List<Id> participations = new List<Id>();
        /** Created contact points. */
        public List<Id> contactPoints = new List<Id>();
        /** Created organization relations. */
        public List<Id> relations = new List<Id>();
        /** Created domain contacts. */
        public List<Id> contacts = new List<Id>();
    }

    /**
     * Values APPLY can overwrite, captured before the change.
     */
    public class Backup {
        /** Contact point before APPLY, when it existed. */
        public AAREG_Contact_Point__c contactPoint;
        /** Participation before APPLY, when it existed. */
        public RelatedContact__c participation;
    }

    /**
     * Raised when a run cannot be started.
     */
    public class MigrationException extends Exception {
    }
}
