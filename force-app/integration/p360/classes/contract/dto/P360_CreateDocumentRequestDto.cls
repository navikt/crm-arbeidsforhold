/**
 * Internal DTO for the SIF CreateDocumentParameter contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_CreateDocumentRequestDto {
    /** Authenticated 360 user context. */
    public String adUserContext;

    /** Required document title. */
    public String title;

    /** Document date. */
    public Date documentDate;

    /** Document archive code or recno. */
    public String archive;

    /** Required document category code or recno. */
    public String category;

    /** Required journal status code or recno. */
    public String status;

    /** Case number used to connect the document. */
    public String caseNumber;

    /** Case external ID used as an alternative case identity. */
    public String caseExternalId;

    /** External ID for idempotency and lookup. */
    public String externalId;

    /** External ID type; SIF defaults to SIF WS Document when omitted. */
    public String externalSystem;

    /** Journal date. */
    public Date journalDate;

    /** Dispatch date, which must be before journalDate when supplied. */
    public Date dispatchedDate;

    /** Files to create or attach to the document. */
    public List<P360_FileParameterDto> files;
}
