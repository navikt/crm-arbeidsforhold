@IsTest
public class AAREG_ApplicationInternalControllerTest {
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
}
