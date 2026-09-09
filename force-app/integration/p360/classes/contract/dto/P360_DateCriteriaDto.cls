/**
 * Internal DTO for the SIF DateCriteriaType contract used by GetCases.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
public class P360_DateCriteriaDto {
    /** Date field name from the Public 360 meta model. */
    public String dateName;

    /** Comparison operator used for the date search. */
    public String operator;

    /** Date value used by the date search. */
    public Date dateValue;
}
