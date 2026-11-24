/**
 * Data and actions for the contact model administration tab.
 *
 * Reading requires access to the contact model objects through AAREG_ContactModel_Admin. Starting runs and
 * setting up the primary account also require the AAREG_ContactModelMigrate custom permission. Counts are
 * aggregates and the view never returns addresses.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see .github/specs/aareg-contact-model.md
 */
public with sharing class AAREG_ContactModelAdminController {
    private static final Integer RUN_LIMIT = 10;

    /**
     * Everything the administration tab shows.
     */
    public class Overview {
        /** Contact model flags in rollout order. */
        @AuraEnabled
        public List<AAREG_ContactModelGate.FlagStatus> flags;
        /** Key figures. */
        @AuraEnabled
        public List<Metric> metrics = new List<Metric>();
        /** Latest runs, newest first. */
        @AuraEnabled
        public List<AAREG_Contact_Migration_Run__c> runs;
        /** Whether the primary account is set up. */
        @AuraEnabled
        public Boolean primaryAccountReady;
        /** Whether the running user may start runs. */
        @AuraEnabled
        public Boolean canMigrate;
    }

    /**
     * One key figure.
     */
    public class Metric {
        /** Stable key for tests and components. */
        @AuraEnabled
        public String key;
        /** Norwegian label. */
        @AuraEnabled
        public String label;
        /** Count. */
        @AuraEnabled
        public Integer value;
        /** One sentence explaining the figure. */
        @AuraEnabled
        public String help;

        Metric(String key, String label, Integer value, String help) {
            this.key = key;
            this.label = label;
            this.value = value;
            this.help = help;
        }
    }

    /**
     * Returns flags, key figures and the latest runs.
     *
     * @return Overview for the administration tab.
     * @throws AuraHandledException When the user lacks read access to the contact model.
     */
    @AuraEnabled
    public static Overview getOverview() {
        requireReadAccess();
        Overview overview = new Overview();
        overview.flags = AAREG_ContactModelGate.describeAll();
        overview.primaryAccountReady = AAREG_ContactModelService.getPrimaryAccountId() != null;
        overview.canMigrate = FeatureManagement.checkPermission(AAREG_ContactMigrationBatch.MIGRATE_PERMISSION);
        overview.metrics.add(
            new Metric(
                'domainContacts',
                'Domenekontaktar',
                [SELECT COUNT() FROM Contact WHERE AAREG_Identity_Key__c != NULL],
                'Éin kontakt per portalbrukar i Aa-registeret.'
            )
        );
        overview.metrics.add(
            new Metric(
                'managedRelations',
                'Forvalta organisasjonstilknytingar',
                [SELECT COUNT() FROM AccountContactRelation WHERE AAREG_Managed__c = TRUE],
                'ACR-rader kontaktmodellen eig. Andre ACR-rader blir ikkje endra.'
            )
        );
        overview.metrics.add(
            new Metric(
                'organizationPoints',
                'Kontaktpunkt for organisasjon',
                [
                    SELECT COUNT()
                    FROM AAREG_Contact_Point__c
                    WHERE Context__c = :AAREG_ContactModelService.CONTEXT_ORGANIZATION
                ],
                'Éi adresse per person og organisasjon.'
            )
        );
        overview.metrics.add(
            new Metric(
                'privatePoints',
                'Private kontaktpunkt',
                [
                    SELECT COUNT()
                    FROM AAREG_Contact_Point__c
                    WHERE Context__c = :AAREG_ContactModelService.CONTEXT_PRIVATE
                ],
                'Adresser personen sjølv har lagt inn under «Min profil».'
            )
        );
        overview.metrics.add(
            new Metric(
                'submitterParticipations',
                'Innsendardeltakingar',
                [SELECT COUNT() FROM RelatedContact__c WHERE Role__c = :AAREG_ContactModelService.ROLE_SUBMITTER],
                'Søknader der innsendaren er kopla til domenekontakten.'
            )
        );
        overview.metrics.add(
            new Metric(
                'unlinkedApplications',
                'Innsende søknader utan innsendardeltaking',
                unlinkedApplications(),
                'Kandidatar for migrering. Køyr PLAN for å sjå klassane.'
            )
        );
        overview.runs = [
            SELECT
                Id,
                Name,
                Mode__c,
                Status__c,
                Source_Run__c,
                Source_Run__r.Name,
                Total__c,
                Class_A__c,
                Class_B__c,
                Class_C__c,
                Class_D__c,
                Class_E__c,
                Linked__c,
                Failed__c,
                Deviations__c,
                Rolled_Back__c,
                Summary__c,
                CreatedDate,
                Completed_At__c
            FROM AAREG_Contact_Migration_Run__c
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT :RUN_LIMIT
        ];
        return overview;
    }

    /**
     * Starts a migration run.
     *
     * @param mode PLAN, APPLY, VERIFY or ROLLBACK.
     * @param sourceRunId Completed APPLY run for VERIFY and ROLLBACK.
     * @return Id of the new run.
     * @throws AuraHandledException When the run cannot be started.
     */
    @AuraEnabled
    public static Id startRun(String mode, Id sourceRunId) {
        try {
            return AAREG_ContactMigrationBatch.startRun(mode, sourceRunId);
        } catch (AAREG_ContactMigrationBatch.MigrationException error) {
            throw auraError(error.getMessage());
        }
    }

    /**
     * Creates the technical primary account when missing.
     *
     * @return Id of the primary account.
     * @throws AuraHandledException When the user lacks the migrate permission or the default settings are missing.
     */
    @AuraEnabled
    public static Id setUpPrimaryAccount() {
        if (!FeatureManagement.checkPermission(AAREG_ContactMigrationBatch.MIGRATE_PERMISSION)) {
            throw auraError('Du manglar løyvet ' + AAREG_ContactMigrationBatch.MIGRATE_PERMISSION + '.');
        }
        try {
            return AAREG_ContactModelService.setUpPrimaryAccount();
        } catch (AAREG_ContactModelService.ContactModelException error) {
            throw auraError(error.getMessage());
        }
    }

    private static Integer unlinkedApplications() {
        return [
            SELECT COUNT()
            FROM Application__c
            WHERE
                Casehandler_Status__c != NULL
                AND Id NOT IN (
                    SELECT Application__c
                    FROM RelatedContact__c
                    WHERE Role__c = :AAREG_ContactModelService.ROLE_SUBMITTER
                )
        ];
    }

    private static void requireReadAccess() {
        if (
            !Schema.SObjectType.AAREG_Contact_Point__c.isAccessible() ||
            !Schema.SObjectType.AAREG_Contact_Migration_Run__c.isAccessible()
        ) {
            throw auraError(
                'Du manglar tilgang til kontaktmodellen. Be om permission set-et AAREG_ContactModel_Admin.'
            );
        }
    }

    private static AuraHandledException auraError(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }
}
