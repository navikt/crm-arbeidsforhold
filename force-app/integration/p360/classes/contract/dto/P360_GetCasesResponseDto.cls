/**
 * Internal DTO for the SIF GetCases response contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_GetCasesResponseDto {
    /** Result cases returned by the service. */
    public List<P360_CaseResultDto> cases;

    /** Number of cases returned in this page. */
    public Integer totalCount;

    /** Short error message when the operation fails. */
    public String errorMessage;

    /** Detailed error information when the operation fails. */
    public String errorDetails;
}
