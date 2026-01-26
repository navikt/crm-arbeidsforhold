@isTest
public class AAREG_accountSelectorTest {
    
    @isTest
      static void getAccountIds() {
        Account account = AAREG_TestDataFactory.getAccount();
        insert account;
    
        test.startTest();
        List<Account> accountIdList = AAREG_accountSelector.selectAccountByOrganizationNumber(account.INT_OrganizationNumber__c);
        test.stoptest();
          System.Assert.areEqual(false, accountIdList.isEmpty(), 'Not an empty list returned');
      }
    
    @isTest
    static void noneOrganizationNumber(){
      Account acct = new Account(
          Name = 'Test',
          INT_OrganizationalStructure__c = 'ORGL',
          ShippingStreet = 'Test 123',
          ShippingPostalCode = '0211',
          ShippingCity = 'Oslo');
        insert acct;
        
        test.startTest();
        List<Account> accountIdList = AAREG_accountSelector.selectAccountByOrganizationNumber(acct.INT_OrganizationNumber__c);
        test.stoptest();
        System.Assert.areEqual(true, accountIdList.isEmpty(), 'An empty list returned');     
    }
}