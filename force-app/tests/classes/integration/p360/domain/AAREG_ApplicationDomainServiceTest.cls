/**
 * Tests AAREG_ApplicationDomainService skeleton behavior.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group AAREG P360 Domain
 */
@IsTest
private class AAREG_ApplicationDomainServiceTest {
    /**
     * Verifies that getApplicationArchiveContext throws a controlled contract exception.
     */
    @IsTest
    static void getApplicationArchiveContextThrowsContractException() {
        AAREG_ApplicationDomainService service = new AAREG_ApplicationDomainService();

        try {
            System.Test.startTest();
            service.getApplicationArchiveContext(Id.valueOf('001000000000001AAA'));
            System.Test.stopTest();

            System.Assert.fail('Expected P360_ContractException.');
        } catch (P360_ContractException e) {
            System.Assert.isTrue(
                e.getMessage()
                    .contains('AAREG_ApplicationDomainService.getApplicationArchiveContext is not implemented yet'),
                'Unexpected exception message: ' + e.getMessage()
            );
        }
    }
}
