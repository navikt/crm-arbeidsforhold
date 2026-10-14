/**
 * Verifies the read-only metadata audit without contacting an actual metadata endpoint.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-09
 * @group AAREG Utility Tests
 */
@IsTest
private class AAREG_MetadataCleanupAuditTest {
    /**
     * Verifies successful lookup and safe request construction through the public audit boundary.
     * @since 2026-10-09
     */
    @IsTest
    static void shouldReportFoundComponent() {
        System.Test.setMock(
            HttpCalloutMock.class,
            new MetadataMock(200, '<records><fullName>LegacyFlow</fullName></records>')
        );

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('Flow', 'LegacyFlow')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('FOUND', results[0].status);
        System.Assert.areEqual('LegacyFlow', results[0].fullName);
        System.Assert.isNull(results[0].errorCode);
    }

    /**
     * Verifies that an explicit nil record, not merely an empty response, confirms absence.
     * @since 2026-10-09
     */
    @IsTest
    static void shouldReportMissingOnlyForExplicitNilRecord() {
        System.Test.setMock(
            HttpCalloutMock.class,
            new MetadataMock(200, '<records xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="true"/>')
        );

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('Flow', 'LegacyFlow')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('NOT_FOUND', results[0].status);
    }

    /**
     * Verifies that a denied API request remains inconclusive for a minimum-access user.
     * @since 2026-10-09
     */
    @IsTest
    static void shouldKeepDeniedRequestInconclusive() {
        Schema.User minimumAccessUser = createMinimumAccessUser();
        System.Test.setMock(HttpCalloutMock.class, new MetadataMock(403, ''));

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
                new List<AAREG_MetadataCleanupAudit.Candidate>{
                    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'LegacyFlow')
                }
            );
            System.Test.stopTest();

            System.Assert.areEqual('UNKNOWN', results[0].status);
            System.Assert.areEqual('HTTP_403', results[0].errorCode);
        }
    }

    /**
     * Verifies that missing response records cannot falsely confirm component removal.
     * @since 2026-10-09
     */
    @IsTest
    static void shouldKeepEmptyResponseInconclusive() {
        System.Test.setMock(HttpCalloutMock.class, new MetadataMock(200, ''));

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('Flow', 'LegacyFlow')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('UNKNOWN', results[0].status);
        System.Assert.areEqual('UNEXPECTED_RESPONSE', results[0].errorCode);
    }

    /**
     * Verifies that oversized batches are rejected before a callout occurs.
     * @since 2026-10-09
     */
    @IsTest
    static void shouldRejectMoreThanTenCandidates() {
        List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>();
        for (Integer index = 0; index < 11; index++) {
            candidates.add(new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'LegacyClass' + index));
        }

        try {
            AAREG_MetadataCleanupAudit.checkCandidates(candidates);
            System.Assert.fail('An oversized batch must be rejected.');
        } catch (AAREG_MetadataCleanupAudit.AuditInputException expected) {
            System.Assert.areEqual(0, Limits.getCallouts());
        }
    }

    /**
     * Verifies that an Apex class is checked through a same-org Tooling API query.
     * @since 2026-10-12
     */
    @IsTest
    static void shouldFindApexClassThroughToolingApi() {
        System.Test.setMock(
            HttpCalloutMock.class,
            new ToolingApiMock(200, '{"totalSize":1,"done":true,"records":[{"Name":"LegacyClass"}]}')
        );

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'LegacyClass')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('FOUND', results[0].status);
        System.Assert.areEqual('LegacyClass', results[0].fullName);
        System.Assert.isNull(results[0].errorCode);
    }

    /**
     * Verifies that a complete exact-name Tooling query confirms an absent Apex class.
     * @since 2026-10-12
     */
    @IsTest
    static void shouldReportApexClassMissingForCompleteToolingQuery() {
        System.Test.setMock(HttpCalloutMock.class, new ToolingApiMock(200, '{"totalSize":0,"done":true,"records":[]}'));

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'LegacyClass')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('NOT_FOUND', results[0].status);
        System.Assert.isNull(results[0].errorCode);
    }

    /**
     * Verifies that a partial Tooling query cannot confirm an Apex class is absent.
     * @since 2026-10-12
     */
    @IsTest
    static void shouldKeepIncompleteToolingQueryInconclusive() {
        System.Test.setMock(
            HttpCalloutMock.class,
            new ToolingApiMock(200, '{"totalSize":1,"done":false,"records":[]}')
        );

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'LegacyClass')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('UNKNOWN', results[0].status);
        System.Assert.areEqual('INCOMPLETE_QUERY', results[0].errorCode);
    }

    /**
     * Verifies that Tooling API failures expose only the HTTP and Salesforce error codes.
     * @since 2026-10-12
     */
    @IsTest
    static void shouldExposeSanitizedToolingApiErrorCode() {
        System.Test.setMock(
            HttpCalloutMock.class,
            new ToolingApiMock(404, '[{"errorCode":"NOT_FOUND","message":"sensitive detail"}]')
        );

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'LegacyClass')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('UNKNOWN', results[0].status);
        System.Assert.areEqual('HTTP_404_NOT_FOUND', results[0].errorCode);
        System.Assert.isFalse(results[0].errorCode.contains('sensitive detail'));
    }

    /**
     * Verifies that namespaced Apex classes are not guessed from the Tooling API Name field.
     * @since 2026-10-12
     */
    @IsTest
    static void shouldKeepNamespacedApexClassInconclusive() {
        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'example__LegacyClass')
            }
        );
        Integer callouts = Limits.getCallouts();
        System.Test.stopTest();

        System.Assert.areEqual('UNKNOWN', results[0].status);
        System.Assert.areEqual('NAMESPACE_OR_UNSUPPORTED_APEX_CLASS_NAME', results[0].errorCode);
        System.Assert.areEqual(0, callouts);
    }

    /**
     * Verifies that a different returned fullName cannot confirm the requested component.
     * @since 2026-10-09
     */
    @IsTest
    static void shouldKeepMismatchedNameInconclusive() {
        System.Test.setMock(
            HttpCalloutMock.class,
            new MetadataMock(200, '<records><fullName>DifferentClass</fullName></records>')
        );

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('Flow', 'LegacyFlow')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('UNKNOWN', results[0].status);
        System.Assert.areEqual('NAME_MISMATCH_OR_MISSING', results[0].errorCode);
    }

    /**
     * Verifies that multiple records cannot associate a nil response with the wrong component.
     * @since 2026-10-09
     */
    @IsTest
    static void shouldKeepMultipleRecordsInconclusive() {
        System.Test.setMock(
            HttpCalloutMock.class,
            new MetadataMock(
                200,
                '<records><fullName>LegacyFlow</fullName></records>' +
                '<records xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="true"/>'
            )
        );

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('Flow', 'LegacyFlow')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('UNKNOWN', results[0].status);
        System.Assert.areEqual('UNEXPECTED_RESPONSE', results[0].errorCode);
    }

    /**
     * Verifies that settings are marked for manual review without a callout.
     * @since 2026-10-09
     */
    @IsTest
    static void shouldSkipSettingsWithoutCallout() {
        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('SecuritySettings', 'Security')
            }
        );
        Integer callouts = Limits.getCallouts();
        System.Test.stopTest();

        System.Assert.areEqual('UNKNOWN', results[0].status);
        System.Assert.areEqual('SETTINGS_REQUIRE_MANUAL_REVIEW', results[0].errorCode);
        System.Assert.areEqual(0, callouts);
    }

    /**
     * Verifies that malformed XML does not expose response content or confirm absence.
     * @since 2026-10-09
     */
    @IsTest
    static void shouldKeepMalformedResponseInconclusive() {
        System.Test.setMock(HttpCalloutMock.class, new MetadataMock(200, '<records>'));

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('Flow', 'LegacyFlow')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('UNKNOWN', results[0].status);
        System.Assert.areEqual('REQUEST_OR_RESPONSE_FAILED', results[0].errorCode);
    }

    /**
     * Verifies that SOAP fault codes are exposed without returning the fault message.
     * @since 2026-10-12
     */
    @IsTest
    static void shouldReturnSanitizedSoapFaultCode() {
        System.Test.setMock(HttpCalloutMock.class, new SoapFaultMock());

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('Flow', 'LegacyFlow')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('UNKNOWN', results[0].status);
        System.Assert.areEqual('SOAP_INVALID_TYPE', results[0].errorCode);
        System.Assert.isFalse(JSON.serialize(results).contains('synthetic fault detail'));
    }

    private static Schema.User createMinimumAccessUser() {
        Schema.Profile minimumAccessProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - Salesforce'
            LIMIT 1
        ];
        Schema.User minimumAccessUser = new Schema.User(
            LastName = 'Metadata Audit Tester',
            Email = 'metadata.audit@example.com',
            Username = 'metadata.audit.' + Crypto.getRandomInteger() + '@example.com',
            Alias = 'mdaudit',
            ProfileId = minimumAccessProfile.Id,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Oslo',
            EmailEncodingKey = 'UTF-8'
        );
        insert minimumAccessUser;
        return minimumAccessUser;
    }

    private class MetadataMock implements HttpCalloutMock {
        private Integer statusCode;
        private String records;

        private MetadataMock(Integer statusCode, String records) {
            this.statusCode = statusCode;
            this.records = records;
        }

        /**
         * Asserts the read-only request contract and returns synthetic metadata.
         * @param request Request intercepted by the Salesforce test framework.
         * @return Synthetic response containing no real org metadata.
         */
        public HttpResponse respond(HttpRequest request) {
            System.Assert.areEqual('POST', request.getMethod());
            System.Assert.areEqual(
                URL.getOrgDomainUrl().toExternalForm() + '/services/Soap/m/67.0',
                request.getEndpoint()
            );
            Dom.Document document = new Dom.Document();
            document.load(request.getBody());
            Dom.XmlNode body = document.getRootElement()
                .getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');
            Dom.XmlNode operation = body.getChildElement('readMetadata', 'http://soap.sforce.com/2006/04/metadata');
            System.Assert.isNotNull(operation, 'Only the readMetadata operation may be sent.');
            System.Assert.areEqual(
                'Flow',
                operation.getChildElement('type', 'http://soap.sforce.com/2006/04/metadata').getText()
            );
            System.Assert.areEqual(
                'LegacyFlow',
                operation.getChildElement('fullNames', 'http://soap.sforce.com/2006/04/metadata').getText()
            );

            HttpResponse response = new HttpResponse();
            response.setStatusCode(this.statusCode);
            response.setBody(
                '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<Body><readMetadataResponse xmlns="http://soap.sforce.com/2006/04/metadata"><result>' +
                    this.records +
                    '</result></readMetadataResponse></Body></Envelope>'
            );
            return response;
        }
    }

    private class ToolingApiMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        private ToolingApiMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        /**
         * Verifies the Tooling API query request and returns a synthetic query result.
         * @param request Request intercepted by the Salesforce test framework.
         * @return Synthetic Tooling API response.
         */
        public HttpResponse respond(HttpRequest request) {
            System.Assert.areEqual('GET', request.getMethod());
            System.Assert.isTrue(
                request.getEndpoint()
                    .startsWith(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v67.0/tooling/query/?q='),
                'ApexClass checks must use the same-org Tooling REST endpoint.'
            );
            String query = EncodingUtil.urlDecode(request.getEndpoint().substringAfter('?q='), 'UTF-8');
            System.Assert.isTrue(query.contains('SELECT Name FROM ApexClass'));
            System.Assert.isFalse(query.contains('NamespacePrefix'));
            System.Assert.isTrue(query.contains('FROM ApexClass'));
            System.Assert.isTrue(query.contains('Name = \'LegacyClass\''));
            System.Assert.isTrue(request.getHeader('Authorization').startsWith('Bearer '));

            HttpResponse response = new HttpResponse();
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody(this.responseBody);
            return response;
        }
    }

    private class SoapFaultMock implements HttpCalloutMock {
        /**
         * Returns a synthetic SOAP fault without any session or org-specific values.
         * @param request Request intercepted by the Salesforce test framework.
         * @return Synthetic HTTP 500 SOAP fault response.
         */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(500);
            response.setBody(
                '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<Body><Fault><faultcode>sf:INVALID_TYPE</faultcode>' +
                    '<faultstring>synthetic fault detail</faultstring></Fault></Body></Envelope>'
            );
            return response;
        }
    }
}
