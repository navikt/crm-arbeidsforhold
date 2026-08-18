/**
 * Visualforce controller for the case handler decision letter page. Loads the
 * application's decision text and strips the leading NAV logo image so it can be
 * re-added by the Visualforce page's own markup instead of rendering twice.
 *
 * @author Ann Kristin Olsen
 * @since July 2026
 * @group AAREG Application Decision
 */
public with sharing class DecisionController {
    /** The application whose decision letter is being rendered, or null if no valid record Id was provided. */
    public Application__c application { get; set; }

    /**
     * Reads the `id` page parameter, loads the application's decision template,
     * and removes its leading NAV logo image.
     */
    public DecisionController() {
        String recordIdParam = ApexPages.currentPage() != null
            ? ApexPages.currentPage().getParameters().get('id')
            : null;

        if (String.isBlank(recordIdParam)) {
            application = null;
            return;
        }

        Id recordId = recordIdParam;
        application = [SELECT AA_CasehandlerDecisionTemplate__c FROM Application__c WHERE Id = :recordId];
        // Remove first image (NAV Logo) since it does not render properly and add it in VF page again
        String decisionString = application.AA_CasehandlerDecisionTemplate__c;
        String subStr1 = '';
        String subStr2 = '';
        if (decisionString != null && decisionString.indexOf('<img') != -1 && decisionString.indexOf('</img>') != -1) {
            subStr1 = decisionString.substring(0, decisionString.indexOf('<img'));
            subStr2 = decisionString.substring(decisionString.indexOf('</img>') + 6, decisionString.length());
        }
        if (subStr1 != '' && subStr2 != '') {
            application.AA_CasehandlerDecisionTemplate__c = subStr1 + subStr2;
        }
    }
}
