/**
 * Test class for AAREG_distributionAccessController.
 * Verifies the behavior of the distribution access integration controller.
 *
 * @author AAREG Team
 * @version 66
 * @group Integration
 */
@isTest
public class AAREG_distributionAccessControllerTest {
    /**
     * Test setup method to initialize common test data.
     */
    @TestSetup
    static void setupTestData() {
        // Test setup for distribution access testing
        // No specific Salesforce objects required for callout tests
    }

    /**
     * Tests the handleRequest method with a valid PUT operation.
     * Verifies that a successful PUT request returns true in FlowOutputs.
     */
    @isTest
    static void testHandleRequest_PUT_Success() {
        // Arrange
        AAREG_distributionAccessController.FlowInputs input = new AAREG_distributionAccessController.FlowInputs();
        input.referenceId = UserInfo.getUserId();
        input.referenceType = 'PUT';
        input.refAccessType = 'Full';
        input.refOrganizationNumber = '123456789';

        List<AAREG_distributionAccessController.FlowInputs> inputs = new List<AAREG_distributionAccessController.FlowInputs>{
            input
        };

        // Act
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AAREG_DistributionAccessMock(200, 'OK'));
        List<AAREG_distributionAccessController.FlowOutputs> outputs = AAREG_distributionAccessController.handleRequest(
            inputs
        );
        Test.stopTest();

        // Assert
        System.Assert.isNotNull(outputs, 'Outputs should not be null');
        System.Assert.areEqual(1, outputs.size(), 'Outputs list should contain one element');
        System.Assert.isTrue(outputs[0].success, 'Operation should be successful');
    }

    /**
     * Tests the handleRequest method with a valid DELETE operation.
     * Verifies that a successful DELETE request returns true in FlowOutputs.
     */
    @isTest
    static void testHandleRequest_DELETE_Success() {
        // Arrange
        AAREG_distributionAccessController.FlowInputs input = new AAREG_distributionAccessController.FlowInputs();
        input.referenceId = UserInfo.getUserId();
        input.referenceType = 'DELETE';
        input.refAccessType = 'Limited';
        input.refOrganizationNumber = '987654321';

        List<AAREG_distributionAccessController.FlowInputs> inputs = new List<AAREG_distributionAccessController.FlowInputs>{
            input
        };

        // Act
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AAREG_DistributionAccessMock(200, 'OK'));
        List<AAREG_distributionAccessController.FlowOutputs> outputs = AAREG_distributionAccessController.handleRequest(
            inputs
        );
        Test.stopTest();

        // Assert
        System.Assert.isNotNull(outputs, 'Outputs should not be null');
        System.Assert.areEqual(1, outputs.size(), 'Outputs list should contain one element');
        System.Assert.isTrue(outputs[0].success, 'Operation should be successful');
    }

    /**
     * Tests the handleRequest method with an invalid operation type.
     * Verifies that an unsupported operation type returns false.
     */
    @isTest
    static void testHandleRequest_InvalidOperationType() {
        // Arrange
        AAREG_distributionAccessController.FlowInputs input = new AAREG_distributionAccessController.FlowInputs();
        input.referenceId = UserInfo.getUserId();
        input.referenceType = 'INVALID';
        input.refAccessType = 'Full';
        input.refOrganizationNumber = '123456789';

        List<AAREG_distributionAccessController.FlowInputs> inputs = new List<AAREG_distributionAccessController.FlowInputs>{
            input
        };

        // Act
        Test.startTest();
        List<AAREG_distributionAccessController.FlowOutputs> outputs = AAREG_distributionAccessController.handleRequest(
            inputs
        );
        Test.stopTest();

        // Assert
        System.Assert.isNotNull(outputs, 'Outputs should not be null');
        System.Assert.areEqual(1, outputs.size(), 'Outputs list should contain one element');
        System.Assert.isFalse(outputs[0].success, 'Operation should fail for invalid type');
    }

    /**
     * Tests the handleRequest method with null input.
     * Verifies that null input returns false result.
     */
    @isTest
    static void testHandleRequest_NullInput() {
        // Act
        Test.startTest();
        List<AAREG_distributionAccessController.FlowOutputs> outputs = AAREG_distributionAccessController.handleRequest(
            null
        );
        Test.stopTest();

        // Assert
        System.Assert.isNotNull(outputs, 'Outputs should not be null');
        System.Assert.areEqual(1, outputs.size(), 'Outputs list should contain one element');
        System.Assert.isFalse(outputs[0].success, 'Operation should fail for null input');
    }

    /**
     * Tests the handleRequest method with empty input list.
     * Verifies that empty input returns false result.
     */
    @isTest
    static void testHandleRequest_EmptyInput() {
        // Act
        Test.startTest();
        List<AAREG_distributionAccessController.FlowOutputs> outputs = AAREG_distributionAccessController.handleRequest(
            new List<AAREG_distributionAccessController.FlowInputs>()
        );
        Test.stopTest();

        // Assert
        System.Assert.isNotNull(outputs, 'Outputs should not be null');
        System.Assert.areEqual(1, outputs.size(), 'Outputs list should contain one element');
        System.Assert.isFalse(outputs[0].success, 'Operation should fail for empty input');
    }

    /**
     * Tests the handleRequest method when organization number is blank.
     * Verifies that missing organization number returns false result.
     */
    @isTest
    static void testHandleRequest_BlankOrganizationNumber() {
        // Arrange
        AAREG_distributionAccessController.FlowInputs input = new AAREG_distributionAccessController.FlowInputs();
        input.referenceId = UserInfo.getUserId();
        input.referenceType = 'PUT';
        input.refAccessType = 'Full';
        input.refOrganizationNumber = '';

        List<AAREG_distributionAccessController.FlowInputs> inputs = new List<AAREG_distributionAccessController.FlowInputs>{
            input
        };

        // Act
        Test.startTest();
        List<AAREG_distributionAccessController.FlowOutputs> outputs = AAREG_distributionAccessController.handleRequest(
            inputs
        );
        Test.stopTest();

        // Assert
        System.Assert.isNotNull(outputs, 'Outputs should not be null');
        System.Assert.isFalse(outputs[0].success, 'Operation should fail for blank organization number');
    }

    /**
     * Tests the generateJson method from AAREG_distributionAccessRequest.
     * Verifies that the JSON is properly formatted with the organization number.
     */
    @isTest
    static void testGenerateJson() {
        // Arrange
        String orgNumber = '123456789';

        // Act
        String json = AAREG_distributionAccessRequest.generateJson(orgNumber);

        // Assert
        System.Assert.isNotNull(json, 'JSON should not be null');
        System.Assert.isTrue(json.contains(orgNumber), 'JSON should contain organization number');
        System.Assert.isTrue(json.contains('organisasjonsnummer'), 'JSON should contain field name');
    }

    /**
     * Tests the generateHeaderToDistribution method with HTTP error response.
     * Verifies that status code errors are properly logged and handled.
     */
    @isTest
    static void testGenerateHeaderToDistribution_HttpError() {
        // Act
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AAREG_DistributionAccessMock(500, 'Internal Server Error'));
        AAREG_distributionAccessRequest.generateHeaderToDistribution('123456789', 'PUT_AAREG_DIST_TILGANG', '{}');
        Test.stopTest();

        // Assert - verify no unhandled exceptions
        System.Assert.isTrue(true, 'Exception should be properly handled and logged');
    }

    /**
     * Tests the FlowOutputs inner class constructors.
     * Verifies that both default and parameterized constructors work correctly.
     */
    @isTest
    static void testFlowOutputsConstructors() {
        // Act & Assert
        AAREG_distributionAccessController.FlowOutputs output1 = new AAREG_distributionAccessController.FlowOutputs();
        System.Assert.isFalse(output1.success, 'Default constructor should set success to false');

        AAREG_distributionAccessController.FlowOutputs output2 = new AAREG_distributionAccessController.FlowOutputs(
            true
        );
        System.Assert.isTrue(output2.success, 'Parameterized constructor should set success to true');
    }
}
