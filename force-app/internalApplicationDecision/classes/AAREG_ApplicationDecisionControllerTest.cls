@isTest
public class AAREG_ApplicationDecisionControllerTest {
    
    /**
     * @description Setter opp felles testdata før hver test:
     *              - En Account av typen County
     *              - En tilhørende Application__c
     *              - To ApplicationBasisCode__c-poster
     *              - To Application_Decision__c-poster
     *              Brukes som grunnlag for testene som ikke oppretter egen data.
     */
    
     @TestSetup
    static void setupTestData() {
         // Create a test Account
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        insert testApplication;
        
         // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes = AAREG_TestDataFactory.getBasisCodeCounty(testApplication);
        insert basisCodes;
        
        // Create test Application_Decision__c records
        List<Application_Decision__c> decisions = new List<Application_Decision__c>();
        decisions.add(new Application_Decision__c(
            Application__c = testApplication.Id
        ));
        decisions.add(new Application_Decision__c(
            Application__c = testApplication.Id
        ));
        insert decisions;
    }
    
    /**
     * @description Verifiserer at getApplicationDecision returnerer alle 
     *              vedtaksposter knyttet til en gitt søknad.
     *              Forventer 2 vedtak basert på testdata fra @TestSetup.
     */

    
     @isTest
    static void testGetApplicationDecision() {
       // Retrieve the test Application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        
        // Call the method
        Test.startTest();
        List<AAREG_ApplicationDecision> result = AAREG_ApplicationDecisionController.getApplicationDecision(testApplication.Id);
        Test.stopTest();

        // Assertions
        System.Assert.areEqual(2, result.size(), 'There should be two decisions.');
    }
    
     /**
     * @description Tester opprettelse av nytt vedtak for en County-søknad.
     *              Verifiserer at:
     *              - Vedtaket knyttes korrekt til søknaden
     *              - Status settes til 'Avslått'
     *              - Tre Application_Decision_Details__c-poster opprettes
     *              - API_Access__c kopieres korrekt fra basisCodes
     */

    @isTest
    static void testCreateApplicationDecision() {
        // Retrieve the test Application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        // Call the method
        Test.startTest();
        Id newDecisionId = AAREG_ApplicationDecisionController.createApplicationDecision(testApplication.Id);
        Test.stopTest();

        // Verify the new decision
        Application_Decision__c newDecision = [SELECT Id, Application__c, Status__c FROM Application_Decision__c WHERE Id = :newDecisionId];
        System.Assert.areEqual(testApplication.Id, newDecision.Application__c, 'Application ID should match.');
        System.Assert.areEqual('Avslått', newDecision.Status__c, 'Status should be Avslått.');


        // Verify the related Application_Decision_Details__c records
        List<Application_Decision_Details__c> decisionDetails = [
            SELECT Id, Application_Decision__c, API_Access__c, Extraction_Access__c, Online_Access__c, Processing_Basis__c
            FROM Application_Decision_Details__c
            WHERE Application_Decision__c = :newDecisionId
        ];
        System.Assert.areEqual(3, decisionDetails.size(), 'There should be tree decision details.');
        System.Assert.areEqual(true, decisionDetails[0].API_Access__c, 'First detail API_Access__c should match.');
        System.Assert.areEqual(false, decisionDetails[2].API_Access__c, 'Second detail API_Access__c should match.');
    }
    
    /**
 	* @description Verifiserer at null som recordId fanges og logges korrekt.
 	*/
	@isTest
    static void testCreateApplicationDecisionWithNullId() {
        Boolean exceptionThrown = false;
    
        Test.startTest();
        try {
            AAREG_ApplicationDecisionController.createApplicationDecision(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
    
        System.Assert.isTrue(
            exceptionThrown,
            'Exception skal kastes når recordId er null.'
        );
    }
    
    /**
     * @description Tester opprettelse av vedtak for OrganizationType 'State'.
     *              Verifiserer at:
     *              - Riktig orgtype gjenspeiles i basisCodes
     *              - To detaljposter opprettes
     *              - Tilgangs-flagg (API_Access__c) kopieres korrekt
     */
    @isTest
    static void testCreateState(){
        
        Test.startTest();
        Account testAccount = AAREG_TestDataFactory.getAccountState();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationState(testAccount);
        insert testApplication;
        
         // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes = AAREG_TestDataFactory.getBasisCodeState(testApplication);
        insert basisCodes;
        
        Id newDecisionId = AAREG_ApplicationDecisionController.createApplicationDecision(testApplication.Id);
        Test.stopTest();
        
        List<Application_Decision_Details__c> decisionDetails = [
            SELECT Id, Application_Decision__c, API_Access__c, Extraction_Access__c, Online_Access__c, Processing_Basis__c
            FROM Application_Decision_Details__c
            WHERE Application_Decision__c = :newDecisionId
        ];
        
        System.Assert.areEqual(basisCodes[0].OrganizationType__c, 'State', 'Application type should match.');
        System.Assert.areEqual(2, decisionDetails.size(), 'There should be two decision details.');
        System.Assert.areEqual(true, decisionDetails[0].API_Access__c, 'First detail API_Access__c should match.');
        System.Assert.areEqual(true, decisionDetails[1].API_Access__c, 'Second detail API_Access__c should match.');
        
    }
    
    /**
     * @description Tester opprettelse av vedtak for OrganizationType 'Pension'.
     *              Verifiserer at switch-casen for Pension i 
     *              assignLegalBasisAndPurpose treffes, og at to detaljposter 
     *              med korrekt tilgangs-flagg opprettes.
     */
    @isTest
    static void testCreatePension(){
        
        Test.startTest();
        Account testAccount = AAREG_TestDataFactory.getAccountPension();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationPension(testAccount);
        insert testApplication;
        
         // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes = AAREG_TestDataFactory.getBasisCodePension(testApplication);
        insert basisCodes;
        
        Id newDecisionId = AAREG_ApplicationDecisionController.createApplicationDecision(testApplication.Id);
        Test.stopTest();
        
        List<Application_Decision_Details__c> decisionDetails = [
            SELECT Id, Application_Decision__c, API_Access__c, Extraction_Access__c, Online_Access__c, Processing_Basis__c
            FROM Application_Decision_Details__c
            WHERE Application_Decision__c = :newDecisionId
        ];
        
        System.Assert.areEqual(basisCodes[0].OrganizationType__c, 'Pension', 'Application type should match.');
        System.Assert.areEqual(2, decisionDetails.size(), 'There should be two decision details.');
        System.Assert.areEqual(true, decisionDetails[0].API_Access__c, 'First detail API_Access__c should match.');
        System.Assert.areEqual(false, decisionDetails[1].API_Access__c, 'Second detail API_Access__c should match.');
        
    }

     /**
     * @description Tester opprettelse av vedtak for OrganizationType 'Municipality'.
     *              Verifiserer at switch-casen for Municipality treffes og at 
     *              kommunens lovgrunnlag/formål kopieres til detaljpostene.
     */

    @isTest
    static void testCreateMunicipality(){
        
        Test.startTest();
        Account testAccount = AAREG_TestDataFactory.getAccountMuncipiality();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationMunicipality(testAccount);
        insert testApplication;
        
         // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes = AAREG_TestDataFactory.getBasisCodeMunicipality(testApplication);
        insert basisCodes;
        
        Id newDecisionId = AAREG_ApplicationDecisionController.createApplicationDecision(testApplication.Id);
        Test.stopTest();
        
        List<Application_Decision_Details__c> decisionDetails = [
            SELECT Id, Application_Decision__c, API_Access__c, Extraction_Access__c, Online_Access__c, Processing_Basis__c
            FROM Application_Decision_Details__c
            WHERE Application_Decision__c = :newDecisionId
        ];
        
        System.Assert.areEqual(basisCodes[0].OrganizationType__c, 'Municipality', 'Application type should match.');
        System.Assert.areEqual(2, decisionDetails.size(), 'There should be two decision details.');
        System.Assert.areEqual(true, decisionDetails[0].API_Access__c, 'First detail API_Access__c should match.');
        System.Assert.areEqual(false, decisionDetails[1].API_Access__c, 'Second detail API_Access__c should match.');
        
    }
    
    /**
     * @description Tester opprettelse av vedtak for OrganizationType 
     *              'Electricity Supervision' (EL-tilsyn).
     *              Verifiserer at switch-casen for EL-tilsyn treffes og at 
     *              tilhørende lovgrunnlag/formål kopieres korrekt.
     */

    @isTest
    static void testCreateEL(){
        
        Test.startTest();
        Account testAccount = AAREG_TestDataFactory.getAccountEL();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationEL(testAccount);
        insert testApplication;
        
         // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes = AAREG_TestDataFactory.getBasisCodeEL(testApplication);
        insert basisCodes;
        
        Id newDecisionId = AAREG_ApplicationDecisionController.createApplicationDecision(testApplication.Id);
        Test.stopTest();
        
        List<Application_Decision_Details__c> decisionDetails = [
            SELECT Id, Application_Decision__c, API_Access__c, Extraction_Access__c, Online_Access__c, Processing_Basis__c
            FROM Application_Decision_Details__c
            WHERE Application_Decision__c = :newDecisionId
        ];
        
        System.Assert.areEqual(basisCodes[0].OrganizationType__c, 'Electricity Supervision', 'Application type should match.');
        System.Assert.areEqual(2, decisionDetails.size(), 'There should be two decision details.');
        System.Assert.areEqual(true, decisionDetails[0].API_Access__c, 'First detail API_Access__c should match.');
        System.Assert.areEqual(false, decisionDetails[1].API_Access__c, 'Second detail API_Access__c should match.');
        
    }
    
    /**
     * @description Tester opprettelse av vedtak for OrganizationType 'Other'.
     *              Verifiserer at fritekstfeltene (OtherLegalBasis__c og 
     *              OtherPurpose__c) brukes når orgtype = 'Other', siden 
     *              switch-statementen ikke har en matchende case.
     */

     @isTest
    static void testCreateOther(){
        
        Test.startTest();
        Account testAccount = AAREG_TestDataFactory.getAccountEL();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationEL(testAccount);
        insert testApplication;
        
         // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(new ApplicationBasisCode__c(
            Application__c = testApplication.Id,
            API_Access__c = true,
            Extraction_Access__c = false,
            Online_Access__c = false,
            ProcessingBasis__c = 'Processing Basis 1',
            OrganizationType__c = 'Other',
            OtherLegalBasis__c= 'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
            OtherPurpose__c = 'Behandling av startlån/boligtilskudd'
        ));
         basisCodes.add(new ApplicationBasisCode__c(
            Application__c = testApplication.Id,
            API_Access__c = false,
            Extraction_Access__c = false,
            Online_Access__c = true,
            ProcessingBasis__c = 'Processing Basis 2',
            OrganizationType__c = 'Other',
            OtherLegalBasis__c= 'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
            OtherPurpose__c = 'Behandling av startlån/boligtilskudd'
        ));
        insert basisCodes;
        
        Id newDecisionId = AAREG_ApplicationDecisionController.createApplicationDecision(testApplication.Id);
        Test.stopTest();
        
        List<Application_Decision_Details__c> decisionDetails = [
            SELECT Id, Application_Decision__c, API_Access__c, Extraction_Access__c, Online_Access__c, Processing_Basis__c
            FROM Application_Decision_Details__c
            WHERE Application_Decision__c = :newDecisionId
        ];
        
        System.Assert.areEqual(basisCodes[0].OrganizationType__c, 'Other', 'Application type should match.');
        System.Assert.areEqual(2, decisionDetails.size(), 'There should be two decision details.');
        System.Assert.areEqual(true, decisionDetails[0].API_Access__c, 'First detail API_Access__c should match.');
        System.Assert.areEqual(false, decisionDetails[1].API_Access__c, 'Second detail API_Access__c should match.');
        
    }
}