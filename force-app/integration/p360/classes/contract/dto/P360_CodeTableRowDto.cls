/**
 * Single P360 code table row read from `P360_Code_Table_Value__mdt`.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 K1/K2
 * @group P360 DTO
 */
public class P360_CodeTableRowDto {
    /** Name of the code table this row belongs to. */
    public String tableName;

    /** Salesforce-side key or value that maps to the P360 code. */
    public String salesforceKey;

    /** Language code for the display label, if the code table is language-dependent. */
    public String languageCode;

    /** P360-side code value. */
    public String p360Code;

    /** P360-side internal record number, if required in addition to the code. */
    public String p360Recno;

    /** Value to send on the wire, if it differs from p360Code. */
    public String transportValue;

    /** Human-readable display label. */
    public String displayLabel;

    /** Sort order for display when multiple rows belong to the same table. */
    public Integer sortOrder;
}
