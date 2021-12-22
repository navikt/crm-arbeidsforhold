@isTest
public class AAREG_accountSelectorTest {
    
    @isTest
      static void getAccountIds() {
        Account account = AAREG_TestDataFactory.getAccount();
        insert account;
    
        test.startTest();
        List<Account> accountIdList = AAREG_accountSelector.selectAccountByOrganizationNumber(account.INT_OrganizationNumber__c);
        System.debug(accountIdList);
        System.assertEquals(false, accountIdList.isEmpty(), 'Not an empty list returned');
        test.stoptest();
      }
}