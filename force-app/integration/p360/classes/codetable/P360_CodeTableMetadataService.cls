/**
 * Reads P360 code table values from `P360_Code_Table_Value__mdt`, cached per transaction.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 K2
 * @group P360 Code Table
 */
public with sharing class P360_CodeTableMetadataService implements P360_ICodeTableService {
    private static final Map<String, P360_CodeTableRowDto> TRANSACTION_CACHE = new Map<String, P360_CodeTableRowDto>();

    /**
     * Looks up a single active code table row, using a per-transaction cache to avoid repeated queries.
     *
     * @param tableName Name of the code table to search.
     * @param salesforceKey Salesforce-side key to look up.
     * @return Matching code table row.
     * @throws P360_MissingCodeTableMappingException When no active row matches the table name and key.
     */
    public P360_CodeTableRowDto getValue(String tableName, String salesforceKey) {
        String cacheKey = tableName + ':' + salesforceKey;

        if (TRANSACTION_CACHE.containsKey(cacheKey)) {
            return TRANSACTION_CACHE.get(cacheKey);
        }

        List<P360_Code_Table_Value__mdt> matches = [
            SELECT
                Table_Name__c,
                Salesforce_Key__c,
                Language_Code__c,
                P360_Code__c,
                P360_Recno__c,
                Transport_Value__c,
                Display_Label__c,
                Sort_Order__c
            FROM P360_Code_Table_Value__mdt
            WHERE Table_Name__c = :tableName AND Salesforce_Key__c = :salesforceKey AND Active__c = TRUE
            LIMIT 1
        ];

        if (matches.isEmpty()) {
            throw new P360_MissingCodeTableMappingException(
                'No active P360 code table mapping for table ' + tableName + ' and key ' + salesforceKey + '.'
            );
        }

        P360_CodeTableRowDto row = toDto(matches[0]);
        TRANSACTION_CACHE.put(cacheKey, row);
        return row;
    }

    private P360_CodeTableRowDto toDto(P360_Code_Table_Value__mdt record) {
        P360_CodeTableRowDto row = new P360_CodeTableRowDto();
        row.tableName = record.Table_Name__c;
        row.salesforceKey = record.Salesforce_Key__c;
        row.languageCode = record.Language_Code__c;
        row.p360Code = record.P360_Code__c;
        row.p360Recno = record.P360_Recno__c;
        row.transportValue = record.Transport_Value__c;
        row.displayLabel = record.Display_Label__c;
        row.sortOrder = record.Sort_Order__c != null ? Integer.valueOf(record.Sort_Order__c) : null;
        return row;
    }
}
