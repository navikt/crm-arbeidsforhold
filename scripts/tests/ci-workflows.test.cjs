const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');

const directory = path.resolve(__dirname, '../../.github/workflows');
const readWorkflow = (name) => fs.readFileSync(path.join(directory, name), 'utf8');

test('package creation runs on main for metadata and package configuration changes', () => {
    const source = readWorkflow('push_create-package1.yml');
    assert.match(source, /workflow_dispatch:/);
    assert.match(source, /branches:\s*\n\s*- main\b/);
    assert.doesNotMatch(source, /- master\b/);
    for (const file of ['force-app/**', 'sfdx-project.json', '.forceignore']) {
        assert.ok(source.includes(`'${file}'`) || source.includes(`"${file}"`), `Missing package trigger: ${file}`);
    }
});

test('direct dev deployment is manual and reuses the tested dependency installer', () => {
    const source = readWorkflow('push_deploy-to-dev1.yml');
    assert.match(source, /workflow_dispatch:/);
    assert.doesNotMatch(source, /^\s+push:/m);
    assert.match(
        source,
        /bash bin\/create-scratch-org\.sh --no-config --alias dev --update-packages --skip-version-check/
    );
    assert.match(source, /PACKAGE_INSTALL_KEY: \$\{\{ secrets\.CRM_PACKAGE_KEY \}\}/);
    assert.match(
        source,
        /sf project deploy start --source-dir force-app --target-org dev --test-level RunLocalTests --wait 60/
    );
    assert.doesNotMatch(source, /\bsfdx\b|sfpowerkit|install-keys|GITHUB_OUTPUT/);
    assert.match(source, /persist-credentials: false/);
    assert.match(source, /node-version: '22'/);
});

for (const lineEnding of ['\n', '\r\n']) {
    test(`credential-bearing dev deployment only runs for main with ${JSON.stringify(lineEnding)} line endings`, () => {
        const source = readWorkflow('push_deploy-to-dev1.yml').replace(/\r?\n/g, lineEnding);
        assert.match(source, /deploy-metadata:\r?\n\s+if: github\.ref == 'refs\/heads\/main'\r?\n/);
    });
}

for (const name of ['pull_request-validation1.yml', 'pull_request-lwc-validation.yml']) {
    test(`${name} validates PRs targeting nested branch names too`, () => {
        assert.match(readWorkflow(name), /branches:\s*\n\s*- '\*\*'/);
    });
}

test('offline CI covers the workflow contracts and Node tooling on PRs and main', () => {
    const source = readWorkflow('scratch-org-offline.yml');
    for (const pattern of ['scripts/*.cjs', 'scripts/tests/**', '.github/workflows/**']) {
        assert.equal(source.split(`'${pattern}'`).length - 1, 2, pattern);
    }
});

test('promotion auto-merge trusts only base code and preserves review and status requirements', () => {
    const source = readWorkflow('promotion-auto-merge.yml');
    assert.match(source, /workflow_run:\s*\n\s+workflows: \['\[HELPER\] Promote Package'\]/);
    assert.match(source, /types: \[completed\]\s*\n\s+branches:\s*\n\s+- main\b/);
    assert.match(source, /github\.event\.workflow_run\.event == 'workflow_dispatch'/);
    assert.match(source, /github\.event\.workflow_run\.head_repository\.full_name == github\.repository/);
    assert.match(source, /--state open --base main/);
    assert.match(source, /--head auto\/package-version-update/);
    assert.match(source, /select\(\.isCrossRepository == false and \.isDraft == false\)/);
    assert.match(source, /ref: \$\{\{ steps\.promotion\.outputs\.base \}\}/);
    assert.match(source, /persist-credentials: false/);
    assert.match(source, /if: steps\.changes\.outputs\.package_version_only == 'true'/);
    assert.match(source, /gh pr merge .*--auto .*--match-head-commit "\$HEAD_SHA"/);
    assert.doesNotMatch(source, /--admin|secrets: inherit|CRM_DEPLOYMENT_PAT|npm ci/);
});

for (const name of fs.readdirSync(directory).filter((name) => name.endsWith('.yml'))) {
    test(`${name} declares token permissions and pins external actions`, () => {
        const source = readWorkflow(name);
        assert.match(source, /^permissions:\s*\n\s+contents: read\b/m);
        for (const [, reference] of source.matchAll(/\buses: ([^\s]+)/g)) {
            if (!reference.startsWith('./')) {
                assert.match(reference, /@[a-f0-9]{40}$/, reference);
            }
        }
    });

    test(`${name} does not interpolate inputs or actors directly into shell scripts`, () => {
        const source = readWorkflow(name);
        assert.doesNotMatch(source, /(?:echo|run:).*\$\{\{\s*(?:inputs\.|github\.event\.inputs\.|github\.actor)/);
    });
}
