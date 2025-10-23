public class AAREG_distributionAccessRequest {
    @future(callout=true)
    public static void generateHeaderToDistribution(String organizationNumber, String referenceType, String jsonS) {
        Integer statusCode;
        LoggerUtility logger = new LoggerUtility();
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('AAREG_DIST_TILGANG_API', referenceType);
        apiCtrl.addHeader('Content-Type', 'application/json');
        apiCtrl.addHeader('Trace-Id', Request.getCurrent().getRequestId());
        apiCtrl.setSystemContext();
        apiCtrl.addSaasProxyServiceAuthHeader();
        apiCtrl.setBody(jsonS);
        try {
            apiCtrl.doCallout();
            statusCode = apiCtrl.getResponse().getStatusCode();
            if (statusCode != 200) {
                throw new StatusCodeException('Statuscode: ' + statusCode);
            }
        } catch (StatusCodeException e) {
            logger.error(e.getMessage(), null);
            logger.publish();
        } catch (Exception e) {
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
