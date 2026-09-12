/**
 * Verifies deterministic idempotency keys for P360 archive events.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Archive Job
 */
@IsTest
private class P360_IdempotencyKeyTest {
    /**
     * Verifies that each archive event type uses its documented stable key format.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldBuildDocumentedKeyForEachArchiveEventType() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            Id sourceId = minimumAccessUser.Id;
            Id contentVersionId = minimumAccessUser.ProfileId;

            System.Assert.areEqual(
                'APPLICATION_DOCUMENT:' + sourceId,
                P360_IdempotencyKey.forApplicationDocument(sourceId)
            );
            System.Assert.areEqual(
                'APPLICATION_ATTACHMENT:' + sourceId + ':' + contentVersionId,
                P360_IdempotencyKey.forApplicationAttachment(sourceId, contentVersionId)
            );
            System.Assert.areEqual('DECISION_DOCUMENT:' + sourceId, P360_IdempotencyKey.forDecisionDocument(sourceId));
            System.Assert.areEqual(
                'AGREEMENT_DOCUMENT:' + sourceId,
                P360_IdempotencyKey.forAgreementDocument(sourceId)
            );
        }
    }

    /**
     * Verifies that archive keys cannot be built without their required identifiers.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldRejectMissingIdentifiers() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            assertContractErrorForApplicationDocument();
            assertContractErrorForApplicationAttachment(null, minimumAccessUser.ProfileId);
            assertContractErrorForApplicationAttachment(minimumAccessUser.Id, null);
            assertContractErrorForDecisionDocument();
            assertContractErrorForAgreementDocument();
        }
    }

    private static void assertContractErrorForApplicationDocument() {
        try {
            P360_IdempotencyKey.forApplicationDocument(null);
            System.Assert.fail('A missing application id must be rejected.');
        } catch (P360_ContractException error) {
            System.Assert.isTrue(error.getMessage().contains('Application id'));
        }
    }

    private static void assertContractErrorForApplicationAttachment(Id applicationId, Id contentVersionId) {
        try {
            P360_IdempotencyKey.forApplicationAttachment(applicationId, contentVersionId);
            System.Assert.fail('A missing attachment identifier must be rejected.');
        } catch (P360_ContractException error) {
            System.Assert.isTrue(error.getMessage().contains('required'));
        }
    }

    private static void assertContractErrorForDecisionDocument() {
        try {
            P360_IdempotencyKey.forDecisionDocument(null);
            System.Assert.fail('A missing application decision id must be rejected.');
        } catch (P360_ContractException error) {
            System.Assert.isTrue(error.getMessage().contains('Application decision id'));
        }
    }

    private static void assertContractErrorForAgreementDocument() {
        try {
            P360_IdempotencyKey.forAgreementDocument(null);
            System.Assert.fail('A missing agreement id must be rejected.');
        } catch (P360_ContractException error) {
            System.Assert.isTrue(error.getMessage().contains('Agreement id'));
        }
    }
}
