/**
 * Test class for AAREG_accountSelector.
 *
 * @author Ann Kristin Olsen
 * @since December 2021
 * @group AAREG External Access
 */
@IsTest
public class AAREG_accountSelectorTest {
    /**
     * selectAccountByOrganizationNumber should return a non-empty list for an existing organization number.
     *
     * @since December 2021
     */
    @IsTest
    static void getAccountIds() {
        Account account = AAREG_TestDataFactory.getAccount();
        insert account;

        System.test.startTest();
        List<Account> accountIdList = AAREG_accountSelector.selectAccountByOrganizationNumber(
            account.INT_OrganizationNumber__c
        );
        System.test.stoptest();
        System.Assert.areEqual(false, accountIdList.isEmpty(), 'Not an empty list returned');
    }

    /**
     * selectAccountByOrganizationNumber should return an empty list when the organization number is blank.
     *
     * @since December 2021
     */
    @IsTest
    static void noneOrganizationNumber() {
        Account acct = new Account(
            Name = 'Test',
            INT_OrganizationalStructure__c = 'ORGL',
            ShippingStreet = 'Test 123',
            ShippingPostalCode = '0211',
            ShippingCity = 'Oslo'
        );
        insert acct;

        System.test.startTest();
        List<Account> accountIdList = AAREG_accountSelector.selectAccountByOrganizationNumber(
            acct.INT_OrganizationNumber__c
        );
        System.test.stoptest();
        System.Assert.areEqual(true, accountIdList.isEmpty(), 'An empty list returned');
    }
}
