/**
 * Internal DTO for the core SIF CaseResult contract returned by GetCases.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_CaseResultDto {
    /** Unique 360 case record number. */
    public String recno;

    /** Case title. */
    public String title;

    /** Case number assigned by 360. */
    public String caseNumber;

    /** External case identity. */
    public String externalId;

    /** Case start date returned by the SIF Date field. */
    public Date startDate;

    /** Human-readable case status. */
    public String statusDescription;

    /** Name of the responsible enterprise. */
    public String responsibleEnterpriseName;

    /** Name of the responsible person. */
    public String responsiblePersonName;

    /** Last modification date. */
    public Date lastChangedDate;

    /** Subarchive record number. */
    public String subArchive;

    /** Subarchive code. */
    public String subArchiveCode;

    /** Access-code code value. */
    public String accessCodeCode;

    /** Human-readable access-code description. */
    public String accessCodeDescription;

    /** Authorization paragraph. */
    public String paragraph;

    /** Case notes. */
    public String notes;

    /** Case type code. */
    public String caseTypeCode;

    /** Globally unique identifier. */
    public String uid;

    /** Origin of the UID. */
    public String uidOrigin;

    /** Case status record number. */
    public String statusRecno;
}
