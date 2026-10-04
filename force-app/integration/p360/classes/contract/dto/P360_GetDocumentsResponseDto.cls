/**
 * Internal DTO for the SIF GetDocuments response contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_GetDocumentsResponseDto {
    /** Result documents returned by the service. */
    public List<P360_DocumentResultDto> documents;

    /** Number of documents returned in this page. */
    public Integer totalCount;

    /** Short error message when the operation fails. */
    public String errorMessage;

    /** Detailed error information when the operation fails. */
    public String errorDetails;
}
