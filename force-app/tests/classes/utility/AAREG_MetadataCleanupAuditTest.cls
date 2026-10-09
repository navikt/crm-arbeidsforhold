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
            new MetadataMock(200, '<records><fullName>LegacyClass</fullName></records>')
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
                new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'LegacyClass')
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
                    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'LegacyClass')
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
                new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'LegacyClass')
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
                new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'LegacyClass')
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
                '<records><fullName>LegacyClass</fullName></records>' +
                '<records xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="true"/>'
            )
        );

        System.Test.startTest();
        List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(
            new List<AAREG_MetadataCleanupAudit.Candidate>{
                new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'LegacyClass')
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
                new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'LegacyClass')
            }
        );
        System.Test.stopTest();

        System.Assert.areEqual('UNKNOWN', results[0].status);
        System.Assert.areEqual('REQUEST_OR_RESPONSE_FAILED', results[0].errorCode);
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
                'ApexClass',
                operation.getChildElement('type', 'http://soap.sforce.com/2006/04/metadata').getText()
            );
            System.Assert.areEqual(
                'LegacyClass',
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
}
