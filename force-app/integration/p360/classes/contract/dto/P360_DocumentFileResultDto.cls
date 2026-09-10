/**
 * Internal DTO for the SIF DocumentFileResult contract returned by GetDocuments when file metadata is included.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_DocumentFileResultDto {
    /** Unique file record number. */
    public String recno;

    /** File title. */
    public String title;

    /** File format code or description. */
    public String format;

    /** File size in bytes. */
    public Integer size;
}
