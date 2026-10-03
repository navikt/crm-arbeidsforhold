/**
 * Maps the approved Aa-registeret application context to the P360 CreateDocument contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Mapper
 */
public with sharing class AAREG_ApplicationToP360DocumentMapper {
    private final P360_ICodeTableService codeTableService;

    /** Input values owned by the Aa-registeret application use case. */
    public class Input {
        /** Document title to send to P360. */
        public String title;

        /** Document date. */
        public Date documentDate;

        /** Existing P360 case number. */
        public String caseNumber;

        /** Salesforce-side external identifier for the document. */
        public String externalId;

        /** Salesforce system name used as the external-system identifier. */
        public String externalSystem;

        /** Mock or pre-loaded file inputs to include in the document request. */
        public List<AAREG_ApplicationFileToP360FileMapper.Input> files;
    }

    /**
     * Creates a mapper with an injected code-table service.
     *
     * @param codeTableService Service used to resolve approved P360 default values.
     */
    public AAREG_ApplicationToP360DocumentMapper(P360_ICodeTableService codeTableService) {
        this.codeTableService = codeTableService;
    }

    /**
     * Maps application input to a CreateDocument request using approved document defaults.
     *
     * @param input Application document values owned by the calling use case.
     * @return Populated P360 CreateDocument request without file transport.
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
        request.archive = value('DocumentArchive').p360Code;
        request.status = value('JournalStatus').p360Code;
        request.accessCode = value('AccessCode').p360Code;
        request.accessGroup = value('DocumentAccessGroup').p360Code;
        request.files = mapFiles(input.files);
        return request;
    }

    private List<P360_FileParameterDto> mapFiles(List<AAREG_ApplicationFileToP360FileMapper.Input> inputs) {
        if (inputs == null || inputs.isEmpty()) {
            return null;
        }
        List<P360_FileParameterDto> files = new List<P360_FileParameterDto>();
        AAREG_ApplicationFileToP360FileMapper fileMapper = new AAREG_ApplicationFileToP360FileMapper();
        for (AAREG_ApplicationFileToP360FileMapper.Input input : inputs) {
            files.add(fileMapper.mapToFile(input));
        }
        return files;
    }

    private P360_CodeTableRowDto value(String tableName) {
        return codeTableService.getValue(tableName, 'Default');
    }

    private void requireInput(Input input) {
        if (input == null) {
            throw new P360_ContractException('Application document mapping input is required.');
        }
        if (String.isBlank(input.title)) {
            throw new P360_ContractException('Application document mapping title is required.');
        }
        if (input.documentDate == null) {
            throw new P360_ContractException('Application document mapping date is required.');
        }
        if (String.isBlank(input.caseNumber)) {
            throw new P360_ContractException('Application document mapping case number is required.');
        }
        if (String.isBlank(input.externalId)) {
            throw new P360_ContractException('Application document mapping external id is required.');
        }
        if (String.isBlank(input.externalSystem)) {
            throw new P360_ContractException('Application document mapping external system is required.');
        }
    }
}
