public class AAREG_createContentVersionForAgreement  {
    
    @InvocableMethod(label = 'Create ContentVersion')
    public static void createFile(FlowInput[] inputs){
        String appId;
        String agrId;
        ContentVersion[] createfiles= new ContentVersion[]{};
        //fetch agreement Id from flow
        for(FlowInput input : inputs){
            agrId = input.currRecId;
            appId = [SELECT id,application__c FROM agreement__c WHERE id=:input.currRecId].application__c;  
        }
        
        //fetch contentversion data from application id
		for(contentVersion conv :[SELECT 
                              Id,
                              ContentLocation, 
                              FileExtension,
                              FirstPublishLocationId, 
                              PathOnClient,
                              PublishStatus, 
                              SharingOption, 
                              Title, 
                              VersionData
                              FROM ContentVersion where FirstPublishLocationId=:appId]){
                                  
                                  //create a duplicate of file connected to agreement
                                  ContentVersion file = new ContentVersion();
                                  file.Title = conv.Title;
                                  file.PathOnClient = file.Title + '.' + conv.FileExtension;
                                  file.VersionData = conv.versionData;
                                  file.FirstPublishLocationId =agrId;
                                  createfiles.add(file);
                              }
        insert createfiles;

    }
    
    public class FlowInput {
        @InvocableVariable(label='Current record Id' required='true')
        public String currRecId;

    }
}