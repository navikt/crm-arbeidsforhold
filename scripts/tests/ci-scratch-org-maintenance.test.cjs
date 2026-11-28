const assert = require('node:assert/strict');
const { test } = require('node:test');
const { createIssueBody, syncMaintenanceIssue } = require('../ci-scratch-org-maintenance.cjs');

const title = '[CI] Reusable scratch org needs attention';

test('creates one owner-directed issue when the registered org needs replacement', () => {
    const calls = [];
    const run = (args) => {
        calls.push(args);
        return args[0] === 'issue' && args[1] === 'list' ? '[]' : '';
    };

    assert.deepEqual(
        syncMaintenanceIssue(
            'ensure',
            'The org expires within seven days.',
            run,
            'https://github.com/navikt/crm-arbeidsforhold/actions/runs/123'
        ),
        { action: 'created' }
    );
    const create = calls.find((args) => args[1] === 'create');
    assert.equal(create[create.indexOf('--title') + 1], title);
    assert.match(create[create.indexOf('--body') + 1], /@navikt\/crm-arbeidsforhold-admin/);
    assert.match(create[create.indexOf('--body') + 1], /reusable-scratch-org-validation\.md/);
    assert.match(create[create.indexOf('--body') + 1], /fresh-org fallback/);
    assert.match(create[create.indexOf('--body') + 1], /actions\/runs\/123/);
});

test('updates the existing notice instead of creating duplicates and closes it after recovery', () => {
    const calls = [];
    const run = (args) => {
        calls.push(args);
        if (args[0] === 'issue' && args[1] === 'list') return JSON.stringify([{ number: 42, title }]);
        return '';
    };

    assert.deepEqual(syncMaintenanceIssue('ensure', 'Package reconciliation failed.', run), {
        action: 'updated',
        number: 42
    });
    assert.deepEqual(syncMaintenanceIssue('resolve', undefined, run), { action: 'closed', number: 42 });
    assert.equal(calls.filter((args) => args[1] === 'create').length, 0);
    assert.ok(calls.some((args) => args[1] === 'edit' && args[2] === '42'));
    assert.ok(calls.some((args) => args[1] === 'close' && args[2] === '42'));
});

test('fails explicitly when issue discovery is ambiguous or replacement reason is invalid', () => {
    const duplicateRun = () =>
        JSON.stringify([
            { number: 1, title },
            { number: 2, title }
        ]);
    assert.throws(() => syncMaintenanceIssue('ensure', 'Org invalid.', duplicateRun), /more than one open/i);
    assert.throws(() => createIssueBody('Org invalid.\nInjected text'), /single-line/i);
    assert.throws(() => syncMaintenanceIssue('unknown', 'Org invalid.', () => '[]'), /usage/i);
});
