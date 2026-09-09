/**
 * Verifies the SIF GetCases contact-filter fields.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_GetCasesContactFilterDtoTest {
    /**
     * Verifies that contact reference and external identities survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void contactFilterPreservesIdentityFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_GetCasesContactFilterDto filter = new P360_GetCasesContactFilterDto();
            filter.contactReferenceNumber = '123456789';
            filter.contactExternalId = 'contact-123';
            filter.contactRecnos = new List<String>{ '200001', '200002' };

            P360_GetCasesContactFilterDto roundTrippedFilter = (P360_GetCasesContactFilterDto) JSON.deserialize(
                JSON.serialize(filter),
                P360_GetCasesContactFilterDto.class
            );

            System.Assert.areEqual(
                filter.contactReferenceNumber,
                roundTrippedFilter.contactReferenceNumber,
                'Expected the contact reference number.'
            );
            System.Assert.areEqual(
                filter.contactExternalId,
                roundTrippedFilter.contactExternalId,
                'Expected the contact external id.'
            );
            System.Assert.areEqual(
                filter.contactRecnos.size(),
                roundTrippedFilter.contactRecnos.size(),
                'Expected the contact recno count.'
            );
            for (Integer index = 0; index < filter.contactRecnos.size(); index++) {
                System.Assert.areEqual(
                    filter.contactRecnos[index],
                    roundTrippedFilter.contactRecnos[index],
                    'Expected the contact recno at index ' + index + '.'
                );
            }
        }
    }
}
