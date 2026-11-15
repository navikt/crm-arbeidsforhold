/**
 * Access diagnosis for the current user in the Arbeidsforhold Admin app.
 *
 * Explains the user's profile, assigned permission sets, relevant custom permissions and
 * object access for the main Aa-registeret objects. The diagnosis covers only the current
 * user, never writes and never grants access.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
public with sharing class AAREG_AdminAccessDiagnosisController {
    private static final List<String> OBJECTS = new List<String>{
        'Application__c',
        'Access_Request__c',
        'Application_Decision__c',
        'Agreement__c',
        'Inquiry__c',
        'P360_Archive_Job__c',
        'Application_Log__c'
    };
    private static final Map<String, String> CUSTOM_PERMISSIONS = new Map<String, String>{
        'P360_Archive_Release' => 'Gir lov til å frigje vedtak til P360-arkivering manuelt.',
        'AAREG_UseAltinnScenario' => 'Gir lov til å bruke Altinn-testscenario i staden for ekte Altinn-svar.'
    };
    private static final String FIX_HINT = 'Be om permission set-et AAREG_Admin_Viewer for lesetilgang.';

    /**
     * The diagnosis for the current user.
     */
    public class Diagnosis {
        @AuraEnabled
        public String userName;
        @AuraEnabled
        public String profileName;
        @AuraEnabled
        public List<String> permissionSets = new List<String>();
        @AuraEnabled
        public List<CustomPermissionAccess> customPermissions = new List<CustomPermissionAccess>();
        @AuraEnabled
        public List<ObjectAccess> objects = new List<ObjectAccess>();
        @AuraEnabled
        public String note;
    }

    /**
     * Whether the user holds one custom permission.
     */
    public class CustomPermissionAccess {
        @AuraEnabled
        public String apiName;
        @AuraEnabled
        public Boolean granted;
        @AuraEnabled
        public String explanation;
    }

    /**
     * Object access for the current user with the permission sources that grant it.
     */
    public class ObjectAccess {
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
        public String grantedBy = '';
        @AuraEnabled
        public String explanation;
    }

    /**
     * Returns the access diagnosis for the current user.
     *
     * @return Diagnosis covering profile, permission sets, custom permissions and object access.
     * @since 2026-11
     */
    @AuraEnabled
    public static Diagnosis getDiagnosis() {
        Diagnosis diagnosis = new Diagnosis();
        diagnosis.userName = UserInfo.getName();
        Map<String, List<String>> grantsByObject = loadAssignments(diagnosis);
        for (String apiName : CUSTOM_PERMISSIONS.keySet()) {
            CustomPermissionAccess permission = new CustomPermissionAccess();
            permission.apiName = apiName;
            permission.granted = FeatureManagement.checkPermission(apiName);
            permission.explanation = CUSTOM_PERMISSIONS.get(apiName);
            diagnosis.customPermissions.add(permission);
        }
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (String apiName : OBJECTS) {
            diagnosis.objects.add(objectAccess(apiName, globalDescribe.get(apiName), grantsByObject.get(apiName)));
        }
        return diagnosis;
    }

    // Setup metadata is read in system mode because the diagnosis must work for users without View Setup.
    // Every query is bound to the running user, so no other user's access is exposed.
    private static Map<String, List<String>> loadAssignments(Diagnosis diagnosis) {
        Map<String, List<String>> grantsByObject = new Map<String, List<String>>();
        Id userId = UserInfo.getUserId();
        try {
            diagnosis.profileName = [SELECT Profile.Name FROM User WHERE Id = :userId WITH SYSTEM_MODE LIMIT 1]
            .Profile.Name;
            Map<Id, String> sourceNames = new Map<Id, String>();
            for (PermissionSetAssignment assignment : [
                SELECT PermissionSetId, PermissionSet.Name, PermissionSet.IsOwnedByProfile
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
                WITH SYSTEM_MODE
            ]) {
                Boolean profileOwned = assignment.PermissionSet.IsOwnedByProfile;
                sourceNames.put(
                    assignment.PermissionSetId,
                    profileOwned ? 'profil ' + diagnosis.profileName : assignment.PermissionSet.Name
                );
                if (!profileOwned) {
                    diagnosis.permissionSets.add(assignment.PermissionSet.Name);
                }
            }
            diagnosis.permissionSets.sort();
            for (ObjectPermissions permission : [
                SELECT ParentId, SobjectType
                FROM ObjectPermissions
                WHERE ParentId IN :sourceNames.keySet() AND SobjectType IN :OBJECTS AND PermissionsRead = TRUE
                WITH SYSTEM_MODE
            ]) {
                if (!grantsByObject.containsKey(permission.SobjectType)) {
                    grantsByObject.put(permission.SobjectType, new List<String>());
                }
                grantsByObject.get(permission.SobjectType).add(sourceNames.get(permission.ParentId));
            }
        } catch (QueryException error) {
            diagnosis.note = 'Kjelda til tilgangen kunne ikkje lesast: ' + error.getMessage();
        }
        return grantsByObject;
    }

    private static ObjectAccess objectAccess(String apiName, Schema.SObjectType objectType, List<String> grants) {
        ObjectAccess access = new ObjectAccess();
        access.apiName = apiName;
        if (objectType == null) {
            access.label = apiName;
            access.explanation = 'Objektet finst ikkje eller er ikkje synleg for deg. ' + FIX_HINT;
            return access;
        }
        Schema.DescribeSObjectResult describe = objectType.getDescribe();
        access.label = describe.getLabel();
        access.canRead = describe.isAccessible();
        access.canCreate = describe.isCreateable();
        access.canEdit = describe.isUpdateable();
        if (grants != null) {
            grants.sort();
            access.grantedBy = String.join(grants, ', ');
        }
        if (!access.canRead) {
            access.explanation = 'Du har ikkje lesetilgang. ' + FIX_HINT;
        } else if (String.isBlank(access.grantedBy)) {
            access.explanation = 'Du kan lese objektet; kjelda er truleg ein profil eller ei permission set-gruppe.';
        } else {
            access.explanation = 'Lesetilgang kjem frå: ' + access.grantedBy + '.';
        }
        return access;
    }
}
