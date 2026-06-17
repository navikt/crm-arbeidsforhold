/**
 * This is the test class for the AAREG_Utility utility class.
 * <br><br>
 * @author Ashish Misra
 * @since Februar 2026
 * @group AAREG Utility
 */
@isTest
@SuppressWarnings('PMD.MethodNamingConventions')
public class AAREG_UtilityTest {

    /**
     * Verifies that the singleton instance is created successfully.
     * Asserts that the instance is not null.
     */
    @isTest
    static void when_Invoked_InstanceCreated() {
        System.Test.startTest();
        AAREG_Utility instance1 = AAREG_Utility.getInstance();
        System.Test.stopTest();

        System.Assert.isNotNull(instance1, 'The instance should not be null');
    }

    /**
     * Verifies that the constructor initializes the threadRecordTypeId correctly.
     * Asserts that the instance is not null.
     */
    @isTest
    static void when_ConstructorInvoked_ThreadRecordTypeIdReturned() {
        Id threadRecordTypeIdInOrg = [SELECT Id FROM RecordType WHERE DeveloperName = 'AAREG_Thread']?.Id;

        System.Test.startTest();
        AAREG_Utility utility = new AAREG_Utility();
        utility.threadRecordTypeIds.put('ThreadRecordTypeName', threadRecordTypeIdInOrg);
        Id threadRTId = utility.getThreadRecordTypeId('ThreadRecordTypeName');
        System.Test.stopTest();

        System.Assert.areEqual(
            threadRTId,
            threadRecordTypeIdInOrg,
            'The thread RecordType Id should match the expected value'
        );
    }

    /**
     * Verifies that the constructor initializes the threadRecordTypeId to null when metadata
     * value does not match any RecordType.
     * Asserts that the instance is not null.
     */
    @isTest
    static void when_UnknownKeyUsed_ThreadRecordTypeIdIsNull() {
        System.Test.startTest();
        AAREG_Utility utility = new AAREG_Utility();
        Id threadRTId = utility.getThreadRecordTypeId('Non_Existing_RecordType');
        System.Test.stopTest();

        System.Assert.isNull(threadRTId, 'The thread RecordType Id should be null');
    }

    /**
     * Verifies that the constructor initializes the threadRecordTypeId to null when metadata
     * has multiple values and the correct one is not in the first place.
     */
    @isTest
    static void when_NoArgGetterInvoked_ThreadRecordTypeIdReturned() {
        Id threadRecordTypeIdInOrg = [SELECT Id FROM RecordType WHERE DeveloperName = 'AAREG_Thread']?.Id;

        System.Test.startTest();
        AAREG_Utility utility = new AAREG_Utility();
        utility.threadRecordTypeIds.put('ThreadRecordTypeName', threadRecordTypeIdInOrg);
        Id threadRTId = utility.getThreadRecordTypeId();
        System.Test.stopTest();

        System.Assert.areEqual(threadRecordTypeIdInOrg, threadRTId, 'The default getter should return thread RecordType Id');
    }

    /**
     * Verifies that the constructor initializes the threadRecordTypeId correctly
     * when metadata has multiple values and the correct one is in the first place.
     */
    @isTest
    static void when_PersonRecordTypeConfigured_PersonThreadRecordTypeIdReturned() {
        Id threadRecordTypeIdInOrg = [SELECT Id FROM RecordType WHERE DeveloperName = 'AAREG_Thread']?.Id;
        Id expectedPersonThreadRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'AAREG_PersonThread'
        ]?.Id;

        System.Test.startTest();
        AAREG_Utility utility = new AAREG_Utility();
        utility.threadRecordTypeIds.put('ThreadRecordTypeName', threadRecordTypeIdInOrg);
        if (expectedPersonThreadRecordTypeId != null) {
            utility.threadRecordTypeIds.put('PersonThreadRecordTypeName', expectedPersonThreadRecordTypeId);
        }
        Id personThreadRTId = utility.getPersonThreadRecordTypeId();
        System.Test.stopTest();

        if (expectedPersonThreadRecordTypeId != null) {
            System.Assert.areEqual(
                expectedPersonThreadRecordTypeId,
                personThreadRTId,
                'The person thread RecordType Id should match expected value when configured'
            );
        } else {
            System.Assert.isNotNull(
                personThreadRTId,
                'The person thread RecordType Id should fall back to regular thread RecordType Id when not configured'
            );
        }
    }

    /**
     * Verifies that the constructor initializes the threadRecordTypeId to null when metadata
     * is empty.
     */
    @isTest
    static void when_PersonKeyRemoved_FallbackToThreadRecordTypeId() {
        Id threadRecordTypeIdInOrg = [SELECT Id FROM RecordType WHERE DeveloperName = 'AAREG_Thread']?.Id;

        System.Test.startTest();
        AAREG_Utility utility = new AAREG_Utility();
        utility.threadRecordTypeIds.put('ThreadRecordTypeName', threadRecordTypeIdInOrg);
        utility.threadRecordTypeIds.put('PersonThreadRecordTypeName', threadRecordTypeIdInOrg);
        Id expectedFallback = utility.getThreadRecordTypeId('ThreadRecordTypeName');
        utility.threadRecordTypeIds.remove('PersonThreadRecordTypeName');
        Id personThreadRTId = utility.getPersonThreadRecordTypeId();
        System.Test.stopTest();

        System.Assert.areEqual(expectedFallback, personThreadRTId, 'Should fall back to thread RecordType Id when person key is missing');
    }


    /**
     * Verifies that multiple invocations of getInstance method
     * return the same instance. (Singleton pattern).
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
     * Verifies that when the class is invoked and everything is set up correctly,
     * the Thread RecordType Id is returned by the utility. Also verifies that the
     * instance is not null.
     */
    @isTest
    static void when_ClassInvoked_AndEverythingOK_ThreadRecordTypeIdIsReturned() {
        Id threadRecordTypeIdInOrg = [SELECT Id FROM RecordType WHERE DeveloperName = 'AAREG_Thread']?.Id;

        System.Test.startTest();
        AAREG_Utility util = AAREG_Utility.getInstance();
        util.threadRecordTypeIds.put('ThreadRecordTypeName', threadRecordTypeIdInOrg);
        Id threadRTId = util.getThreadRecordTypeId('ThreadRecordTypeName');
        System.Test.stopTest();

        System.Assert.isNotNull(threadRTId, 'Thread RecordType Id should be populated');
    }
}
