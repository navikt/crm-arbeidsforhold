/**
 * Checks historical metadata candidates through Tooling and Metadata APIs in the executing Salesforce org.
 *
 * Uses the caller's API-enabled session without elevating permissions. ApexClass lookups use Tooling API REST;
 * other supported metadata types use Metadata API SOAP readMetadata. No metadata or data is modified.
 * Session identifiers, response payloads and exception messages are never logged or returned.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-09
 * @group AAREG Utility
 */
public with sharing class AAREG_MetadataCleanupAudit {
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

        /**
         * Creates a sanitized result for one metadata candidate.
         * @param candidate Component that was checked.
         * @param status FOUND, NOT_FOUND, or UNKNOWN.
         * @param errorCode Sanitized diagnostic code, or null when no error occurred.
         */
        public CheckResult(Candidate candidate, String status, String errorCode) {
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
     * Sends one synchronous read call per candidate. ApexClass uses Tooling API; other types use
     * readMetadata to make absence attribution unambiguous. Missing sessions, unsupported settings,
     * faults and malformed responses remain UNKNOWN. No absence is inferred from a failed request.
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
            } else if (candidate.metadataType == 'ApexClass') {
                results.add(
                    fromLookup(
                        candidate,
                        AAREG_MetadataAuditToolingClient.checkApexClass(candidate.fullName, sessionId)
                    )
                );
            } else {
                results.add(
                    fromLookup(
                        candidate,
                        AAREG_MetadataAuditSoapClient.readComponent(
                            candidate.metadataType,
                            candidate.fullName,
                            sessionId
                        )
                    )
                );
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

    private static CheckResult fromLookup(Candidate candidate, Map<String, String> lookup) {
        return new CheckResult(candidate, lookup.get('status'), lookup.get('errorCode'));
    }
}
