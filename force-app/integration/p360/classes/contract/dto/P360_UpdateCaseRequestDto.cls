/**
 * Internal DTO for the core SIF UpdateCaseParameter contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_UpdateCaseRequestDto {
    /** Authenticated 360 user context. */
    public String adContextUser;

    /** Existing case number used as one possible case identity. */
    public String caseNumber;

    /** External case identity used as an alternative to case number. */
    public String externalId;

    /** External ID type; SIF defaults to SIF WS Case when omitted. */
    public String externalSystem;

    /** Optional replacement case title. */
    public String title;

    /** Optional replacement title screened from public search. */
    public String unofficialTitle;

    /** Optional replacement start date. */
    public Date startDate;

    /** Optional replacement case status code or recno. */
    public String status;

    /** Optional replacement journal unit code or recno. */
    public String journalUnit;

    /** Optional replacement subarchive code or recno. */
    public String subArchive;

    /** Whether the case is stored on paper. */
    public Boolean filedOnPaper;

    /** Explicitly removes the responsible person when true. */
    public Boolean removeResponsiblePerson;

    /** Synchronizes registered and unregistered case contacts when true. */
    public Boolean syncCaseContacts;

    /** Synchronizes case estates when true. */
    public Boolean syncCaseEstates;

    /** Synchronizes case archive codes when true. */
    public Boolean syncArchiveCodes;
}
