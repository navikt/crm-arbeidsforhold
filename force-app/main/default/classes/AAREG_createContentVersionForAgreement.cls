public class AAREG_createContentVersionForAgreement {
  @InvocableMethod(label='Create ContentVersion')
  public static void createFile(FlowInput[] inputs) {
    String appId;
    String agrId;
    String contId;
    String condId;
    ContentVersion[] createfiles = new List<ContentVersion>{};
    //fetch agreement Id from flow
    for (FlowInput input : inputs) {
      agrId = input.currRecId;
    }

    appId = [SELECT id, application__c FROM agreement__c WHERE id = :agrId LIMIT 1].application__c;
    contId = [SELECT id, ContentDocumentId FROM contentdocumentlink WHERE LinkedEntityId = :appId LIMIT 1]
    .ContentDocumentId;
    condId = [SELECT id, LatestPublishedVersionId FROM contentdocument WHERE id = :contId LIMIT 1]
    .LatestPublishedVersionId;

    //fetch contentversion data from application id
    for (contentVersion conv : [
      SELECT
        Id,
        ContentLocation,
        FileExtension,
        FirstPublishLocationId,
        PathOnClient,
        PublishStatus,
        SharingOption,
        Title,
        VersionData
      FROM ContentVersion
      WHERE Id = :condId
    ]) {
      //create a duplicate of file connected to agreement
      ContentVersion file = new ContentVersion();
      file.Title = conv.Title;
      file.PathOnClient = file.Title + '.' + conv.FileExtension;
      file.VersionData = conv.versionData;
      file.FirstPublishLocationId = agrId;
      createfiles.add(file);
    }
    insert createfiles;
  }

  public class FlowInput {
    @InvocableVariable(label='Current record Id' required='true')
    public String currRecId;
  }
}
