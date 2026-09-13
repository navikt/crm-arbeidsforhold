/**
 * Maps the approved Aa-registeret decision context to the P360 outgoing document contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Mapper
 */
public with sharing class AAREG_DecisionToP360DocumentMapper {
    private final P360_ICodeTableService codeTableService;

    /** Input values owned by the Aa-registeret decision use case. */
    public class Input {
        /** Decision document title to send to P360. */
        public String title;

        /** Decision document date. */
        public Date documentDate;

        /** Existing P360 case number. */
        public String caseNumber;

        /** Salesforce-side external identifier for the decision document. */
        public String externalId;

        /** Salesforce system name used as the external-system identifier. */
        public String externalSystem;
    }

    /**
     * Creates a mapper with an injected code-table service.
     *
     * @param codeTableService Service used to resolve approved P360 default values.
     */
    public AAREG_DecisionToP360DocumentMapper(P360_ICodeTableService codeTableService) {
        this.codeTableService = codeTableService;
    }

    /**
     * Maps decision input to an outgoing CreateDocument request without file transport.
     *
     * @param input Decision document values owned by the calling use case.
     * @return Populated P360 CreateDocument request.
     * @throws P360_ContractException When input or a required input value is missing.
     * @throws P360_MissingCodeTableMappingException When an approved default value is unavailable.
     */
    public P360_CreateDocumentRequestDto mapToCreateDocument(Input input) {
        requireInput(input);

        P360_CreateDocumentRequestDto request = new P360_CreateDocumentRequestDto();
        request.title = input.title;
        request.documentDate = input.documentDate;
        request.caseNumber = input.caseNumber;
        request.externalId = input.externalId;
        request.externalSystem = input.externalSystem;
        request.archive = value('DecisionDocumentArchive', 'Default').p360Code;
        request.category = value('DocumentCategory', 'Outgoing').p360Code;
        request.status = value('JournalStatus', 'Default').p360Code;
        request.accessCode = value('AccessCode', 'Default').p360Code;
        request.accessGroup = value('DocumentAccessGroup', 'Default').p360Code;
        return request;
    }

    private P360_CodeTableRowDto value(String tableName, String salesforceKey) {
        return codeTableService.getValue(tableName, salesforceKey);
    }

    private void requireInput(Input input) {
        if (input == null) {
            throw new P360_ContractException('Decision document mapping input is required.');
        }
        if (String.isBlank(input.title)) {
            throw new P360_ContractException('Decision document mapping title is required.');
        }
        if (input.documentDate == null) {
            throw new P360_ContractException('Decision document mapping date is required.');
        }
        if (String.isBlank(input.caseNumber)) {
            throw new P360_ContractException('Decision document mapping case number is required.');
        }
        if (String.isBlank(input.externalId)) {
            throw new P360_ContractException('Decision document mapping external id is required.');
        }
        if (String.isBlank(input.externalSystem)) {
            throw new P360_ContractException('Decision document mapping external system is required.');
        }
    }
}
