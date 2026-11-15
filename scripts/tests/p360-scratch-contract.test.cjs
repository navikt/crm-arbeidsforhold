const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');

const script = path.resolve(__dirname, '../p360-scratch-contract.sh');

function fixture(t, scratchOrgs) {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'p360-contract-'));
    t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const calls = path.join(directory, 'calls');
    const response = path.join(directory, 'orgs.json');
    fs.writeFileSync(response, JSON.stringify({ result: { scratchOrgs } }));
    fs.writeFileSync(
        path.join(directory, 'sf'),
        '#!/bin/sh\nprintf "%s\\n" "$*" >> "$CAPTURE_TEST_CALLS"\ncat "$CAPTURE_TEST_ORGS"\n',
        { mode: 0o755 }
    );
    return {
        run: (mode) =>
            spawnSync('bash', [script, mode], {
                encoding: 'utf8',
                env: {
                    ...process.env,
                    PATH: `${directory}${path.delimiter}${process.env.PATH}`,
                    CAPTURE_TEST_CALLS: calls,
                    CAPTURE_TEST_ORGS: response
                }
            }),
        calls: () => (fs.existsSync(calls) ? fs.readFileSync(calls, 'utf8').trim().split('\n') : [])
    };
}

for (const [name, scratchOrgs] of [
    ['missing scratch target', []],
    [
        'non-scratch target with the expected alias',
        [{ alias: 'crm-arbeidsforhold', isScratch: false, instanceUrl: 'https://example.invalid' }]
    ],
    [
        'untrusted instance domain despite scratch classification',
        [{ alias: 'crm-arbeidsforhold', isScratch: true, instanceUrl: 'https://example.invalid' }]
    ]
]) {
    for (const mode of ['verify', 'e2e']) {
        test(`${mode} refuses ${name} without querying, deploying or running Apex`, (t) => {
            const f = fixture(t, scratchOrgs);
            const result = f.run(mode);
            assert.equal(result.status, 1, result.stderr);
            assert.match(result.stderr, /STOP: The explicit target is not a locally identified scratch org/);
            assert.deepEqual(f.calls(), ['org list --skip-connection-status --json']);
        });
    }
}

test('rejects unknown actions before accessing Salesforce', (t) => {
    const f = fixture(t, []);
    assert.equal(f.run('unexpected').status, 2);
    assert.deepEqual(f.calls(), []);
});
