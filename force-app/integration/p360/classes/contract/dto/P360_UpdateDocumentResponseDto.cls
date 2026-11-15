/**
 * Internal DTO for the SIF document-operation result returned by UpdateDocument.
 *
 * This carrier does not interpret errors or perform access checks.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group P360 DTO
 */
public with sharing class P360_UpdateDocumentResponseDto {
    /** Unique 360 document record number. */
    public String recno;

    /** Document number assigned by 360. */
    public String documentNumber;

    /** Whether the update succeeded. */
    public Boolean successful;

    /** Short error message when the update fails. */
    public String errorMessage;

    /** Detailed error information, which must not be logged without sanitization. */
    public String errorDetails;
}
