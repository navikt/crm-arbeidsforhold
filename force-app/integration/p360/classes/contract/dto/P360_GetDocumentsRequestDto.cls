/**
 * Internal DTO for the SIF GetDocumentsQuery contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_GetDocumentsRequestDto {
    /** Authenticated 360 user context. */
    public String adContextUser;

    /** Maximum number of documents returned by the search. */
    public Integer maxReturnedDocuments;

    /** Pagination page used with maxReturnedDocuments and sortCriterion. */
    public Integer page;

    /** Result ordering, either RecnoAscending or RecnoDescending. */
    public String sortCriterion;

    /** Exact document number filter. */
    public String documentNumber;

    /** Exact document title filter. */
    public String title;

    /** Document archive or archive code filter. */
    public String documentArchive;

    /** Case number filter for connected case. */
    public String caseNumber;

    /** Case external ID filter. */
    public String caseExternalId;

    /** External ID type; SIF defaults to SIF WS Document when omitted. */
    public String externalSystem;

    /** Returns documents modified after this date. */
    public Date lastDate;

    /** Restricts the result to a contact reference number. */
    public String contactReferenceNumber;

    /** Restricts the result to a contact external ID. */
    public String contactExternalId;

    /** Includes file metadata in the result if supported by the service. */
    public Boolean includeFileMetadata;

    /** Restricts results and related data to publicly publishable information. */
    public Boolean onlyPublicInfo;
}
