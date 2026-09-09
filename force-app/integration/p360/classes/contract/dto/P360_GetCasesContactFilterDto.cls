/**
 * Internal DTO for the SIF GetCases contact-filter fields.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_GetCasesContactFilterDto {
    /** Personal ID number or enterprise number used for contact search. */
    public String contactReferenceNumber;

    /** Exact contact external identity used for contact search. */
    public String contactExternalId;

    /** Contact record numbers used for contact search. */
    public List<String> contactRecnos;
}
