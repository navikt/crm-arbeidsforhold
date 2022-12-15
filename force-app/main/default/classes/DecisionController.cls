public with sharing class DecisionController {
  public Application__c application { get; set; }
  
  public DecisionController() {
    Id recordId = ApexPages.currentPage().getParameters().get('id');
    application = [SELECT AA_CasehandlerDecisionTemplate__c FROM Application__c WHERE Id = :recordId];
    // Remove first image (NAV Logo) since it does not render properly and add it in VF page again
    String decisionString = application.AA_CasehandlerDecisionTemplate__c;
    String subStr1 = '';
    String subStr2 = '';
    if (decisionString.indexOf('<img') != -1 && decisionString.indexOf('</img>') != -1) {
      subStr1 = decisionString.substring(0, decisionString.indexOf('<img'));
      subStr2 = decisionString.substring(decisionString.indexOf('</img>')+6, decisionString.length());
    }
    if (subStr1 != '' && subStr2 != '') {
      application.AA_CasehandlerDecisionTemplate__c = subStr1 + subStr2;
    }
    // Remove unecessary linebreaks
    for (Integer i = 0; i < 6; i++) {
      application.AA_CasehandlerDecisionTemplate__c = application.AA_CasehandlerDecisionTemplate__c.replaceFirst('<br>', '');
    }
  }
}
