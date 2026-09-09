/**
 * Internal DTO for the SIF CaseOperationResult contract returned by CreateCase.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_CreateCaseResponseDto {
    /** Unique 360 case record number. */
    public String recno;

    /** Case number assigned by 360. */
    public String caseNumber;

    /** eArchive imported case number when applicable. */
    public String importedCaseNumber;

    /** Globally unique identifier. */
    public String uid;

    /** Origin of the UID. */
    public String uidOrigin;

    /** Short error message when the operation fails. */
    public String errorMessage;

    /** Detailed error information when the operation fails. */
    public String errorDetails;
}
