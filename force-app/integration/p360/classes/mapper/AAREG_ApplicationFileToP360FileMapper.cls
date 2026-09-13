/**
 * Maps an application file payload to the P360 CreateDocument file parameter.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Mapper
 */
public with sharing class AAREG_ApplicationFileToP360FileMapper {
    /** Input values owned by the Salesforce file-producing use case. */
    public class Input {
        /** File title sent to P360. */
        public String title;

        /** File extension or P360 format code. */
        public String format;

        /** Base64-encoded file content. */
        public String base64Data;
    }

    /**
     * Maps file input to the P360 file parameter without performing upload or callout logic.
     *
     * @param input File values owned by the calling use case.
     * @return P360 file parameter containing the original base64 content.
     * @throws P360_ContractException When required file input is missing.
     */
    public P360_FileParameterDto mapToFile(Input input) {
        requireInput(input);

        P360_FileParameterDto file = new P360_FileParameterDto();
        file.title = input.title;
        file.format = input.format;
        file.base64Data = input.base64Data;
        file.versionFormat = 'Original';
        return file;
    }

    private void requireInput(Input input) {
        if (input == null) {
            throw new P360_ContractException('File mapping input is required.');
        }
        if (String.isBlank(input.title)) {
            throw new P360_ContractException('File title is required.');
        }
        if (String.isBlank(input.format)) {
            throw new P360_ContractException('File format is required.');
        }
        if (String.isBlank(input.base64Data)) {
            throw new P360_ContractException('File base64 data is required.');
        }
    }
}
