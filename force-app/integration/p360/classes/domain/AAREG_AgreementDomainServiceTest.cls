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
     * Verifies that Agreement archive context loading stops at the explicit F3 boundary.
     *
     * @since 2026-09
     */
    @IsTest
    static void archiveContextStopsAtF3Boundary() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        AAREG_AgreementDomainService service = new AAREG_AgreementDomainService();

        System.runAs(minimumAccessUser) {
            try {
                service.getAgreementArchiveContext(UserInfo.getUserId());
                System.Assert.fail('Expected a contract exception until the typed domain context is implemented.');
            } catch (P360_ContractException caughtError) {
                System.Assert.areEqual(
                    'AAREG_AgreementDomainService.getAgreementArchiveContext is not implemented yet. TODO F3.',
                    caughtError.getMessage(),
                    'Expected the explicit Agreement domain boundary message.'
                );
            }
        }
    }
}
