public with sharing class AAREG_ApplicationDecisionPDFFileService {
    
    @InvocableMethod(label='AAREG Create ContentVersion PDF')
    public static List<FlowOutput> createFile(FlowInput[] inputs){
        String decisionId;
        String applicationId;
        String fileTitle;
        String fileExtension ='pdf';
        List<FlowOutput> outputs = new List<FlowOutput>();
        
        for(FlowInput input : inputs){
            decisionId = input.decisionRecordId;
            applicationId = input.applicationRecordId;
            fileTitle = input.decisionFileTitle;   
        }
        
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
       
      ContentDocumentLink contentLink = new ContentDocumentLink();
      contentLink.ContentDocumentId = cv.ContentDocumentId;
      contentLink.LinkedEntityId = applicationId;
      contentLink.ShareType = 'V'; // Viewer access
      contentLink.Visibility = 'AllUsers';
      insert contentLink;
        
      FlowOutput output = new FlowOutput();
      output.contentDocumentId = contentLink.ContentDocumentId;
      outputs.add(output);
        
      return outputs;
    }
    
    public class FlowInput {
    @InvocableVariable(label='Decision Id' required='true')
    public String decisionRecordId;
        
    @InvocableVariable(label='Application Id' required='true')
    public String applicationRecordId;
        
	@InvocableVariable(label='File title' required='true')
    public String decisionFileTitle;   
  }
    
    public class FlowOutput{
    @InvocableVariable(label='ContentdocumentId' required='true')
    public String contentDocumentId;
    }

}