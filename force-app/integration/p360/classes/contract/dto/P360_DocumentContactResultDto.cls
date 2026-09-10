/**
 * Internal DTO for the SIF DocumentContactResult contract used by GetDocuments.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_DocumentContactResultDto {
    /** Private-person or enterprise reference number. */
    public String referenceNumber;

    /** Contact external identity. */
    public String externalId;

    /** Contact role code or recno. */
    public String role;

    /** Name used for contact search and display in the document contact result. */
    public String searchName;

    /** Contact record number. */
    public String recno;

    /** Contact address. */
    public P360_AddressDto address;

    /** Email address for the contact. */
    public String email;

    /** Contact domain, such as Enterprise or PrivatePerson. */
    public String contactType;

    /** Whether the contact is unofficial. */
    public Boolean isUnofficial;
}
