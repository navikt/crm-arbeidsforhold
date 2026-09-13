/**
 * Verifies the controlled boundary of the Agreement domain service skeleton.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group AAREG P360 Domain
 */
@IsTest
private class AAREG_AgreementDomainServiceTest {
    /**
     * Verifies that Agreement archive context returns a typed internal context.
     *
     * @since 2026-09
     */
    @IsTest
    static void archiveContextStopsAtF3Boundary() {
        User minimumAccessUser = createAgreementUser();
        AAREG_AgreementDomainService service = new AAREG_AgreementDomainService();

        System.runAs(minimumAccessUser) {
            Agreement__c agreement = new Agreement__c();
            insert agreement;

            AAREG_AgreementArchiveContext context = service.getAgreementArchiveContext(agreement.Id);

            System.Assert.areEqual(agreement.Id, context.agreementId, 'Expected the agreement id.');
        }
    }

    /**
     * Verifies that a missing Agreement id is rejected before querying Salesforce.

     * @since 2026-09
     */
    @IsTest
    static void missingAgreementIdIsRejected() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            try {
                new AAREG_AgreementDomainService().getAgreementArchiveContext(null);
                System.Assert.fail('Expected a contract exception for a missing agreement id.');
            } catch (P360_ContractException caughtError) {
                System.Assert.areEqual('Agreement id is required.', caughtError.getMessage());
            }
        }
    }

    private static User createAgreementUser() {
        User userRecord;
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            userRecord = P360_TestDataFactory.createMinimumAccessUser();
            AAREG_TestDataFactory.assignPermissionSet(userRecord.Id, 'AAREG_Arbeidsforhold_Saksbehandling');
        }
        return userRecord;
    }
}
