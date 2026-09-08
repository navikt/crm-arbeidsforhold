/**
 * Internal result object for the archive application use case.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group AAREG P360 Orchestration
 */
public class AAREG_ArchiveApplicationResult {
    /** Indicates whether the archive operation completed successfully. */
    public Boolean success;

    /** Human-readable technical or functional result message. */
    public String message;

    /** Correlation ID used for tracing the archive flow. */
    public String correlationId;

    /** External P360 case id or equivalent archive case reference. */
    public String externalCaseId;

    /** External P360 document id or equivalent archive document reference. */
    public String externalDocumentId;
}
