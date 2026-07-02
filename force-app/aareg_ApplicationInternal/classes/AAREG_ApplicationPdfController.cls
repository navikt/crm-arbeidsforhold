/**
 * @description Extension-controller for AAREG_ApplicationPdf Visualforce-side.
 * @group AAREG
 */
public with sharing class AAREG_ApplicationPdfController {
    /**
     * Represents the application record associated with this controller.
     */
    public Application__c app { get; set; }
    /**
     * A list of ApplicationBasisCode__c objects.
     * This property is used to store and manage the basis codes associated with the application.
     */
    public List<ApplicationBasisCode__c> basisCodes { get; set; }

    /**
     * Constructor for the AAREG_ApplicationPdfController class.
     * Initializes the controller with a standard controller instance.
     *
     * @param stdController The standard controller instance provided by the Visualforce page.
     */
    public AAREG_ApplicationPdfController(ApexPages.StandardController stdController) {
        this.app = (Application__c) stdController.getRecord();

        this.basisCodes = [
            SELECT Id, OrganizationType__c, ProcessingBasis__c
            FROM ApplicationBasisCode__c
            WHERE Application__c = :app.Id
        ];
    }
}