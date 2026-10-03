/**
 * Maps the approved Aa-registeret application context to the P360 CreateCase contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Mapper
 */
public with sharing class AAREG_ApplicationToP360CaseMapper {
    private final P360_ICodeTableService codeTableService;

    /**
     * Input values owned by the Aa-registeret application use case.
     */
    public class Input {
        /** Case title to send to P360. */
        public String title;

        /** Salesforce-side external identifier for the application. */
        public String externalId;

        /** Salesforce system name used as the external-system identifier. */
        public String externalSystem;
    }

    /**
     * Creates a mapper with an injected code-table service.
     *
     * @param codeTableService Service used to resolve approved P360 default values.
     */
    public AAREG_ApplicationToP360CaseMapper(P360_ICodeTableService codeTableService) {
        this.codeTableService = codeTableService;
    }

    /**
     * Maps application input to a CreateCase request using the approved Default code-table profile.
     *
     * @param input Application values owned by the calling use case.
     * @return Populated P360 CreateCase request.
     * @throws P360_ContractException When input or a required input value is missing.
     * @throws P360_MissingCodeTableMappingException When an approved default value is unavailable.
     */
    public P360_CreateCaseRequestDto mapToCreateCase(Input input) {
        requireInput(input);

        P360_CreateCaseRequestDto request = new P360_CreateCaseRequestDto();
        request.title = input.title;
        request.externalId = input.externalId;
        request.externalSystem = input.externalSystem;
        request.defaultValueSet = value('DefaultValueSet').p360Code;
        request.status = value('CaseStatus').p360Code;
        request.caseType = value('CaseType').p360Code;
        request.accessCode = value('AccessCode').p360Code;
        request.accessGroup = value('CaseAccessGroup').p360Code;
        request.responsibleEnterpriseNumber = value('ResponsibleEnterpriseNumber').p360Code;

        P360_CodeTableRowDto archiveCode = value('ClassCode1ArchiveCode');
        P360_CodeTableRowDto archiveSort = value('ClassCode1Sort');
        P360_ClassCodeParameterDto archiveCodeParameter = new P360_ClassCodeParameterDto();
        archiveCodeParameter.archiveCode = archiveCode.p360Code;
        archiveCodeParameter.sortOrder = Integer.valueOf(archiveSort.p360Code);
        archiveCodeParameter.isManualText = false;
        request.archiveCodes = new List<P360_ClassCodeParameterDto>{ archiveCodeParameter };
        return request;
    }

    private P360_CodeTableRowDto value(String tableName) {
        return codeTableService.getValue(tableName, 'Default');
    }

    private void requireInput(Input input) {
        if (input == null) {
            throw new P360_ContractException('Application mapping input is required.');
        }
        if (String.isBlank(input.title)) {
            throw new P360_ContractException('Application mapping title is required.');
        }
        if (String.isBlank(input.externalId)) {
            throw new P360_ContractException('Application mapping external id is required.');
        }
        if (String.isBlank(input.externalSystem)) {
            throw new P360_ContractException('Application mapping external system is required.');
        }
    }
}
