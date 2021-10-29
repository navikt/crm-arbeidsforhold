public class AAREG_distributionAccessRequest {
     @future(callout=true)
    public static void generateHeaderToDistribution(String organizationNumber, String referenceType, String jsonS){
       String statusCodeValue;
       Integer statusCode;
       
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
            statusCodeValue = 'true'; 
        }else{
            statusCodeValue = 'false';
            //Bør det være en logger her?
        }
        //return statusCodeValue;
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