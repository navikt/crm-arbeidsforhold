public class AAREG_distributionAccessRequest {
    @future(callout=true)
    public static void generateHeaderToDistribution(String organizationNumber, String referenceType, String jsonS) {
        Integer statusCode;
        ApiController apiCtrl = new ApiController();
        //Map<String, String> params = new Map<String, String>();
        //params.put('organisasjonsnummer', organizationNumber);
        apiCtrl.initRequest('AAREG_DIST_TILGANG_API', referenceType); //,params);
        apiCtrl.addHeader('Content-Type', 'application/json');
        apiCtrl.setSystemContext();
        apiCtrl.addServiceAuthHeader('aareg');
        apiCtrl.setBody(jsonS);
        try {
            apiCtrl.doCallout();
            statusCode = apiCtrl.getResponse().getStatusCode();
            if (statusCode != 200) {
                throw new StatusCodeException('Statuscode: ' + statusCode);
            }
        } catch (StatusCodeException e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(e.getMessage(), null);
            logger.publish();
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(e.getMessage(), null);
            logger.publish();
        }
    }

    public static String generateJson(String organizationNumber) {
        JSONGenerator gen = JSON.createGenerator(true);
        // Write data to the JSON string.
        gen.writeStartObject();
        gen.writeStringField('organisasjonsnummer', organizationNumber);
        gen.writeEndObject();
        // Get the JSON string.
        return gen.getAsString();
    }
    public class StatusCodeException extends Exception {
    }
}
