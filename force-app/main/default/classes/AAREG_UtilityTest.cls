@isTest
public class AAREG_UtilityTest {
    @isTest
    static void testGetInstanceAndThreadRecordTypeId() {

        System.Test.startTest();
        AAREG_Utility utility = AAREG_Utility.getInstance();
        String threadRecordTypeId = utility.getThreadRecordTypeId();
        System.Test.stopTest();

        // Assertions
        System.Assert.areNotEqual(null, utility, 'Utility instance should not be null');
        System.Assert.areNotEqual(null, threadRecordTypeId, 'Thread RecordType Id should not be null when metadata is configured'
        );
    }

    @isTest
    static void testSingletonBehavior() {

        System.Test.startTest();
        AAREG_Utility util1 = AAREG_Utility.getInstance();
        AAREG_Utility util2 = AAREG_Utility.getInstance();
        System.Test.stopTest();

        // Assertion
        System.Assert.areEqual(util1, util2, 'getInstance should always return the same instance');
    }
}
