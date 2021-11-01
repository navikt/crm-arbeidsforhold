public class AAREG_distributionAccessRequest {
     @future(callout=true)
    public static void generateHeaderToDistribution(String organizationNumber, String referenceType, String jsonS,string referenceId){
       String statusMessage;
       Integer statusCode;
       String descriptionMessage;
       String userName =[SELECT name from User where id =:UserInfo.getUserId()]?.name;
       
        ApiController apiCtrl = new ApiController();
        Map<String, String> params = new Map<String, String>();
        params.put('organisasjonsnummer', organizationNumber);
        apiCtrl.initRequest('AAREG_DIST_TILGANG_API', referenceType,params);
        apiCtrl.addHeader('Content-Type', 'application/json');
        apiCtrl.setSystemContext(); 
        apiCtrl.addServiceAuthHeader('aareg');
        apiCtrl.setBody(jsonS);
        apiCtrl.doCallout();
        
        statusCode = apiCtrl.getResponse().getStatusCode();
        if (statusCode == 200) {
            statusMessage = 'Tilgang oversendt OK';
            if(referenceType =='DEL_AAREG_DIST_TILGANG'){
                descriptionMessage = 'Bruker - '+userName+' har trigget en deaktivering av tilgang';
            }
            if(referenceType =='PUT_AAREG_DIST_TILGANG'){
                descriptionMessage = 'Bruker - '+userName+' har trigget en opprettelse av tilgang';
            }  
        }else{
            statusMessage = 'Tilgang ikke oversendt OK';
            /*LoggerUtility logger = new LoggerUtility();
			logger.Error('Status: ' + apiCtrl.getResponse().getStatus() +'\n' +'Body: ' + apiCtrl.getResponse().getBody(),null,CRM_ApplicationDomain.Domain.AAREG );
			String errorRef = logger.peek().UUID__c;
			logger.publish();
        }*/
        
        Id devRecordTypeId = SObjectType.Task.getRecordTypeInfosByDeveloperName().get('AAREG_Task').getRecordTypeId();
        Task tas = new Task();
        tas.WhatId = referenceId;
        tas.RecordTypeId = devRecordTypeId;
        tas.ActivityDate = System.today();
        tas.Subject = statusMessage;
        tas.Status ='Completed';
        tas.Description =statusMessage;
        tas.Type ='Tilgang';
        tas.Priority = 'Normal';
        insert tas;
    }
    
    public static String generateJson(String accessType){
        JSONGenerator gen = JSON.createGenerator(true);
        // Write data to the JSON string.
                gen.writeStartObject();
                gen.writeStringField('tilgangskode', accessType);      
                gen.writeEndObject();
                // Get the JSON string.
                return gen.getAsString();       
    }

}