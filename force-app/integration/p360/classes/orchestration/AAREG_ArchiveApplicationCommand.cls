/**
 * Command object for the archive application use case.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group AAREG P360 Orchestration
 */
public class AAREG_ArchiveApplicationCommand {
    /** Salesforce Application record id to archive. */
    public Id applicationId;

    /** Optional Salesforce Agreement record id related to the application. */
    public Id agreementId;

    /** Correlation ID used for tracing the archive flow. */
    public String correlationId;

    /** External ID used for idempotency and traceability. */
    public String externalId;
}
