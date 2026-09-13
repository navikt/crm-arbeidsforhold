/**
 * Typed internal context for Application-related P360 archive work.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group AAREG P360 Domain
 */
public class AAREG_ApplicationArchiveContext {
    /** Salesforce Application record id. */
    public Id applicationId;

    /** Existing P360 document id, when the application is already archived. */
    public String p360DocumentId;

    /** Existing P360 document number, when the application is already archived. */
    public String p360DocumentNumber;

    /** Existing P360 file id, when the application file is already archived. */
    public String p360FileId;
}
