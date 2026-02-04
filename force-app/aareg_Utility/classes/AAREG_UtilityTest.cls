/**
 * This is the test class for the AAREG_Utility utility class.
 * <br><br>
 * @author Ashish Misra (ashish.misra@nav.com), NAV
 * @since 0.1.0, Februar 2026
 * @group AAREG Utility
 */
@isTest
public class AAREG_UtilityTest {
    /**
     * Verifies that the singleton instance is created successfully.
     * Asserts that the instance is not null.
     */
    @isTest
    static void when_Invoked_InstanceCreated() {
        System.Test.startTest();
        resetSingleton();
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
        String threadRecordTypeIdIOrgen = [SELECT Id FROM RecordType WHERE developerName = 'AAREG_Thread']?.Id;

        mockMetadataWithValue('AAREG_Thread');

        System.Test.startTest();
        resetSingleton();
        AAREG_Utility aaregConstructor = new AAREG_Utility();
        String threadRTId = aaregConstructor.getThreadRecordTypeId();
        System.Test.stopTest();

        System.Assert.areEqual(
            threadRTId,
            threadRecordTypeIdIOrgen,
            'The thread RecordType Id should match the expected value'
        );
    }

    /**
     * Verifies that the constructor initializes the threadRecordTypeId to null when metadata
     * value does not match any RecordType.
     * Asserts that the instance is not null.
     */
    @isTest
    static void when_ConstructorInvoked_MetadataMismatchWithDatabase_ThreadRecordTypeId_IsNull() {
        String threadRecordTypeIdIOrgen = [SELECT Id FROM RecordType WHERE developerName = 'AAREG_Thread']?.Id;
        system.assert.isNotNull(threadRecordTypeIdIOrgen, 'The thread RecordType Id should not be null');

        mockMetadataWithValue('Non_Existing_RecordType');

        System.Test.startTest();
        resetSingleton();
        AAREG_Utility aaregConstructor = new AAREG_Utility();
        String threadRTId = aaregConstructor.getThreadRecordTypeId();
        System.Test.stopTest();

        System.Assert.areNotEqual(
            threadRTId,
            threadRecordTypeIdIOrgen,
            'The thread RecordType Id should not match the expected value'
        );
        System.Assert.isNull(threadRTId, 'The thread RecordType Id should be null');
    }

    /**
     * Verifies that the constructor initializes the threadRecordTypeId to null when metadata
     * has multiple values and the correct one is not in the first place.
     */
    @isTest
    static void when_ConstructorInvoked_MetadataWithMulitpleValuesInCorrecAtFirstPlace_ThreadRecordTypeId_IsNull() {
        String threadRecordTypeIdIOrgen = [SELECT Id FROM RecordType WHERE developerName = 'AAREG_Thread']?.Id;
        system.assert.isNotNull(threadRecordTypeIdIOrgen, 'The thread RecordType Id should not be null');

        mockMetadataWithMultipleValues('Non_Existing_RecordType1', 'Non_Existing_RecordType2', 'AAREG_Thread');

        System.Test.startTest();
        resetSingleton();
        AAREG_Utility aaregConstructor = new AAREG_Utility();
        String threadRTId = aaregConstructor.getThreadRecordTypeId();
        System.Test.stopTest();

        System.Assert.areNotEqual(
            threadRTId,
            threadRecordTypeIdIOrgen,
            'The thread RecordType Id should not match the expected value'
        );
        System.Assert.isNull(threadRTId, 'The thread RecordType Id should be null');
    }

    /**
     * Verifies that the constructor initializes the threadRecordTypeId correctly
     * when metadata has multiple values and the correct one is in the first place.
     */
    @isTest
    static void when_ConstructorInvoked_MetadataWithMulitpleValuesCorrectAtFirstPlace_ThreadRecordTypeIdIsReturned() {
        String threadRecordTypeIdIOrgen = [SELECT Id FROM RecordType WHERE developerName = 'AAREG_Thread']?.Id;

        mockMetadataWithMultipleValues('AAREG_Thread', 'Non_Existing_RecordType1', 'Non_Existing_RecordType2');

        System.Test.startTest();
        resetSingleton();
        AAREG_Utility aaregConstructor = new AAREG_Utility();
        String threadRTId = aaregConstructor.getThreadRecordTypeId();
        System.Test.stopTest();

        System.Assert.areEqual(
            threadRTId,
            threadRecordTypeIdIOrgen,
            'The thread RecordType Id should match the expected value'
        );
    }

    /**
     * Verifies that the constructor initializes the threadRecordTypeId to null when metadata
     * is empty.
     */
    @isTest
    static void when_ConstructorInvoked_MetaDataEmpty_ThreadRecordTypeIsNull() {
        mockEmptyMetadata();

        System.Test.startTest();
        resetSingleton();
        AAREG_Utility aaregConstructor = new AAREG_Utility();
        System.Test.stopTest();

        System.Assert.isNull(aaregConstructor.getThreadRecordTypeId(), 'The thread RecordType Id should be null');
    }

    /**
     * Verifies that multiple invocations of getInstance method
     * return the same instance. (Singleton pattern).
     */
    @isTest
    static void when_InvokedMulitpleTimes_ReturnsTheSameInstanceOfClass_isSingleton() {
        System.Test.startTest();
        resetSingleton();
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
        System.Test.startTest();
        resetSingleton();
        AAREG_Utility util = AAREG_Utility.getInstance();
        String threadRTId = util.getThreadRecordTypeId();
        System.Test.stopTest();

        System.Assert.isNotNull(threadRTId, 'Thread RecordType Id should be populated');
    }

    /*********************************************************************
     * Helper Methods for setting up test data and mocking dependencies
     *********************************************************************/

    // Helper method to reset the singleton instance for testing
    private static void resetSingleton() {
        AAREG_Utility.instance = null;
    }

    // Helper method to mock custom metadata
    private static void mockMetadataWithValue(String value) {
        CustomMetadataDAOTest.setMetadata(
            'SELECT Value__c FROM AAREG_Setting__mdt WHERE DeveloperName = \'ThreadRecordTypeName\'',
            (List<AAREG_Setting__mdt>) JSON.deserialize(
                '[{"attributes": {"type": "AAREG_Setting__mdt"},' + '"Value__c":"' + value + '"}]',
                List<AAREG_Setting__mdt>.class
            )
        );
    }

    // Helper method to mock custom metadata with multiple values
    private static void mockMetadataWithMultipleValues(String value1, String value2, String value3) {
        CustomMetadataDAOTest.setMetadata(
            'SELECT Value__c FROM AAREG_Setting__mdt WHERE DeveloperName = \'ThreadRecordTypeName\'',
            (List<AAREG_Setting__mdt>) JSON.deserialize(
                '[{"attributes": {"type": "AAREG_Setting__mdt"},' +
                    '"Value__c":"' +
                    value1 +
                    '"},' +
                    '{"attributes": {"type": "AAREG_Setting__mdt"},' +
                    '"Value__c":"' +
                    value2 +
                    '"},' +
                    '{"attributes": {"type": "AAREG_Setting__mdt"},' +
                    '"Value__c":"' +
                    value3 +
                    '"}]',
                List<AAREG_Setting__mdt>.class
            )
        );
    }

    // Helper method to mock empty custom metadata
    private static void mockEmptyMetadata() {
        CustomMetadataDAOTest.setMetadata(
            'SELECT Value__c FROM AAREG_Setting__mdt WHERE DeveloperName = \'ThreadRecordTypeName\'',
            new List<AAREG_Setting__mdt>()
        );
    }
}
