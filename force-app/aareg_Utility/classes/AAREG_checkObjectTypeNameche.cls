global class AAREG_checkObjectTypeNameche{
    //Testclass is done by AAREG_ContactSupportControllerTest.apxc
    @InvocableMethod
     public static void CheckObjectTypeName(List<Id> values) {         
         if(!(values.isEmpty())){
             //Current record Id from flow
            Id currentRecord = values[0];
             
             Thread__c threadRec = [SELECT CRM_Related_Object__c, CreatedById FROM Thread__c WHERE id= :currentRecord];
            
             //get the related objects id and object name
             String tempStr = threadRec?.CRM_Related_Object__c;
             Id relRecId =Id.valueOf(tempStr);
             String relatedRecordObjectName = relRecId.getSObjectType().getDescribe().getName();
			 
             
             //get user id and profile name
             String userId = threadRec?.CreatedById;
             String profileId =[SELECT profile.UserLicense.name FROM user WHERE IsActive=true and id=:userId]?.profile.UserLicense.name;
           
             if(relatedRecordObjectName=='Application__c' && profileId == 'Salesforce Platform'){
                 Application__c appl = [SELECT Account__c, CreatedById FROM Application__c WHERE Id = :tempStr];
				String accountId = appl.Account__c;
				String applUserId = appl.CreatedById;
                
                 Thread__c thread = new Thread__c(
                     id = currentRecord,
                     OwnerId = applUserId,
                     CRM_Account__c=accountId);
                  update thread;
             }
          }
     }
}