/**
 * Test-only HTTP callout mock for the distribution access integration, returning a
 * configurable status code and message with a fixed JSON body.
 *
 * @author Ann Kristin Olsen
 * @since February 2026
 * @group AAREG Distribution Access
 */
@isTest
public class AAREG_DistributionAccessMock implements HttpCalloutMock {
    /** The HTTP status code the mock response should return. */
    private Integer statusCode;
    /** The HTTP status message the mock response should return. */
    private String statusMessage;

    /**
     * Creates a mock that responds with the given status code and message.
     *
     * @param statusCode The HTTP status code to return.
     * @param statusMessage The HTTP status message to return.
     */
    public AAREG_DistributionAccessMock(Integer statusCode, String statusMessage) {
        this.statusCode = statusCode;
        this.statusMessage = statusMessage;
    }

    /**
     * Builds the mock HTTP response with a fixed JSON body.
     *
     * @param req The outgoing request being mocked. Not inspected by this mock.
     * @return An HttpResponse with the configured status code, status message, and
     * a fixed `{"message": "Mock response"}` body.
     */
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setStatus(statusMessage);
        res.setBody('{"message": "Mock response"}');
        return res;
    }
}
