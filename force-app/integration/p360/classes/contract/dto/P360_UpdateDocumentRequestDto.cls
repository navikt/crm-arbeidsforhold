/**
 * Internal DTO for the selected SIF UpdateDocumentParameter fields.
 *
 * This carrier does not validate document identity or perform access checks.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group P360 DTO
 */
public with sharing class P360_UpdateDocumentRequestDto {
    /** Authenticated 360 user context. */
    public String adUserContext;

    /** Existing document number used as one possible document identity. */
    public String documentNumber;

    /** External document identity used as an alternative to document number. */
    public String externalId;

    /** External ID type used with the external document identity. */
    public String externalSystem;

    /** Replacement document title. */
    public String title;

    /** Replacement title screened from public search. */
    public String unofficialTitle;

    /** Replacement document date. */
    public Date documentDate;

    /** Replacement document category code or recno. */
    public String category;

    /** Replacement journal status code or recno. */
    public String status;

    /** Replacement access code or recno. */
    public String accessCode;

    /** Replacement access paragraph code. */
    public String paragraph;

    /** Replacement access group code or recno. */
    public String accessGroup;

    /** Replacement journal date. */
    public Date journalDate;

    /** Replacement dispatch date. */
    public Date dispatchedDate;

    /** Whether the document is stored on paper. */
    public Boolean filedOnPaper;

    /** Registered document contacts to add or synchronize. */
    public List<P360_ContactParameterDto> contacts;

    /** Unregistered document contacts to add or synchronize. */
    public List<P360_UnregisteredContactParameterDto> unregisteredContacts;

    /** When true, synchronizes contacts and can remove existing document contacts. */
    public Boolean syncDocumentContacts;

    /** When true, removes the responsible person from the document. */
    public Boolean removeResponsiblePerson;

    /** Files to add to the identified document; existing files cannot be changed here. */
    public List<P360_FileParameterDto> files;
}
