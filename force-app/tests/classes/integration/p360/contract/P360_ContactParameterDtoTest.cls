/**
 * Verifies the shared registered-contact DTO used by SIF Case and Document contracts.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_ContactParameterDtoTest {
    /**
     * Verifies that registered-contact fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void contactParameterPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_ContactParameterDto contact = new P360_ContactParameterDto();
            contact.externalId = 'contact-123';
            contact.role = 'Contact';
            contact.isUnofficial = false;
            contact.dispatchChannel = 'recno:1';

            P360_ContactParameterDto roundTrippedContact = (P360_ContactParameterDto) JSON.deserialize(
                JSON.serialize(contact),
                P360_ContactParameterDto.class
            );

            System.Assert.areEqual(contact.externalId, roundTrippedContact.externalId, 'Expected the external id.');
            System.Assert.areEqual(contact.role, roundTrippedContact.role, 'Expected the contact role.');
            System.Assert.areEqual(
                contact.isUnofficial,
                roundTrippedContact.isUnofficial,
                'Expected the unofficial flag.'
            );
            System.Assert.areEqual(
                contact.dispatchChannel,
                roundTrippedContact.dispatchChannel,
                'Expected the dispatch channel.'
            );
        }
    }
}
