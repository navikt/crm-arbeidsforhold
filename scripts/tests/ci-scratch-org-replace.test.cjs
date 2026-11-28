const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
    replaceScratchOrg,
    setEnvironmentRegistration,
    verifyRepositoryOwner
} = require('../ci-scratch-org-replace.cjs');

const registration = {
    authUrl: 'force://secret-auth-url',
    orgId: '00D000000000001AAA',
    expiration: '2030-01-15',
    fingerprint: 'a'.repeat(64)
};

function ownerRunner({ permission = 'admin', membership = 'active' } = {}) {
    const calls = [];
    const run = (command, args, options = {}) => {
        calls.push({ command, args, options });
        if (command === 'gh' && args[0] === 'api' && args[1] === 'user') return 'repo-owner';
        if (command === 'gh' && args[0] === 'api' && args[1].startsWith('orgs/navikt/teams/')) return membership;
        if (command === 'gh' && args[0] === 'api' && args[1].includes('/collaborators/')) return permission;
        return '';
    };
    return { calls, run };
}

test('requires active membership in the repository owner team and admin repository permission', () => {
    const accepted = ownerRunner();
    assert.equal(verifyRepositoryOwner(accepted.run), 'repo-owner');
    assert.ok(accepted.calls.some(({ args }) => args[1].includes('teams/crm-arbeidsforhold-admin/memberships/')));
    assert.ok(accepted.calls.some(({ args }) => args[1].includes('/collaborators/repo-owner/permission')));

    assert.throws(() => verifyRepositoryOwner(ownerRunner({ membership: 'pending' }).run), /active members/i);
    assert.throws(() => verifyRepositoryOwner(ownerRunner({ permission: 'write' }).run), /admin permission/i);
});

test('does not contact Salesforce when the caller is not an active repository owner', async () => {
    const calls = [];
    const run = (command, args) => {
        calls.push({ command, args });
        if (command === 'git' && args[0] === 'remote') return 'https://github.com/navikt/crm-arbeidsforhold.git';
        if (command === 'git' && args[0] === 'fetch') return '';
        if (command === 'git' && args[0] === 'branch') return 'main';
        if (command === 'git' && args[0] === 'rev-parse') return 'main-commit';
        if (command === 'git' && args[0] === 'status') return '';
        if (command === 'gh' && args[0] === 'api' && args[1] === 'user') return 'contributor';
        if (command === 'gh' && args[0] === 'api' && args[1].startsWith('orgs/navikt/teams/')) return 'pending';
        throw new Error('Unexpected command.');
    };

    await assert.rejects(
        replaceScratchOrg({
            targetDevHub: 'existing-dev-hub',
            repositoryPath: '/repo',
            run,
            confirm: async () => {},
            environment: { CRM_PACKAGE_KEY: 'test-key' }
        }),
        /active members/i
    );
    assert.equal(
        calls.some(({ command }) => command === 'sf'),
        false
    );
});

test('rejects local changes to the replacement command before contacting Salesforce', async () => {
    const calls = [];
    const run = (command, args) => {
        calls.push({ command, args });
        if (command === 'git' && args[0] === 'remote') return 'https://github.com/navikt/crm-arbeidsforhold.git';
        if (command === 'git' && args[0] === 'fetch') return '';
        if (command === 'git' && args[0] === 'branch') return 'main';
        if (command === 'git' && args[0] === 'rev-parse') return 'same-commit';
        if (command === 'git' && args[0] === 'status') {
            return args.includes('scripts/ci-scratch-org-replace.cjs') ? ' M scripts/ci-scratch-org-replace.cjs' : '';
        }
        if (command === 'gh' && args[0] === 'api' && args[1] === 'user') return 'repo-owner';
        if (command === 'gh' && args[0] === 'api' && args[1].startsWith('orgs/navikt/teams/')) return 'active';
        if (command === 'gh' && args[0] === 'api' && args[1].includes('/collaborators/')) return 'admin';
        if (command === process.execPath && args[0] === 'bin/package-dependencies.js') return '';
        if (command === process.execPath && args[0] === 'scripts/ci-scratch-plan.cjs') return 'a'.repeat(64);
        if (command === 'sf') throw new Error('Contacted Salesforce despite local changes.');
        throw new Error('Unexpected command.');
    };

    await assert.rejects(
        replaceScratchOrg({
            targetDevHub: 'existing-dev-hub',
            repositoryPath: '/repo',
            run,
            confirm: async () => {},
            environment: { CRM_PACKAGE_KEY: 'test-key' }
        }),
        /local changes/i
    );
    assert.deepEqual(calls[1], { command: 'git', args: ['fetch', 'origin', 'main'] });
    assert.equal(
        calls.some(({ command }) => command === 'sf'),
        false
    );
});

test('deletes a newly created org when its creation response cannot be parsed', async () => {
    const calls = [];
    const run = (command, args) => {
        calls.push({ command, args });
        if (command === 'git' && args[0] === 'remote') return 'https://github.com/navikt/crm-arbeidsforhold.git';
        if (command === 'git' && args[0] === 'fetch') return '';
        if (command === 'git' && args[0] === 'branch') return 'main';
        if (command === 'git' && args[0] === 'rev-parse') return 'same-commit';
        if (command === 'git' && args[0] === 'status') return '';
        if (command === 'gh' && args[0] === 'api' && args[1] === 'user') return 'repo-owner';
        if (command === 'gh' && args[0] === 'api' && args[1].startsWith('orgs/navikt/teams/')) return 'active';
        if (command === 'gh' && args[0] === 'api' && args[1].includes('/collaborators/')) return 'admin';
        if (command === process.execPath && args[0] === 'bin/package-dependencies.js') return '';
        if (command === process.execPath && args[0] === 'scripts/ci-scratch-plan.cjs') return 'a'.repeat(64);
        if (command === 'sf' && args[0] === 'org' && args[1] === 'create') return '{invalid json';
        if (command === 'sf' && args[0] === 'org' && args[1] === 'delete') return '';
        throw new Error(`Unexpected command: ${command} ${args.join(' ')}`);
    };

    await assert.rejects(
        replaceScratchOrg({
            targetDevHub: 'existing-dev-hub',
            repositoryPath: '/repo',
            run,
            confirm: async () => {},
            environment: { CRM_PACKAGE_KEY: 'test-key' }
        }),
        /could not parse scratch-org creation/i
    );
    assert.ok(calls.some(({ command, args }) => command === 'sf' && args[1] === 'delete'));
});

test('preserves the new org when GitHub registration reports an ambiguous secret-write failure', async () => {
    const calls = [];
    const orgId = '00D000000000003AAA';
    const run = (command, args) => {
        calls.push({ command, args });
        if (command === 'git' && args[0] === 'remote') return 'https://github.com/navikt/crm-arbeidsforhold.git';
        if (command === 'git' && args[0] === 'fetch') return '';
        if (command === 'git' && args[0] === 'branch') return 'main';
        if (command === 'git' && args[0] === 'rev-parse') return 'same-commit';
        if (command === 'git' && args[0] === 'status') return '';
        if (command === 'gh' && args[0] === 'api' && args[1] === 'user') return 'repo-owner';
        if (command === 'gh' && args[0] === 'api' && args[1].startsWith('orgs/navikt/teams/')) return 'active';
        if (command === 'gh' && args[0] === 'api' && args[1].includes('/collaborators/')) return 'admin';
        if (command === 'gh' && args[0] === 'variable' && args[1] === 'list') return '[]';
        if (command === 'gh' && args[0] === 'secret' && args[1] === 'set') throw new Error('network timeout');
        if (command === process.execPath && args[0] === 'bin/package-dependencies.js') return '';
        if (command === process.execPath && args[0] === 'scripts/ci-scratch-plan.cjs') {
            if (args[1] === 'fingerprint') return 'a'.repeat(64);
            if (args[1] === 'tests') return '["ExampleTest"]';
            return '';
        }
        if (command === 'sf' && args[0] === 'org' && args[1] === 'create') {
            return JSON.stringify({ result: { orgId } });
        }
        if (command === 'sf' && args[0] === 'org' && args[1] === 'display') {
            return JSON.stringify({ result: { id: orgId, expirationDate: '2026-12-28T00:00:00Z' } });
        }
        if (command === 'sf' && args[0] === 'org' && args[1] === 'auth') {
            return JSON.stringify({ result: { sfdxAuthUrl: registration.authUrl } });
        }
        if (command === 'sf' && args[0] === 'org' && args[1] === 'delete') return '';
        return '';
    };

    await assert.rejects(
        replaceScratchOrg({
            targetDevHub: 'existing-dev-hub',
            repositoryPath: '/repo',
            run,
            confirm: async () => {},
            environment: { CRM_PACKAGE_KEY: 'test-key' }
        }),
        /environment update failed.*org was kept/is
    );
    assert.equal(
        calls.some(({ command, args }) => command === 'sf' && args[1] === 'delete'),
        false
    );
});

test('sets environment variables before sending the auth URL through gh stdin', () => {
    const calls = [];
    const run = (command, args, options = {}) => {
        calls.push({ command, args, options });
        if (args[0] === 'variable' && args[1] === 'list') return '[]';
        return '';
    };

    setEnvironmentRegistration(registration, run);

    const secretIndex = calls.findIndex(({ args }) => args[0] === 'secret' && args[1] === 'set');
    const variableIndices = calls
        .map(({ args }, index) => (args[0] === 'variable' && args[1] === 'set' ? index : -1))
        .filter((index) => index >= 0);
    assert.equal(variableIndices.length, 3);
    assert.ok(variableIndices.every((index) => index < secretIndex));
    const secret = calls[secretIndex];
    assert.equal(secret.options.input, registration.authUrl);
    assert.ok(calls.every(({ args }) => !args.includes(registration.authUrl)));
});

test('restores previous variables when the auth URL secret update fails', () => {
    const calls = [];
    const run = (command, args) => {
        calls.push({ command, args });
        if (args[0] === 'variable' && args[1] === 'list') {
            return JSON.stringify([
                { name: 'CI_SCRATCH_ORG_ID', value: '00D000000000002AAA' },
                { name: 'CI_SCRATCH_ORG_EXPIRATION', value: '2030-02-15' },
                { name: 'CI_SCRATCH_ORG_CONFIG_SHA256', value: 'b'.repeat(64) }
            ]);
        }
        if (args[0] === 'secret') throw new Error('permission denied');
        return '';
    };

    assert.throws(() => setEnvironmentRegistration(registration, run), /previous variables were restored/i);
    assert.ok(calls.some(({ args }) => args[0] === 'variable' && args.includes('00D000000000002AAA')));
    assert.ok(calls.every(({ args }) => !args.includes(registration.authUrl)));
});

test('rejects malformed registration before calling GitHub', () => {
    const calls = [];
    const run = (...args) => calls.push(args);
    assert.throws(
        () => setEnvironmentRegistration({ ...registration, orgId: 'wrong' }, run),
        /invalid CI scratch org registration/i
    );
    assert.equal(calls.length, 0);
});
