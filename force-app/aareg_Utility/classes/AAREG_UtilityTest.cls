/**
 * @description This is the test class for the AAREG_Utility utility class.
 * <br><br>
 * @author Ashish Misra (ashish.misra@nav.com), NAV
 * @since 0.1.0, Februar 2026
 * @group AAREG Utility
 */
@isTest
public class AAREG_UtilityTest {
    /**
     * @description Gets the instance of the AAREG_Utility class.
     * Asserts that the instance is not null.
     */
    @isTest
    static void when_Invoked_ReturnsInstanceOfClass() {
        System.Test.startTest();
        AAREG_Utility instance1 = AAREG_Utility.getInstance();
        System.Test.stopTest();

        System.Assert.isNotNull(instance1, 'The instance should not be null');
    }

   /**
     * @description Gets the instance of the AAREG_Utility class.
     * Asserts that the instance is not null.
     */
    @isTest
    static void when_ConstructorInvoked_ReturnsIntializedClass() {

        String threadRecordTypeIdIOrgen = [SELECT Id FROM RecordType WHERE developerName = 'AAREG_Thread']?.Id;

        CustomMetadataDAOTest.setMetadata(
            'SELECT Value__c FROM AAREG_Setting__mdt WHERE DeveloperName = \'ThreadRecordTypeName\'',
            (List<AAREG_Setting__mdt>) JSON.deserialize(
                '[{"attributes": {"type": "AAREG_Setting__mdt"},' +
                    '"Value__c":"AAREG_Thread"}]',
                List<AAREG_Setting__mdt>.class
            )
        );

        System.Test.startTest();
        AAREG_Utility aaregConstructor = new AAREG_Utility();
        String threadRTId = aaregConstructor.getThreadRecordTypeId();
        System.Test.stopTest();

        System.Assert.areEqual(threadRTId, threadRecordTypeIdIOrgen, 'The thread RecordType Id should match the expected value');
    }

    /**
     * @description Gets the instance of the AAREG_Utility class and makes sure that multiple
     * invocations return the same instance. (Singleton pattern).
     */
    @isTest
    static void when_InvokedMulitpleTimes_ReturnsTheSameInstanceOfClass_isSingleton() {
        System.Test.startTest();
        AAREG_Utility util1 = AAREG_Utility.getInstance();
        AAREG_Utility util2 = AAREG_Utility.getInstance();
        System.Test.stopTest();

        // Assertion
        System.Assert.areEqual(util1, util2, 'getInstance method should always return the same instance');
    }

    /**
     * @description Make sure that it returns the Thread RecordType Id from the AAREG_Utility
     * class along with the instance.
     */
    @isTest
    static void when_Invoked_ReturnsWithThreadRecordTypeId() {
        System.Test.startTest();
        AAREG_Utility util = AAREG_Utility.getInstance();
        String threadRTId = util.getThreadRecordTypeId();
        System.Test.stopTest();

        System.Assert.isNotNull(threadRTId, 'Thread RecordType Id should be populated');
    }
}
