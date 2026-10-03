/**
 * Internal DTO for the SIF AdditionalFieldParameter contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_AdditionalFieldParameterDto {
    /** Additional field name from the Public 360 meta model. */
    public String name;

    /** Single additional field value. */
    public String value;

    /** Optional comparison operator used by Get operations. */
    public String operatorType;
}
