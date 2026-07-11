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
            CRM_FROM__c = UserInfo.getUserId(),
            CRM_Account__c = acct.Id
        );
        insert th;

        Test.startTest();
        AAREG_checkObjectTypeNameche.checkObjectTypeName(new List<Id>{ th.Id });
        Test.stopTest();

        Thread__c updated = [SELECT Id, CRM_Account__c FROM Thread__c WHERE Id = :th.Id LIMIT 1];
        System.assertNotEquals(null, updated.Id);
        System.assertNotEquals(null, updated.CRM_Account__c);
    }
}
