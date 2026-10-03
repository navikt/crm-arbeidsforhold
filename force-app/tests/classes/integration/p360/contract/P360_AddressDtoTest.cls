/**
 * Verifies the shared SIF Address DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_AddressDtoTest {
    /**
     * Verifies that all documented address fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void addressPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_AddressDto address = new P360_AddressDto();
            address.streetAddress = 'Drammensveien 1';
            address.zipCode = '0123';
            address.zipPlace = 'Oslo';
            address.country = 'NOR';
            address.county = '0301';
            address.area = '03';
            address.state = 'Oslo';

            P360_AddressDto roundTrippedAddress = (P360_AddressDto) JSON.deserialize(
                JSON.serialize(address),
                P360_AddressDto.class
            );

            System.Assert.areEqual(
                address.streetAddress,
                roundTrippedAddress.streetAddress,
                'Expected the street address.'
            );
            System.Assert.areEqual(address.zipCode, roundTrippedAddress.zipCode, 'Expected the zip code.');
            System.Assert.areEqual(address.zipPlace, roundTrippedAddress.zipPlace, 'Expected the zip place.');
            System.Assert.areEqual(address.country, roundTrippedAddress.country, 'Expected the country.');
            System.Assert.areEqual(address.county, roundTrippedAddress.county, 'Expected the county.');
            System.Assert.areEqual(address.area, roundTrippedAddress.area, 'Expected the area.');
            System.Assert.areEqual(address.state, roundTrippedAddress.state, 'Expected the state.');
        }
    }
}
