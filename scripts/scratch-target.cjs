'use strict';

const ORG = 'crm-arbeidsforhold';
const SCRATCH_URL = /^https:\/\/[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.scratch\.my\.salesforce\.com$/;
const SAFE_USERNAME = /^[a-zA-Z0-9._+@-]+$/;

class ScratchTargetError extends Error {}

function localScratchTarget(runSf, expectedOrgId) {
    const aliases = runSf(['alias', 'list', '--json']);
    if (aliases.status !== 0 || !Array.isArray(aliases.result)) {
        throw new ScratchTargetError('STOP: Unable to inspect locally cached Salesforce aliases.');
    }

    const matches = aliases.result.filter((entry) => entry?.alias === ORG);
    const username = matches[0]?.value;
    if (
        matches.length !== 1 ||
        typeof username !== 'string' ||
        !SAFE_USERNAME.test(username) ||
        aliases.result.some((entry) => entry?.alias === username)
    ) {
        throw new ScratchTargetError('STOP: The explicit target is not a locally identified scratch org.');
    }

    const authorizations = runSf(['org', 'list', 'auth', '--json']);
    if (authorizations.status !== 0 || !Array.isArray(authorizations.result)) {
        throw new ScratchTargetError('STOP: Unable to inspect locally cached Salesforce authorizations.');
    }

    const orgs = authorizations.result.filter((org) => org?.username === username);
    const org = orgs[0];
    if (
        orgs.length !== 1 ||
        org.orgId !== expectedOrgId ||
        org.isScratchOrg !== true ||
        org.isDevHub !== false ||
        org.isExpired !== false ||
        org.error ||
        !SCRATCH_URL.test(org.instanceUrl ?? '')
    ) {
        throw new ScratchTargetError('STOP: The explicit target is not a locally identified scratch org.');
    }

    return username;
}

function verifyScratchTarget(runSf, log, expectedOrgId = process.env.AAREG_SCRATCH_ORG_ID) {
    if (typeof expectedOrgId !== 'string' || !expectedOrgId || expectedOrgId !== expectedOrgId.trim()) {
        throw new ScratchTargetError('STOP: Set AAREG_SCRATCH_ORG_ID to the independently verified scratch org ID.');
    }

    const target = localScratchTarget(runSf, expectedOrgId);
    function runOnTarget(args) {
        const targetFlags = args.reduce((positions, value, index) => {
            if (value === '--target-org') positions.push(index);
            return positions;
        }, []);
        if (targetFlags.length !== 1 || args[targetFlags[0] + 1] !== target) {
            throw new ScratchTargetError('STOP: A Salesforce command does not explicitly target the verified user.');
        }
        if (localScratchTarget(runSf, expectedOrgId) !== target) {
            throw new ScratchTargetError('STOP: The scratch target changed during execution.');
        }
        return runSf(args, { target });
    }

    const check = runOnTarget([
        'data',
        'query',
        '--target-org',
        target,
        '--query',
        'SELECT Id, IsSandbox FROM Organization',
        '--json'
    ]);
    const records = check.result?.records;
    if (check.status !== 0 || !Array.isArray(records) || records.length !== 1 || records[0]?.IsSandbox !== true) {
        throw new ScratchTargetError('STOP: The target org did not confirm IsSandbox=true.');
    }
    if (records[0].Id !== expectedOrgId) {
        throw new ScratchTargetError('STOP: The target org did not confirm the expected scratch identity.');
    }

    log('Target verified: crm-arbeidsforhold, scratch domain and IsSandbox=true.');
    return { target, runSf: runOnTarget };
}

module.exports = { ScratchTargetError, verifyScratchTarget };
