/**
 * Temporary archive response DTO used to make F2 compile.
 * TODO F3: Replace with full P360 archive response contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 DTO
 */
public class P360_ArchiveResponseDto {
    /** Indicates whether the archive operation completed successfully. */
    public Boolean success;

    /** Human-readable technical or functional result message. */
    public String message;

    /** External P360 case id or equivalent archive case reference. */
    public String externalCaseId;

    /** External P360 document id or equivalent archive document reference. */
    public String externalDocumentId;
}
