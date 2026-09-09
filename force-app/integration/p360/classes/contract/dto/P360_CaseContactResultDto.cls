/**
 * Internal DTO for the core SIF CaseContactResult contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_CaseContactResultDto {
    /** Name of the contact. */
    public String contactName;

    /** Contact role code on the case. */
    public String role;

    /** Contact record number. */
    public String recno;

    /** Private-person or enterprise reference number. */
    public String referenceNumber;

    /** Contact domain, such as Enterprise or PrivatePerson. */
    public String contactType;

    /** Contact external identity. */
    public String externalId;

    /** Contact address. */
    public P360_AddressDto address;

    /** Whether the contact is unofficial. */
    public Boolean isUnofficial;

    /** Subject area of the case contact. */
    public String subjectArea;

    /** Notes on the case contact. */
    public String notes;

    /** Action class returned for the case contact. */
    public P360_ActionClassDto actionClass;

    /** Contact role record number. */
    public String roleRecno;
}
