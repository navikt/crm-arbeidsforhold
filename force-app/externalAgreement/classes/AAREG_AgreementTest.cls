/**
 * @description Test class for AAREG_Agreement wrapper class
 * Tests data encapsulation and property access for agreement LWC interface
 * @author AAREG Team
 * @version 66
 * @group External Agreement
 */
@IsTest
public class AAREG_AgreementTest {
    /**
     * @description Tests basic instantiation of agreement wrapper
     */
    @IsTest
    static void testAgreementInstantiation() {
        Test.startTest();
        AAREG_Agreement agreement = new AAREG_Agreement();
        Test.stopTest();

        System.Assert.isNotNull(agreement, 'Agreement should be instantiated');
    }

    /**
     * @description Tests setting and getting agreement core properties
     */
    @IsTest
    static void testAgreementCoreProperties() {
        Test.startTest();
        AAREG_Agreement agreement = new AAREG_Agreement();
        agreement.avtaleId = '001000000000001';
        agreement.avtaleDato = DateTime.now();
        agreement.avtaleNummer = 'AVT-2026-001';
        agreement.soknadsNummer = 'SØK-2026-001';
        Test.stopTest();

        System.assertEquals('001000000000001', agreement.avtaleId, 'Agreement ID should be set');
        System.Assert.isNotNull(agreement.avtaleDato, 'Agreement date should be set');
        System.assertEquals('AVT-2026-001', agreement.avtaleNummer, 'Agreement number should be set');
        System.assertEquals('SØK-2026-001', agreement.soknadsNummer, 'Application number should be set');
    }

    /**
     * @description Tests setting and getting access permission properties
     */
    @IsTest
    static void testAgreementAccessProperties() {
        Test.startTest();
        AAREG_Agreement agreement = new AAREG_Agreement();
        agreement.apiTilgang = true;
        agreement.uttrekk = false;
        agreement.webTilgang = true;
        Test.stopTest();

        System.assertEquals(true, agreement.apiTilgang, 'API access should be true');
        System.assertEquals(false, agreement.uttrekk, 'Extract access should be false');
        System.assertEquals(true, agreement.webTilgang, 'Web access should be true');
    }

    /**
     * @description Tests setting and getting consumer properties
     */
    @IsTest
    static void testAgreementConsumerProperties() {
        Test.startTest();
        AAREG_Agreement agreement = new AAREG_Agreement();
        agreement.konsumentId = 'K001';
        agreement.konsumentNavn = 'Test Konsument';
        agreement.konsumentKontaktNavn = 'John Doe';
        agreement.konsumentOrganisasjonsnummer = '999999999';
        agreement.konsumentAdresse = 'Testveien 1';
        agreement.konsumentPoststed = 'Oslo';
        agreement.konsumentPostnummer = '0150';
        agreement.konsumentEpost = 'test@example.com';
        Test.stopTest();

        System.assertEquals('K001', agreement.konsumentId, 'Consumer ID should be set');
        System.assertEquals('Test Konsument', agreement.konsumentNavn, 'Consumer name should be set');
        System.assertEquals('John Doe', agreement.konsumentKontaktNavn, 'Contact name should be set');
        System.assertEquals('999999999', agreement.konsumentOrganisasjonsnummer, 'Organization number should be set');
        System.assertEquals('Testveien 1', agreement.konsumentAdresse, 'Address should be set');
        System.assertEquals('Oslo', agreement.konsumentPoststed, 'City should be set');
        System.assertEquals('0150', agreement.konsumentPostnummer, 'Postal code should be set');
        System.assertEquals('test@example.com', agreement.konsumentEpost, 'Email should be set');
    }

    /**
     * @description Tests setting and getting data processor properties
     */
    @IsTest
    static void testAgreementDataProcessorProperties() {
        Test.startTest();
        AAREG_Agreement agreement = new AAREG_Agreement();
        agreement.databehandlerNavn = 'Data Processor AS';
        agreement.databehandlerOrganisasjonsnummer = '888888888';
        agreement.organisasjonsType = 'AS';
        agreement.sakseier = 'NAV';
        agreement.status = 'Aktiv';
        Test.stopTest();

        System.assertEquals('Data Processor AS', agreement.databehandlerNavn, 'Data processor name should be set');
        System.assertEquals(
            '888888888',
            agreement.databehandlerOrganisasjonsnummer,
            'Data processor org number should be set'
        );
        System.assertEquals('AS', agreement.organisasjonsType, 'Organization type should be set');
        System.assertEquals('NAV', agreement.sakseier, 'Case owner should be set');
        System.assertEquals('Aktiv', agreement.status, 'Status should be set');
    }

    /**
     * @description Tests multiple agreement instances don't interfere
     */
    @IsTest
    static void testMultipleAgreementInstances() {
        Test.startTest();
        AAREG_Agreement agreement1 = new AAREG_Agreement();
        agreement1.avtaleId = 'ID1';
        agreement1.avtaleNummer = 'NUM1';

        AAREG_Agreement agreement2 = new AAREG_Agreement();
        agreement2.avtaleId = 'ID2';
        agreement2.avtaleNummer = 'NUM2';
        Test.stopTest();

        System.assertEquals('ID1', agreement1.avtaleId, 'First agreement ID should not be affected');
        System.assertEquals('NUM1', agreement1.avtaleNummer, 'First agreement number should not be affected');
        System.assertEquals('ID2', agreement2.avtaleId, 'Second agreement ID should be independent');
        System.assertEquals('NUM2', agreement2.avtaleNummer, 'Second agreement number should be independent');
    }

    /**
     * @description Tests null values handling
     */
    @IsTest
    static void testAgreementNullValues() {
        Test.startTest();
        AAREG_Agreement agreement = new AAREG_Agreement();
        // All properties should be null initially
        Test.stopTest();

        System.assertEquals(null, agreement.avtaleId, 'Unset ID should be null');
        System.assertEquals(null, agreement.konsumentNavn, 'Unset consumer name should be null');
        System.assertEquals(null, agreement.apiTilgang, 'Unset API access should be null');
    }

    /**
     * @description Tests property defaults after instantiation
     */
    @IsTest
    static void testAgreementDefaultValues() {
        Test.startTest();
        AAREG_Agreement agreement = new AAREG_Agreement();
        agreement.apiTilgang = false;
        agreement.uttrekk = false;
        agreement.webTilgang = false;
        Test.stopTest();

        System.assertEquals(false, agreement.apiTilgang, 'API access should default to false');
        System.assertEquals(false, agreement.uttrekk, 'Extract should default to false');
        System.assertEquals(false, agreement.webTilgang, 'Web access should default to false');
    }
}
