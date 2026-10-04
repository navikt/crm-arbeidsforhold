/**
 * Verifies the SIF FileParameter DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_FileParameterDtoTest {
    /**
     * Verifies that file-parameter fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void fileParameterPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_FileParameterDto file = new P360_FileParameterDto();
            file.title = 'Decision attachment';
            file.format = 'pdf';
            file.data = 'dGVzdA==';
            file.base64Data = 'eGV4';
            file.uploadedFileReference = 'file-ref-001';
            file.relationType = 'MainFile';
            file.versionFormat = 'Original';

            P360_FileParameterDto roundTrippedFile = (P360_FileParameterDto) JSON.deserialize(
                JSON.serialize(file),
                P360_FileParameterDto.class
            );

            System.Assert.areEqual(file.title, roundTrippedFile.title, 'Expected the title.');
            System.Assert.areEqual(file.format, roundTrippedFile.format, 'Expected the format.');
            System.Assert.areEqual(file.data, roundTrippedFile.data, 'Expected the raw data.');
            System.Assert.areEqual(file.base64Data, roundTrippedFile.base64Data, 'Expected the base64 data.');
            System.Assert.areEqual(
                file.uploadedFileReference,
                roundTrippedFile.uploadedFileReference,
                'Expected the uploaded file reference.'
            );
            System.Assert.areEqual(file.relationType, roundTrippedFile.relationType, 'Expected the relation type.');
            System.Assert.areEqual(file.versionFormat, roundTrippedFile.versionFormat, 'Expected the version format.');
        }
    }
}
