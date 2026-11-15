/**
 * Temporary archive request DTO used to make F2 compile.
 * TODO F3: Replace with full P360 archive request contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 DTO
 */
public class P360_ArchiveRequestDto {
    /** Correlation ID used for tracing the archive flow. */
    public String correlationId;

    /** External ID used for idempotency and traceability. */
    public String externalId;

    /** Temporary title field for F2 skeleton usage. */
    public String title;

    /** CreateCase parameters; null when the document is filed on an existing case. */
    public P360_CreateCaseRequestDto createCase;

    /** CreateDocument parameters; the case number is filled from CreateCase when blank. */
    public P360_CreateDocumentRequestDto createDocument;
}
