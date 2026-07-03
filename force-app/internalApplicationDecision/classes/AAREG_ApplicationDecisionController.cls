/**
 * Controller for internal application decision handling in AAREG.
 *
 * This class exposes operations for reading decision records, creating new
 * decisions, copying basis code details, and building decision detail records.
 */
public with sharing class AAREG_ApplicationDecisionController {
    private static final String STATUS_IN_PROGRESS  = 'In progress';
    private static final String OTHER_LEGAL_BASIS   = 'Annet - oppgi i tekstfelt under';
    private static final String ORG_TYPE_STATE      = 'State';
    private static final String ORG_TYPE_MUNICIPAL  = 'Municipality';
    private static final String ORG_TYPE_PENSION    = 'Pension';
    private static final String ORG_TYPE_ELECTRIC   = 'Electricity Supervision';
    private static final String ORG_TYPE_COUNTY     = 'County';
    private static final String ORG_TYPE_OTHER      = 'Other';

    /**
     * @description Henter vedtaksdata for en gitt søknad.
     * @param recordId Id til Application__c
     * @return Liste med AAREG_ApplicationDecision wrappere
     */
    @AuraEnabled(cacheable=true)
    public static List<AAREG_ApplicationDecision> getApplicationDecision(Id recordId) {
        List<AAREG_ApplicationDecision> decisionWrappers = new List<AAREG_ApplicationDecision>();

        Schema.DescribeSObjectResult describe = getSObjectDescribe(Application_Decision__c.sObjectType);
        if (!describe.isAccessible()) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Kan ikke lese vedtak. Mangler tilgang til objektet.', null);
            logger.publish();
            throw new AuraHandledException('Kan ikke lese vedtak. Mangler tilgang til objektet.');
        }

        List<Application_Decision__c> decisions = [
            SELECT Id, Name, Application__c, Status__c, Process_status__c
            FROM Application_Decision__c
            WHERE Application__c = :recordId
            WITH USER_MODE
        ];

        for (Application_Decision__c app : decisions) {
            AAREG_ApplicationDecision wrapper = new AAREG_ApplicationDecision();
            wrapper.vedtaksId         = app.Id;
            wrapper.vedtaksNr         = app.Name;
            wrapper.soknadsId         = app.Application__c;
            wrapper.status            = app.Status__c;
            wrapper.statusProsess     = app.Process_status__c;
            decisionWrappers.add(wrapper);
        }

        return decisionWrappers;
    }

     /**
     * @description Oppretter et nytt vedtak basert på søknad, og kopierer 
     *              behandlingsgrunnlag til Application_Decision_Details__c.
     * @param recordId Id til Application__c
     * @return Id til det opprettede Application_Decision__c
     */

     @AuraEnabled
     public static Id createApplicationDecision(Id recordId) {
         try {
             Application_Decision__c newDecision = buildNewDecision(recordId);

             Schema.DescribeSObjectResult decisionDescribe = getSObjectDescribe(Application_Decision__c.sObjectType);
             if (!decisionDescribe.isCreateable()) {
                 LoggerUtility logger = new LoggerUtility();
                 logger.error('Kan ikke opprette vedtak. Mangler CRUD-tilgang.', null);
                 logger.publish();
                 throw new AuraHandledException('Kan ikke opprette vedtak. Mangler CRUD-tilgang.');
             }

             insert newDecision;
 
             List<ApplicationBasisCode__c> basisCodes = getBasisCodes(recordId);
             List<Application_Decision_Details__c> details =
                 buildDecisionDetails(newDecision.Id, basisCodes);
 
             if (!details.isEmpty()) {
                 Schema.DescribeSObjectResult detailDescribe = getSObjectDescribe(Application_Decision_Details__c.sObjectType);
                 if (!detailDescribe.isCreateable()) {
                     LoggerUtility logger = new LoggerUtility();
                     logger.error('Kan ikke opprette vedtaksdetaljer. Mangler CRUD-tilgang.', null);
                     logger.publish();
                     throw new AuraHandledException('Kan ikke opprette vedtaksdetaljer. Mangler CRUD-tilgang.');
                 }

                 insert details;
             }
 
             return newDecision.Id;
            } catch (DmlException e) {
                LoggerUtility logger = new LoggerUtility();
                logger.error('DML-feil ved opprettelse av vedtak: ' + e.getMessage(), null);
                logger.publish();
                throw new AuraHandledException('Kunne ikke opprette vedtak: ' + e.getMessage());
        
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.error('Uventet feil ved opprettelse av vedtak: ' + e.getMessage(), null);
                logger.publish();
                throw new AuraHandledException('En uventet feil oppstod: ' + e.getMessage());
            }
     }

     /**
     * Builds a new Application_Decision__c object populated with default values.
     *
     * @param applicationId The Id of the Application__c record to associate with the decision.
     * @return A new Application_Decision__c instance ready for insert.
     */
    private static Application_Decision__c buildNewDecision(Id applicationId) {
        return new Application_Decision__c(
            Application__c           = applicationId,
            Process_status__c        = STATUS_IN_PROGRESS,
            Decision_date__c         = System.today(),
            Letter_complaint_text__c = System.Label.AAREG_complaint_description_section,
            Letter_terms_text__c     = System.Label.AAREG_terms_description_section,
            Letter_github_text__c    = System.Label.AAREG_github_description_text,
            Letter_webaccess_text__c = System.Label.AAREG_web_access_text
        );
    }

    /**
     * Returns the describe result for a given SObject type.
     *
     * @param sObjectType The SObject type to describe.
     * @return The Schema.DescribeSObjectResult for the type.
     */
    private static Schema.DescribeSObjectResult getSObjectDescribe(Schema.SObjectType sObjectType) {
        return sObjectType.getDescribe();
    }

    /**
     * Retrieves all basis codes associated with the given application.
     *
     * @param applicationId The Id of the Application__c record whose basis codes should be loaded.
     * @return List of ApplicationBasisCode__c records linked to the application.
     */
    private static List<ApplicationBasisCode__c> getBasisCodes(Id applicationId) {
        Schema.DescribeSObjectResult describe = getSObjectDescribe(ApplicationBasisCode__c.sObjectType);
        if (!describe.isAccessible()) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Kan ikke lese behandlingsgrunnlag. Mangler tilgang til objektet.', null);
            logger.publish();
            throw new AuraHandledException('Kan ikke lese behandlingsgrunnlag. Mangler tilgang til objektet.');
        }

        return [
            SELECT Id,
              Name,
              API_Access__c,
              Extraction_Access__c,
              Online_Access__c,
              Application__c,
              ProcessingBasis__c,
              LegalBasisCounty__c,
              LegalBasisElectricitySupervision__c,
              LegalBasisMunicipality__c,
              LegalBasisPension__c,
              LegalBasisState__c,
              OrganizationType__c,
              OtherLegalBasis__c,
              OtherPurpose__c,
              PurposeCounty__c,
              PurposeElectricitySupervision__c,
              PurposeMunicipality__c,
              PurposePension__c,
              PurposeState__c
        FROM ApplicationBasisCode__c
        WHERE Application__c = :applicationId
        WITH USER_MODE
        ];
    }

    /**
     * Builds Application_Decision_Details__c records based on the provided basis codes.
     *
     * @param decisionId The Id of the created Application_Decision__c record.
     * @param basisCodes The list of ApplicationBasisCode__c records to convert into decision details.
     * @return List of Application_Decision_Details__c records ready for insert.
     */
    private static List<Application_Decision_Details__c> buildDecisionDetails(
        Id decisionId,
        List<ApplicationBasisCode__c> basisCodes
    ) {
        List<Application_Decision_Details__c> details = new List<Application_Decision_Details__c>();

        for (ApplicationBasisCode__c basis : basisCodes) {
            Application_Decision_Details__c detail = new Application_Decision_Details__c(
                Application_Decision__c = decisionId,
                API_Access__c           = basis.API_Access__c,
                Extraction_Access__c    = basis.Extraction_Access__c,
                Online_Access__c        = basis.Online_Access__c,
                Processing_Basis__c     = basis.ProcessingBasis__c
            );

            assignLegalBasisAndPurpose(detail, basis);
            details.add(detail);
        }
        return details;
    }

     /**
     * Sets the legal basis and purpose fields on the decision detail record.
     *
     * @param detail The detail record to populate.
     * @param basis The source basis code record containing organization type and legal basis values.
     */
    private static void assignLegalBasisAndPurpose(
        Application_Decision_Details__c detail,
        ApplicationBasisCode__c basis
    ) {
        String legalBasis;
        String purpose;

        switch on basis.OrganizationType__c {
            when 'State' {
                legalBasis = basis.LegalBasisState__c;
                purpose    = basis.PurposeState__c;
            }
            when 'Municipality' {
                legalBasis = basis.LegalBasisMunicipality__c;
                purpose    = basis.PurposeMunicipality__c;
            }
            when 'Pension' {
                legalBasis = basis.LegalBasisPension__c;
                purpose    = basis.PurposePension__c;
            }
            when 'Electricity Supervision' {
                legalBasis = basis.LegalBasisElectricitySupervision__c;
                purpose    = basis.PurposeElectricitySupervision__c;
            }
            when 'County' {
                legalBasis = basis.LegalBasisCounty__c;
                purpose    = basis.PurposeCounty__c;
            }
        }
        Boolean isOtherOrgType = basis.OrganizationType__c == ORG_TYPE_OTHER;
        Boolean isOtherLegalBasis = legalBasis == OTHER_LEGAL_BASIS;
        Boolean useOtherFields = isOtherOrgType || isOtherLegalBasis;

        if (useOtherFields) {
            detail.Legal_Basis__c = basis.OtherLegalBasis__c;
            detail.Purpose__c     = basis.OtherPurpose__c;
        } else {
            detail.Legal_Basis__c = legalBasis;
            detail.Purpose__c     = purpose;
        }
    }
  }