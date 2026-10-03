/**
 * Verifies the controlled boundary of the Application domain service skeleton.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group AAREG P360 Domain
 */
@IsTest
private class AAREG_ApplicationDomainServiceTest {
    /**
     * Verifies that Application archive context returns typed internal reference data.
     *
     * @since 2026-09
     */
    @IsTest
    static void archiveContextStopsAtF3Boundary() {
        User minimumAccessUser = createApplicationUser();
        AAREG_ApplicationDomainService service = new AAREG_ApplicationDomainService();

        System.runAs(minimumAccessUser) {
            Application__c application = new Application__c();
            insert application;

            AAREG_ApplicationArchiveContext context = service.getApplicationArchiveContext(application.Id);

            System.Assert.areEqual(application.Id, context.applicationId, 'Expected the application id.');
            System.Assert.isNull(context.p360DocumentId, 'Expected no P360 document id in the current domain slice.');
        }
    }

    /**
     * Verifies that a missing Application id is rejected before querying Salesforce.

     * @since 2026-09
     */
    @IsTest
    static void missingApplicationIdIsRejected() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            try {
                new AAREG_ApplicationDomainService().getApplicationArchiveContext(null);
                System.Assert.fail('Expected a contract exception for a missing application id.');
            } catch (P360_ContractException caughtError) {
                System.Assert.areEqual('Application id is required.', caughtError.getMessage());
            }
        }
    }

    private static User createApplicationUser() {
        User userRecord;
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            userRecord = P360_TestDataFactory.createMinimumAccessUser();
            AAREG_TestDataFactory.assignPermissionSet(userRecord.Id, 'AAREG_Arbeidsforhold_Saksbehandling');
        }
        return userRecord;
    }
}
