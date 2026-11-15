/**
 * Behaviour tests for the Arbeidsforhold Admin access diagnosis.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
@IsTest
private with sharing class AAREG_AdminAccessDiagnosisControllerTest {
    private static AAREG_AdminAccessDiagnosisController.ObjectAccess findObject(
        AAREG_AdminAccessDiagnosisController.Diagnosis diagnosis,
        String apiName
    ) {
        for (AAREG_AdminAccessDiagnosisController.ObjectAccess access : diagnosis.objects) {
            if (access.apiName == apiName) {
                return access;
            }
        }
        System.Assert.fail('Missing object ' + apiName);
        return null;
    }

    @IsTest
    static void viewerPermissionSetExplainsReadButNotEditAccess() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        PermissionSet viewer = [SELECT Id FROM PermissionSet WHERE Name = 'AAREG_Admin_Viewer' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = minimumAccessUser.Id, PermissionSetId = viewer.Id);
        AAREG_AdminAccessDiagnosisController.Diagnosis diagnosis;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            diagnosis = AAREG_AdminAccessDiagnosisController.getDiagnosis();
            System.Assert.areEqual(0, Limits.getDmlStatements(), 'Diagnosis must not write');
            System.Test.stopTest();
        }

        AAREG_AdminAccessDiagnosisController.ObjectAccess application = findObject(diagnosis, 'Application__c');
        System.Assert.isTrue(application.canRead, 'Viewer grants read');
        System.Assert.isFalse(application.canEdit, 'Viewer does not grant edit');
        System.Assert.isTrue(application.grantedBy.contains('AAREG_Admin_Viewer'), 'Source of access is explained');
        System.Assert.isTrue(diagnosis.permissionSets.contains('AAREG_Admin_Viewer'), 'Assigned set is listed');
    }

    @IsTest
    static void minimumAccessUserGetsExplanationForMissingAccess() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        AAREG_AdminAccessDiagnosisController.Diagnosis diagnosis;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            diagnosis = AAREG_AdminAccessDiagnosisController.getDiagnosis();
            System.Test.stopTest();
        }

        AAREG_AdminAccessDiagnosisController.ObjectAccess job = findObject(diagnosis, 'P360_Archive_Job__c');
        System.Assert.isFalse(job.canRead, 'Minimum access user cannot read jobs');
        System.Assert.isTrue(job.explanation.contains('AAREG_Admin_Viewer'), 'Explanation points to the fix');
        System.Assert.areEqual('Minimum Access - Salesforce', diagnosis.profileName, 'Profile is shown');
    }

    @IsTest
    static void archiveReleaseCustomPermissionIsReported() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        AAREG_AdminAccessDiagnosisController.Diagnosis diagnosis;

        System.runAs(minimumAccessUser) {
            diagnosis = AAREG_AdminAccessDiagnosisController.getDiagnosis();
        }

        Boolean found = false;
        for (AAREG_AdminAccessDiagnosisController.CustomPermissionAccess permission : diagnosis.customPermissions) {
            if (permission.apiName == 'P360_Archive_Release') {
                found = true;
                System.Assert.isFalse(permission.granted, 'Minimum access user cannot release archives');
                System.Assert.isNotNull(permission.explanation, 'Custom permission is explained');
            }
        }
        System.Assert.isTrue(found, 'P360_Archive_Release must be part of the diagnosis');
    }
}
