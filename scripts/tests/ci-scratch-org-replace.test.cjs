const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const {
    commandRunner,
    replaceScratchOrg,
    setEnvironmentRegistration,
    validationArguments,
    verifyRepositoryOwner
} = require('../ci-scratch-org-replace.cjs');

const registration = {
    authUrl: 'force://secret-auth-url',
    orgId: '00D000000000001AAA',
    expiration: '2030-01-15',
    fingerprint: 'a'.repeat(64)
};

test('reports selected deployment failures without exposing unrelated response fields or credentials', () => {
    const response = JSON.stringify({
        message: 'Deployment failed for test-key',
        unrelated: 'do-not-print',
        result: { details: { componentFailures: [{ problem: 'Example.cls: missing field' }] } }
    });
    assert.throws(
        () =>
            commandRunner(
                process.execPath,
                ['-e', `process.stdout.write(${JSON.stringify(response)}); process.exit(1)`],
                {
                    diagnostics: 'deployment',
                    env: { CRM_PACKAGE_KEY: 'test-key' }
                }
            ),
        (error) => /missing field/.test(error.message) && !/test-key|do-not-print/.test(error.message)
    );
});

function withFakeRegistrationLock(run, state = {}) {
    let counter = 0;
    return (command, args, options) => {
        if (command === 'gh' && args[0] === 'api') {
            const endpoint = args[1];
            if (endpoint.endsWith('/git/ref/heads/main')) return 'a'.repeat(40);
            if (endpoint.endsWith('/git/commits/' + 'a'.repeat(40))) return 'b'.repeat(40);
            if (endpoint.endsWith('/git/commits')) return (++counter).toString(16).padStart(40, '0');
            if (endpoint.endsWith('/git/refs')) {
                if (state.sha) throw new Error('reference already exists');
                state.sha = args.find((argument) => argument.startsWith('sha=')).slice(4);
                return '';
            }
            if (endpoint.endsWith('/git/refs/heads/ci-scratch-org-registration-lock') && args.includes('DELETE')) {
                delete state.sha;
                return '';
            }
            if (endpoint.endsWith('/git/ref/heads/ci-scratch-org-registration-lock')) {
                if (!state.sha) throw new Error('reference missing');
                return state.sha;
            }
        }
        return run(command, args, options);
    };
}

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

test('rejects changes to deploy filters and package-plan helpers before contacting Salesforce', async () => {
    for (const changedPath of ['.forceignore', 'bin/package-dependency-report.js']) {
        const calls = [];
        const run = (command, args) => {
            calls.push({ command, args });
            if (command === 'git' && args[0] === 'remote') return 'https://github.com/navikt/crm-arbeidsforhold.git';
            if (command === 'git' && args[0] === 'fetch') return '';
            if (command === 'git' && args[0] === 'branch') return 'main';
            if (command === 'git' && args[0] === 'rev-parse') return 'same-commit';
            if (command === 'git' && args[0] === 'status') return args.includes(changedPath) ? ` M ${changedPath}` : '';
            if (command === 'sf') throw new Error('Contacted Salesforce despite local changes.');
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
            /local changes/i
        );
        assert.equal(
            calls.some(({ command }) => command === 'sf'),
            false,
            changedPath
        );
    }
});

test('validates repository tests and coverage in a check-only deployment', () => {
    const args = validationArguments('/tmp/force-app', ['ExampleTest', 'AnotherTest'], 'ci-org');
    assert.ok(args.includes('--dry-run'));
    assert.ok(args.includes('--test-level') && args.includes('RunSpecifiedTests'));
    assert.deepEqual(args.filter((argument) => argument === '--tests').length, 2);
    assert.ok(args.includes('--coverage-formatters') && args.includes('json'));
    assert.ok(args.includes('--source-dir') && args.includes('/tmp/force-app'));
    assert.ok(args.includes('--target-org') && args.includes('ci-org'));
    assert.equal(args.includes('apex'), false);
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

test('preserves the new org when GitHub registration reports an ambiguous secret-write failure', async (context) => {
    const repositoryPath = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-scratch-replace-test-'));
    context.after(() => fs.rmSync(repositoryPath, { recursive: true, force: true }));
    fs.mkdirSync(path.join(repositoryPath, 'force-app/main/default/classes'), { recursive: true });
    fs.writeFileSync(
        path.join(repositoryPath, 'force-app/main/default/classes/Example.cls'),
        'public class Example {}'
    );
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

    let registrationError;
    await assert.rejects(
        replaceScratchOrg({
            targetDevHub: 'existing-dev-hub',
            repositoryPath,
            run: withFakeRegistrationLock(run),
            confirm: async () => {},
            environment: { CRM_PACKAGE_KEY: 'test-key' }
        }),
        (error) => {
            registrationError = error;
            return /environment update failed.*org was kept/is.test(error.message);
        }
    );
    const creation = calls.find(({ command, args }) => command === 'sf' && args[1] === 'create');
    assert.ok(registrationError.message.includes(creation.args[creation.args.indexOf('--alias') + 1]));
    const testDiscovery = calls.find(
        ({ command, args }) =>
            command === process.execPath && args[0] === 'scripts/ci-scratch-plan.cjs' && args[1] === 'tests'
    );
    const deploy = calls.find(({ command, args }) => command === 'sf' && args[0] === 'project' && args[1] === 'deploy');
    const coverage = calls.find(
        ({ command, args }) =>
            command === process.execPath && args[0] === 'scripts/ci-scratch-plan.cjs' && args[1] === 'coverage'
    );
    assert.ok(testDiscovery && deploy && coverage);
    assert.ok(deploy.args.includes('--dry-run'));
    const stagedSource = testDiscovery.args[2];
    assert.equal(deploy.args[deploy.args.indexOf('--source-dir') + 1], stagedSource);
    assert.equal(coverage.args[3], stagedSource);
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

    setEnvironmentRegistration(registration, withFakeRegistrationLock(run));

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

    assert.throws(
        () => setEnvironmentRegistration(registration, withFakeRegistrationLock(run)),
        /previous variables were restored/i
    );
    assert.ok(calls.some(({ args }) => args[0] === 'variable' && args.includes('00D000000000002AAA')));
    assert.ok(calls.every(({ args }) => !args.includes(registration.authUrl)));
});

test('restores a variable whose write succeeded remotely but reported a network error', () => {
    const values = {
        CI_SCRATCH_ORG_ID: '00D000000000002AAA',
        CI_SCRATCH_ORG_EXPIRATION: '2030-02-15',
        CI_SCRATCH_ORG_CONFIG_SHA256: 'b'.repeat(64)
    };
    const run = (command, args) => {
        if (args[0] === 'variable' && args[1] === 'list') {
            return JSON.stringify(Object.entries(values).map(([name, value]) => ({ name, value })));
        }
        if (args[0] === 'variable' && args[1] === 'set') {
            const name = args[2];
            const value = args[args.indexOf('--body') + 1];
            values[name] = value;
            if (name === 'CI_SCRATCH_ORG_EXPIRATION' && value === registration.expiration) {
                throw new Error('network timeout');
            }
        }
        return '';
    };

    assert.throws(
        () => setEnvironmentRegistration(registration, withFakeRegistrationLock(run)),
        /previous variables were restored/i
    );
    assert.deepEqual(values, {
        CI_SCRATCH_ORG_ID: '00D000000000002AAA',
        CI_SCRATCH_ORG_EXPIRATION: '2030-02-15',
        CI_SCRATCH_ORG_CONFIG_SHA256: 'b'.repeat(64)
    });
});

test('only one operator can read or write registration until the shared lock is released', () => {
    const state = {};
    const operations = [];
    let secondAttempted = false;
    let secondError;
    const run = withFakeRegistrationLock((command, args) => {
        operations.push(args.slice(0, 3));
        if (args[0] === 'variable' && args[1] === 'list') {
            if (!secondAttempted) {
                secondAttempted = true;
                try {
                    setEnvironmentRegistration(registration, run);
                } catch (error) {
                    secondError = error;
                }
            }
            return '[]';
        }
        return '';
    }, state);

    setEnvironmentRegistration(registration, run);

    assert.match(secondError?.message ?? '', /lock/i);
    assert.equal(operations.filter((args) => args[0] === 'variable' && args[1] === 'list').length, 1);
    assert.equal(operations.filter((args) => args[0] === 'secret' && args[1] === 'set').length, 1);
    assert.equal(state.sha, undefined);
});

test('releases the shared registration lock after a rollback', () => {
    const state = {};
    const run = withFakeRegistrationLock((command, args) => {
        if (args[0] === 'variable' && args[1] === 'list') return '[]';
        if (args[0] === 'secret') throw new Error('network timeout');
        return '';
    }, state);

    assert.throws(() => setEnvironmentRegistration(registration, run), /environment update failed/i);
    assert.equal(state.sha, undefined);
});

test('does not alter registration when lock creation has an ambiguous failure', () => {
    const state = {};
    const calls = [];
    const normal = withFakeRegistrationLock((command, args) => {
        calls.push(args);
        return '';
    }, state);
    const run = (command, args, options) => {
        if (command === 'gh' && args[1]?.endsWith('/git/refs')) {
            normal(command, args, options);
            throw new Error('network timeout');
        }
        return normal(command, args, options);
    };

    assert.throws(() => setEnvironmentRegistration(registration, run), /shared registration lock/i);
    assert.ok(state.sha);
    assert.equal(calls.length, 0);
});

test('never deletes a registration lock that changed ownership', () => {
    const state = {};
    const normal = withFakeRegistrationLock((command, args) => {
        if (args[0] === 'variable' && args[1] === 'list') return '[]';
        if (args[0] === 'secret' && args[1] === 'set') state.sha = 'f'.repeat(40);
        return '';
    }, state);

    assert.throws(() => setEnvironmentRegistration(registration, normal), /could not release.*lock/i);
    assert.equal(state.sha, 'f'.repeat(40));
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
