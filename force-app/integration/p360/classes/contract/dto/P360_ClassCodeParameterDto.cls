/**
 * SIF classification code parameter used by Case and Document contracts.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_ClassCodeParameterDto {
    /** Sort order for the classification code; primary code is 1. */
    public Integer sortOrder;

    /** Classification type code or recno. */
    public String archiveType;

    /** Indicates whether archiveCode is manually supplied text. */
    public Boolean isManualText;

    /** Classification code or value. */
    public String archiveCode;
}
