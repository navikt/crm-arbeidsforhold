/**
 * Internal DTO for registered Case and Document contact references in SIF contracts.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_ContactParameterDto {
    /** Reference number of a private person or enterprise, or recno:... for any contact domain. */
    public String referenceNumber;

    /** External ID usable across contact domains. */
    public String externalId;

    /** Required role of the contact on the Case or Document. */
    public String role;

    /** Whether the contact is unofficial and screened from the public journal. */
    public Boolean isUnofficial;

    /** Preferred dispatch channel for a Document contact. */
    public String dispatchChannel;
}
