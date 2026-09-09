/**
 * Internal DTO for the SIF CreateCaseParameter contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_CreateCaseRequestDto {
    /** Authenticated 360 user context. */
    public String adContextUser;

    /** Required case title. */
    public String title;

    /** Optional title screened from public search. */
    public String unofficialTitle;

    /** External ID for idempotency and lookup. */
    public String externalId;

    /** External ID type; SIF defaults to SIF WS Case when omitted. */
    public String externalSystem;

    /** Optional name of the external key. */
    public String externalName;

    /** Start date of the case progress. */
    public Date startDate;

    /** Case status code or recno. */
    public String status;

    /** Closing date used with a closing status. */
    public Date closedDate;

    /** Journal unit code or recno. */
    public String journalUnit;

    /** Subarchive code or recno. */
    public String subArchive;

    /** Classification codes used by the case. */
    public List<P360_ClassCodeParameterDto> archiveCodes;

    /** Case type code or recno; SIF defaults to the Noark case type. */
    public String caseType;

    /** Case category code or recno. */
    public String category;
}
