/**
 * Launchpad for the Arbeidsforhold Admin app.
 *
 * Returns the main destinations for Arbeidsforhold, Aa-registeret, P360 and the contact model,
 * grouped by area. Each destination says whether the running user can open it, so the launchpad
 * never sends a user to a page that fails. Access is read from the running user's own object
 * access, tab settings, app menu and dashboards; nothing is granted or changed.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
public with sharing class AAREG_AdminNavigationController {
    private static final String KIND_OBJECT = 'object';
    private static final String KIND_TAB = 'navItem';
    private static final String KIND_APP = 'app';
    private static final String KIND_DASHBOARD = 'dashboard';
    private static final String KIND_SETUP = 'url';
    private static final Set<String> ADMIN_VIEWER = new Set<String>{ 'AAREG_Admin_Viewer' };
    /** Permission sets in this package that grant each launchpad tab; keep in sync with the permission set metadata. */
    @TestVisible
    private static final Map<String, Set<String>> TAB_PERMISSION_SETS = new Map<String, Set<String>>{
        'AAREG_Admin_Access' => ADMIN_VIEWER,
        'AAREG_Admin_Configuration' => ADMIN_VIEWER,
        'AAREG_Admin_Journey' => ADMIN_VIEWER,
        'AAREG_Admin_Monitor' => ADMIN_VIEWER,
        'AAREG_Admin_Permissions' => new Set<String>{ 'AAREG_Admin_Viewer', 'AAREG_Admin_Access_Overview' },
        'AAREG_Contact_Model' => new Set<String>{ 'AAREG_ContactModel_Admin' }
    };

    /** One area of the launchpad. */
    public class LaunchGroup {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public List<LaunchItem> items = new List<LaunchItem>();

        LaunchGroup(String key, String label) {
            this.key = key;
            this.label = label;
        }
    }

    /**
     * One destination. Target is the object API name, tab API name, app developer name, dashboard
     * record ID or relative setup URL, depending on kind.
     */
    public class LaunchItem {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String kind;
        @AuraEnabled
        public String target;
        @AuraEnabled
        public Boolean available = false;
        @AuraEnabled
        public String reason;
    }

    private class Destination {
        String groupKey;
        String key;
        String label;
        String description;
        String kind;
        String target;
        Destination(String groupKey, String kind, String target, String label, String description) {
            this.groupKey = groupKey;
            this.kind = kind;
            this.target = target;
            this.key = kind + ':' + target;
            this.label = label;
            this.description = description;
        }
    }

    /**
     * Returns the launchpad for the running user.
     *
     * @return Groups in display order. Unavailable destinations are included with a reason.
     * @since 2026-11
     */
    @AuraEnabled
    public static List<LaunchGroup> getLaunchpad() {
        List<Destination> destinations = destinations();
        Map<String, LaunchGroup> groups = new Map<String, LaunchGroup>{
            'aareg' => new LaunchGroup('aareg', 'Aa-registeret'),
            'operations' => new LaunchGroup('operations', 'Integrasjonar og drift'),
            'contactModel' => new LaunchGroup('contactModel', 'Kontaktmodell'),
            'reports' => new LaunchGroup('reports', 'Rapportar og dashboard'),
            'access' => new LaunchGroup('access', 'Tilgang og løyve'),
            'apps' => new LaunchGroup('apps', 'Andre appar')
        };
        Set<String> tabNames = new Set<String>();
        Set<String> appNames = new Set<String>();
        Set<String> dashboardNames = new Set<String>();
        for (Destination destination : destinations) {
            if (destination.kind == KIND_TAB) {
                tabNames.add(destination.target);
            } else if (destination.kind == KIND_APP) {
                appNames.add(destination.target);
            } else if (destination.kind == KIND_DASHBOARD) {
                dashboardNames.add(destination.target);
            }
        }
        Set<String> visibleTabs = visibleTabs(tabNames);
        Set<String> accessibleApps = accessibleApps(appNames);
        Map<String, Dashboard> dashboards = accessibleDashboards(dashboardNames);
        Boolean viewSetup = hasViewSetup();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        for (Destination destination : destinations) {
            LaunchItem item = new LaunchItem();
            item.key = destination.key;
            item.label = destination.label;
            item.description = destination.description;
            item.kind = destination.kind;
            item.target = destination.target;
            if (destination.kind == KIND_OBJECT) {
                Schema.SObjectType objectType = globalDescribe.get(destination.target);
                item.available =
                    objectType != null && objectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible();
                item.reason = item.available ? null : 'Du har ikkje lesetilgang til objektet.';
            } else if (destination.kind == KIND_TAB) {
                item.available = visibleTabs.contains(destination.target);
                item.reason = item.available ? null : 'Fana er ikkje synleg for deg.';
            } else if (destination.kind == KIND_APP) {
                item.available = accessibleApps.contains(destination.target);
                item.reason = item.available ? null : 'Du har ikkje tilgang til appen.';
            } else if (destination.kind == KIND_DASHBOARD) {
                Dashboard dashboard = dashboards.get(destination.target);
                item.available = dashboard != null;
                item.target = dashboard == null ? null : dashboard.Id;
                item.label = dashboard == null ? destination.label : dashboard.Title;
                item.reason = item.available ? null : 'Dashboardet finst ikkje eller er ikkje delt med deg.';
            } else {
                item.available = viewSetup;
                item.reason = item.available ? null : 'Krev løyvet «View Setup».';
            }
            groups.get(destination.groupKey).items.add(item);
        }
        return groups.values();
    }

    private static List<Destination> destinations() {
        return new List<Destination>{
            new Destination(
                'aareg',
                KIND_OBJECT,
                'Application__c',
                'Søknader',
                'Alle søknader om tilgang til Aa-registeret.'
            ),
            new Destination('aareg', KIND_OBJECT, 'Application_Decision__c', 'Vedtak', 'Vedtak på søknadene.'),
            new Destination('aareg', KIND_OBJECT, 'Agreement__c', 'Avtalar', 'Avtalar om tilgang til Aa-registeret.'),
            new Destination(
                'aareg',
                KIND_OBJECT,
                'Access_Request__c',
                'Tilgangsførespurnader',
                'Førespurnader om tilgang.'
            ),
            new Destination('aareg', KIND_OBJECT, 'Inquiry__c', 'Henvendingar', 'Henvendingar frå brukarane.'),
            new Destination(
                'aareg',
                KIND_TAB,
                'AAREG_Admin_Journey',
                'Søknadsreise',
                'Følg ein søknad gjennom heile prosessen.'
            ),
            new Destination(
                'operations',
                KIND_TAB,
                'AAREG_Admin_Monitor',
                'Integrasjonsmonitor',
                'Status for integrasjonar og jobbar.'
            ),
            new Destination(
                'operations',
                KIND_OBJECT,
                'P360_Archive_Job__c',
                'P360-arkivering',
                'Arkiveringsjobbar mot P360.'
            ),
            new Destination(
                'operations',
                KIND_OBJECT,
                'Application_Log__c',
                'Applikasjonslogg',
                'Feil og hendingar frå Apex og flytar.'
            ),
            new Destination(
                'operations',
                KIND_TAB,
                'AAREG_Admin_Configuration',
                'Konfigurasjon',
                'Innstillingar og funksjonsbrytarar.'
            ),
            new Destination(
                'contactModel',
                KIND_TAB,
                'AAREG_Contact_Model',
                'Kontaktmodell',
                'Status, utrulling og migrering.'
            ),
            new Destination(
                'contactModel',
                KIND_OBJECT,
                'AAREG_Contact_Point__c',
                'Kontaktpunkt',
                'E-post og telefon per kontakt og organisasjon.'
            ),
            new Destination(
                'contactModel',
                KIND_OBJECT,
                'AAREG_Contact_Migration_Run__c',
                'Migreringskøyringar',
                'Køyringar av kontaktmigreringa.'
            ),
            new Destination(
                'reports',
                KIND_DASHBOARD,
                'ZQCrjooiTzlUAAYJyxboIDkUaswcMq',
                'Admin-dashboard',
                'Hovuddashboardet for Aa-registeret.'
            ),
            new Destination(
                'reports',
                KIND_DASHBOARD,
                'cJnGwvGCUSKVeTaRvFsWdJsGDkPlHk',
                'Henvendingar',
                'Dashboard for henvendingar.'
            ),
            new Destination(
                'reports',
                KIND_DASHBOARD,
                'eialYSsGhUzuguROmbhAdrcVmFiQFv',
                'Dashboard',
                'Dashboard for Aa-registeret.'
            ),
            new Destination(
                'reports',
                KIND_DASHBOARD,
                'AAREG_Contact_Model_Overview',
                'Kontaktmodell',
                'Dashboard for kontaktmodellen.'
            ),
            new Destination('reports', KIND_OBJECT, 'Report', 'Alle rapportar', 'Rapportar du har tilgang til.'),
            new Destination(
                'access',
                KIND_TAB,
                'AAREG_Admin_Permissions',
                'Løyve og brukarar',
                'Kva løyva tyder, og kven som har dei.'
            ),
            new Destination('access', KIND_TAB, 'AAREG_Admin_Access', 'Tilgangsdiagnose', 'Di eiga tilgang.'),
            new Destination(
                'access',
                KIND_SETUP,
                '/lightning/setup/PermSets/home',
                'Løyvesett i Setup',
                'Endre løyvesett i Setup.'
            ),
            new Destination(
                'access',
                KIND_SETUP,
                '/lightning/setup/ManageUsers/home',
                'Brukarar i Setup',
                'Administrer brukarar i Setup.'
            ),
            new Destination('apps', KIND_APP, 'AAREG_application', 'Søknad', 'Saksbehandling av søknader.'),
            new Destination('apps', KIND_APP, 'AAREG_support', 'Brukarstøtte', 'Brukarstøtte og henvendingar.'),
            new Destination('apps', KIND_APP, 'AAREG_Contact_Model', 'Kontaktmodell', 'Eigen app for kontaktmodellen.')
        };
    }

    private static Set<String> visibleTabs(Set<String> tabNames) {
        Set<String> visible = new Set<String>();
        Set<String> assignedSets = new Set<String>();
        Set<Id> permissionSetIds = new Set<Id>();
        for (PermissionSetAssignment assignment : [
            SELECT PermissionSetId, PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            WITH SYSTEM_MODE
        ]) {
            permissionSetIds.add(assignment.PermissionSetId);
            assignedSets.add(assignment.PermissionSet.Name);
        }
        // Lightning requests only see profile-owned tab settings, so permission-set grants are resolved by name.
        for (String tabName : tabNames) {
            Set<String> granting = TAB_PERMISSION_SETS.containsKey(tabName)
                ? TAB_PERMISSION_SETS.get(tabName).clone()
                : new Set<String>();
            granting.retainAll(assignedSets);
            if (!granting.isEmpty()) {
                visible.add(tabName);
            }
        }
        for (PermissionSetTabSetting setting : [
            SELECT Name
            FROM PermissionSetTabSetting
            WHERE Name IN :tabNames AND ParentId IN :permissionSetIds
            WITH SYSTEM_MODE
        ]) {
            visible.add(setting.Name);
        }
        return visible;
    }

    private static Set<String> accessibleApps(Set<String> appNames) {
        Set<String> accessible = new Set<String>();
        for (AppMenuItem app : [
            SELECT Name
            FROM AppMenuItem
            WHERE Name IN :appNames AND IsAccessible = TRUE AND IsVisible = TRUE
        ]) {
            accessible.add(app.Name);
        }
        return accessible;
    }

    private static Map<String, Dashboard> accessibleDashboards(Set<String> developerNames) {
        Map<String, Dashboard> dashboards = new Map<String, Dashboard>();
        for (Dashboard dashboard : [
            SELECT Id, DeveloperName, Title
            FROM Dashboard
            WHERE DeveloperName IN :developerNames
            WITH USER_MODE
        ]) {
            dashboards.put(dashboard.DeveloperName, dashboard);
        }
        return dashboards;
    }

    private static Boolean hasViewSetup() {
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
}
