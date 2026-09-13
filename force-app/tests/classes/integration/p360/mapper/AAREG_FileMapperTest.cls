/**
 * Verifies Salesforce file mapping to the P360 file parameter contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Mapper
 */
@IsTest
private class AAREG_FileMapperTest {
    /**
     * Verifies that file title, format and base64 data are preserved for CreateDocument.
     *
     * @since 2026-09
     */
    @IsTest
    static void mapsFileContentToP360FileParameter() {
        AAREG_ApplicationFileToP360FileMapper.Input input = new AAREG_ApplicationFileToP360FileMapper.Input();
        input.title = 'Søknad - Tilgang til Aa-registeret - S111001';
        input.format = 'docx';
        input.base64Data = 'UEsDBA==';

        P360_FileParameterDto file = new AAREG_ApplicationFileToP360FileMapper().mapToFile(input);

        System.Assert.areEqual(input.title, file.title, 'Expected the file title.');
        System.Assert.areEqual(input.format, file.format, 'Expected the file format.');
        System.Assert.areEqual(input.base64Data, file.base64Data, 'Expected the base64 file data.');
        System.Assert.areEqual('Original', file.versionFormat, 'Expected the original version marker.');
    }

    /**
     * Verifies that missing file content is rejected before any document request is built.
     *
     * @since 2026-09
     */
    @IsTest
    static void missingBase64DataThrowsControlledException() {
        AAREG_ApplicationFileToP360FileMapper.Input input = new AAREG_ApplicationFileToP360FileMapper.Input();
        input.title = 'Missing content';
        input.format = 'docx';

        try {
            new AAREG_ApplicationFileToP360FileMapper().mapToFile(input);
            System.Assert.fail('Expected missing file content to be rejected.');
        } catch (P360_ContractException error) {
            System.Assert.areEqual('File base64 data is required.', error.getMessage());
        }
    }
}
