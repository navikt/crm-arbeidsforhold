@IsTest
private class DecisionControllerTest {
    @TestSetup
    static void setup() {
        Account account = AAREG_TestDataFactory.getAccountCounty();
        insert account;
        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        application.AA_CasehandlerDecisionTemplate__c = 'test';
        insert application;
    }

    @IsTest
    static void testWithoutHTMLTags() {
        Application__c application = [SELECT Id FROM Application__c];
        String applicationId = (String) application.Id;

        Test.setCurrentPage(Page.AAREG_decisionPDF);
        ApexPages.currentPage().getParameters().put('Id', applicationId);

        Test.startTest();
        DecisionController dc = new DecisionController();
        Test.stopTest();

        application = [SELECT Id FROM Application__c];
        applicationId = (String) application.Id;

        System.assertEquals(applicationId, ApexPages.currentPage().getParameters().get('id'));
    }

    @IsTest
    static void testWithHTMLTags() {
        Application__c application = [SELECT Id, AA_CasehandlerDecisionTemplate__c FROM Application__c];
        application.AA_CasehandlerDecisionTemplate__c = 'testdata testdata testdata testdata <img src="testimg"></img> testdata testdata testdata testdata';
        update application;
        String applicationId = (String) application.Id;

        Test.setCurrentPage(Page.AAREG_decisionPDF);
        ApexPages.currentPage().getParameters().put('Id', applicationId);

        Test.startTest();
        DecisionController dc = new DecisionController();
        Test.stopTest();

        application = [SELECT Id FROM Application__c];
        applicationId = (String) application.Id;

        System.assertEquals(applicationId, ApexPages.currentPage().getParameters().get('id'));
    }

    @IsTest
    static void testWithoutIdParameter() {
        Test.setCurrentPage(Page.AAREG_decisionPDF);

        Test.startTest();
        DecisionController dc = new DecisionController();
        Test.stopTest();

        System.assertEquals(null, dc.application, 'Application should remain null when no id parameter is provided.');
    }
}
