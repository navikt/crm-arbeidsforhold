/**
 * Verifies the core SIF CaseContactResult DTO used by CaseResult.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_CaseContactResultDtoTest {
    /**
     * Verifies that primitive case-contact result fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void caseContactResultPreservesCoreFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_CaseContactResultDto contact = new P360_CaseContactResultDto();
            contact.contactName = 'Example Contact';
            contact.role = 'Sakspart';
            contact.recno = '200001';
            contact.referenceNumber = '123456789';
            contact.contactType = 'PrivatePerson';
            contact.externalId = 'contact-123';
            contact.address = new P360_AddressDto();
            contact.address.streetAddress = 'Drammensveien 1';
            contact.address.country = 'NOR';
            contact.isUnofficial = false;
            contact.subjectArea = 'Employment';
            contact.notes = 'Contact notes';
            contact.roleRecno = '300001';

            P360_CaseContactResultDto roundTrippedContact = (P360_CaseContactResultDto) JSON.deserialize(
                JSON.serialize(contact),
                P360_CaseContactResultDto.class
            );

            System.Assert.areEqual(contact.contactName, roundTrippedContact.contactName, 'Expected the contact name.');
            System.Assert.areEqual(contact.role, roundTrippedContact.role, 'Expected the role.');
            System.Assert.areEqual(contact.recno, roundTrippedContact.recno, 'Expected the contact recno.');
            System.Assert.areEqual(
                contact.referenceNumber,
                roundTrippedContact.referenceNumber,
                'Expected the reference number.'
            );
            System.Assert.areEqual(contact.contactType, roundTrippedContact.contactType, 'Expected the contact type.');
            System.Assert.areEqual(contact.externalId, roundTrippedContact.externalId, 'Expected the external id.');
            System.Assert.areEqual(
                contact.address.streetAddress,
                roundTrippedContact.address.streetAddress,
                'Expected the contact street address.'
            );
            System.Assert.areEqual(
                contact.address.country,
                roundTrippedContact.address.country,
                'Expected the contact country.'
            );
            System.Assert.areEqual(
                contact.isUnofficial,
                roundTrippedContact.isUnofficial,
                'Expected the unofficial flag.'
            );
            System.Assert.areEqual(contact.subjectArea, roundTrippedContact.subjectArea, 'Expected the subject area.');
            System.Assert.areEqual(contact.notes, roundTrippedContact.notes, 'Expected the notes.');
            System.Assert.areEqual(contact.roleRecno, roundTrippedContact.roleRecno, 'Expected the role recno.');
        }
    }
}
