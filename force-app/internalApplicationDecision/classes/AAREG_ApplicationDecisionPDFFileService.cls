/**
 * Service class responsible for handling operations related to generating
 * PDF files for application decisions in the AAREG module.
 *
 * This class provides methods to create, manage, and process PDF files
 * associated with application decisions.
 *
 * @author AAREG Team
 * @version 66
 * @date 25.06.2026
 * @group AAREG_ApplicationDecisionInternal
 * @group-content This class is part of the internal application decision handling module.
 */
public with sharing class AAREG_ApplicationDecisionPDFFileService {
    @InvocableMethod(label='AAREG Create ContentVersion PDF')
    /**
     * Creates a PDF file based on the provided flow inputs.
     * Handles PDF generation, content version creation, and document linking to multiple records.
     *
     * @param inputs A list of FlowInput objects that contain the data required to create the file.
     * @return A list of FlowOutput objects representing the results of the file creation process.
     */
    public static List<FlowOutput> createFile(FlowInput[] inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();

        try {
            // Validate input is not empty
            if (inputs == null || inputs.isEmpty()) {
                LoggerUtility logger = new LoggerUtility();
                logger.error('Ingen input mottatt for PDF-opprettelse.', null);
                logger.publish();
                throw new AuraHandledException('Ingen input mottatt for PDF-opprettelse.');
            }

            // Process single input (handle only first input if multiple are provided)
            FlowInput input = inputs[0];

            // Validate required fields
            if (
                String.isBlank(input.decisionRecordId) ||
                String.isBlank(input.applicationRecordId) ||
                String.isBlank(input.decisionFileTitle)
            ) {
                LoggerUtility logger = new LoggerUtility();
                logger.error('Påkrevde felt mangler i PDF-input.', null);
                logger.publish();
                throw new AuraHandledException('Påkrevde felt mangler i PDF-input.');
            }

            String decisionId = input.decisionRecordId;
            String applicationId = input.applicationRecordId;
            String accessRequestId = input.accessRequestRecordId;
            String agreementId = input.agreementRecordId;
            String fileTitle = input.decisionFileTitle;
            String fileExtension = 'pdf';

            // Generate PDF from Visualforce page
            PageReference pdfPage = Page.AAREG_decisionInternalPDF;
            pdfPage.getParameters().put('id', decisionId);

            Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('TEST PDF') : pdfPage.getContentAsPDF();

            // Check if user has create access to ContentVersion (CRUD check)
            Schema.DescribeSObjectResult cvDescribe = ContentVersion.sObjectType.getDescribe();
            if (!cvDescribe.isCreateable()) {
                LoggerUtility logger = new LoggerUtility();
                logger.error('Kan ikke opprette PDF-fil. Mangler CRUD-tilgang til ContentVersion.', null);
                logger.publish();
                throw new AuraHandledException('Kan ikke opprette PDF-fil. Mangler tilgang.');
            }

            // Create content version with PDF blob
            ContentVersion content = new ContentVersion();
            content.Title = fileTitle;
            content.PathOnClient = fileTitle + '.' + fileExtension;
            content.VersionData = pdfBlob;
            insert content;

            // Query inserted content with security context to get ContentDocumentId
            List<ContentVersion> cvList = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id = :content.Id
                WITH USER_MODE
                LIMIT 1
            ];

            if (cvList.isEmpty()) {
                LoggerUtility logger = new LoggerUtility();
                logger.error('ContentVersion ble ikke funnet etter insert.', null);
                logger.publish();
                throw new AuraHandledException('Kunne ikke finne opprettet PDF-fil.');
            }

            ContentVersion cv = cvList[0];

            // Build map of target records to link PDF to
            Map<String, Id> targets = new Map<String, Id>{
                'application' => String.isBlank(applicationId) ? null : (Id) applicationId,
                'decision' => String.isBlank(decisionId) ? null : (Id) decisionId,
                'accessRequest' => String.isBlank(accessRequestId) ? null : (Id) accessRequestId,
                'agreement' => String.isBlank(agreementId) ? null : (Id) agreementId
            };

            // Check if user has create access to ContentDocumentLink (CRUD check)
            Schema.DescribeSObjectResult cdlDescribe = ContentDocumentLink.sObjectType.getDescribe();
            if (!cdlDescribe.isCreateable()) {
                LoggerUtility logger = new LoggerUtility();
                logger.error('Kan ikke linke PDF-fil. Mangler CRUD-tilgang til ContentDocumentLink.', null);
                logger.publish();
                throw new AuraHandledException('Kan ikke linke PDF-fil. Mangler tilgang.');
            }

            // Create content document links to all valid target records
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id targetId : targets.values()) {
                if (targetId != null) {
                    links.add(
                        new ContentDocumentLink(
                            ContentDocumentId = cv.ContentDocumentId,
                            LinkedEntityId = targetId,
                            ShareType = 'V', // Viewer
                            Visibility = 'AllUsers'
                        )
                    );
                }
            }

            // Insert all content document links
            if (!links.isEmpty()) {
                insert links;
            }

            // Build and return output
            FlowOutput output = new FlowOutput();
            output.contentDocumentId = cv.ContentDocumentId;
            outputs.add(output);

            return outputs;
        } catch (DmlException e) {
            // Handle DML-specific errors
            LoggerUtility logger = new LoggerUtility();
            logger.error('DML-feil ved opprettelse av PDF-fil: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('DML-feil ved opprettelse av PDF-fil: ' + e.getMessage());
        } catch (Exception e) {
            // Handle unexpected errors
            LoggerUtility logger = new LoggerUtility();
            logger.error('Uventet feil ved opprettelse av PDF-fil: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Uventet feil ved opprettelse av PDF-fil: ' + e.getMessage());
        }
    }
    /**
     * Represents the input parameters for the flow invocation.
     * Contains all record IDs and file metadata needed to generate and link PDF files.
     */
    public class FlowInput {
        @InvocableVariable(label='Decision Id' required=true)
        public String decisionRecordId;

        @InvocableVariable(label='Application Id' required=true)
        public String applicationRecordId;

        @InvocableVariable(label='Access Request Id' required=true)
        public String accessRequestRecordId;

        @InvocableVariable(label='Agreement Id' required=false)
        public String agreementRecordId;

        @InvocableVariable(label='File title' required=true)
        public String decisionFileTitle;
    }

    /**
     * Represents the output of a flow process.
     * Contains the ContentDocumentId of the created PDF file for reference in flows.
     */
    public class FlowOutput {
        @InvocableVariable(label='ContentdocumentId' required=true)
        public String contentDocumentId;
    }
}
