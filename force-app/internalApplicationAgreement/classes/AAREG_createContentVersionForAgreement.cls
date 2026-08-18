/**
 * Flow-invocable action that duplicates an application's latest published file as a
 * new ContentVersion attached to the related agreement.
 *
 * @author Ann Kristin Olsen
 * @author Jordan Mathews
 * @since July 2021
 * @group AAREG Internal Application Agreement
 */
public class AAREG_createContentVersionForAgreement {
    /**
     * Invocable action ("Create ContentVersion"). Looks up the application linked to
     * each agreement, finds its latest published file, and inserts a copy of that
     * file attached to the agreement.
     *
     * @param inputs The Flow inputs, each carrying the current Agreement__c record Id.
     */
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

        appId = [SELECT id, application__c FROM agreement__c WHERE id = :agrId LIMIT 1]?.application__c;
        contId = [SELECT id, ContentDocumentId FROM contentdocumentlink WHERE LinkedEntityId = :appId LIMIT 1]
        ?.ContentDocumentId;
        condId = [SELECT id, LatestPublishedVersionId FROM contentdocument WHERE id = :contId LIMIT 1]
        ?.LatestPublishedVersionId;

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

    /**
     * Flow input for AAREG_createContentVersionForAgreement.createFile.
     */
    public class FlowInput {
        /** Id of the current Agreement__c record being processed by the Flow. */
        @InvocableVariable(label='Current record Id' required='true')
        public String currRecId;
    }
}
