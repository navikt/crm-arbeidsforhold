/**
 * Controller for the internal application decision PDF Visualforce page.
 *
 * Loads the application, decision, and related decision detail data required
 * to generate a PDF presentation of the decision.
 *
 * @author AAREG Team
 * @version 66
 * @group Internal Application Decision
 */
public with sharing class AAREG_ApplicationDecisionPDFController {
    /** The current decision record Id from the page parameters. */
    public Id currentRecordId { get; set; }

    /** The decision wrapper loaded for the current decision record. */
    public AAREG_ApplicationDecision currentRecord { get; set; }

    /** The application wrapper loaded for the decision's related application. */
    public AAREG_ApplicationInternal applicationRecord { get; set; }

    /** The list of decision detail wrappers displayed in the PDF. */
    public List<AAREG_BasisCodesInternal> decisionDetailsRecords { get; set; }

    /**
     * Initializes the PDF controller and loads the decision and application data.
     * Handles all data loading with appropriate error handling and security checks.
     *
     * @param sc The standard Visualforce controller used by the page.
     */
    public AAREG_ApplicationDecisionPDFController(ApexPages.StandardController sc) {
        try {
            this.currentRecordId = sc.getId();
            this.currentRecord = getApplicationDecisionRecord(this.currentRecordId);
            this.applicationRecord = getApplicationRecord(this.currentRecord.soknadsId);
            this.decisionDetailsRecords = getApplicationDecisionDetails(this.currentRecordId);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved initialisering av PDF-controller: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Kunne ikke laste PDF-data: ' + e.getMessage());
        }
    }

    /**
     * @description Queries application data for PDF presentation.
     * @param currentRecordId Id of the Application__c record
     * @return AAREG_ApplicationInternal wrapper with application details
     */
    private AAREG_ApplicationInternal getApplicationRecord(String currentRecordId) {
        try {
            AAREG_ApplicationInternal applicationWrapperTempList = new AAREG_ApplicationInternal();

            // Check if user has read access to Application__c (FLS)
            Schema.DescribeSObjectResult describe = Application__c.sObjectType.getDescribe();
            if (!describe.isAccessible()) {
                LoggerUtility logger = new LoggerUtility();
                logger.error('Kan ikke lese søknadsdata. Mangler tilgang til objektet.', null);
                logger.publish();
                throw new AuraHandledException('Kan ikke lese søknadsdata. Mangler tilgang til objektet.');
            }

            // Query application with security context enforced (WITH USER_MODE)
            List<Application__c> application = [
                SELECT
                    Id,
                    Name,
                    AccountId__c,
                    AccountName__c,
                    Account__c,
                    ApplicationSubmittedDate__c,
                    Contact__c,
                    DataProcessorName__c,
                    DataProcessorOrganizationNumber__c,
                    Email__c,
                    MailingAddress__c,
                    MailingCity__c,
                    MailingPostalCode__c,
                    OrganizationNumber__c,
                    CasehandlerOwner__r.Name
                FROM Application__c
                WHERE Id = :currentRecordId
                WITH USER_MODE
                LIMIT 1
            ];

            // Map application record to wrapper if found
            if (!application.isEmpty()) {
                Application__c app = application[0];
                applicationWrapperTempList.SoknadsId = app.Id;
                applicationWrapperTempList.SoknadsNavn = app.Name;
                applicationWrapperTempList.KonsumentId = app.Account__c;
                applicationWrapperTempList.KonsumentNavn = app.AccountName__c;
                applicationWrapperTempList.KonsumentKontaktNavn = app.Contact__c;
                applicationWrapperTempList.KonsumentOrganisasjonsnummer = app.OrganizationNumber__c;
                applicationWrapperTempList.KonsumentAdresse = app.MailingAddress__c;
                applicationWrapperTempList.KonsumentPoststed = app.MailingCity__c;
                applicationWrapperTempList.KonsumentPostnummer = app.MailingPostalCode__c;
                applicationWrapperTempList.KonsumentEpost = app.Email__c;
                applicationWrapperTempList.SoknadLevert = app.ApplicationSubmittedDate__c;
                applicationWrapperTempList.DatabehandlerNavn = app.DataProcessorName__c;
                applicationWrapperTempList.DatabehandlerOrganisasjonsnummer = app.DataProcessorOrganizationNumber__c;
                applicationWrapperTempList.Sakseier = app.CasehandlerOwner__r.Name;
            }
            return applicationWrapperTempList;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved henting av søknadsdata: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Kunne ikke hente søknadsdata: ' + e.getMessage());
        }
    }

    /**
     * @description Queries decision record data for PDF presentation.
     * @param currentRecordId Id of the Application_Decision__c record
     * @return AAREG_ApplicationDecision wrapper with decision details
     */
    private AAREG_ApplicationDecision getApplicationDecisionRecord(String currentRecordId) {
        try {
            AAREG_ApplicationDecision decisionWrapper = new AAREG_ApplicationDecision();

            // Check if user has read access to Application_Decision__c (FLS)
            Schema.DescribeSObjectResult describe = Application_Decision__c.sObjectType.getDescribe();
            if (!describe.isAccessible()) {
                LoggerUtility logger = new LoggerUtility();
                logger.error('Kan ikke lese vedtaksdata. Mangler tilgang til objektet.', null);
                logger.publish();
                throw new AuraHandledException('Kan ikke lese vedtaksdata. Mangler tilgang til objektet.');
            }

            // Query decision with security context enforced (WITH USER_MODE)
            List<Application_Decision__c> decisionRecords = [
                SELECT
                    Id,
                    Name,
                    CreatedDate,
                    Application__c,
                    Status__c,
                    decision_description__c,
                    Letter_complaint_text__c,
                    Letter_terms_text__c,
                    Decision_date__c,
                    Web_access_count__c,
                    Letter_github_text__c,
                    Letter_webaccess_text__c
                FROM Application_Decision__c
                WHERE Id = :currentRecordId
                WITH USER_MODE
                LIMIT 1
            ];

            // Map decision record to wrapper if found
            if (!decisionRecords.isEmpty()) {
                Application_Decision__c app = decisionRecords[0];
                decisionWrapper.vedtaksNr = app.Name;
                decisionWrapper.vedtaksdato = app.Decision_date__c;
                decisionWrapper.vedtaksbegrunnelse = app.decision_description__c;
                decisionWrapper.vedtaksId = app.Id;
                decisionWrapper.status = app.Status__c;
                decisionWrapper.soknadsId = app.Application__c;
                decisionWrapper.klagetekst = app.Letter_complaint_text__c;
                decisionWrapper.vilkaartekst = app.Letter_terms_text__c;
                decisionWrapper.webTilgang = app.Web_access_count__c;
                decisionWrapper.githubtekst = app.Letter_github_text__c;
                decisionWrapper.webTilgangtekst = app.Letter_webaccess_text__c;
            }

            return decisionWrapper;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved henting av vedtaksdata: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Kunne ikke hente vedtaksdata: ' + e.getMessage());
        }
    }

    /**
     * @description Queries decision detail records for PDF presentation.
     * @param currentRecordId Id of the Application_Decision__c record
     * @return List of AAREG_BasisCodesInternal wrappers with detail data
     */
    private List<AAREG_BasisCodesInternal> getApplicationDecisionDetails(String currentRecordId) {
        try {
            List<AAREG_BasisCodesInternal> decisionDetailsRecords = new List<AAREG_BasisCodesInternal>();

            // Check if user has read access to Application_Decision_Details__c (FLS)
            Schema.DescribeSObjectResult describe = Application_Decision_Details__c.sObjectType.getDescribe();
            if (!describe.isAccessible()) {
                LoggerUtility logger = new LoggerUtility();
                logger.error('Kan ikke lese vedtaksdetaljer. Mangler tilgang til objektet.', null);
                logger.publish();
                throw new AuraHandledException('Kan ikke lese vedtaksdetaljer. Mangler tilgang til objektet.');
            }

            // Query decision details with security context enforced (WITH USER_MODE)
            List<Application_Decision_Details__c> detailRecords = [
                SELECT
                    Id,
                    Name,
                    Application_Decision__c,
                    API_Access__c,
                    Extraction_Access__c,
                    Legal_Basis__c,
                    Online_Access__c,
                    Processing_Basis__c,
                    Purpose__c,
                    Decision_description__c,
                    Approved__c
                FROM Application_Decision_Details__c
                WHERE Application_Decision__c = :currentRecordId
                WITH USER_MODE
            ];

            // Map detail records to wrapper objects if any exist
            if (!detailRecords.isEmpty()) {
                for (Application_Decision_Details__c detail : detailRecords) {
                    AAREG_BasisCodesInternal detailWrapper = new AAREG_BasisCodesInternal();
                    detailWrapper.vedtaksDetailId = detail.Id;
                    detailWrapper.vedtaksDetailNr = detail.Name;
                    detailWrapper.behandlingsgrunnlag = detail.Processing_Basis__c;
                    detailWrapper.hjemmel = detail.Legal_Basis__c;
                    detailWrapper.formaal = detail.Purpose__c;
                    detailWrapper.apiTilgang = detail.API_Access__c;
                    detailWrapper.uttrekk = detail.Extraction_Access__c;
                    detailWrapper.webTilgang = detail.Online_Access__c;
                    detailWrapper.vedtaksbegrunnelse = detail.Decision_description__c;
                    detailWrapper.behandlingsgrunnlagGodkjent = detail.Approved__c;
                    decisionDetailsRecords.add(detailWrapper);
                }
            }
            return decisionDetailsRecords;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved henting av vedtaksdetaljer: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Kunne ikke hente vedtaksdetaljer: ' + e.getMessage());
        }
    }
}
