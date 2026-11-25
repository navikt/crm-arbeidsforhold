/**
 * Permission overview for the Arbeidsforhold Admin app.
 *
 * Reads the Arbeidsforhold permission sets and permission set groups (API names starting with
 * AAREG_ or P360_) live from the org and combines them with the plain-language guide in
 * AAREG_Permission_Guide__mdt. Users with the custom permission AAREG_Admin_Access_Overview, or
 * with View Setup, can also list the internal users that hold these permissions, see access issues
 * and inspect one user's effective access. Nothing is ever written or granted.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 * @see AAREG_AdminAccessDiagnosisController
 */
public with sharing class AAREG_AdminPermissionController {
    /** Custom permission that unlocks the user list and user access details. */
    public static final String OVERVIEW_PERMISSION = 'AAREG_Admin_Access_Overview';
    @TestVisible
    private static final List<String> FAMILY_PATTERNS = new List<String>{ 'AAREG_%', 'P360_%' };
    @TestVisible
    private static final Integer STALE_LOGIN_DAYS = 90;
    @TestVisible
    private static final Integer EXPIRY_WARNING_DAYS = 14;
    private static final Set<String> PERSONAL_AUDIENCES = new Set<String>{ 'Caseworker', 'Support', 'Administrator' };
    private static final Map<String, String> AUDIENCE_LABELS = new Map<String, String>{
        'Caseworker' => 'Saksbehandlar',
        'Support' => 'Brukarstøtte',
        'Administrator' => 'Administrator',
        'Integration' => 'Integrasjonsbrukar',
        'Portal' => 'Portalbrukar',
        'Test' => 'Berre testmiljø'
    };
    private static final List<String> ACCESS_OBJECTS = new List<String>{
        'Application__c',
        'Application_Decision__c',
        'Agreement__c',
        'Access_Request__c',
        'Inquiry__c',
        'Thread__c',
        'Message__c',
        'RelatedContact__c',
        'P360_Archive_Job__c',
        'Application_Log__c',
        'AAREG_Contact_Point__c',
        'AAREG_Contact_Migration_Run__c',
        'Account',
        'Contact'
    };
    private static final List<String> FAMILY_APPS = new List<String>{
        'Arbeidsforhold_Admin',
        'AAREG_application',
        'AAREG_support',
        'AAREG_Contact_Model'
    };
    private static final String NO_ACCESS_MESSAGE = 'Du manglar løyvesettet AAREG_Admin_Access_Overview som trengst for å sjå andre brukarar.';

    /** One permission set or permission set group with its guide and live grants. */
    public class PermissionEntry {
        @AuraEnabled
        public String apiName;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String kind;
        @AuraEnabled
        public String orgDescription;
        @AuraEnabled
        public String audience;
        @AuraEnabled
        public String audienceLabel;
        @AuraEnabled
        public String explanation;
        @AuraEnabled
        public Boolean documented = false;
        @AuraEnabled
        public List<String> recommendedWith = new List<String>();
        @AuraEnabled
        public Integer directAssignees = 0;
        @AuraEnabled
        public List<ObjectGrant> objects = new List<ObjectGrant>();
        @AuraEnabled
        public List<String> customPermissions = new List<String>();
        @AuraEnabled
        public List<String> apps = new List<String>();
        @AuraEnabled
        public Integer apexClassCount = 0;
        @AuraEnabled
        public List<String> members = new List<String>();
        @AuraEnabled
        public List<String> memberOf = new List<String>();
        private Decimal sortOrder = 9999;
    }

    /** Object access granted by one or more permission sources. */
    public class ObjectGrant {
        @AuraEnabled
        public String apiName;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Boolean canRead = false;
        @AuraEnabled
        public Boolean canCreate = false;
        @AuraEnabled
        public Boolean canEdit = false;
        @AuraEnabled
        public Boolean canDelete = false;
        @AuraEnabled
        public Boolean viewAll = false;
        @AuraEnabled
        public Boolean modifyAll = false;
        @AuraEnabled
        public String accessText;
        @AuraEnabled
        public List<String> sources = new List<String>();
    }

    /** One internal user holding Arbeidsforhold permissions. */
    public class UserSummary {
        @AuraEnabled
        public Id userId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String username;
        @AuraEnabled
        public String profileName;
        @AuraEnabled
        public Boolean isActive;
        @AuraEnabled
        public Boolean isFrozen = false;
        @AuraEnabled
        public Boolean isPasswordLocked = false;
        @AuraEnabled
        public Datetime lastLogin;
        @AuraEnabled
        public List<Assignment> assignments = new List<Assignment>();
        @AuraEnabled
        public List<Issue> issues = new List<Issue>();
        @AuraEnabled
        public String status = 'ok';
    }

    /** One permission set or group assignment. */
    public class Assignment {
        @AuraEnabled
        public String apiName;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String audienceLabel;
        @AuraEnabled
        public Date expiresOn;
    }

    /** One access issue. Level is error, warning or info. */
    public class Issue {
        @AuraEnabled
        public String level;
        @AuraEnabled
        public String message;

        Issue(String level, String message) {
            this.level = level;
            this.message = message;
        }
    }

    /** Effective access for one user across the Arbeidsforhold objects, custom permissions and apps. */
    public class UserAccess {
        @AuraEnabled
        public Id userId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public List<String> sources = new List<String>();
        @AuraEnabled
        public List<ObjectGrant> objects = new List<ObjectGrant>();
        @AuraEnabled
        public List<NamedGrant> customPermissions = new List<NamedGrant>();
        @AuraEnabled
        public List<NamedGrant> apps = new List<NamedGrant>();
    }

    /** Whether a named capability is granted, and by which sources. */
    public class NamedGrant {
        @AuraEnabled
        public String apiName;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Boolean granted = false;
        @AuraEnabled
        public List<String> sources = new List<String>();
    }

    private class Source {
        String apiName;
        String label;
        String kind;
        Source(String apiName, String label, String kind) {
            this.apiName = apiName;
            this.label = label;
            this.kind = kind;
        }
    }

    /**
     * Returns every Arbeidsforhold permission set and permission set group with its guide, grants and
     * number of active direct assignees.
     *
     * @return Entries sorted by the guide order, then by API name. Undocumented entries are last.
     * @since 2026-11
     */
    @AuraEnabled
    public static List<PermissionEntry> getCatalog() {
        Map<Id, PermissionEntry> entriesBySourceId = new Map<Id, PermissionEntry>();
        Map<String, PermissionEntry> entriesByName = new Map<String, PermissionEntry>();
        Map<String, AAREG_Permission_Guide__mdt> guides = loadGuides();

        for (PermissionSet permissionSet : [
            SELECT Id, Name, Label, Description
            FROM PermissionSet
            WHERE IsOwnedByProfile = FALSE AND PermissionSetGroupId = NULL AND Name LIKE :FAMILY_PATTERNS
            WITH SYSTEM_MODE
        ]) {
            if (!isFamily(permissionSet.Name)) {
                continue;
            }
            PermissionEntry entry = newEntry(
                permissionSet.Name,
                permissionSet.Label,
                'Løyvesett',
                permissionSet.Description,
                guides
            );
            entriesBySourceId.put(permissionSet.Id, entry);
            entriesByName.put(permissionSet.Name, entry);
        }
        Map<Id, PermissionEntry> groupsById = new Map<Id, PermissionEntry>();
        for (PermissionSetGroup permissionGroup : [
            SELECT Id, DeveloperName, MasterLabel, Description
            FROM PermissionSetGroup
            WHERE DeveloperName LIKE :FAMILY_PATTERNS
            WITH SYSTEM_MODE
        ]) {
            if (!isFamily(permissionGroup.DeveloperName)) {
                continue;
            }
            PermissionEntry entry = newEntry(
                permissionGroup.DeveloperName,
                permissionGroup.MasterLabel,
                'Løyvesettgruppe',
                permissionGroup.Description,
                guides
            );
            groupsById.put(permissionGroup.Id, entry);
            entriesByName.put(permissionGroup.DeveloperName, entry);
        }

        addGrants(entriesBySourceId);
        addGroupMembers(groupsById, entriesByName);
        addAssigneeCounts(entriesBySourceId, groupsById);

        List<PermissionEntry> entries = new List<PermissionEntry>(entriesByName.values());
        entries.sort(new EntryOrder());
        return entries;
    }

    /**
     * Whether the running user may list other users and their access.
     *
     * @return True with the custom permission AAREG_Admin_Access_Overview or View Setup.
     * @since 2026-11
     */
    @AuraEnabled
    public static Boolean canViewUsers() {
        if (FeatureManagement.checkPermission(OVERVIEW_PERMISSION)) {
            return true;
        }
        Id userId = UserInfo.getUserId();
        return ![
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId AND PermissionSet.PermissionsViewSetup = TRUE
                WITH SYSTEM_MODE
                LIMIT 1
            ]
            .isEmpty();
    }

    /**
     * Lists internal users (active and inactive) that hold at least one Arbeidsforhold permission set
     * or group, with their assignments and access issues.
     *
     * @return Users sorted by name.
     * @throws AuraHandledException When the running user may not view other users.
     * @since 2026-11
     */
    @AuraEnabled
    public static List<UserSummary> getUsers() {
        requireOverviewAccess();
        Map<String, AAREG_Permission_Guide__mdt> guides = loadGuides();
        Map<Id, UserSummary> usersById = new Map<Id, UserSummary>();
        Map<Id, Set<String>> effectiveNamesByUser = new Map<Id, Set<String>>();
        Set<Id> groupIds = new Set<Id>();
        String aaregPattern = FAMILY_PATTERNS[0];
        String p360Pattern = FAMILY_PATTERNS[1];
        List<PermissionSetAssignment> assignments = [
            SELECT
                AssigneeId,
                Assignee.Name,
                Assignee.Username,
                Assignee.IsActive,
                Assignee.LastLoginDate,
                Assignee.Profile.Name,
                PermissionSet.Name,
                PermissionSet.Label,
                PermissionSetGroupId,
                PermissionSetGroup.DeveloperName,
                PermissionSetGroup.MasterLabel,
                ExpirationDate
            FROM PermissionSetAssignment
            WHERE
                Assignee.UserType = 'Standard'
                AND ((PermissionSetGroupId = NULL
                AND (PermissionSet.Name LIKE :aaregPattern
                OR PermissionSet.Name LIKE :p360Pattern))
                OR PermissionSetGroup.DeveloperName LIKE :aaregPattern
                OR PermissionSetGroup.DeveloperName LIKE :p360Pattern)
            WITH SYSTEM_MODE
            ORDER BY Assignee.Name
            LIMIT 5000
        ];
        for (PermissionSetAssignment row : assignments) {
            String apiName = row.PermissionSetGroupId != null
                ? row.PermissionSetGroup.DeveloperName
                : row.PermissionSet.Name;
            if (!isFamily(apiName)) {
                continue;
            }
            if (!usersById.containsKey(row.AssigneeId)) {
                UserSummary summary = new UserSummary();
                summary.userId = row.AssigneeId;
                summary.name = row.Assignee.Name;
                summary.username = row.Assignee.Username;
                summary.isActive = row.Assignee.IsActive;
                summary.lastLogin = row.Assignee.LastLoginDate;
                summary.profileName = row.Assignee.Profile?.Name;
                usersById.put(row.AssigneeId, summary);
                effectiveNamesByUser.put(row.AssigneeId, new Set<String>());
            }
            Boolean viaGroup = row.PermissionSetGroupId != null;
            Assignment assignment = new Assignment();
            assignment.apiName = apiName;
            assignment.label = viaGroup ? row.PermissionSetGroup.MasterLabel : row.PermissionSet.Label;
            assignment.audienceLabel = audienceLabel(guides.get(apiName));
            assignment.expiresOn = row.ExpirationDate?.date();
            usersById.get(row.AssigneeId).assignments.add(assignment);
            effectiveNamesByUser.get(row.AssigneeId).add(apiName);
            if (viaGroup) {
                groupIds.add(row.PermissionSetGroupId);
            }
        }
        addGroupMemberNames(assignments, groupIds, effectiveNamesByUser);
        addLoginState(usersById);
        Boolean production = isProduction();
        for (UserSummary summary : usersById.values()) {
            evaluate(summary, effectiveNamesByUser.get(summary.userId), guides, production);
        }
        return usersById.values();
    }

    /**
     * Returns the effective access for one internal user across the Arbeidsforhold objects,
     * custom permissions and apps, with the permission sources that grant it.
     *
     * @param userId Internal user to inspect.
     * @return Effective access with sources, including profile and permission set groups.
     * @throws AuraHandledException When the running user may not view other users, or the user is not internal.
     * @since 2026-11
     */
    @AuraEnabled
    public static UserAccess getUserAccess(Id userId) {
        requireOverviewAccess();
        List<User> users = [SELECT Id, Name, UserType FROM User WHERE Id = :userId WITH SYSTEM_MODE LIMIT 1];
        if (users.isEmpty() || users[0].UserType != 'Standard') {
            throw newAuraException('Fann ingen intern brukar med denne ID-en.');
        }
        UserAccess access = new UserAccess();
        access.userId = users[0].Id;
        access.name = users[0].Name;

        Map<Id, String> sourceNames = new Map<Id, String>();
        for (PermissionSetAssignment row : [
            SELECT
                PermissionSetId,
                PermissionSet.Name,
                PermissionSet.Label,
                PermissionSet.IsOwnedByProfile,
                PermissionSet.Profile.Name,
                PermissionSetGroupId,
                PermissionSetGroup.MasterLabel
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
            WITH SYSTEM_MODE
        ]) {
            String name;
            if (row.PermissionSet.IsOwnedByProfile) {
                name = 'Profil: ' + row.PermissionSet.Profile?.Name;
            } else if (row.PermissionSetGroupId != null) {
                name = 'Gruppe: ' + row.PermissionSetGroup.MasterLabel;
            } else {
                name = row.PermissionSet.Label;
            }
            sourceNames.put(row.PermissionSetId, name);
        }
        access.sources = new List<String>(new Set<String>(sourceNames.values()));
        access.sources.sort();

        Map<String, ObjectGrant> grantsByObject = new Map<String, ObjectGrant>();
        for (String apiName : ACCESS_OBJECTS) {
            ObjectGrant grant = new ObjectGrant();
            grant.apiName = apiName;
            grant.label = objectLabel(apiName);
            grantsByObject.put(apiName, grant);
        }
        for (ObjectPermissions permission : [
            SELECT
                ParentId,
                SobjectType,
                PermissionsRead,
                PermissionsCreate,
                PermissionsEdit,
                PermissionsDelete,
                PermissionsViewAllRecords,
                PermissionsModifyAllRecords
            FROM ObjectPermissions
            WHERE ParentId IN :sourceNames.keySet() AND SobjectType IN :ACCESS_OBJECTS
            WITH SYSTEM_MODE
        ]) {
            ObjectGrant grant = grantsByObject.get(permission.SobjectType);
            mergeGrant(grant, permission);
            addUnique(grant.sources, sourceNames.get(permission.ParentId));
        }
        for (ObjectGrant grant : grantsByObject.values()) {
            grant.accessText = accessText(grant);
            grant.sources.sort();
            access.objects.add(grant);
        }

        Map<Id, NamedGrant> permissionsById = new Map<Id, NamedGrant>();
        for (CustomPermission permission : [
            SELECT Id, DeveloperName, MasterLabel
            FROM CustomPermission
            WHERE DeveloperName LIKE :FAMILY_PATTERNS
            WITH SYSTEM_MODE
            ORDER BY DeveloperName
        ]) {
            if (isFamily(permission.DeveloperName)) {
                permissionsById.put(permission.Id, namedGrant(permission.DeveloperName, permission.MasterLabel));
            }
        }
        Map<Id, NamedGrant> appsById = new Map<Id, NamedGrant>();
        for (AppMenuItem app : [
            SELECT ApplicationId, Name, Label
            FROM AppMenuItem
            WHERE Name IN :FAMILY_APPS
            WITH SYSTEM_MODE
            ORDER BY Label
        ]) {
            appsById.put(app.ApplicationId, namedGrant(app.Name, app.Label));
        }
        for (SetupEntityAccess entity : [
            SELECT ParentId, SetupEntityId
            FROM SetupEntityAccess
            WHERE
                ParentId IN :sourceNames.keySet()
                AND (SetupEntityId IN :permissionsById.keySet()
                OR SetupEntityId IN :appsById.keySet())
            WITH SYSTEM_MODE
        ]) {
            NamedGrant grant = permissionsById.containsKey(entity.SetupEntityId)
                ? permissionsById.get(entity.SetupEntityId)
                : appsById.get(entity.SetupEntityId);
            grant.granted = true;
            addUnique(grant.sources, sourceNames.get(entity.ParentId));
        }
        access.customPermissions = permissionsById.values();
        access.apps = appsById.values();
        return access;
    }

    private static PermissionEntry newEntry(
        String apiName,
        String label,
        String kind,
        String orgDescription,
        Map<String, AAREG_Permission_Guide__mdt> guides
    ) {
        PermissionEntry entry = new PermissionEntry();
        entry.apiName = apiName;
        entry.label = label;
        entry.kind = kind;
        entry.orgDescription = orgDescription;
        AAREG_Permission_Guide__mdt guide = guides.get(apiName);
        if (guide == null) {
            entry.audienceLabel = 'Ikkje dokumentert';
            entry.explanation = 'Løyvet manglar forklaring i AAREG_Permission_Guide__mdt.';
            return entry;
        }
        entry.documented = true;
        entry.audience = guide.Audience__c;
        entry.audienceLabel = audienceLabel(guide);
        entry.explanation = guide.Explanation__c;
        entry.recommendedWith = splitNames(guide.Recommended_With__c);
        entry.sortOrder = guide.Sort_Order__c == null ? 9998 : guide.Sort_Order__c;
        return entry;
    }

    private static void addGrants(Map<Id, PermissionEntry> entriesBySourceId) {
        Set<Id> sourceIds = entriesBySourceId.keySet();
        Map<Id, Map<String, ObjectGrant>> objectsBySource = new Map<Id, Map<String, ObjectGrant>>();
        for (ObjectPermissions permission : [
            SELECT
                ParentId,
                SobjectType,
                PermissionsRead,
                PermissionsCreate,
                PermissionsEdit,
                PermissionsDelete,
                PermissionsViewAllRecords,
                PermissionsModifyAllRecords
            FROM ObjectPermissions
            WHERE ParentId IN :sourceIds
            WITH SYSTEM_MODE
            ORDER BY SobjectType
        ]) {
            ObjectGrant grant = new ObjectGrant();
            grant.apiName = permission.SobjectType;
            grant.label = objectLabel(permission.SobjectType);
            mergeGrant(grant, permission);
            grant.accessText = accessText(grant);
            entriesBySourceId.get(permission.ParentId).objects.add(grant);
        }

        Map<Id, List<Id>> permissionSourcesByEntity = new Map<Id, List<Id>>();
        Map<Id, List<Id>> appSourcesByEntity = new Map<Id, List<Id>>();
        for (SetupEntityAccess entity : [
            SELECT ParentId, SetupEntityId, SetupEntityType
            FROM SetupEntityAccess
            WHERE ParentId IN :sourceIds AND SetupEntityType IN ('CustomPermission', 'TabSet', 'ApexClass')
            WITH SYSTEM_MODE
        ]) {
            PermissionEntry entry = entriesBySourceId.get(entity.ParentId);
            if (entity.SetupEntityType == 'ApexClass') {
                entry.apexClassCount++;
            } else if (entity.SetupEntityType == 'CustomPermission') {
                addToList(permissionSourcesByEntity, entity.SetupEntityId, entity.ParentId);
            } else {
                addToList(appSourcesByEntity, entity.SetupEntityId, entity.ParentId);
            }
        }
        for (CustomPermission permission : [
            SELECT Id, MasterLabel, DeveloperName
            FROM CustomPermission
            WHERE Id IN :permissionSourcesByEntity.keySet()
            WITH SYSTEM_MODE
        ]) {
            for (Id sourceId : permissionSourcesByEntity.get(permission.Id)) {
                entriesBySourceId.get(sourceId).customPermissions.add(permission.DeveloperName);
            }
        }
        for (AppMenuItem app : [
            SELECT ApplicationId, Label
            FROM AppMenuItem
            WHERE ApplicationId IN :appSourcesByEntity.keySet()
            WITH SYSTEM_MODE
        ]) {
            for (Id sourceId : appSourcesByEntity.get(app.ApplicationId)) {
                entriesBySourceId.get(sourceId).apps.add(app.Label);
            }
        }
    }

    private static void addGroupMembers(
        Map<Id, PermissionEntry> groupsById,
        Map<String, PermissionEntry> entriesByName
    ) {
        for (PermissionSetGroupComponent component : [
            SELECT PermissionSetGroupId, PermissionSet.Name
            FROM PermissionSetGroupComponent
            WHERE PermissionSetGroupId IN :groupsById.keySet()
            WITH SYSTEM_MODE
            ORDER BY PermissionSet.Name
        ]) {
            PermissionEntry groupEntry = groupsById.get(component.PermissionSetGroupId);
            groupEntry.members.add(component.PermissionSet.Name);
            PermissionEntry member = entriesByName.get(component.PermissionSet.Name);
            if (member != null) {
                member.memberOf.add(groupEntry.apiName);
                groupEntry.objects.addAll(member.objects);
                groupEntry.customPermissions.addAll(member.customPermissions);
                groupEntry.apps.addAll(member.apps);
                groupEntry.apexClassCount += member.apexClassCount;
            }
        }
    }

    private static void addAssigneeCounts(
        Map<Id, PermissionEntry> entriesBySourceId,
        Map<Id, PermissionEntry> groupsById
    ) {
        Set<Id> setIds = entriesBySourceId.keySet();
        Set<Id> groupIds = groupsById.keySet();
        for (AggregateResult row : [
            SELECT PermissionSetId, PermissionSetGroupId, COUNT(Id) total
            FROM PermissionSetAssignment
            WHERE Assignee.IsActive = TRUE AND (PermissionSetId IN :setIds OR PermissionSetGroupId IN :groupIds)
            WITH SYSTEM_MODE
            GROUP BY PermissionSetId, PermissionSetGroupId
        ]) {
            Id groupId = (Id) row.get('PermissionSetGroupId');
            Integer total = (Integer) row.get('total');
            PermissionEntry entry = groupId != null
                ? groupsById.get(groupId)
                : entriesBySourceId.get((Id) row.get('PermissionSetId'));
            if (entry != null) {
                entry.directAssignees += total;
            }
        }
    }

    private static void addGroupMemberNames(
        List<PermissionSetAssignment> assignments,
        Set<Id> groupIds,
        Map<Id, Set<String>> effectiveNamesByUser
    ) {
        if (groupIds.isEmpty()) {
            return;
        }
        Map<Id, List<String>> membersByGroup = new Map<Id, List<String>>();
        for (PermissionSetGroupComponent component : [
            SELECT PermissionSetGroupId, PermissionSet.Name
            FROM PermissionSetGroupComponent
            WHERE PermissionSetGroupId IN :groupIds
            WITH SYSTEM_MODE
        ]) {
            if (!membersByGroup.containsKey(component.PermissionSetGroupId)) {
                membersByGroup.put(component.PermissionSetGroupId, new List<String>());
            }
            membersByGroup.get(component.PermissionSetGroupId).add(component.PermissionSet.Name);
        }
        for (PermissionSetAssignment row : assignments) {
            if (row.PermissionSetGroupId != null && membersByGroup.containsKey(row.PermissionSetGroupId)) {
                effectiveNamesByUser.get(row.AssigneeId).addAll(membersByGroup.get(row.PermissionSetGroupId));
            }
        }
    }

    private static void addLoginState(Map<Id, UserSummary> usersById) {
        for (UserLogin login : [
            SELECT UserId, IsFrozen, IsPasswordLocked
            FROM UserLogin
            WHERE UserId IN :usersById.keySet()
            WITH SYSTEM_MODE
        ]) {
            UserSummary summary = usersById.get(login.UserId);
            summary.isFrozen = login.IsFrozen;
            summary.isPasswordLocked = login.IsPasswordLocked;
        }
    }

    @TestVisible
    private static void evaluate(
        UserSummary summary,
        Set<String> effectiveNames,
        Map<String, AAREG_Permission_Guide__mdt> guides,
        Boolean production
    ) {
        if (!summary.isActive) {
            summary.issues.add(new Issue('warning', 'Inaktiv brukar har framleis Arbeidsforhold-løyve. Fjern løyva.'));
        } else {
            if (summary.isFrozen) {
                summary.issues.add(new Issue('error', 'Brukaren er frosen og kan ikkje logge inn.'));
            }
            if (summary.isPasswordLocked) {
                summary.issues.add(new Issue('error', 'Passordet er låst etter for mange forsøk.'));
            }
            if (summary.lastLogin == null) {
                summary.issues.add(new Issue('warning', 'Har aldri logga inn.'));
            } else if (summary.lastLogin < Datetime.now().addDays(-STALE_LOGIN_DAYS)) {
                summary.issues.add(
                    new Issue('warning', 'Har ikkje logga inn på ' + STALE_LOGIN_DAYS + ' dagar eller meir.')
                );
            }
        }
        Boolean hasPersonalPermission = false;
        for (String apiName : effectiveNames) {
            AAREG_Permission_Guide__mdt guide = guides.get(apiName);
            if (guide != null && PERSONAL_AUDIENCES.contains(guide.Audience__c)) {
                hasPersonalPermission = true;
            }
        }
        Date expiryLimit = Date.today().addDays(EXPIRY_WARNING_DAYS);
        for (Assignment assignment : summary.assignments) {
            if (assignment.expiresOn != null && assignment.expiresOn <= expiryLimit) {
                summary.issues.add(
                    new Issue('warning', '«' + assignment.apiName + '» går ut ' + assignment.expiresOn.format() + '.')
                );
            }
        }
        for (String apiName : sortedNames(effectiveNames)) {
            AAREG_Permission_Guide__mdt guide = guides.get(apiName);
            if (guide == null) {
                continue;
            }
            if (guide.Audience__c == 'Portal') {
                summary.issues.add(
                    new Issue('warning', '«' + apiName + '» er meint for portalbrukarar, ikkje interne brukarar.')
                );
            } else if (guide.Audience__c == 'Integration' && hasPersonalPermission) {
                summary.issues.add(
                    new Issue(
                        'warning',
                        '«' + apiName + '» er meint for integrasjonsbrukarar, men brukaren har òg personlege løyve.'
                    )
                );
            } else if (guide.Audience__c == 'Test') {
                summary.issues.add(
                    new Issue(production ? 'error' : 'info', '«' + apiName + '» skal berre brukast i testmiljø.')
                );
            }
            for (String companion : splitNames(guide.Recommended_With__c)) {
                if (!effectiveNames.contains(companion)) {
                    summary.issues.add(
                        new Issue(
                            'warning',
                            '«' + apiName + '» blir normalt tildelt saman med «' + companion + '», som manglar.'
                        )
                    );
                }
            }
        }
        summary.status = worstLevel(summary.issues);
    }

    private static String worstLevel(List<Issue> issues) {
        String worst = 'ok';
        for (Issue issue : issues) {
            if (issue.level == 'error') {
                return 'error';
            }
            if (issue.level == 'warning') {
                worst = 'warning';
            } else if (worst == 'ok') {
                worst = 'info';
            }
        }
        return worst;
    }

    private static Map<String, AAREG_Permission_Guide__mdt> loadGuides() {
        Map<String, AAREG_Permission_Guide__mdt> guides = new Map<String, AAREG_Permission_Guide__mdt>();
        for (AAREG_Permission_Guide__mdt guide : AAREG_Permission_Guide__mdt.getAll().values()) {
            guides.put(guide.Permission_Name__c, guide);
        }
        return guides;
    }

    private static Boolean isFamily(String apiName) {
        return apiName != null && (apiName.startsWith('AAREG_') || apiName.startsWith('P360_'));
    }

    private static void requireOverviewAccess() {
        if (!canViewUsers()) {
            throw newAuraException(NO_ACCESS_MESSAGE);
        }
    }

    private static AuraHandledException newAuraException(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }

    private static Boolean isProduction() {
        return ![SELECT IsSandbox FROM Organization WITH SYSTEM_MODE LIMIT 1].IsSandbox;
    }

    private static String audienceLabel(AAREG_Permission_Guide__mdt guide) {
        if (guide == null || guide.Audience__c == null) {
            return 'Ikkje dokumentert';
        }
        return AUDIENCE_LABELS.containsKey(guide.Audience__c)
            ? AUDIENCE_LABELS.get(guide.Audience__c)
            : guide.Audience__c;
    }

    private static void mergeGrant(ObjectGrant grant, ObjectPermissions permission) {
        grant.canRead |= permission.PermissionsRead;
        grant.canCreate |= permission.PermissionsCreate;
        grant.canEdit |= permission.PermissionsEdit;
        grant.canDelete |= permission.PermissionsDelete;
        grant.viewAll |= permission.PermissionsViewAllRecords;
        grant.modifyAll |= permission.PermissionsModifyAllRecords;
    }

    private static String accessText(ObjectGrant grant) {
        List<String> parts = new List<String>();
        if (grant.canRead) {
            parts.add('Les');
        }
        if (grant.canCreate) {
            parts.add('Opprett');
        }
        if (grant.canEdit) {
            parts.add('Endre');
        }
        if (grant.canDelete) {
            parts.add('Slett');
        }
        if (grant.viewAll) {
            parts.add('Sjå alle');
        }
        if (grant.modifyAll) {
            parts.add('Endre alle');
        }
        return parts.isEmpty() ? 'Ingen tilgang' : String.join(parts, ', ');
    }

    private static String objectLabel(String apiName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(apiName);
        return objectType == null ? apiName : objectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel();
    }

    private static NamedGrant namedGrant(String apiName, String label) {
        NamedGrant grant = new NamedGrant();
        grant.apiName = apiName;
        grant.label = label;
        return grant;
    }

    private static List<String> splitNames(String value) {
        List<String> names = new List<String>();
        if (String.isBlank(value)) {
            return names;
        }
        for (String name : value.split(',')) {
            if (String.isNotBlank(name)) {
                names.add(name.trim());
            }
        }
        return names;
    }

    private static List<String> sortedNames(Set<String> names) {
        List<String> sorted = new List<String>(names);
        sorted.sort();
        return sorted;
    }

    private static void addUnique(List<String> values, String value) {
        if (value != null && !values.contains(value)) {
            values.add(value);
        }
    }

    private static void addToList(Map<Id, List<Id>> values, Id key, Id value) {
        if (!values.containsKey(key)) {
            values.put(key, new List<Id>());
        }
        values.get(key).add(value);
    }

    private class EntryOrder implements System.Comparator<PermissionEntry> {
        public Integer compare(PermissionEntry left, PermissionEntry right) {
            if (left.sortOrder != right.sortOrder) {
                return left.sortOrder < right.sortOrder ? -1 : 1;
            }
            return left.apiName.compareTo(right.apiName);
        }
    }
}
