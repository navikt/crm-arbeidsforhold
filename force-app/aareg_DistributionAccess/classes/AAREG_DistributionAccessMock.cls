@isTest
public class AAREG_DistributionAccessMock implements HttpCalloutMock {
    private Integer statusCode;
    private String statusMessage;

    public AAREG_DistributionAccessMock(Integer statusCode, String statusMessage) {
        this.statusCode = statusCode;
        this.statusMessage = statusMessage;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setStatus(statusMessage);
        res.setBody('{"message": "Mock response"}');
        return res;
    }
}