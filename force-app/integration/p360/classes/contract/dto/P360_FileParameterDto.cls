/**
 * Internal DTO for the SIF Document File contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_FileParameterDto {
    /** Required file title. */
    public String title;

    /** Required file format code or recno. */
    public String format;

    /** Preferred binary file data representation. */
    public String data;

    /** Supported legacy base64 file data representation. */
    public String base64Data;

    /** File reference returned by FileService.Upload. */
    public String uploadedFileReference;

    /** Document relation type code or recno. */
    public String relationType;

    /** File version format code or recno. */
    public String versionFormat;
}
