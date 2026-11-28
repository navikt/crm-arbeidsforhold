/**
 * Read-only cleanup overview for the Arbeidsforhold Admin app.
 *
 * Combines two sources: the generated static resource AAREG_Metadata_Inventory, which lists
 * components removed from the repository and the owned components still in source, and the
 * curated register AAREG_Cleanup_Guide__mdt, which marks deprecated components and links the
 * issue and runbook. For each component the controller checks whether it still exists in the org
 * the user is logged in to, so the same tab gives evidence in scratch, SIT2 and production.
 *
 * Verified deletion per environment comes from AAREG_Cleanup_Verification__mdt. A component is
 * archived, and hidden by default, when its deletion is verified in every environment in
 * AAREG_Cleanup_Environment__mdt marked Required For Archive and it does not exist in this org.
 * The current org is matched to an environment by org kind and sandbox name, so the tab can
 * export the components that are ready to be verified here.
 *
 * Presence is read in system mode because metadata names are not personal data and the answer
 * must not depend on the viewer's folder or setup access. Nothing is written or deleted; deletion
 * follows docs/operations/salesforce-metadata-cleanup-runbook.md.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
public with sharing class AAREG_AdminMetadataCleanupController {
    @TestVisible
    private static final String STATE_PRESENT = 'present';
    @TestVisible
    private static final String STATE_ABSENT = 'absent';
    @TestVisible
    private static final String STATE_MANUAL = 'manual';
    private static final String RESOURCE_NAME = 'AAREG_Metadata_Inventory';
    private static final String STAGE_REMOVED = 'Removed';
    private static final String STAGE_DEPRECATED = 'Deprecated';
    private static final Integer ORPHAN_LIMIT = 2000;
    private static final String KIND_PRODUCTION = 'Production';
    private static final String KIND_SANDBOX = 'Sandbox';
    private static final String KIND_SCRATCH = 'Scratch';

    /** SOQL source per metadata type: sObject, name field and an optional filter. */
    private static final Map<String, List<String>> QUERY_SOURCES = new Map<String, List<String>>{
        'ApexClass' => new List<String>{ 'ApexClass', 'Name', 'NamespacePrefix = null' },
        'ApexTrigger' => new List<String>{ 'ApexTrigger', 'Name', 'NamespacePrefix = null' },
        'ApexPage' => new List<String>{ 'ApexPage', 'Name', 'NamespacePrefix = null' },
        'ApexComponent' => new List<String>{ 'ApexComponent', 'Name', 'NamespacePrefix = null' },
        'StaticResource' => new List<String>{ 'StaticResource', 'Name', 'NamespacePrefix = null' },
        'PermissionSet' => new List<String>{ 'PermissionSet', 'Name', 'IsOwnedByProfile = false' },
        'PermissionSetGroup' => new List<String>{ 'PermissionSetGroup', 'DeveloperName', null },
        'CustomPermission' => new List<String>{ 'CustomPermission', 'DeveloperName', null },
        'Flow' => new List<String>{ 'FlowDefinitionView', 'ApiName', null },
        'Report' => new List<String>{ 'Report', 'DeveloperName', null },
        'Dashboard' => new List<String>{ 'Dashboard', 'DeveloperName', null },
        'EmailTemplate' => new List<String>{ 'EmailTemplate', 'DeveloperName', null },
        'AuraDefinitionBundle' => new List<String>{ 'AuraDefinitionBundle', 'DeveloperName', null },
        'CustomApplication' => new List<String>{ 'AppDefinition', 'DeveloperName', null },
        'ApexTestSuite' => new List<String>{ 'ApexTestSuite', 'TestSuiteName', null }
    };
    /** Types the orphan check covers; reports, dashboards and e-mail templates are user content. */
    private static final List<String> ORPHAN_TYPES = new List<String>{
        'ApexClass',
        'ApexTrigger',
        'ApexPage',
        'StaticResource',
        'PermissionSet',
        'PermissionSetGroup',
        'CustomPermission',
        'Flow',
        'AuraDefinitionBundle',
        'CustomApplication'
    };
    /** Where to look for types that only the Metadata or Tooling API can read. */
    private static final Map<String, String> MANUAL_HINTS = new Map<String, String>{
        'Layout' => 'Setup > Object Manager > objekt > Page Layouts.',
        'FlexiPage' => 'Setup > Lightning App Builder.',
        'QuickAction' => 'Setup > Object Manager > objekt > Buttons, Links, and Actions.',
        'LightningComponentBundle' => 'Setup > Lightning Components.',
        'Workflow' => 'Setup > Workflow Rules.',
        'ValidationRule' => 'Setup > Object Manager > objekt > Validation Rules.',
        'WebLink' => 'Setup > Object Manager > objekt > Buttons, Links, and Actions.',
        'CompactLayout' => 'Setup > Object Manager > objekt > Compact Layouts.',
        'PathAssistant' => 'Setup > Path Settings.',
        'ReportType' => 'Setup > Report Types.',
        'RemoteSiteSetting' => 'Setup > Remote Site Settings.',
        'CustomTab' => 'Setup > Tabs.',
        'CustomMetadata' => 'Setup > Custom Metadata Types > Manage Records.'
    };
    private static final String DEFAULT_HINT = 'Sjekk i Setup eller hent metadata med Salesforce CLI.';

    @TestVisible
    private static String inventoryOverride;
    @TestVisible
    private static List<AAREG_Cleanup_Guide__mdt> guideOverride;
    @TestVisible
    private static List<AAREG_Cleanup_Environment__mdt> environmentOverride;
    @TestVisible
    private static List<AAREG_Cleanup_Verification__mdt> verificationOverride;
    @TestVisible
    private static String orgKindOverride;
    @TestVisible
    private static String sandboxNameOverride;

    /** The complete overview for the org the user is logged in to. */
    public class Overview {
        @AuraEnabled
        public String orgName;
        @AuraEnabled
        public Boolean isSandbox;
        /** Production, Sandbox or Scratch. */
        @AuraEnabled
        public String orgKind;
        @AuraEnabled
        public String sandboxName;
        /** Developer name of the matching AAREG_Cleanup_Environment__mdt, or null. */
        @AuraEnabled
        public String currentEnvironment;
        @AuraEnabled
        public List<Environment> environments = new List<Environment>();
        @AuraEnabled
        public String sourceCommit;
        @AuraEnabled
        public String sourceCommitUrl;
        @AuraEnabled
        public String generatedAt;
        @AuraEnabled
        public List<String> ownedPrefixes = new List<String>();
        @AuraEnabled
        public List<Item> items = new List<Item>();
        @AuraEnabled
        public List<Orphan> orphans = new List<Orphan>();
        @AuraEnabled
        public Integer presentCount = 0;
        @AuraEnabled
        public Integer absentCount = 0;
        @AuraEnabled
        public Integer manualCount = 0;
        @AuraEnabled
        public Integer archivedCount = 0;
        @AuraEnabled
        public String warning;
    }

    /** One removed or deprecated component and whether it exists in this org. */
    public class Item {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String stage;
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String guidance;
        @AuraEnabled
        public String path;
        @AuraEnabled
        public String removedOn;
        @AuraEnabled
        public String subject;
        @AuraEnabled
        public String commitUrl;
        @AuraEnabled
        public String replacement;
        @AuraEnabled
        public String reason;
        @AuraEnabled
        public String issueUrl;
        @AuraEnabled
        public String runbookUrl;
        /** Verified deleted in every required environment and absent here. Hidden by default. */
        @AuraEnabled
        public Boolean archived = false;
        /** Verified deleted in this environment, but exists again. */
        @AuraEnabled
        public Boolean reappeared = false;
        /** Absent in a mapped environment without a verification for it yet. */
        @AuraEnabled
        public Boolean readyToVerify = false;
        @AuraEnabled
        public List<Verification> verifications = new List<Verification>();
    }

    /** An environment where deletion can be verified. */
    public class Environment {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Boolean requiredForArchive;
        @AuraEnabled
        public Boolean isCurrent = false;
    }

    /** Evidence that a component is deleted from one environment. */
    public class Verification {
        @AuraEnabled
        public String environment;
        @AuraEnabled
        public String environmentLabel;
        @AuraEnabled
        public String verifiedOn;
        @AuraEnabled
        public String verifiedBy;
        @AuraEnabled
        public String evidenceUrl;
    }

    /** A component with an owned prefix that exists in the org but not in the repository. */
    public class Orphan {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String name;
    }

    private class Inventory {
        String commitHash;
        String committedAt;
        String repositoryUrl;
        List<String> ownedPrefixes = new List<String>();
        List<Map<String, Object>> removed = new List<Map<String, Object>>();
        Map<String, Set<String>> repository = new Map<String, Set<String>>();
    }

    /**
     * Builds the cleanup overview. Read-only.
     *
     * @return removed and deprecated components with their presence in this org, and orphans
     * @throws AuraHandledException when the inventory resource is missing or unreadable
     */
    @AuraEnabled
    public static Overview getOverview() {
        Inventory inventory;
        try {
            inventory = readInventory();
        } catch (Exception error) {
            throw new AuraHandledException('Fann ikkje oversikta ' + RESOURCE_NAME + ': ' + error.getMessage());
        }
        Overview overview = new Overview();
        overview.orgName = UserInfo.getOrganizationName();
        applyOrgContext(overview);
        overview.sourceCommit = inventory.commitHash;
        overview.sourceCommitUrl = commitUrl(inventory, inventory.commitHash);
        overview.generatedAt = inventory.committedAt;
        overview.ownedPrefixes = inventory.ownedPrefixes;
        overview.items = buildItems(inventory);
        List<String> failedTypes = new List<String>();
        applyPresence(overview.items, failedTypes);
        overview.orphans = findOrphans(inventory, failedTypes);
        applyVerifications(overview);
        for (Item item : overview.items) {
            if (item.archived) {
                overview.archivedCount++;
            } else if (item.state == STATE_PRESENT) {
                overview.presentCount++;
            } else if (item.state == STATE_ABSENT) {
                overview.absentCount++;
            } else {
                overview.manualCount++;
            }
        }
        if (!failedTypes.isEmpty()) {
            overview.warning = 'Kunne ikkje lese ' + String.join(failedTypes, ', ') + ' i denne orgen.';
        }
        return overview;
    }

    private static void applyOrgContext(Overview overview) {
        Organization org = [SELECT IsSandbox, TrialExpirationDate FROM Organization WITH SYSTEM_MODE LIMIT 1];
        overview.isSandbox = org.IsSandbox;
        overview.orgKind = orgKindOverride != null
            ? orgKindOverride
            : !org.IsSandbox ? KIND_PRODUCTION : org.TrialExpirationDate != null ? KIND_SCRATCH : KIND_SANDBOX;
        overview.sandboxName = overview.orgKind == KIND_SANDBOX ? currentSandboxName() : null;
        for (AAREG_Cleanup_Environment__mdt record : environments()) {
            Environment environment = new Environment();
            environment.name = record.DeveloperName;
            environment.label = record.MasterLabel;
            environment.requiredForArchive = record.Required_For_Archive__c;
            environment.isCurrent =
                overview.orgKind == record.Org_Kind__c &&
                (overview.orgKind == KIND_PRODUCTION ||
                (String.isNotBlank(record.Sandbox_Name__c) &&
                record.Sandbox_Name__c.equalsIgnoreCase(overview.sandboxName)));
            if (environment.isCurrent && overview.currentEnvironment == null) {
                overview.currentEnvironment = environment.name;
            }
            overview.environments.add(environment);
        }
    }

    private static String currentSandboxName() {
        if (sandboxNameOverride != null) {
            return sandboxNameOverride;
        }
        try {
            return System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
        } catch (Exception error) {
            return null;
        }
    }

    private static List<AAREG_Cleanup_Environment__mdt> environments() {
        List<AAREG_Cleanup_Environment__mdt> records = environmentOverride != null
            ? environmentOverride.clone()
            : [
                  SELECT
                      DeveloperName,
                      MasterLabel,
                      Org_Kind__c,
                      Sandbox_Name__c,
                      Required_For_Archive__c,
                      Sort_Order__c
                  FROM AAREG_Cleanup_Environment__mdt
              ];
        List<AAREG_Cleanup_Environment__mdt> sorted = new List<AAREG_Cleanup_Environment__mdt>();
        while (!records.isEmpty()) {
            Integer first = 0;
            for (Integer index = 1; index < records.size(); index++) {
                if (sortValue(records[index]) < sortValue(records[first])) {
                    first = index;
                }
            }
            sorted.add(records.remove(first));
        }
        return sorted;
    }

    private static Decimal sortValue(AAREG_Cleanup_Environment__mdt record) {
        return record.Sort_Order__c == null ? 9999 : record.Sort_Order__c;
    }

    private static List<AAREG_Cleanup_Verification__mdt> verifications() {
        return verificationOverride != null
            ? verificationOverride
            : [
                  SELECT
                      Metadata_Type__c,
                      Component_Name__c,
                      Verified_On__c,
                      Verified_By__c,
                      Evidence_Url__c,
                      Environment__r.DeveloperName
                  FROM AAREG_Cleanup_Verification__mdt
              ];
    }

    private static void applyVerifications(Overview overview) {
        Map<String, Map<String, AAREG_Cleanup_Verification__mdt>> byKey = new Map<String, Map<String, AAREG_Cleanup_Verification__mdt>>();
        for (AAREG_Cleanup_Verification__mdt record : verifications()) {
            String key = (record.Metadata_Type__c + ':' + record.Component_Name__c).toLowerCase();
            if (!byKey.containsKey(key)) {
                byKey.put(key, new Map<String, AAREG_Cleanup_Verification__mdt>());
            }
            byKey.get(key).put(record.Environment__r.DeveloperName, record);
        }
        for (Item item : overview.items) {
            Map<String, AAREG_Cleanup_Verification__mdt> verified = byKey.containsKey(item.key.toLowerCase())
                ? byKey.get(item.key.toLowerCase())
                : new Map<String, AAREG_Cleanup_Verification__mdt>();
            Boolean allRequired = true;
            Boolean anyRequired = false;
            for (Environment environment : overview.environments) {
                AAREG_Cleanup_Verification__mdt record = verified.get(environment.name);
                if (environment.requiredForArchive) {
                    anyRequired = true;
                    allRequired &= record != null;
                }
                if (record != null) {
                    item.verifications.add(toVerification(environment, record));
                }
            }
            item.archived = anyRequired && allRequired && item.state != STATE_PRESENT;
            item.reappeared = item.state == STATE_PRESENT && !verified.isEmpty();
            item.readyToVerify =
                overview.currentEnvironment != null &&
                item.state == STATE_ABSENT &&
                !verified.containsKey(overview.currentEnvironment);
        }
    }

    private static Verification toVerification(Environment environment, AAREG_Cleanup_Verification__mdt record) {
        Verification verification = new Verification();
        verification.environment = environment.name;
        verification.environmentLabel = environment.label;
        verification.verifiedOn = record.Verified_On__c == null ? null : String.valueOf(record.Verified_On__c);
        verification.verifiedBy = record.Verified_By__c;
        verification.evidenceUrl = record.Evidence_Url__c;
        return verification;
    }

    private static Inventory readInventory() {
        String body = inventoryOverride;
        if (body == null) {
            body = [SELECT Body FROM StaticResource WHERE Name = :RESOURCE_NAME WITH SYSTEM_MODE LIMIT 1]
                .Body.toString();
        }
        Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(body);
        Inventory inventory = new Inventory();
        inventory.commitHash = (String) raw.get('commit');
        inventory.committedAt = (String) raw.get('committedAt');
        inventory.repositoryUrl = (String) raw.get('repositoryUrl');
        for (Object prefix : (List<Object>) raw.get('ownedPrefixes')) {
            inventory.ownedPrefixes.add((String) prefix);
        }
        for (Object entry : (List<Object>) raw.get('removed')) {
            inventory.removed.add((Map<String, Object>) entry);
        }
        Map<String, Object> repository = (Map<String, Object>) raw.get('repository');
        for (String type : repository.keySet()) {
            Set<String> names = new Set<String>();
            for (Object name : (List<Object>) repository.get(type)) {
                names.add(((String) name).toLowerCase());
            }
            inventory.repository.put(type, names);
        }
        return inventory;
    }

    private static List<Item> buildItems(Inventory inventory) {
        Map<String, Item> itemsByKey = new Map<String, Item>();
        for (Map<String, Object> entry : inventory.removed) {
            Item item = newItem((String) entry.get('type'), (String) entry.get('name'), STAGE_REMOVED);
            item.path = (String) entry.get('path');
            item.removedOn = (String) entry.get('removedOn');
            item.subject = (String) entry.get('subject');
            item.commitUrl = commitUrl(inventory, (String) entry.get('commit'));
            itemsByKey.put(item.key, item);
        }
        for (AAREG_Cleanup_Guide__mdt guide : guides()) {
            String key = guide.Metadata_Type__c + ':' + guide.Component_Name__c;
            Item item = itemsByKey.containsKey(key)
                ? itemsByKey.get(key)
                : newItem(guide.Metadata_Type__c, guide.Component_Name__c, STAGE_DEPRECATED);
            item.stage = guide.Status__c;
            item.replacement = guide.Replacement__c;
            item.reason = guide.Reason__c;
            item.issueUrl = guide.Issue_Url__c;
            item.runbookUrl = guide.Runbook_Url__c;
            itemsByKey.put(key, item);
        }
        return itemsByKey.values();
    }

    private static Item newItem(String type, String name, String stage) {
        Item item = new Item();
        item.key = type + ':' + name;
        item.type = type;
        item.name = name;
        item.stage = stage;
        return item;
    }

    private static List<AAREG_Cleanup_Guide__mdt> guides() {
        return guideOverride != null ? guideOverride : AAREG_Cleanup_Guide__mdt.getAll().values();
    }

    private static String commitUrl(Inventory inventory, String commitHash) {
        return String.isBlank(inventory.repositoryUrl) || String.isBlank(commitHash)
            ? null
            : inventory.repositoryUrl + '/commit/' + commitHash;
    }

    private static void applyPresence(List<Item> items, List<String> failedTypes) {
        Map<String, Set<String>> namesByType = new Map<String, Set<String>>();
        for (Item item : items) {
            if (!namesByType.containsKey(item.type)) {
                namesByType.put(item.type, new Set<String>());
            }
            namesByType.get(item.type).add(item.name);
        }
        Map<String, Set<String>> existing = new Map<String, Set<String>>();
        for (String type : namesByType.keySet()) {
            Set<String> found = existingNames(type, namesByType.get(type), failedTypes);
            if (found != null) {
                existing.put(type, found);
            }
        }
        for (Item item : items) {
            Set<String> found = existing.get(item.type);
            if (found == null) {
                item.state = STATE_MANUAL;
                item.guidance = MANUAL_HINTS.containsKey(item.type) ? MANUAL_HINTS.get(item.type) : DEFAULT_HINT;
            } else {
                item.state = found.contains(item.name.toLowerCase()) ? STATE_PRESENT : STATE_ABSENT;
            }
        }
    }

    /** Lower-case names of the given components that exist in the org, or null when the type cannot be read. */
    private static Set<String> existingNames(String type, Set<String> names, List<String> failedTypes) {
        try {
            if (QUERY_SOURCES.containsKey(type)) {
                return queryNames(QUERY_SOURCES.get(type), names);
            }
            if (type == 'CustomObject') {
                return describedObjects(names);
            }
            if (type == 'CustomField') {
                return describedFields(names);
            }
            if (type == 'ListView' || type == 'RecordType') {
                return queryObjectChildren(type, names);
            }
        } catch (Exception error) {
            failedTypes.add(type);
        }
        return null;
    }

    private static Set<String> queryNames(List<String> source, Set<String> names) {
        String query =
            'SELECT ' +
            source[1] +
            ' FROM ' +
            source[0] +
            ' WHERE ' +
            source[1] +
            ' IN :names' +
            (source[2] == null ? '' : ' AND ' + source[2]);
        return collectNames(
            Database.queryWithBinds(query, new Map<String, Object>{ 'names' => names }, AccessLevel.SYSTEM_MODE),
            source[1]
        );
    }

    private static Set<String> collectNames(List<SObject> records, String field) {
        Set<String> found = new Set<String>();
        for (SObject record : records) {
            found.add(((String) record.get(field)).toLowerCase());
        }
        return found;
    }

    private static Set<String> describedObjects(Set<String> names) {
        Set<String> found = new Set<String>();
        Map<String, Schema.SObjectType> describe = Schema.getGlobalDescribe();
        for (String name : names) {
            if (describe.containsKey(name.toLowerCase())) {
                found.add(name.toLowerCase());
            }
        }
        return found;
    }

    private static Set<String> describedFields(Set<String> names) {
        Set<String> found = new Set<String>();
        Map<String, Schema.SObjectType> describe = Schema.getGlobalDescribe();
        for (String name : names) {
            String objectName = name.substringBefore('.').toLowerCase();
            if (
                describe.containsKey(objectName) &&
                describe.get(objectName)
                    .getDescribe()
                    .fields.getMap()
                    .containsKey(name.substringAfter('.').toLowerCase())
            ) {
                found.add(name.toLowerCase());
            }
        }
        return found;
    }

    private static Set<String> queryObjectChildren(String type, Set<String> names) {
        Set<String> objects = new Set<String>();
        Set<String> developerNames = new Set<String>();
        for (String name : names) {
            objects.add(name.substringBefore('.'));
            developerNames.add(name.substringAfter('.'));
        }
        String query =
            'SELECT SobjectType, DeveloperName FROM ' +
            type +
            ' WHERE SobjectType IN :objects AND DeveloperName IN :developerNames';
        Set<String> found = new Set<String>();
        for (
            SObject record : Database.queryWithBinds(
                query,
                new Map<String, Object>{ 'objects' => objects, 'developerNames' => developerNames },
                AccessLevel.SYSTEM_MODE
            )
        ) {
            found.add((record.get('SobjectType') + '.' + record.get('DeveloperName')).toLowerCase());
        }
        return found;
    }

    private static List<Orphan> findOrphans(Inventory inventory, List<String> failedTypes) {
        List<Orphan> orphans = new List<Orphan>();
        List<String> patterns = new List<String>();
        for (String prefix : inventory.ownedPrefixes) {
            patterns.add(prefix + '%');
        }
        for (String type : ORPHAN_TYPES) {
            List<String> source = QUERY_SOURCES.get(type);
            String query =
                'SELECT ' +
                source[1] +
                ' FROM ' +
                source[0] +
                ' WHERE ' +
                source[1] +
                ' LIKE :patterns' +
                (source[2] == null ? '' : ' AND ' + source[2]) +
                ' ORDER BY ' +
                source[1] +
                ' LIMIT ' +
                ORPHAN_LIMIT;
            try {
                Set<String> known = inventory.repository.get(type);
                for (
                    SObject record : Database.queryWithBinds(
                        query,
                        new Map<String, Object>{ 'patterns' => patterns },
                        AccessLevel.SYSTEM_MODE
                    )
                ) {
                    String name = (String) record.get(source[1]);
                    if (known == null || !known.contains(name.toLowerCase())) {
                        orphans.add(newOrphan(type, name));
                    }
                }
            } catch (Exception error) {
                failedTypes.add(type);
            }
        }
        orphans.addAll(orphanObjects(inventory));
        return orphans;
    }

    private static List<Orphan> orphanObjects(Inventory inventory) {
        List<Orphan> orphans = new List<Orphan>();
        Set<String> known = inventory.repository.containsKey('CustomObject')
            ? inventory.repository.get('CustomObject')
            : new Set<String>();
        Map<String, Schema.SObjectType> describe = Schema.getGlobalDescribe();
        List<String> objectNames = new List<String>(describe.keySet());
        objectNames.sort();
        for (String objectName : objectNames) {
            if (!objectName.endsWith('__c') && !objectName.endsWith('__mdt')) {
                continue;
            }
            for (String prefix : inventory.ownedPrefixes) {
                if (objectName.startsWith(prefix.toLowerCase()) && !known.contains(objectName)) {
                    orphans.add(newOrphan('CustomObject', String.valueOf(describe.get(objectName))));
                    break;
                }
            }
        }
        return orphans;
    }

    private static Orphan newOrphan(String type, String name) {
        Orphan orphan = new Orphan();
        orphan.key = type + ':' + name;
        orphan.type = type;
        orphan.name = name;
        return orphan;
    }
}
