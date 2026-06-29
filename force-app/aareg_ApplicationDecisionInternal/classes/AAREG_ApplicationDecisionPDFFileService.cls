/**
 * Service class responsible for handling operations related to generating
 * PDF files for application decisions in the AAREG module.
 *
 * This class provides methods to create, manage, and process PDF files
 * associated with application decisions.
 *
 * @author AAREG Team
 * @date 25.06.2026
 * @group AAREG_ApplicationDecisionInternal
 * @group-content This class is part of the internal application decision handling module.
 */
public with sharing class AAREG_ApplicationDecisionPDFFileService {
    
    @InvocableMethod(label='AAREG Create ContentVersion PDF')
    /**
     * Creates a file based on the provided flow inputs.
     *
     * @param inputs A list of FlowInput objects that contain the data required to create the file.
     * @return A list of FlowOutput objects representing the results of the file creation process.
     */
    public static List<FlowOutput> createFile(FlowInput[] inputs){
      String decisionId;
      String accessRequestId;
      String applicationId;
      String agreementId;
      String fileTitle;
      String fileExtension = 'pdf';
      List<FlowOutput> outputs = new List<FlowOutput>();
      
      for(FlowInput input : inputs){
          decisionId = input.decisionRecordId;
          applicationId = input.applicationRecordId;
          accessRequestId = input.accessRequestRecordId;
          agreementId = input.agreementRecordId;
          fileTitle = input.decisionFileTitle;   
      }
      System.debug('agreementId mottatt fra flow: ' + agreementId);
      
      PageReference pdfPage = Page.AAREG_decisionInternalPDF;
      pdfPage.getParameters().put('id', decisionId);
      
      Blob pdfBlob = Test.isRunningTest()
          ? Blob.valueOf('TEST PDF')
          : pdfPage.getContentAsPDF();
      
      ContentVersion content = new ContentVersion();
      content.Title = fileTitle;
      content.PathOnClient = fileTitle + '.' + fileExtension;
      content.VersionData = pdfBlob;
      insert content;
      
      ContentVersion cv = [
          SELECT Id, ContentDocumentId
          FROM ContentVersion
          WHERE Id = :content.Id
      ];
      
      List<ContentDocumentLink> links = new List<ContentDocumentLink>();
      
      Map<String, Id> targets = new Map<String, Id>{
          'application'   => applicationId,
          'decision'      => decisionId,
          'accessRequest' => accessRequestId,
          'agreement'     => agreementId
      };
      
      for (Id targetId : targets.values()) {
          if (targetId != null) {       
              links.add(new ContentDocumentLink(
                  ContentDocumentId = cv.ContentDocumentId,
                  LinkedEntityId    = targetId,
                  ShareType         = 'V',        // Viewer
                  Visibility        = 'AllUsers'
              ));
          }
      }
      
      if (!links.isEmpty()) {
          insert links;
      }
      
      FlowOutput output = new FlowOutput();
      output.contentDocumentId = cv.ContentDocumentId; 
      outputs.add(output);
      
      return outputs;
  }
  
  /**
   * Represents the input parameters for the flow.
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
   */
  public class FlowOutput {
      @InvocableVariable(label='ContentdocumentId' required=true)
      public String contentDocumentId;
  }
}