/**
 * Internal DTO for the SIF DocumentResult contract returned by GetDocuments.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_DocumentResultDto {
    /** Unique 360 document record number. */
    public String recno;

    /** Document number assigned by 360. */
    public String documentNumber;

    /** Document title. */
    public String title;

    /** Archive code or recno. */
    public String archive;

    /** Document category code or description. */
    public String category;

    /** Journal status code or description. */
    public String status;

    /** Date the document was created or entered. */
    public Date documentDate;

    /** Date the document was journaled or closed. */
    public Date journalDate;

    /** Case number associated with the document. */
    public String caseNumber;

    /** Case external ID used as an alternative case identity. */
    public String caseExternalId;

    /** External document ID. */
    public String externalId;

    /** Globally unique identifier. */
    public String uid;

    /** Origin of the UID. */
    public String uidOrigin;
}
