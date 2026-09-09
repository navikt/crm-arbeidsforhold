/**
 * Internal DTO for the core SIF GetCasesQuery contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_GetCasesRequestDto {
    /** Authenticated 360 user context. */
    public String adContextUser;

    /** Maximum number of cases returned by the search. */
    public Integer maxReturnedCases;

    /** Pagination page used with maxReturnedCases and sortCriterion. */
    public Integer page;

    /** Result ordering, either RecnoAscending or RecnoDescending. */
    public String sortCriterion;

    /** Exact case record number filter. */
    public String recno;

    /** Case number filter. */
    public String caseNumber;

    /** External case identity filter. */
    public String externalId;

    /** External ID type; SIF defaults to SIF WS Case when omitted. */
    public String externalSystem;

    /** Case title filter; SIF supports wildcard search. */
    public String title;

    /** Archive code value filter. */
    public String archiveCode;

    /** Project number filter. */
    public String projectNumber;

    /** Case category code filter. */
    public String categoryCode;

    /** Returns cases modified after this date. */
    public Date lastDate;

    /** Subarchive code or recno filter. */
    public String subArchive;

    /** Case type code or recno filter. */
    public String caseType;

    /** Restricts results and related data to publicly publishable information. */
    public Boolean onlyPublicInfo;

    /** Includes case-case relations in the result. */
    public Boolean includeReferringCases;

    /** Includes case-document relations in the result. */
    public Boolean includeReferringDocuments;

    /** Includes case-contact relations in the result. */
    public Boolean includeCaseContacts;

    /** Includes additional 360 fields in the result. */
    public Boolean includeCustomFields;
}
