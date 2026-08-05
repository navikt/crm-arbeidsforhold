@IsTest
public class AAREG_checkObjectTypeNamecheTest {
    @IsTest
    static void checkObjectTypeName_handles_non_empty_values() {
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c app = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert app;

        Thread__c th;
        th = new Thread__c(
            Name = 'Check object type',
            CRM_Related_Object__c = app.Id,
            CRM_FROM__c = UserInfo.getUserId()
        );
        insert th;

        Test.startTest();
        AAREG_checkObjectTypeNameche.bypassProfileLicenseCheck = true;
        AAREG_checkObjectTypeNameche.checkObjectTypeName(new List<Id>{ th.Id });
        AAREG_checkObjectTypeNameche.bypassProfileLicenseCheck = false;
        Test.stopTest();

        Thread__c updated = [SELECT Id, CRM_Account__c, OwnerId FROM Thread__c WHERE Id = :th.Id LIMIT 1];
        Application__c insertedApp = [SELECT Account__c, CreatedById FROM Application__c WHERE Id = :app.Id LIMIT 1];
        System.assertNotEquals(null, updated.Id);
        System.assertEquals(insertedApp.Account__c, updated.CRM_Account__c);
        System.assertEquals(insertedApp.CreatedById, updated.OwnerId);
    }
}
