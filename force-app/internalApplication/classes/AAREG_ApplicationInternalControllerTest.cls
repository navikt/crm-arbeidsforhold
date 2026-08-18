/**
 * Test class for AAREG_ApplicationInternalController.
 *
 * @author Ann Kristin Olsen
 * @author Kenneth Sørensen
 * @since January 2026
 * @group AAREG Internal Application
 */
@IsTest
public class AAREG_ApplicationInternalControllerTest {
    /**
     * getApplicationDetails should return application, basis codes, and related contacts for a county account.
     *
     * @since January 2026
     */
    @IsTest
    static void testGetApplicationDetailsCounty() {
        // Create a test Account
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        insert testApplication;

        // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = AAREG_TestDataFactory.getBasisCodeCounty(testApplication);
        insert basisCodes;

        // Create test RelatedContact records
        List<RelatedContact__c> relatedContacts = AAREG_TestDataFactory.getRelatedContact(testApplication);
        insert relatedContacts;

        // Call the method
        Test.startTest();
        AAREG_ApplicationInternalController.ApplicationWrapper result = AAREG_ApplicationInternalController.getApplicationDetails(
            testApplication.Id
        );
        Test.stopTest();

        // Assertions for Application
        System.Assert.areEqual(1, result.application.size(), 'There should be one application');
        System.Assert.areEqual(testApplication.Id, result.application[0].SoknadsId, 'Application ID should match');
        System.Assert.areEqual(
            testApplication.OrganizationStructure__c,
            'County',
            'Organisationstructure should match'
        );

        // Assertions for Basis Codes
        System.Assert.areEqual(3, result.basisCodes.size(), 'There should be two basis codes');
        System.Assert.areEqual(
            'Tildeling og kontroll av drosjeløyve',
            result.basisCodes[0].Formaal,
            'First basis code name should match'
        );
        System.Assert.areEqual(
            'Kontroll av helsepersonell - tilsynssaker',
            result.basisCodes[2].Formaal,
            'Second basis code name should match'
        );

        // Assertions for Related Contacts
        System.Assert.areEqual(2, result.relatedContacts.size(), 'There should be two related contacts');
        System.Assert.areEqual(
            'Kommunekontakt 1',
            result.relatedContacts[0].KontaktNavn,
            'First contact name should match'
        );
        System.Assert.areEqual(
            'Kommunekontakt 2',
            result.relatedContacts[1].KontaktNavn,
            'Second contact name should match'
        );
    }

    /**
     * getApplicationDetails should return application and basis codes for a state account.
     *
     * @since January 2026
     */
    @IsTest
    static void testGetApplicationDetailsState() {
        // Create a test Account
        Account testAccount = AAREG_TestDataFactory.getAccountState();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationState(testAccount);
        insert testApplication;

        // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = AAREG_TestDataFactory.getBasisCodeState(testApplication);
        insert basisCodes;

        // Call the method
        Test.startTest();
        AAREG_ApplicationInternalController.ApplicationWrapper result = AAREG_ApplicationInternalController.getApplicationDetails(
            testApplication.Id
        );
        Test.stopTest();

        // Assertions for Application
        System.Assert.areEqual(1, result.application.size(), 'There should be one application');
        System.Assert.areEqual(testApplication.Id, result.application[0].SoknadsId, 'Application ID should match');
        System.Assert.areEqual(testApplication.OrganizationStructure__c, 'State', 'Organisationstructure should match');

        // Assertions for Basis Codes
        System.Assert.areEqual(2, result.basisCodes.size(), 'There should be one basis codes');
        System.Assert.areEqual(
            'Kontroll av virksomheter som benytter eksplosiver.',
            result.basisCodes[0].Formaal,
            'First basis code name should match'
        );
    }

    /**
     * getApplicationDetails should return application and basis codes for an electricity supervision account.
     *
     * @since January 2026
     */
    @IsTest
    static void testGetApplicationDetailsEL() {
        // Create a test Account
        Account testAccount = AAREG_TestDataFactory.getAccountEL();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationEL(testAccount);
        insert testApplication;

        // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = AAREG_TestDataFactory.getBasisCodeEL(testApplication);
        insert basisCodes;

        // Call the method
        Test.startTest();
        AAREG_ApplicationInternalController.ApplicationWrapper result = AAREG_ApplicationInternalController.getApplicationDetails(
            testApplication.Id
        );
        Test.stopTest();

        // Assertions for Application
        System.Assert.areEqual(1, result.application.size(), 'There should be one application');
        System.Assert.areEqual(testApplication.Id, result.application[0].SoknadsId, 'Application ID should match');
        System.Assert.areEqual(
            testApplication.OrganizationStructure__c,
            'Electricity Supervision',
            'Organisationstructure should match'
        );

        // Assertions for Basis Codes
        System.Assert.areEqual(2, result.basisCodes.size(), 'There should be one basis codes');
        System.Assert.areEqual(
            'Tilsyn med elektriske anlegg og elektrisk utstyr',
            result.basisCodes[0].Formaal,
            'First basis code name should match'
        );
    }

    /**
     * getApplicationDetails should return application and basis codes for a pension account.
     *
     * @since January 2026
     */
    @IsTest
    static void testGetApplicationDetailsPension() {
        // Create a test Account
        Account testAccount = AAREG_TestDataFactory.getAccountPension();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationPension(testAccount);
        insert testApplication;

        // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = AAREG_TestDataFactory.getBasisCodePension(testApplication);
        insert basisCodes;

        // Call the method
        Test.startTest();
        AAREG_ApplicationInternalController.ApplicationWrapper result = AAREG_ApplicationInternalController.getApplicationDetails(
            testApplication.Id
        );
        Test.stopTest();

        // Assertions for Application
        System.Assert.areEqual(1, result.application.size(), 'There should be one application');
        System.Assert.areEqual(testApplication.Id, result.application[0].SoknadsId, 'Application ID should match');
        System.Assert.areEqual(
            testApplication.OrganizationStructure__c,
            'Pension',
            'Organisationstructure should match'
        );

        // Assertions for Basis Codes
        System.Assert.areEqual(2, result.basisCodes.size(), 'There should be one basis codes');
        System.Assert.areEqual(
            'Arbeid med administrasjon knyttet til OU-samordningen',
            result.basisCodes[0].Formaal,
            'First basis code name should match'
        );
    }

    /**
     * getApplicationDetails should return application and basis codes for a municipality account.
     *
     * @since January 2026
     */
    @IsTest
    static void testGetApplicationDetailsMunicipality() {
        // Create a test Account
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationMunicipality(testAccount);
        insert testApplication;

        // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = AAREG_TestDataFactory.getBasisCodeMunicipality(testApplication);
        insert basisCodes;

        // Call the method
        Test.startTest();
        AAREG_ApplicationInternalController.ApplicationWrapper result = AAREG_ApplicationInternalController.getApplicationDetails(
            testApplication.Id
        );
        Test.stopTest();

        // Assertions for Application
        System.Assert.areEqual(1, result.application.size(), 'There should be one application');
        System.Assert.areEqual(testApplication.Id, result.application[0].SoknadsId, 'Application ID should match');
        System.Assert.areEqual(
            testApplication.OrganizationStructure__c,
            'Municipality',
            'Organisationstructure should match'
        );

        // Assertions for Basis Codes
        System.Assert.areEqual(2, result.basisCodes.size(), 'There should be one basis codes');
        System.Assert.areEqual(
            'Behandling av startlån/boligtilskudd',
            result.basisCodes[0].Formaal,
            'First basis code name should match'
        );
    }

    /**
     * getApplicationDetails should translate the Other organization type and map its other legal basis and purpose.
     *
     * @since July 2026
     */
    @IsTest
    static void testGetApplicationDetailsWithOtherOrganizationType() {
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;

        Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        testApplication.OrganizationStructure__c = 'Other';
        insert testApplication;

        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>{
            new ApplicationBasisCode__c(
                Application__c = testApplication.Id,
                OrganizationType__c = 'Other',
                OtherLegalBasis__c = 'Other legal basis',
                OtherPurpose__c = 'Other purpose'
            )
        };
        insert basisCodes;

        Test.startTest();
        AAREG_ApplicationInternalController.ApplicationWrapper result = AAREG_ApplicationInternalController.getApplicationDetails(
            testApplication.Id
        );
        Test.stopTest();

        System.assertEquals(1, result.basisCodes.size(), 'One basis code should be returned.');
        System.assertEquals('Other legal basis', result.basisCodes[0].Hjemmel, 'Other legal basis should be mapped.');
        System.assertEquals('Other purpose', result.basisCodes[0].Formaal, 'Other purpose should be mapped.');
        System.assertEquals(
            'Annet',
            result.basisCodes[0].OrganisasjonsType,
            'Other organization type should be translated.'
        );
    }

    /**
     * getApplicationDetails should return an empty related contacts list when none exist.
     *
     * @since July 2026
     */
    @IsTest
    static void testGetApplicationDetailsWithNoRelatedContacts() {
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;

        Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        insert testApplication;

        Test.startTest();
        AAREG_ApplicationInternalController.ApplicationWrapper result = AAREG_ApplicationInternalController.getApplicationDetails(
            testApplication.Id
        );
        Test.stopTest();

        System.assertEquals(
            0,
            result.relatedContacts.size(),
            'No related contacts should be returned when none exist.'
        );
    }

    /**
     * AAREG_ApplicationInternal wrapper properties should be settable and readable.
     *
     * @since August 2026
     */
    @IsTest
    static void testApplicationInternalWrapperProperties() {
        Date today = Date.today();
        Date deadline = Date.today().addDays(7);

        AAREG_ApplicationInternal wrapper = new AAREG_ApplicationInternal();
        wrapper.SoknadsId = 'APP-1';
        wrapper.SoknadsNavn = 'Soknad';
        wrapper.APITilgang = true;
        wrapper.Uttrekk = false;
        wrapper.WebTilgang = true;
        wrapper.KonsumentId = 'K-1';
        wrapper.KonsumentNavn = 'Konsument';
        wrapper.KonsumentKontaktNavn = 'Kontakt';
        wrapper.KonsumentOrganisasjonsnummer = '123456789';
        wrapper.KonsumentAdresse = 'Gate 1';
        wrapper.KonsumentPoststed = 'Oslo';
        wrapper.KonsumentPostnummer = '0101';
        wrapper.KonsumentEpost = 'test@nav.no';
        wrapper.OrganisasjonsType = 'County';
        wrapper.SoknadLevert = today;
        wrapper.Svarfrist = deadline;
        wrapper.Vilkaar = true;
        wrapper.DatabehandlerNavn = 'DBH';
        wrapper.DatabehandlerOrganisasjonsnummer = '987654321';
        wrapper.Sakseier = 'Sakseier';

        System.assertEquals('APP-1', wrapper.SoknadsId);
        System.assertEquals('Soknad', wrapper.SoknadsNavn);
        System.assertEquals(true, wrapper.APITilgang);
        System.assertEquals(false, wrapper.Uttrekk);
        System.assertEquals(true, wrapper.WebTilgang);
        System.assertEquals('K-1', wrapper.KonsumentId);
        System.assertEquals('Konsument', wrapper.KonsumentNavn);
        System.assertEquals('Kontakt', wrapper.KonsumentKontaktNavn);
        System.assertEquals('123456789', wrapper.KonsumentOrganisasjonsnummer);
        System.assertEquals('Gate 1', wrapper.KonsumentAdresse);
        System.assertEquals('Oslo', wrapper.KonsumentPoststed);
        System.assertEquals('0101', wrapper.KonsumentPostnummer);
        System.assertEquals('test@nav.no', wrapper.KonsumentEpost);
        System.assertEquals('County', wrapper.OrganisasjonsType);
        System.assertEquals(today, wrapper.SoknadLevert);
        System.assertEquals(deadline, wrapper.Svarfrist);
        System.assertEquals(true, wrapper.Vilkaar);
        System.assertEquals('DBH', wrapper.DatabehandlerNavn);
        System.assertEquals('987654321', wrapper.DatabehandlerOrganisasjonsnummer);
        System.assertEquals('Sakseier', wrapper.Sakseier);
    }

    /**
     * getApplicationDetails should return the organization type unchanged when it is unknown.
     *
     * @since August 2026
     */
    @IsTest
    static void testGetApplicationDetailsWithUnknownOrganizationType() {
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;

        Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        testApplication.OrganizationStructure__c = null;
        insert testApplication;

        Test.startTest();
        AAREG_ApplicationInternalController.ApplicationWrapper result = AAREG_ApplicationInternalController.getApplicationDetails(
            testApplication.Id
        );
        Test.stopTest();

        System.assertEquals(1, result.application.size(), 'One application should be returned.');
        System.assertEquals(
            null,
            result.application[0].OrganisasjonsType,
            'Unknown org type should be returned unchanged.'
        );
        System.assertEquals('Unknown', AAREG_ApplicationInternalController.translateOrganizationType('Unknown'));
    }

    /**
     * getApplicationDetails should map the municipality's "other" legal basis and purpose.
     *
     * @since August 2026
     */
    @IsTest
    static void testGetApplicationDetailsMunicipalityWithOtherLegalBasis() {
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;

        Application__c testApplication = AAREG_TestDataFactory.getApplicationMunicipality(testAccount);
        insert testApplication;

        ApplicationBasisCode__c basisCode = new ApplicationBasisCode__c(
            Application__c = testApplication.Id,
            OrganizationType__c = 'Municipality',
            LegalBasisMunicipality__c = 'Annet - oppgi i tekstfelt under',
            OtherLegalBasis__c = 'Kommunal hjemmel annet',
            OtherPurpose__c = 'Kommunalt formaal annet'
        );
        insert basisCode;

        Test.startTest();
        AAREG_ApplicationInternalController.ApplicationWrapper result = AAREG_ApplicationInternalController.getApplicationDetails(
            testApplication.Id
        );
        Test.stopTest();

        System.assertEquals(1, result.basisCodes.size(), 'One basis code should be returned.');
        System.assertEquals('Kommunal hjemmel annet', result.basisCodes[0].Hjemmel);
        System.assertEquals('Kommunalt formaal annet', result.basisCodes[0].Formaal);
    }

    /**
     * translateOrganizationType should translate Other to Annet.
     *
     * @since August 2026
     */
    @IsTest
    static void testTranslateOrganizationTypeOther() {
        System.assertEquals('Annet', AAREG_ApplicationInternalController.translateOrganizationType('Other'));
    }
}
