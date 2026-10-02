import { describe, expect, it } from 'vitest';
import { classifySalesforceFailure } from '../../src/infrastructure/salesforce-errors.js';
import { EXIT_CODES } from '../../src/domain/events.js';

describe('Salesforce failure classification', () => {
    it.each([
        'No authorization information found for target org',
        'Authentication failed: expired access token',
        'INVALID_SESSION_ID: Session expired or invalid',
        'INSUFFICIENT_ACCESS: user is not authorized'
    ])('maps a clear auth or authorization failure to exit 4: %s', (message) => {
        expect(classifySalesforceFailure({ stderr: message }, EXIT_CODES.OPERATION_FAILURE)).toBe(
            EXIT_CODES.AUTH_OR_AUTHORIZATION_FAILURE
        );
    });

    it('retains the caller fallback for unrelated failures', () => {
        expect(classifySalesforceFailure({ stderr: 'network timeout' }, EXIT_CODES.PARTIAL_COMPLETION)).toBe(
            EXIT_CODES.PARTIAL_COMPLETION
        );
    });
});
