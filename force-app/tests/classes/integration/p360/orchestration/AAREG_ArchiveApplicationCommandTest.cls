/**
 * Tests AAREG_ArchiveApplicationCommand field behavior.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group AAREG P360 Orchestration
 */
@IsTest
private class AAREG_ArchiveApplicationCommandTest {
    /**
     * Verifies that all command fields can be set and read.
     */
    @IsTest
    static void fieldsCanBeSetAndRead() {
        AAREG_ArchiveApplicationCommand command = new AAREG_ArchiveApplicationCommand();

        System.Test.startTest();
        command.applicationId = Id.valueOf('001000000000004AAA');
        command.agreementId = Id.valueOf('001000000000005AAA');
        command.correlationId = 'corr-123';
        command.externalId = 'external-123';
        System.Test.stopTest();

        System.Assert.areEqual(Id.valueOf('001000000000004AAA'), command.applicationId, 'Unexpected application id.');
        System.Assert.areEqual(Id.valueOf('001000000000005AAA'), command.agreementId, 'Unexpected agreement id.');
        System.Assert.areEqual('corr-123', command.correlationId, 'Unexpected correlation id.');
        System.Assert.areEqual('external-123', command.externalId, 'Unexpected external id.');
    }
}
