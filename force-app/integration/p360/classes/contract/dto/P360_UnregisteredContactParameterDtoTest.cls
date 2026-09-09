/**
 * Verifies the SIF unregistered document-contact parameter DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_UnregisteredContactParameterDtoTest {
    /**
     * Verifies that all documented unregistered-contact fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void unregisteredContactParameterPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_UnregisteredContactParameterDto contact = new P360_UnregisteredContactParameterDto();
            contact.role = 'Sender';
            contact.isUnofficial = true;
            contact.dispatchChannel = 'recno:1';
            contact.contactName = 'Example Contact';
            contact.contactCompanyName = 'Example Company';
            contact.referenceNumber = 'reference-123';
            contact.address = 'Example Street 1';
            contact.country = 'NO';
            contact.state = 'Oslo';
            contact.zipCode = '0123';
            contact.zipPlace = 'Oslo';
            contact.email = 'contact@example.test';
            contact.mobilePhone = '+4712345678';
            contact.phone = '+4722345678';
            contact.fax = '+4722345679';

            P360_UnregisteredContactParameterDto roundTrippedContact = (P360_UnregisteredContactParameterDto) JSON.deserialize(
                JSON.serialize(contact),
                P360_UnregisteredContactParameterDto.class
            );

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
            System.Assert.areEqual(contact.contactName, roundTrippedContact.contactName, 'Expected the contact name.');
            System.Assert.areEqual(
                contact.contactCompanyName,
                roundTrippedContact.contactCompanyName,
                'Expected the company name.'
            );
            System.Assert.areEqual(
                contact.referenceNumber,
                roundTrippedContact.referenceNumber,
                'Expected the reference number.'
            );
            System.Assert.areEqual(contact.address, roundTrippedContact.address, 'Expected the address.');
            System.Assert.areEqual(contact.country, roundTrippedContact.country, 'Expected the country.');
            System.Assert.areEqual(contact.state, roundTrippedContact.state, 'Expected the state.');
            System.Assert.areEqual(contact.zipCode, roundTrippedContact.zipCode, 'Expected the zip code.');
            System.Assert.areEqual(contact.zipPlace, roundTrippedContact.zipPlace, 'Expected the zip place.');
            System.Assert.areEqual(contact.email, roundTrippedContact.email, 'Expected the email.');
            System.Assert.areEqual(contact.mobilePhone, roundTrippedContact.mobilePhone, 'Expected the mobile phone.');
            System.Assert.areEqual(contact.phone, roundTrippedContact.phone, 'Expected the phone.');
            System.Assert.areEqual(contact.fax, roundTrippedContact.fax, 'Expected the fax.');
        }
    }
}
