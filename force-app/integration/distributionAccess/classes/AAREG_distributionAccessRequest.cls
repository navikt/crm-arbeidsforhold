/**
 * Request handler for distribution access integration with external APIs.
 * Manages HTTP callouts and error handling for distribution access operations.
 *
 * @author AAREG Team
 * @version 66
 * @group Integration
 */
public class AAREG_distributionAccessRequest {
    /**
     * Asynchronous method to send HTTP request to distribution API.
     * Makes a callout to the external distribution service with the provided JSON payload.
     *
     * @param organizationNumber The organization number for the request
     * @param referenceType The type of operation (PUT_AAREG_DIST_TILGANG or DEL_AAREG_DIST_TILGANG)
     * @param jsonS The JSON payload to send in the request body
     */
    @future(callout=true)
    public static void generateHeaderToDistribution(String organizationNumber, String referenceType, String jsonS) {
        Integer statusCode;
        ApiController apiCtrl = new ApiController();

        try {
            apiCtrl.initRequest('AAREG_DIST_TILGANG_API', referenceType);
            apiCtrl.addHeader('Content-Type', 'application/json');
            apiCtrl.addHeader('Trace-Id', Request.getCurrent().getRequestId());
            apiCtrl.setSystemContext();
            apiCtrl.addSaasProxyServiceAuthHeader();
            apiCtrl.setBody(jsonS);

            apiCtrl.doCallout();
            statusCode = apiCtrl.getResponse().getStatusCode();

            if (statusCode != 200) {
                throw new StatusCodeException('Distribution API returned status code: ' + statusCode);
            }
        } catch (StatusCodeException e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Distribution access request failed: ' + e.getMessage(), null);
            logger.publish();
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Unexpected error in distribution access request: ' + e.getMessage(), null);
            logger.publish();
        }
    }

    /**
     * Generates JSON payload for distribution access request.
     * Creates a JSON object containing the organization number.
     *
     * @param organizationNumber The organization number to include in the JSON
     * @return String containing the formatted JSON payload
     */
    public static String generateJson(String organizationNumber) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('organisasjonsnummer', organizationNumber);
        gen.writeEndObject();
        return gen.getAsString();
    }

    /**
     * Custom exception for HTTP status code errors.
     */
    public class StatusCodeException extends Exception {
    }
}
