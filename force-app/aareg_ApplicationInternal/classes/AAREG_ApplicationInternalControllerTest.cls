@isTest
public class AAREG_ApplicationInternalControllerTest {

    @isTest
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
        AAREG_ApplicationInternalController.ApplicationWrapper result =
            AAREG_ApplicationInternalController.getApplicationDetails(testApplication.Id);
        Test.stopTest();

        // Assertions for Application
        System.assertEquals(1, result.application.size(), 'There should be one application');
        System.assertEquals(testApplication.Id, result.application[0].SoknadsId, 'Application ID should match');
        System.assertEquals(testApplication.OrganizationStructure__c,'County','Organisationstructure should match');

        // Assertions for Basis Codes
        System.assertEquals(2, result.basisCodes.size(), 'There should be two basis codes');
        System.assertEquals('Tildeling og kontroll av drosjeløyve', result.basisCodes[0].Formaal, 'First basis code name should match');
        System.assertEquals('Kontroll av helsepersonell - tilsynssaker', result.basisCodes[1].Formaal, 'Second basis code name should match');

        // Assertions for Related Contacts
        System.assertEquals(2, result.relatedContacts.size(), 'There should be two related contacts');
        System.assertEquals('Kommunekontakt 1', result.relatedContacts[0].KontaktNavn, 'First contact name should match');
        System.assertEquals('Kommunekontakt 2', result.relatedContacts[1].KontaktNavn, 'Second contact name should match');
    }
    
     @isTest
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
        AAREG_ApplicationInternalController.ApplicationWrapper result =
            AAREG_ApplicationInternalController.getApplicationDetails(testApplication.Id);
        Test.stopTest();

        // Assertions for Application
        System.assertEquals(1, result.application.size(), 'There should be one application');
        System.assertEquals(testApplication.Id, result.application[0].SoknadsId, 'Application ID should match');
        System.assertEquals(testApplication.OrganizationStructure__c,'State','Organisationstructure should match');
        
         // Assertions for Basis Codes
        System.assertEquals(1, result.basisCodes.size(), 'There should be one basis codes');
        System.assertEquals('Kontroll av virksomheter som benytter eksplosiver.', result.basisCodes[0].Formaal, 'First basis code name should match');

    }
    
     @isTest
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
        AAREG_ApplicationInternalController.ApplicationWrapper result =
            AAREG_ApplicationInternalController.getApplicationDetails(testApplication.Id);
        Test.stopTest();

        // Assertions for Application
        System.assertEquals(1, result.application.size(), 'There should be one application');
        System.assertEquals(testApplication.Id, result.application[0].SoknadsId, 'Application ID should match');
        System.assertEquals(testApplication.OrganizationStructure__c,'Electricity Supervision','Organisationstructure should match');
        
        // Assertions for Basis Codes
        System.assertEquals(1, result.basisCodes.size(), 'There should be one basis codes');
        System.assertEquals('Tilsyn med elektriske anlegg og elektrisk utstyr', result.basisCodes[0].Formaal, 'First basis code name should match');
    }
    
    @isTest
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
        AAREG_ApplicationInternalController.ApplicationWrapper result =
            AAREG_ApplicationInternalController.getApplicationDetails(testApplication.Id);
        Test.stopTest();

        // Assertions for Application
        System.assertEquals(1, result.application.size(), 'There should be one application');
        System.assertEquals(testApplication.Id, result.application[0].SoknadsId, 'Application ID should match');
        System.assertEquals(testApplication.OrganizationStructure__c,'Pension','Organisationstructure should match');
        
         // Assertions for Basis Codes
        System.assertEquals(1, result.basisCodes.size(), 'There should be one basis codes');
        System.assertEquals('Arbeid med administrasjon knyttet til OU-samordningen', result.basisCodes[0].Formaal, 'First basis code name should match');

    }
    
    @isTest
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
        AAREG_ApplicationInternalController.ApplicationWrapper result =
            AAREG_ApplicationInternalController.getApplicationDetails(testApplication.Id);
        Test.stopTest();

        // Assertions for Application
        System.assertEquals(1, result.application.size(), 'There should be one application');
        System.assertEquals(testApplication.Id, result.application[0].SoknadsId, 'Application ID should match');
        System.assertEquals(testApplication.OrganizationStructure__c,'Municipality','Organisationstructure should match');
        
         // Assertions for Basis Codes
        System.assertEquals(1, result.basisCodes.size(), 'There should be one basis codes');
        System.assertEquals('Behandling av startlån/boligtilskudd', result.basisCodes[0].Formaal, 'First basis code name should match');

    }
    
   
}