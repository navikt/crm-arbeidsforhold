global class AAREG_checkObjectTypeNameche{
    //Testclass is done by AAREG_ContactSupportControllerTest.apxc
    @InvocableMethod
     public static void CheckObjectTypeName(List<Id> values) {         
         if(!(values.isEmpty())){
             //Current record Id from flow
            Id currentRecord = values[0];
            
             //get the related objects id and object name
             String tempStr = [SELECT CRM_Related_Object__c FROM Thread__c where id=:currentRecord]?.CRM_Related_Object__c;
             Id relRecId =Id.valueOf(tempStr);
             String relatedRecordObjectName = relRecId.getSObjectType().getDescribe().getName();
             
             //get user id and profile name
             String userId =[SELECT CreatedById  FROM Thread__c WHERE id=:currentRecord]?.CreatedById;
             String profileId =[SELECT profile.UserLicense.name FROM user WHERE IsActive=true and id=:userId]?.profile.UserLicense.name;
              
             //if created from application, update account and user id
              if(relatedRecordObjectName=='Application__c' && profileId =='Customer Community Plus Login' ){
                 String accountId = [SELECT id,Account__c FROM Application__c WHERE Id = :tempStr]?.Account__c;
                 
                 Thread__c thread = new Thread__c(
                     id = currentRecord,
                     CRM_From__c = userId,
                     CRM_Account__c=accountId);
                  update thread;
              }
             if(relatedRecordObjectName=='Application__c' && profileId =='Salesforce Platform'){
                 String accountId = [SELECT id,Account__c FROM Application__c WHERE Id = :tempStr]?.Account__c;
                 String applUserId =[SELECT createdById FROM Application__c WHERE id =:tempStr]?.createdById;
                 
                 Thread__c thread = new Thread__c(
                     id = currentRecord,
                     CRM_From__c = applUserId,
                     CRM_Account__c=accountId);
                  update thread;
             }
          }
     }
}