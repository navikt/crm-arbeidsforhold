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
              
             //if created from application, update account and user id
              if(relatedRecordObjectName=='Application__c'){
                 String accountId = [SELECT id,Account__c FROM Application__c WHERE Id = :tempStr]?.Account__c;
                 String userId =[SELECT CreatedById  FROM Thread__c WHERE id=:currentRecord]?.CreatedById;
                 Thread__c thread = new Thread__c(
                     id = currentRecord,
                     CRM_From__c = userId,
                     CRM_Account__c=accountId);
                  update thread;
              }
          }
     }
}