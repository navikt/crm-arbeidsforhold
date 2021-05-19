@isTest
public class AAREG_CodeBaseListControllerTest {
@TestSetup
    static void createData(){
        Account acc = new Account();
        acc.Name = 'TestingAA-reg';
        insert acc;
        
		Id devRecordTypeId = SObjectType.Application__c.getRecordTypeInfosByDeveloperName().get('Aa_RegisterAccess').getRecordTypeId();    
        Application__c app = new Application__c();
        app.Account__c = acc.Id;
        app.RecordTypeId = devRecordTypeId;
        app.ApplicationSubmittedDate__c = system.now();
        insert app;
        
        ApplicationBasisCode__c abc = new ApplicationBasisCode__c();
        abc.Application__c = app.Id;
        abc.OrganizationType__c='County';
        abc.LegalBasisCounty__c='Aa-registerforskriften § 10 bokstav e';
        abc.PurposeCounty__c='Planleggingsarbeid - infrastruktur/kollektivtrasport/kartlegging av arbeidsreiser';
        abc.DecisionBasis__c = 'ja,da...';
        insert abc;   
    }

@isTest
    static void testCodeBaseComponent(){
        Application__c appl =[SELECT id FROM Application__c LIMIT 1];
        List<ApplicationBasisCode__c> baseList =AAREG_CodeBaseListController.getCodeBaseList(appl.Id);
        
        //List should not be empty
        System.assertNotEquals(baseList.size(), 0,'List should not be empty');
        
        //Loop through fields to ensure is not null
        for(ApplicationBasisCode__c abc : baseList){
            System.assertNotEquals(abc.LegalBasisCounty__c, null,'Legal should not be null');
            System.assertNotEquals(abc.PurposeCounty__c, null,'purpose should not be null');
            System.assertNotEquals(abc.DecisionBasis__c, null,'decision should not be null');
        }
    }
}