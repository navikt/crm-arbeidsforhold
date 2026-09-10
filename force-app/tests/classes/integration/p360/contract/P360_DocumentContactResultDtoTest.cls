/**
 * Verifies the SIF DocumentContactResult DTO used by GetDocuments.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_DocumentContactResultDtoTest {
    /**
     * Verifies that document-contact fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void documentContactResultPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_DocumentContactResultDto contact = new P360_DocumentContactResultDto();
            contact.referenceNumber = '123456789';
            contact.externalId = 'person-456';
            contact.role = 'Recipient';
            contact.searchName = 'Ola Nordmann';
            contact.recno = '500200';
            contact.address = new P360_AddressDto();
            contact.address.streetAddress = 'Testveien 1';
            contact.address.zipCode = '0150';
            contact.address.zipPlace = 'Oslo';
            contact.address.country = 'Norge';
            contact.email = 'ola@example.com';
            contact.contactType = 'PrivatePerson';
            contact.isUnofficial = false;

            P360_DocumentContactResultDto roundTrippedContact = (P360_DocumentContactResultDto) JSON.deserialize(
                JSON.serialize(contact),
                P360_DocumentContactResultDto.class
            );

            System.Assert.areEqual(
                contact.referenceNumber,
                roundTrippedContact.referenceNumber,
                'Expected the contact reference number.'
            );
            System.Assert.areEqual(contact.externalId, roundTrippedContact.externalId, 'Expected the external id.');
            System.Assert.areEqual(contact.role, roundTrippedContact.role, 'Expected the role.');
            System.Assert.areEqual(contact.searchName, roundTrippedContact.searchName, 'Expected the search name.');
            System.Assert.areEqual(contact.recno, roundTrippedContact.recno, 'Expected the recno.');
            System.Assert.areEqual(
                contact.address.streetAddress,
                roundTrippedContact.address.streetAddress,
                'Expected the street address.'
            );
            System.Assert.areEqual(contact.email, roundTrippedContact.email, 'Expected the email.');
            System.Assert.areEqual(contact.contactType, roundTrippedContact.contactType, 'Expected the contact type.');
            System.Assert.areEqual(
                contact.isUnofficial,
                roundTrippedContact.isUnofficial,
                'Expected the unofficial flag.'
            );
        }
    }
}
