/**
 * Internal DTO for the shared SIF Address contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_AddressDto {
    /** Street address. */
    public String streetAddress;

    /** Postal code. */
    public String zipCode;

    /** Postal place or city. */
    public String zipPlace;

    /** Country name or ISO country code. */
    public String country;

    /** Municipality or county code. */
    public String county;

    /** County or area code. */
    public String area;

    /** Optional state used for some foreign countries. */
    public String state;
}
