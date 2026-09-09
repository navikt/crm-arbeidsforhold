/**
 * Internal DTO for the SIF CaseDocumentFileResult contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_CaseDocumentFileResultDto {
    /** Unique file record number. */
    public String recno;

    /** File title. */
    public String title;

    /** File format code or description. */
    public String format;

    /** File size. */
    public Integer size;
}
