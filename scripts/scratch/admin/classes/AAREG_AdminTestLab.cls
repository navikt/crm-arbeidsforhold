/**
 * Scratch-only synthetic scenarios for the Arbeidsforhold Admin app. Deployed as unpackaged metadata by
 * scripts/aareg-admin-scratch.cjs and never part of the crm-arbeidsforhold package.
 *
 * Every record is marked with {@link PREFIX} so it can be found and reset. P360 jobs are only created in
 * statuses the archive worker never claims, so no scenario reaches P360 or any other external service.
 *
 * @since 2026-11
 */
public with sharing class AAREG_AdminTestLab {
    /** Name prefix that marks synthetic test lab accounts. */
    public static final String PREFIX = 'AAREG TESTLAB';
    private static final String JOB_PREFIX = 'AAREG-TESTLAB-';

    /** Named scenarios and what they show in the admin app. */
    public static final Map<String, String> SCENARIOS = new Map<String, String>{
        'soknad-ny' => 'Ny søknad som ikkje er sendt inn og ikkje har P360-jobb',
        'p360-arkivert' => 'Innsend søknad med vellukka P360-jobb',
        'p360-feila' => 'Innsend søknad der P360-jobben har feila og ikkje blir prøvd på nytt',
        'p360-manuell' => 'Innsend søknad der P360-jobben ventar på manuell vurdering',
        'p360-utgatt-lease' => 'Innsend søknad der P360-jobben står «In Progress» med utgått lease'
    };

    /**
     * Creates one marked synthetic application for the named scenario.
     *
     * @param scenario a key in {@link SCENARIOS}
     * @return the created record names and IDs, and the number of callouts made
     * @throws IllegalArgumentException when the scenario is unknown or the org is not a scratch org
     */
    public static Map<String, Object> seed(String scenario) {
        if (!SCENARIOS.containsKey(scenario)) {
            throw new IllegalArgumentException('Ukjent scenario. Vel ein av: ' + String.join(SCENARIOS.keySet(), ', '));
        }
        requireScratch();
        String stamp = String.valueOf(System.now().getTime()) + '-' + Crypto.getRandomInteger();
        Account account = new Account(Name = PREFIX + ' ' + scenario + ' ' + stamp);
        insert as user account;
        Access_Request__c accessRequest = new Access_Request__c();
        insert as user accessRequest;
        Application__c application = new Application__c(
            Account__c = account.Id,
            Access_Request__c = accessRequest.Id,
            ApplicationSubmittedDate__c = scenario == 'soknad-ny' ? null : System.today()
        );
        insert as user application;
        P360_Archive_Job__c job = jobFor(scenario, application, stamp);
        if (job != null) {
            insert as user job;
        }
        return new Map<String, Object>{
            'scenario' => scenario,
            'description' => SCENARIOS.get(scenario),
            'accountName' => account.Name,
            'applicationId' => application.Id,
            'applicationName' => [SELECT Name FROM Application__c WHERE Id = :application.Id WITH USER_MODE]
            .Name,
            'jobId' => job?.Id,
            'jobStatus' => job?.Status__c,
            'callouts' => Limits.getCallouts()
        };
    }

    /**
     * Lists marked synthetic applications and their newest P360 job status.
     *
     * @return the applications and the number of callouts made
     */
    public static Map<String, Object> inspect() {
        requireScratch();
        List<Object> applications = new List<Object>();
        for (Application__c application : [
            SELECT
                Id,
                Name,
                Status__c,
                Account__r.Name,
                (SELECT Status__c, Last_Error_Code__c FROM P360ArchiveJobs__r ORDER BY CreatedDate DESC LIMIT 1)
            FROM Application__c
            WHERE Account__r.Name LIKE :PREFIX + ' %'
            WITH USER_MODE
            ORDER BY CreatedDate
        ]) {
            P360_Archive_Job__c job = application.P360ArchiveJobs__r.isEmpty()
                ? null
                : application.P360ArchiveJobs__r[0];
            applications.add(
                new Map<String, Object>{
                    'applicationName' => application.Name,
                    'applicationId' => application.Id,
                    'status' => application.Status__c,
                    'accountName' => application.Account__r.Name,
                    'jobStatus' => job?.Status__c,
                    'jobError' => job?.Last_Error_Code__c
                }
            );
        }
        return new Map<String, Object>{ 'applications' => applications, 'callouts' => Limits.getCallouts() };
    }

    /**
     * Deletes marked synthetic records only. Jobs are deleted only when their idempotency key has the test lab
     * prefix. An application on a test lab account is kept when it still has an unmarked job. Access requests and
     * accounts are kept while any remaining application uses them.
     *
     * @return the number of deleted and kept records per object and the number of callouts made
     */
    public static Map<String, Object> reset() {
        requireScratch();
        String accountPattern = PREFIX + ' %';
        String jobPattern = JOB_PREFIX + '%';
        Map<Id, Account> accounts = new Map<Id, Account>(
            [SELECT Id FROM Account WHERE Name LIKE :accountPattern WITH USER_MODE]
        );
        Map<Id, Application__c> applications = new Map<Id, Application__c>(
            [
                SELECT Id, Access_Request__c
                FROM Application__c
                WHERE Account__c IN :accounts.keySet()
                WITH USER_MODE
            ]
        );
        List<P360_Archive_Job__c> jobs = [
            SELECT Id
            FROM P360_Archive_Job__c
            WHERE Idempotency_Key__c LIKE :jobPattern
            WITH USER_MODE
        ];
        for (P360_Archive_Job__c unmarkedJob : [
            SELECT Application__c
            FROM P360_Archive_Job__c
            WHERE Application__c IN :applications.keySet() AND (NOT Idempotency_Key__c LIKE :jobPattern)
            WITH USER_MODE
        ]) {
            applications.remove(unmarkedJob.Application__c);
        }

        Set<Id> accessRequestIds = new Set<Id>();
        for (Application__c application : applications.values()) {
            accessRequestIds.add(application.Access_Request__c);
        }
        accessRequestIds.remove(null);
        Set<Id> keptAccountIds = new Set<Id>();
        for (Application__c remaining : [
            SELECT Account__c, Access_Request__c
            FROM Application__c
            WHERE
                Id NOT IN :applications.keySet()
                AND (Account__c IN :accounts.keySet()
                OR Access_Request__c IN :accessRequestIds)
            WITH USER_MODE
        ]) {
            keptAccountIds.add(remaining.Account__c);
            accessRequestIds.remove(remaining.Access_Request__c);
        }
        keptAccountIds.retainAll(accounts.keySet());
        List<Access_Request__c> accessRequests = [
            SELECT Id
            FROM Access_Request__c
            WHERE Id IN :accessRequestIds
            WITH USER_MODE
        ];
        List<Account> deletableAccounts = new List<Account>();
        for (Account account : accounts.values()) {
            if (!keptAccountIds.contains(account.Id)) {
                deletableAccounts.add(account);
            }
        }

        delete as user jobs;
        delete as user applications.values();
        delete as user accessRequests;
        delete as user deletableAccounts;
        return new Map<String, Object>{
            'deleted' => new Map<String, Integer>{
                'P360_Archive_Job__c' => jobs.size(),
                'Application__c' => applications.size(),
                'Access_Request__c' => accessRequests.size(),
                'Account' => deletableAccounts.size()
            },
            'keptAccounts' => keptAccountIds.size(),
            'callouts' => Limits.getCallouts()
        };
    }

    private static P360_Archive_Job__c jobFor(String scenario, Application__c application, String stamp) {
        Map<String, String> statusByScenario = new Map<String, String>{
            'p360-arkivert' => 'Succeeded',
            'p360-feila' => 'Failed',
            'p360-manuell' => 'Manual Review',
            'p360-utgatt-lease' => 'In Progress'
        };
        if (!statusByScenario.containsKey(scenario)) {
            return null;
        }
        P360_Archive_Job__c job = new P360_Archive_Job__c(
            Idempotency_Key__c = JOB_PREFIX + scenario + '-' + stamp,
            Correlation_Id__c = PREFIX + ' ' + scenario,
            Status__c = statusByScenario.get(scenario),
            Archive_Event_Type__c = 'ApplicationDocument',
            Application__c = application.Id,
            Access_Request__c = application.Access_Request__c,
            Attempt_Count__c = 1
        );
        if (scenario == 'p360-feila') {
            // No Next_Attempt_Date__c: the worker only claims failed jobs whose next attempt is due.
            job.Attempt_Count__c = 5;
            job.Last_Error_Code__c = 'TESTLAB_SYNTHETIC_FAILURE';
            job.Last_Error_Message__c = 'Syntetisk feil frå testlaben. Ingen ekte P360-kall er gjort.';
        } else if (scenario == 'p360-utgatt-lease') {
            job.Lease_Expires_Date__c = System.now().addHours(-1);
            job.Started_Date__c = System.now().addHours(-2);
        }
        return job;
    }

    private static void requireScratch() {
        Boolean scratch =
            URL.getOrgDomainUrl().getHost().endsWith('.scratch.my.salesforce.com') &&
            [SELECT IsSandbox FROM Organization LIMIT 1]
            .IsSandbox;
        if (!scratch) {
            throw new IllegalArgumentException('Testlaben kan berre køyrast i ein scratch-org.');
        }
    }
}
