/**
 * Internal DTO for the SIF Permission contract used by Case and Document row permissions.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_PermissionParameterDto {
    /** Access group name or recno. */
    public String accessGroup;

    /** Contact external ID or recno. */
    public String contactExternalId;

    /** Access level, such as Read, Insert, Edit or Delete. */
    public String accessLevel;

    /** Whether the permission is granted. */
    public Boolean grant;

    /** Whether the permission allows viewing document files. */
    public Boolean viewFile;

    /** Whether the permission allows inserting document files. */
    public Boolean insertFile;

    /** Whether the permission allows modifying document files. */
    public Boolean modifyFile;

    /** Whether the permission allows inserting document revisions. */
    public Boolean insertRev;

    /** Whether the permission allows modifying document revisions. */
    public Boolean modifyRev;

    /** Whether the permission allows adding documents to a case. */
    public Boolean insertDoc;

    /** Permission description shown in Public 360. */
    public String reference;
}
