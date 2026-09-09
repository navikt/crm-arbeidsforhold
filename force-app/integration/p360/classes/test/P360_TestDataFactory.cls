/**
 * Test-only factory and builders for P360 integration scenarios.
 *
 * @author Not available (new file)
 * @since 2026-09
 * @group P360 Test Utility
 */
@IsTest
public with sharing class P360_TestDataFactory {
    /**
     * Creates a minimum-access user for tests that do not require elevated permissions.
     *
     * @return User Inserted minimum-access test user.
     * @since 2026-09
     */
    public static User createMinimumAccessUser() {
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - Salesforce'
            LIMIT 1
        ];

        User minimumAccessUser = new User(
            FirstName = 'P360',
            LastName = 'Tester',
            Email = 'p360.min.access@example.com',
            Username = 'p360.min.access.' + System.currentTimeMillis() + '@example.com',
            Alias = 'p360min',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Oslo',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id
        );

        insert minimumAccessUser;
        return minimumAccessUser;
    }

    /**
     * Starts building a standard archive request.
     *
     * @return ArchiveRequestBuilder Fluent builder for an archive request.
     * @since 2026-09
     */
    public static ArchiveRequestBuilder archiveRequest() {
        return new ArchiveRequestBuilder();
    }

    /**
     * Starts building a standard successful archive response.
     *
     * @return ArchiveResponseBuilder Fluent builder for an archive response.
     * @since 2026-09
     */
    public static ArchiveResponseBuilder archiveResponse() {
        return new ArchiveResponseBuilder();
    }

    /**
     * Fluent builder for the temporary archive request DTO used by the P360 adapter tests.
     *
     * @since 2026-09
     */
    public class ArchiveRequestBuilder {
        private String correlationId = 'p360-test-correlation';
        private String externalId = 'p360-test-external-id';
        private String title = 'P360 test archive request';

        /**
         * Sets the archive request correlation id.
         *
         * @param value Correlation id used by the request.
         * @return ArchiveRequestBuilder This builder.
         * @since 2026-09
         */
        public ArchiveRequestBuilder withCorrelationId(String value) {
            correlationId = value;
            return this;
        }

        /**
         * Sets the archive request external id.
         *
         * @param value External id used by the request.
         * @return ArchiveRequestBuilder This builder.
         * @since 2026-09
         */
        public ArchiveRequestBuilder withExternalId(String value) {
            externalId = value;
            return this;
        }

        /**
         * Sets the archive request title.
         *
         * @param value Title used by the request.
         * @return ArchiveRequestBuilder This builder.
         * @since 2026-09
         */
        public ArchiveRequestBuilder withTitle(String value) {
            title = value;
            return this;
        }

        /**
         * Builds the archive request DTO.
         *
         * @return P360_ArchiveRequestDto Configured archive request DTO.
         * @since 2026-09
         */
        public P360_ArchiveRequestDto build() {
            P360_ArchiveRequestDto request = new P360_ArchiveRequestDto();
            request.correlationId = correlationId;
            request.externalId = externalId;
            request.title = title;
            return request;
        }
    }

    /**
     * Fluent builder for the temporary archive response DTO used by P360 adapter tests.
     *
     * @since 2026-09
     */
    public class ArchiveResponseBuilder {
        private Boolean success = true;
        private String message = 'P360 test archive response.';
        private String externalCaseId = 'p360-test-case-id';
        private String externalDocumentId = 'p360-test-document-id';

        /**
         * Sets whether the archive operation succeeded.
         *
         * @param value Success value used by the response.
         * @return ArchiveResponseBuilder This builder.
         * @since 2026-09
         */
        public ArchiveResponseBuilder withSuccess(Boolean value) {
            success = value;
            return this;
        }

        /**
         * Sets the archive response message.
         *
         * @param value Message used by the response.
         * @return ArchiveResponseBuilder This builder.
         * @since 2026-09
         */
        public ArchiveResponseBuilder withMessage(String value) {
            message = value;
            return this;
        }

        /**
         * Sets the external case id.
         *
         * @param value External case id used by the response.
         * @return ArchiveResponseBuilder This builder.
         * @since 2026-09
         */
        public ArchiveResponseBuilder withExternalCaseId(String value) {
            externalCaseId = value;
            return this;
        }

        /**
         * Sets the external document id.
         *
         * @param value External document id used by the response.
         * @return ArchiveResponseBuilder This builder.
         * @since 2026-09
         */
        public ArchiveResponseBuilder withExternalDocumentId(String value) {
            externalDocumentId = value;
            return this;
        }

        /**
         * Builds the archive response DTO.
         *
         * @return P360_ArchiveResponseDto Configured archive response DTO.
         * @since 2026-09
         */
        public P360_ArchiveResponseDto build() {
            P360_ArchiveResponseDto response = new P360_ArchiveResponseDto();
            response.success = success;
            response.message = message;
            response.externalCaseId = externalCaseId;
            response.externalDocumentId = externalDocumentId;
            return response;
        }
    }
}
