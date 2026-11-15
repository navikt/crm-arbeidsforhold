'use strict';

const ORG = 'crm-arbeidsforhold';
const SCRATCH_URL = /^https:\/\/[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.scratch\.my\.salesforce\.com$/;

class ScratchTargetError extends Error {}

function verifyScratchTarget(runSf, log) {
    const authorizations = runSf(['org', 'list', 'auth', '--json']);
    if (authorizations.status !== 0 || !Array.isArray(authorizations.result)) {
        throw new ScratchTargetError('STOP: Unable to inspect locally cached Salesforce authorizations.');
    }

    const matches = authorizations.result.filter(
        (org) => typeof org?.alias === 'string' && org.alias.split(',').includes(ORG)
    );
    const org = matches[0];
    if (
        matches.length !== 1 ||
        org.isScratchOrg !== true ||
        org.isDevHub === true ||
        org.isExpired === true ||
        org.error ||
        !SCRATCH_URL.test(org.instanceUrl ?? '') ||
        typeof org.username !== 'string' ||
        !org.username.trim()
    ) {
        throw new ScratchTargetError('STOP: The explicit target is not a locally identified scratch org.');
    }

    const target = org.username;
    const check = runSf([
        'data',
        'query',
        '--target-org',
        target,
        '--query',
        'SELECT IsSandbox FROM Organization',
        '--json'
    ]);
    if (check.status !== 0 || check.result?.records?.[0]?.IsSandbox !== true) {
        throw new ScratchTargetError('STOP: The target org did not confirm IsSandbox=true.');
    }

    log('Target verified: crm-arbeidsforhold, scratch domain and IsSandbox=true.');
    return target;
}

module.exports = { ScratchTargetError, verifyScratchTarget };
