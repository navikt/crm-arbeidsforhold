/**
 * Internal DTO for the SIF UnregisteredContactParameter contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_UnregisteredContactParameterDto {
    /** Contact role as a code or recno. */
    public String role;

    /** Whether the contact is screened from the public journal. */
    public Boolean isUnofficial;

    /** Preferred dispatch channel for the document contact. */
    public String dispatchChannel;

    /** Required name of the unregistered contact. */
    public String contactName;

    /** Optional company name associated with the contact. */
    public String contactCompanyName;

    /** Optional external reference number of the contact. */
    public String referenceNumber;

    /** Optional street address. */
    public String address;

    /** Optional country. */
    public String country;

    /** Optional state or region. */
    public String state;

    /** Optional postal code. */
    public String zipCode;

    /** Optional postal place. */
    public String zipPlace;

    /** Optional email address. */
    public String email;

    /** Optional mobile phone number. */
    public String mobilePhone;

    /** Optional phone number. */
    public String phone;

    /** Optional fax number. */
    public String fax;
}
