/**
 * Internal DTO for the SIF UpdateCase CaseOperationResult contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_UpdateCaseResponseDto {
    /** Unique 360 case record number. */
    public String recno;

    /** Case number assigned by 360. */
    public String caseNumber;

    /** Whether the update completed successfully. */
    public Boolean successful;

    /** Short error message when the operation fails. */
    public String errorMessage;

    /** Detailed error information when the operation fails. */
    public String errorDetails;
}
