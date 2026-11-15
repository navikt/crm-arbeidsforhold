/**
 * Verifies the internal UpdateDocument request contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group P360 DTO
 */
@IsTest
private class P360_UpdateDocumentRequestDtoTest {
    /**
     * Preserves document identity, update fields and nested references through a JSON round trip.
     *
     * @since 2026-11
     */
    @IsTest
    static void documentNumberAndUpdatesSurviveRoundTrip() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            P360_ContactParameterDto contact = new P360_ContactParameterDto();
            contact.externalId = 'contact-123';
            contact.role = 'Sender';
            P360_UnregisteredContactParameterDto unregisteredContact = new P360_UnregisteredContactParameterDto();
            unregisteredContact.contactName = 'Synthetic contact';
            unregisteredContact.role = 'Recipient';
            P360_FileParameterDto file = new P360_FileParameterDto();
            file.title = 'attachment.pdf';
            file.format = 'PDF';
            file.uploadedFileReference = 'file-ref-123';

            P360_UpdateDocumentRequestDto request = new P360_UpdateDocumentRequestDto();
            request.adUserContext = 'synthetic-context';
            request.documentNumber = '26/00001-1';
            request.title = 'Updated title';
            request.documentDate = Date.newInstance(2026, 11, 15);
            request.category = 'Incoming';
            request.status = 'Open';
            request.accessCode = 'U';
            request.paragraph = 'test-paragraph';
            request.accessGroup = 'test-group';
            request.journalDate = Date.newInstance(2026, 11, 18);
            request.dispatchedDate = Date.newInstance(2026, 11, 16);
            request.filedOnPaper = false;
            request.contacts = new List<P360_ContactParameterDto>{ contact };
            request.unregisteredContacts = new List<P360_UnregisteredContactParameterDto>{ unregisteredContact };
            request.files = new List<P360_FileParameterDto>{ file };
            request.syncDocumentContacts = false;
            request.removeResponsiblePerson = true;

            P360_UpdateDocumentRequestDto output = (P360_UpdateDocumentRequestDto) JSON.deserialize(
                JSON.serialize(request, true),
                P360_UpdateDocumentRequestDto.class
            );
            System.Test.stopTest();

            System.Assert.areEqual('synthetic-context', output.adUserContext);
            System.Assert.areEqual('26/00001-1', output.documentNumber);
            System.Assert.areEqual('Updated title', output.title);
            System.Assert.areEqual(Date.newInstance(2026, 11, 15), output.documentDate);
            System.Assert.areEqual('Incoming', output.category);
            System.Assert.areEqual('Open', output.status);
            System.Assert.areEqual('U', output.accessCode);
            System.Assert.areEqual('test-paragraph', output.paragraph);
            System.Assert.areEqual('test-group', output.accessGroup);
            System.Assert.areEqual(Date.newInstance(2026, 11, 18), output.journalDate);
            System.Assert.areEqual(Date.newInstance(2026, 11, 16), output.dispatchedDate);
            System.Assert.areEqual(false, output.filedOnPaper);
            System.Assert.areEqual(false, output.syncDocumentContacts);
            System.Assert.areEqual(true, output.removeResponsiblePerson);
            System.Assert.areEqual('contact-123', output.contacts[0].externalId);
            System.Assert.areEqual('Sender', output.contacts[0].role);
            System.Assert.areEqual('Synthetic contact', output.unregisteredContacts[0].contactName);
            System.Assert.areEqual('Recipient', output.unregisteredContacts[0].role);
            System.Assert.areEqual('attachment.pdf', output.files[0].title);
            System.Assert.areEqual('PDF', output.files[0].format);
            System.Assert.areEqual('file-ref-123', output.files[0].uploadedFileReference);
        }
    }

    /**
     * Preserves external identity and distinguishes an omitted field from an explicit empty string.
     *
     * @since 2026-11
     */
    @IsTest
    static void externalIdentityPreservesNullAndExplicitEmptyString() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            P360_UpdateDocumentRequestDto request = new P360_UpdateDocumentRequestDto();
            request.externalId = 'document-123';
            request.externalSystem = 'synthetic-system';
            request.title = null;
            request.unofficialTitle = '';
            String serialized = JSON.serialize(request, true);
            Map<String, Object> fields = (Map<String, Object>) JSON.deserializeUntyped(serialized);
            P360_UpdateDocumentRequestDto output = (P360_UpdateDocumentRequestDto) JSON.deserialize(
                serialized,
                P360_UpdateDocumentRequestDto.class
            );
            System.Test.stopTest();

            System.Assert.areEqual('document-123', output.externalId);
            System.Assert.areEqual('synthetic-system', output.externalSystem);
            System.Assert.isNull(output.title);
            System.Assert.isNull(output.syncDocumentContacts);
            System.Assert.isFalse(fields.containsKey('title'), 'A null update field must be omitted when requested.');
            System.Assert.areEqual('', output.unofficialTitle, 'An explicit empty string must be preserved.');
            System.Assert.areEqual('', fields.get('unofficialTitle'));
        }
    }
}
