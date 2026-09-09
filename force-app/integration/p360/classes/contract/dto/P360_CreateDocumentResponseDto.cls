/**
 * Internal DTO for the SIF DocumentOperationResult returned by CreateDocument.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_CreateDocumentResponseDto {
    /** Unique 360 document record number. */
    public String recno;

    /** Document number assigned by 360. */
    public String documentNumber;

    /** eArchive imported document number when applicable. */
    public String importedDocumentNumber;

    /** Globally unique identifier. */
    public String uid;

    /** Origin of the UID. */
    public String uidOrigin;

    /** Short error message when the operation fails. */
    public String errorMessage;

    /** Detailed error information when the operation fails. */
    public String errorDetails;
}
