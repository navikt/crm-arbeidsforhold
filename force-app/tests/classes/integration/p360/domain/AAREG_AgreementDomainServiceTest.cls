/**
 * Tests AAREG_AgreementDomainService skeleton behavior.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group AAREG P360 Domain
 */
@IsTest
private class AAREG_AgreementDomainServiceTest {
    /**
     * Verifies that getAgreementArchiveContext throws a controlled contract exception.
     */
    @IsTest
    static void getAgreementArchiveContextThrowsContractException() {
        AAREG_AgreementDomainService service = new AAREG_AgreementDomainService();

        try {
            System.Test.startTest();
            service.getAgreementArchiveContext(Id.valueOf('001000000000002AAA'));
            System.Test.stopTest();

            System.Assert.fail('Expected P360_ContractException.');
        } catch (P360_ContractException e) {
            System.Assert.isTrue(
                e.getMessage()
                    .contains('AAREG_AgreementDomainService.getAgreementArchiveContext is not implemented yet'),
                'Unexpected exception message: ' + e.getMessage()
            );
        }
    }
}
