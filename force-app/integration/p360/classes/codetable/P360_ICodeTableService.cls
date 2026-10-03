/**
 * Contract for looking up P360 code table values by table name and Salesforce key.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 K2
 * @group P360 Code Table
 */
public interface P360_ICodeTableService {
    /**
     * Looks up a single active code table row.
     *
     * @param tableName Name of the code table to search.
     * @param salesforceKey Salesforce-side key to look up.
     * @return Matching code table row.
     * @throws P360_MissingCodeTableMappingException When no active row matches the table name and key.
     */
    P360_CodeTableRowDto getValue(String tableName, String salesforceKey);
}
