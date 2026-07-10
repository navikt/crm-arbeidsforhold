/**
 * @description Test class for P360 Exception classes
 * Tests custom exception types for P360 integration
 * @author AAREG Team
 * @version 66
 * @group P360 Exception
 */
@IsTest
public class P360_ExceptionTest {
    /**
     * @description Tests P360_ContractException instantiation and message
     * Verifies exception can be created with message
     */
    @IsTest
    static void testP360ContractException() {
        Test.startTest();
        String exceptionMessage = 'Test contract exception message';
        try {
            throw new P360_ContractException(exceptionMessage);
        } catch (P360_ContractException e) {
            System.Assert.areEqual(exceptionMessage, e.getMessage(), 'Exception should preserve message');
        } catch (Exception e) {
            System.Assert.fail('Should throw P360_ContractException: ' + e.getTypeName());
        }
        Test.stopTest();
    }

    /**
     * @description Tests P360_IntegrationException instantiation and message
     * Verifies exception can be created with message
     */
    @IsTest
    static void testP360IntegrationException() {
        Test.startTest();
        String exceptionMessage = 'Test integration exception message';
        try {
            throw new P360_IntegrationException(exceptionMessage);
        } catch (P360_IntegrationException e) {
            System.Assert.areEqual(exceptionMessage, e.getMessage(), 'Exception should preserve message');
        } catch (Exception e) {
            System.Assert.fail('Should throw P360_IntegrationException: ' + e.getTypeName());
        }
        Test.stopTest();
    }

    /**
     * @description Tests P360_TransportException instantiation and message
     * Verifies exception can be created with message
     */
    @IsTest
    static void testP360TransportException() {
        Test.startTest();
        String exceptionMessage = 'Test transport exception message';
        try {
            throw new P360_TransportException(exceptionMessage);
        } catch (P360_TransportException e) {
            System.Assert.areEqual(exceptionMessage, e.getMessage(), 'Exception should preserve message');
        } catch (Exception e) {
            System.Assert.fail('Should throw P360_TransportException: ' + e.getTypeName());
        }
        Test.stopTest();
    }

    /**
     * @description Tests exception inheritance from Exception base class
     * Verifies exceptions can be caught as generic Exception
     */
    @IsTest
    static void testExceptionInheritance() {
        Test.startTest();
        Boolean contractThrown = false;
        Boolean integrationThrown = false;
        Boolean transportThrown = false;

        try {
            throw new P360_ContractException('Test');
        } catch (Exception e) {
            contractThrown = true;
        }

        try {
            throw new P360_IntegrationException('Test');
        } catch (Exception e) {
            integrationThrown = true;
        }

        try {
            throw new P360_TransportException('Test');
        } catch (Exception e) {
            transportThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(contractThrown, 'P360_ContractException should be throwable');
        System.Assert.isTrue(integrationThrown, 'P360_IntegrationException should be throwable');
        System.Assert.isTrue(transportThrown, 'P360_TransportException should be throwable');
    }

    /**
     * @description Tests exception without explicit message parameter
     * Verifies exceptions can be created with no parameters
     */
    @IsTest
    static void testExceptionDefaultConstructor() {
        Test.startTest();
        try {
            throw new P360_ContractException();
        } catch (P360_ContractException e) {
            System.Assert.isTrue(true, 'Exception should handle default constructor');
        } catch (Exception e) {
            System.Assert.fail('Should throw P360_ContractException: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
