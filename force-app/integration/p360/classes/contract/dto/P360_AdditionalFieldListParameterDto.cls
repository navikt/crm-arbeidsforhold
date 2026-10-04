/**
 * Internal DTO for the SIF AdditionalFieldListParameter contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_AdditionalFieldListParameterDto {
    /** Additional field name from the Public 360 meta model. */
    public String name;

    /** Values for the multi-value additional field. */
    public List<String> value;
}
