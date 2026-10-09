/**
 * Checks historical metadata candidates through readMetadata in the executing Salesforce org.
 *
 * Uses the caller's API-enabled session without elevating permissions. Requires an approved
 * same-org callout configuration and Metadata API access. No metadata or data is modified.
 * Session identifiers, response payloads and exception messages are never logged or returned.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-09
 * @group AAREG Utility
 */
public with sharing class AAREG_MetadataCleanupAudit {
    private static final String SOAP_NAMESPACE = 'http://schemas.xmlsoap.org/soap/envelope/';
    private static final String METADATA_NAMESPACE = 'http://soap.sforce.com/2006/04/metadata';
    private static final String INSTANCE_NAMESPACE = 'http://www.w3.org/2001/XMLSchema-instance';
    private static final Integer MAX_CANDIDATES = 10;

    /** Identifies one historical component using its Metadata API type and fullName. */
    public class Candidate {
        /** Metadata API type, such as ApexClass or CustomField. */
        public String metadataType { get; private set; }
        /** API fullName, including object or folder qualification where applicable. */
        public String fullName { get; private set; }

        /**
         * Creates a component reference without fetching or modifying metadata.
         * @param metadataType Metadata API type.
         * @param fullName Exact API fullName, not a display label or repository path.
         */
        public Candidate(String metadataType, String fullName) {
            this.metadataType = metadataType;
            this.fullName = fullName;
        }
    }

    /** Holds an existence result without exposing response content or authentication data. */
    public class CheckResult {
        /** Metadata API type requested by the caller. */
        public String metadataType { get; private set; }
        /** Historical fullName requested by the caller. */
        public String fullName { get; private set; }
        /** FOUND, NOT_FOUND, or UNKNOWN; UNKNOWN never authorizes a deletion. */
        public String status { get; private set; }
        /** Sanitized diagnostic code for UNKNOWN, otherwise null. */
        public String errorCode { get; private set; }

        private CheckResult(Candidate candidate, String status, String errorCode) {
            this.metadataType = candidate.metadataType;
            this.fullName = candidate.fullName;
            this.status = status;
            this.errorCode = errorCode;
        }
    }

    /** Signals invalid input or insufficient callout budget before any request is sent. */
    public class AuditInputException extends System.Exception {
    }

    /**
     * Checks at most ten candidates against the org in which this method executes.
     *
     * Sends one synchronous readMetadata call per candidate to make nil-record attribution
     * unambiguous. Missing sessions, unsupported settings, faults and malformed responses
     * remain UNKNOWN. No absence is inferred from a failed request or an empty response.
     * Run only in an explicitly approved org using an authorized API-enabled session.
     *
     * @param candidates Non-null list of up to ten valid type/fullName references.
     * @return Results in input order; NOT_FOUND requires an explicit nil record.
     * @throws AuditInputException Invalid input or insufficient remaining callout budget.
     */
    public static List<CheckResult> checkCandidates(List<Candidate> candidates) {
        validateCandidates(candidates);
        String sessionId = UserInfo.getSessionId();
        List<CheckResult> results = new List<CheckResult>();

        for (Candidate candidate : candidates) {
            if (candidate.metadataType.endsWith('Settings')) {
                results.add(new CheckResult(candidate, 'UNKNOWN', 'SETTINGS_REQUIRE_MANUAL_REVIEW'));
            } else if (String.isBlank(sessionId) && !System.Test.isRunningTest()) {
                results.add(new CheckResult(candidate, 'UNKNOWN', 'NO_API_SESSION'));
            } else {
                results.add(checkCandidate(candidate, sessionId));
            }
        }
        return results;
    }

    private static void validateCandidates(List<Candidate> candidates) {
        if (candidates == null || candidates.size() > MAX_CANDIDATES) {
            throw new AuditInputException('Supply a non-null list of at most ten candidates.');
        }
        if (candidates.size() > Limits.getLimitCallouts() - Limits.getCallouts()) {
            throw new AuditInputException('Insufficient remaining callout budget for this batch.');
        }
        for (Candidate candidate : candidates) {
            validateCandidate(candidate);
        }
    }

    private static void validateCandidate(Candidate candidate) {
        if (candidate == null) {
            throw new AuditInputException('Candidates cannot contain null entries.');
        }
        if (
            String.isBlank(candidate.metadataType) ||
            !Pattern.compile('^[A-Za-z][A-Za-z0-9]*$').matcher(candidate.metadataType).matches()
        ) {
            throw new AuditInputException('Each candidate requires a valid metadata type.');
        }
        if (String.isBlank(candidate.fullName) || candidate.fullName.length() > 255) {
            throw new AuditInputException('Each candidate requires a fullName of at most 255 characters.');
        }
    }

    private static CheckResult checkCandidate(Candidate candidate, String sessionId) {
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/Soap/m/67.0');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', '""');
            request.setTimeout(10000);
            request.setBody(createRequestBody(candidate, sessionId));
            HttpResponse response = new Http().send(request);
            if (response.getStatusCode() != 200) {
                return new CheckResult(candidate, 'UNKNOWN', 'HTTP_' + response.getStatusCode());
            }
            if (response.getBody().length() > 1000000) {
                return new CheckResult(candidate, 'UNKNOWN', 'RESPONSE_TOO_LARGE');
            }
            return parseResponse(candidate, response.getBody());
        } catch (System.Exception error) {
            return new CheckResult(candidate, 'UNKNOWN', 'REQUEST_OR_RESPONSE_FAILED');
        }
    }

    private static String createRequestBody(Candidate candidate, String sessionId) {
        Dom.Document document = new Dom.Document();
        Dom.XmlNode envelope = document.createRootElement('Envelope', SOAP_NAMESPACE, 'soapenv');
        Dom.XmlNode header = envelope.addChildElement('Header', SOAP_NAMESPACE, 'soapenv');
        Dom.XmlNode session = header.addChildElement('SessionHeader', METADATA_NAMESPACE, 'met');
        session.addChildElement('sessionId', METADATA_NAMESPACE, 'met').addTextNode(sessionId == null ? '' : sessionId);
        Dom.XmlNode body = envelope.addChildElement('Body', SOAP_NAMESPACE, 'soapenv');
        Dom.XmlNode operation = body.addChildElement('readMetadata', METADATA_NAMESPACE, 'met');
        operation.addChildElement('type', METADATA_NAMESPACE, 'met').addTextNode(candidate.metadataType);
        operation.addChildElement('fullNames', METADATA_NAMESPACE, 'met').addTextNode(candidate.fullName);
        return document.toXmlString();
    }

    private static CheckResult parseResponse(Candidate candidate, String responseBody) {
        Dom.Document document = new Dom.Document();
        document.load(responseBody);
        Dom.XmlNode body = document.getRootElement().getChildElement('Body', SOAP_NAMESPACE);
        if (body == null) {
            return new CheckResult(candidate, 'UNKNOWN', 'UNEXPECTED_RESPONSE');
        }
        if (body.getChildElement('Fault', SOAP_NAMESPACE) != null) {
            return new CheckResult(candidate, 'UNKNOWN', 'SOAP_FAULT');
        }
        Dom.XmlNode response = body.getChildElement('readMetadataResponse', METADATA_NAMESPACE);
        Dom.XmlNode result = response == null ? null : response.getChildElement('result', METADATA_NAMESPACE);
        return parseRecord(candidate, result);
    }

    private static CheckResult parseRecord(Candidate candidate, Dom.XmlNode result) {
        if (result == null || result.getChildElements().size() != 1) {
            return new CheckResult(candidate, 'UNKNOWN', 'UNEXPECTED_RESPONSE');
        }
        Dom.XmlNode record = result.getChildElements()[0];
        if (record.getName() != 'records' || record.getNamespace() != METADATA_NAMESPACE) {
            return new CheckResult(candidate, 'UNKNOWN', 'UNEXPECTED_RESPONSE');
        }
        String nilValue = record.getAttribute('nil', INSTANCE_NAMESPACE);
        if (new Set<String>{ 'true', '1' }.contains(nilValue)) {
            return new CheckResult(candidate, 'NOT_FOUND', null);
        }
        Dom.XmlNode fullName = record.getChildElement('fullName', METADATA_NAMESPACE);
        if (fullName == null || !candidate.fullName.equals(fullName.getText())) {
            return new CheckResult(candidate, 'UNKNOWN', 'NAME_MISMATCH_OR_MISSING');
        }
        return new CheckResult(candidate, 'FOUND', null);
    }
}
