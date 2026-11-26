const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const { scratchFingerprint } = require('../ci-scratch-plan.cjs');

const directory = path.resolve(__dirname, '../../.github/workflows');
const readWorkflow = (name) => fs.readFileSync(path.join(directory, name), 'utf8').replace(/\r\n/g, '\n');

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

test('PR pilot starts from trusted main and validates a captured PR snapshot without changing required CI', () => {
    const pilot = readWorkflow('ci-reusable-pr-pilot.yml');
    assert.match(
        pilot,
        /workflow_run:\s*\n\s+workflows:\s*\n\s+- '\[PR\] Validate'\s*\n\s+types:\s*\n\s+- in_progress/
    );
    assert.match(pilot, /pull-requests: read/);
    assert.match(pilot, /ref: \$\{\{ github\.sha \}\}[\s\S]*?path: trusted/);
    assert.match(pilot, /node trusted\/scripts\/ci-pr-pilot\.cjs resolve/);
    assert.match(pilot, /ref: \$\{\{ steps\.pull\.outputs\.merge_sha \}\}[\s\S]*?path: candidate/);
    assert.match(pilot, /ci-pr-pilot\.cjs" verify-snapshot/);
    assert.match(pilot, /ci-pr-pilot\.cjs" verify-source/);
    assert.match(pilot, /ci-changes\.cjs" "\$BASE_SHA" "\$HEAD_SHA"/);
    assert.match(pilot, /uses: \.\/\.github\/workflows\/ci-reusable-scratch-org\.yml/);
    assert.match(pilot, /if: needs\.prepare\.outputs\.salesforce == 'true'/);
    assert.match(pilot, /CRM_PROD_SFDX_URL: \$\{\{ secrets\.CRM_PROD_SFDX_URL \}\}/);
    assert.match(pilot, /CRM_PACKAGE_KEY: \$\{\{ secrets\.CRM_PACKAGE_KEY \}\}/);
    assert.doesNotMatch(pilot, /secrets: inherit|pull-requests: write|contents: write|actions: write/);

    const required = readWorkflow('pull_request-validation1.yml');
    assert.match(required, /uses: \.\/\.github\/workflows\/salesforce-validation\.yml/);
    assert.doesNotMatch(required, /ci-reusable-pr-pilot|ci-reusable-scratch-org/);
});

test('shared scratch validation runs trusted tools against the captured PR and records minimal evidence', () => {
    const source = readWorkflow('ci-reusable-scratch-org.yml');
    assert.match(source, /workflow_dispatch:/);
    assert.match(source, /workflow_call:/);
    assert.match(source, /ref: \$\{\{ github\.sha \}\}[\s\S]*?path: trusted/);
    assert.match(source, /ref: \$\{\{ inputs\.merge_sha \|\| github\.sha \}\}[\s\S]*?path: candidate/);
    assert.match(source, /working-directory: candidate/);
    assert.match(source, /ci-pr-pilot\.cjs" verify-snapshot/);
    assert.match(source, /ci-pr-pilot\.cjs" verify-source/);
    assert.match(source, /\$TRUSTED_ROOT\/bin\/package-dependencies\.js/);
    assert.match(source, /\$TRUSTED_ROOT\/scripts\/ci-scratch-plan\.cjs/);
    assert.match(source, /\$TRUSTED_ROOT\/scripts\/ci-pr-evidence\.cjs" create/);
    assert.match(source, /actions\/upload-artifact@[a-f0-9]{40}/);
    assert.match(source, /name: reusable-pr-pilot-evidence-\$\{\{ github\.run_attempt \}\}/);
    assert.match(source, /if: inputs\.pull_number != ''/);
    assert.match(source, /group: crm-arbeidsforhold-reusable-scratch-org/);
    assert.match(source, /cancel-in-progress: false/);
});

test('PR-controlled Salesforce output cannot issue GitHub workflow commands', () => {
    const source = readWorkflow('ci-reusable-scratch-org.yml');
    for (const [start, end] of [
        ['- name: Resolve and validate exact package versions', '- name: Select reusable org or fresh fallback'],
        ['- name: Deploy source to fresh org', '- name: Run repository Apex tests in fresh org'],
        ['- name: Validate reusable org with tests and coverage', '- name: Deploy source to fresh org']
    ]) {
        const section = source.slice(source.indexOf(start), source.indexOf(end));
        assert.ok(section.includes('::stop-commands::$command_token'), start);
        assert.ok(section.includes('::$command_token::'), start);
        assert.ok(section.indexOf('::stop-commands::$command_token') < section.indexOf('::$command_token::'), start);
    }
});

test(
    'reuse validation failures remain failures and cannot trigger the fresh-org route',
    { skip: process.platform === 'win32' ? 'The workflow runs on Ubuntu with Bash.' : false },
    (context) => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-reuse-failure-'));
        context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
        const fakeSf = path.join(directory, 'sf');
        fs.writeFileSync(fakeSf, '#!/bin/sh\nprintf "%s" "$TEST_RESPONSE"\nexit 19\n', { mode: 0o755 });
        const workflow = readWorkflow('ci-reusable-scratch-org.yml');
        const section = workflow.slice(
            workflow.indexOf('- name: Validate reusable org with tests and coverage'),
            workflow.indexOf('- name: Deploy source to fresh org')
        );
        const script = section.match(/\n {14}run: \|\n((?: {18}.*\n)+)/)?.[1].replace(/^ {18}/gm, '');
        assert.ok(script);
        assert.doesNotMatch(section, /continue-on-error|CI_VALIDATION_ROUTE=fresh/);
        assert.match(
            workflow,
            /- name: Create one-time fallback scratch org[\s\S]*?if: env\.CI_VALIDATION_ROUTE == 'fresh'/
        );

        for (const diagnostic of [
            { componentFailures: [{ problem: 'Metadata compilation failed' }] },
            { runTestResult: { failures: [{ message: '::error::Apex test failed' }] } }
        ]) {
            const result = spawnSync('/bin/bash', ['-c', script], {
                cwd: directory,
                encoding: 'utf8',
                env: {
                    ...process.env,
                    PATH: directory + path.delimiter + process.env.PATH,
                    RUNNER_TEMP: directory,
                    TRUSTED_ROOT: path.resolve(__dirname, '../..'),
                    TEST_RESPONSE: JSON.stringify({ result: { details: diagnostic } })
                }
            });
            assert.equal(result.status, 19, result.stderr);
            const token = result.stdout.match(/::stop-commands::([a-f0-9-]+)/)?.[1];
            assert.ok(token);
            const message = diagnostic.componentFailures?.[0].problem ?? diagnostic.runTestResult.failures[0].message;
            assert.ok(result.stdout.indexOf(message) > result.stdout.indexOf(`::stop-commands::${token}`));
            assert.ok(result.stdout.indexOf(`::${token}::`) > result.stdout.indexOf(message));
        }
    }
);

test('reusable scratch validation is main-only, serialized, and retains its manual and fresh-org routes', () => {
    const source = readWorkflow('ci-reusable-scratch-org.yml');
    assert.match(source, /workflow_dispatch:/);
    assert.match(source, /if: github\.ref == 'refs\/heads\/main'/);
    assert.match(source, /ref: \$\{\{ github\.sha \}\}/);
    assert.match(source, /environment: ci-scratch-org/);
    assert.match(source, /cancel-in-progress: false/);
    assert.match(source, /--include-unreleased --plan-file/);
    assert.match(source, /CI_SCRATCH_ORG_AUTH_URL/);
    assert.match(
        source,
        /sf org login sfdx-url --sfdx-url-file "\$auth_file" --alias ci-devhub --set-default-dev-hub >"\$login_log" 2>&1/
    );
    assert.match(source, /--target-org ci-reuse \\\s*--dry-run \\\s*--test-level RunLocalTests/);
    assert.match(source, /sf org create scratch \\\s*--definition-file config\/project-scratch-def\.json/);
    assert.match(source, /node "\$TRUSTED_ROOT\/scripts\/ci-scratch-plan\.cjs" install/);
    assert.match(source, /sf project deploy start --source-dir force-app --target-org ci-fresh/);
    assert.match(source, /sf org delete scratch --target-org ci-fresh --no-prompt/);
    assert.doesNotMatch(source, /pull_request:|pull_request_target:/);
    assert.doesNotMatch(source, /pull-requests: write|contents: write|actions: write/);
});

test('scratch validation excludes the non-package sources used by existing CI before either route', () => {
    const source = readWorkflow('ci-reusable-scratch-org.yml');
    const excluded = [
        './force-app/unpackagable',
        './force-app/unpackagable-with-auto-deploy',
        './force-app/scratch-org'
    ];
    const sourceScope = source.indexOf('- name: Exclude non-package sources from validation');
    assert.ok(sourceScope >= 0);
    for (const directory of excluded) assert.ok(source.includes(`rm -rf ${directory}`));
    assert.ok(sourceScope < source.indexOf('- name: Validate reusable org with tests and coverage'));
    assert.ok(sourceScope < source.indexOf('- name: Deploy source to fresh org'));
    assert.ok(sourceScope < source.indexOf('- name: Run repository Apex tests in fresh org'));
});

test('checks active scratch status and matching org identity before querying installed packages', () => {
    const source = readWorkflow('ci-reusable-scratch-org.yml');
    const scratchQuery = source.indexOf('sf data query');
    const scratchVerification = source.indexOf('ci-scratch-plan.cjs" verify-scratch');
    const login = source.indexOf('sf org login sfdx-url --sfdx-url-file "$auth_file" --alias ci-reuse');
    const identity = source.indexOf('jq -e --arg expected "$CI_SCRATCH_ORG_ID"');
    const packages = source.indexOf('sf package installed list --target-org ci-reuse');
    assert.ok(scratchQuery >= 0);
    assert.match(source, /ScratchOrgInfo/);
    assert.ok(scratchQuery < scratchVerification);
    assert.ok(scratchVerification < login);
    assert.ok(login < identity);
    assert.ok(identity < packages);
    assert.match(source, /CI_SCRATCH_ORG_ID.*=~ \^\[a-zA-Z0-9\]/);
});

test(
    'routes the actual workflow safely with a simulated Salesforce CLI',
    { skip: process.platform === 'win32' ? 'The workflow runs on Ubuntu with Bash.' : false },
    (context) => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-scratch-route-'));
        context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
        for (const subdirectory of ['bin', 'config', 'scripts']) fs.mkdirSync(path.join(directory, subdirectory));

        const projectFile = path.join(directory, 'sfdx-project.json');
        const definitionFile = path.join(directory, 'config/project-scratch-def.json');
        const traceFile = path.join(directory, 'sf-calls.txt');
        const githubEnv = path.join(directory, 'github-env.txt');
        fs.writeFileSync(
            projectFile,
            JSON.stringify({
                sourceApiVersion: '67.0',
                packageDirectories: [{ dependencies: [{ package: 'base' }] }]
            })
        );
        fs.writeFileSync(definitionFile, '{}');
        fs.writeFileSync(
            path.join(directory, 'package-plan.json'),
            JSON.stringify({ base: { SubscriberPackageVersionId: 'planned-version' } })
        );
        fs.copyFileSync(
            path.resolve(__dirname, '../ci-scratch-plan.cjs'),
            path.join(directory, 'scripts/ci-scratch-plan.cjs')
        );
        const cliFile = path.join(directory, 'fake-cli.cjs');
        fs.writeFileSync(
            cliFile,
            `
            const fs = require('node:fs');
            const args = process.argv.slice(2);
            fs.appendFileSync(process.env.TEST_TRACE, args.slice(0, 3).join(' ') + '\\n');
            const scenario = process.env.TEST_SCENARIO;
            if (args[0] === 'data' && args[1] === 'query') {
                if (scenario === 'query-failed') process.exit(1);
                const records = scenario === 'inactive' ? [] : [{
                    ScratchOrg: process.env.CI_SCRATCH_ORG_ID.slice(0, 15),
                    Status: 'Active',
                    ExpirationDate: process.env.CI_SCRATCH_ORG_EXPIRATION
                }];
                console.log(JSON.stringify({ result: { records } }));
            } else if (args[0] === 'org' && args[1] === 'login') {
                process.exit(0);
            } else if (args[0] === 'org' && args[1] === 'display') {
                const id = scenario === 'wrong-org' ? 'B'.repeat(15) + 'XYZ' : process.env.CI_SCRATCH_ORG_ID;
                console.log(JSON.stringify({ result: { id } }));
            } else if (args[0] === 'package' && args[1] === 'installed') {
                const id = scenario === 'old-package' ? 'old-version' : 'planned-version';
                console.log(JSON.stringify({ result: [{ SubscriberPackageVersionId: id }] }));
            } else {
                process.exit(2);
            }
        `
        );
        const quote = (value) => `'${value.replaceAll("'", "'\\''")}'`;
        fs.writeFileSync(
            path.join(directory, 'bin/sf'),
            `#!/bin/sh\nexec ${quote(process.execPath)} ${quote(cliFile)} "$@"\n`,
            { mode: 0o755 }
        );

        const workflow = readWorkflow('ci-reusable-scratch-org.yml');
        const route = workflow.slice(workflow.indexOf('- name: Select reusable org or fresh fallback'));
        const script = route.match(/\n {14}run: \|\n((?: {18}.*\n)+)/)?.[1].replace(/^ {18}/gm, '');
        assert.ok(script, 'The workflow route script must be present.');

        const scenarios = [
            { name: 'ready', route: 'reuse', calls: ['data query', 'org login', 'org display', 'package installed'] },
            { name: 'inactive', route: 'fresh', calls: ['data query'] },
            { name: 'query-failed', route: 'fresh', calls: ['data query'] },
            {
                name: 'old-package',
                route: 'fresh',
                calls: ['data query', 'org login', 'org display', 'package installed']
            },
            { name: 'wrong-org', status: 1, calls: ['data query', 'org login', 'org display'] },
            { name: 'invalid-id', status: 1, calls: [] },
            { name: 'forced', route: 'fresh', calls: [] }
        ];
        for (const scenario of scenarios) {
            fs.writeFileSync(traceFile, '');
            fs.writeFileSync(githubEnv, '');
            const result = spawnSync('/bin/bash', ['-c', script], {
                cwd: directory,
                encoding: 'utf8',
                env: {
                    ...process.env,
                    PATH: path.join(directory, 'bin') + path.delimiter + process.env.PATH,
                    TRUSTED_ROOT: directory,
                    RUNNER_TEMP: directory,
                    GITHUB_ENV: githubEnv,
                    TEST_TRACE: traceFile,
                    TEST_SCENARIO: scenario.name,
                    CI_SCRATCH_ORG_AUTH_URL: 'placeholder',
                    CI_SCRATCH_ORG_ID:
                        scenario.name === 'invalid-id' ? "invalid' OR Status='Active" : 'A'.repeat(15) + 'XYZ',
                    CI_SCRATCH_ORG_EXPIRATION: '2099-12-01',
                    CI_SCRATCH_ORG_CONFIG_SHA256: scratchFingerprint(projectFile, definitionFile),
                    CI_FORCE_FRESH: scenario.name === 'forced' ? 'true' : 'false'
                }
            });
            assert.equal(result.status, scenario.status ?? 0, `${scenario.name}: ${result.stderr}`);
            if (scenario.route) {
                assert.match(fs.readFileSync(githubEnv, 'utf8'), new RegExp(`CI_VALIDATION_ROUTE=${scenario.route}`));
            } else {
                assert.equal(fs.readFileSync(githubEnv, 'utf8'), '');
            }
            const calls = fs.readFileSync(traceFile, 'utf8');
            assert.deepEqual(
                calls.trim()
                    ? calls
                          .trim()
                          .split('\n')
                          .map((line) => line.split(' ').slice(0, 2).join(' '))
                    : [],
                scenario.calls,
                scenario.name
            );
            assert.equal(fs.existsSync(path.join(directory, 'reuse-auth.txt')), false, scenario.name);
        }
    }
);

test('promotion helper uses the local reusable workflow', () => {
    const caller = readWorkflow('helper_promotion1.yml');
    assert.match(caller, /uses: \.\/\.github\/workflows\/package-promotion\.yml/);
    assert.match(caller, /packageId: \$\{\{ inputs\.packageId \}\}/);
    assert.match(caller, /comment: \$\{\{ inputs\.comment \}\}/);
    assert.match(caller, /if: github\.ref == 'refs\/heads\/main'/);
    assert.match(
        caller,
        /run-package-promotion:[\s\S]*?permissions:\s*\n\s+contents: write\s*\n\s+pull-requests: write\s*\n\s+actions: write/
    );
    assert.match(caller, /CRM_PROD_SFDX_URL: \$\{\{ secrets\.CRM_PROD_SFDX_URL \}\}/);
    assert.match(caller, /CRM_PREPROD_SFDX_URL: \$\{\{ secrets\.CRM_PREPROD_SFDX_URL \}\}/);
    assert.match(caller, /CRM_UAT_SFDX_URL: \$\{\{ secrets\.CRM_UAT_SFDX_URL \}\}/);
    assert.match(caller, /CRM_PACKAGE_KEY: \$\{\{ secrets\.CRM_PACKAGE_KEY \}\}/);
    assert.doesNotMatch(caller, /secrets: inherit|CRM_DEPLOYMENT_PAT/);
    assert.doesNotMatch(caller, /crm-workflows-base\/\.github\/workflows\/packagePromotion\.yml/);

    const promotion = readWorkflow('package-promotion.yml');
    assert.match(promotion, /workflow_call:/);
    assert.match(promotion, /validate-inputs:[\s\S]*?PACKAGE_ID: \$\{\{ inputs\.packageId \}\}/);
    assert.match(promotion, /\[\[ ! "\$PACKAGE_ID" =~ \^\(\[A-Za-z0-9\]\{15\}\|\[A-Za-z0-9\]\{18\}\)\$ \]\]/);
    assert.match(
        promotion,
        /install-package-preprod:[\s\S]*?needs: \[validate-inputs\][\s\S]*?uses: \.\/\.github\/workflows\/package-install\.yml/
    );
    assert.match(
        promotion,
        /install-package-uat:[\s\S]*?needs: \[validate-inputs\][\s\S]*?uses: \.\/\.github\/workflows\/package-install\.yml/
    );
    assert.match(promotion, /promote-package:[\s\S]*?needs: \[validate-inputs, install-package-preprod\]/);
    assert.match(promotion, /promote-package:\n\s+name: [^\n]+\n\s+environment: production\n/);
    assert.match(promotion, /create-release:\n\s+name: [^\n]+\n\s+environment: production\n/);
    assert.match(promotion, /sf package version promote/);
    assert.match(promotion, /packageMinorVersionUpdater@/);
    assert.match(promotion, /create-pull-request@/);
    assert.match(promotion, /gh pr merge .*--auto .*--match-head-commit/);
    assert.match(
        promotion,
        /Wait for version-update PR to merge[\s\S]*?gh pr view[\s\S]*?gh workflow run push_create-package1\.yml --ref "\$dispatch_ref"/
    );
    assert.match(
        promotion,
        /gh pr view .*--json state,mergedAt,headRefOid,mergedBy,mergeCommit[\s\S]*?merged_by=\$\(jq -r '\.mergedBy\.login \/\/ empty'[\s\S]*?if \[\[ "\$merged_by" != "app\/github-actions" && "\$merged_by" != "github-actions\[bot\]" \]\]; then[\s\S]*?gh api "repos\/\$GITHUB_REPOSITORY\/actions\/workflows\/push_create-package1\.yml\/runs\?head_sha=\$merge_sha[\s\S]*?gh workflow run/
    );
    assert.match(promotion, /dispatch_ref="package-create-\$\{GITHUB_RUN_ID\}-\$\{GITHUB_RUN_ATTEMPT\}"/);
    assert.match(
        promotion,
        /gh api -X POST "repos\/\$GITHUB_REPOSITORY\/git\/refs" -f ref="refs\/tags\/\$dispatch_ref" -f sha="\$merge_sha"[\s\S]*?trap cleanup_dispatch_tag EXIT[\s\S]*?gh workflow run push_create-package1\.yml --ref "\$dispatch_ref"/
    );
    assert.match(
        promotion,
        /cleanup_dispatch_tag\(\) \{[\s\S]*?gh api -X DELETE "repos\/\$GITHUB_REPOSITORY\/git\/refs\/tags\/\$dispatch_ref"[\s\S]*?exit "\$dispatch_status"/
    );
    assert.match(
        promotion,
        /push-new-version-number:[\s\S]*?permissions:\s*\n\s+contents: write\s*\n\s+pull-requests: write\s*\n\s+actions: write/
    );
    assert.match(promotion, /create-release:[\s\S]*?softprops\/action-gh-release@/);
    assert.match(promotion, /target_commitish: \$\{\{ github\.sha \}\}/);
    assert.doesNotMatch(promotion, /CRM_DEPLOYMENT_PAT|merge-pull-request-action|--admin/);
    assert.doesNotMatch(
        promotion,
        /navikt\/crm-workflows-base\/.*(?:@master|@main)|(?:actions|peter-evans|metcalfc|softprops)\/.*@(?![a-f0-9]{40}\b)[^\s]+/
    );
    assert.equal(fs.existsSync(path.join(directory, 'promotion-auto-merge.yml')), false);
});

test('bot-merged promotion PRs dispatch the review audit for the exact merge commit', () => {
    const audit = readWorkflow('post-merge-review-audit.yml');
    assert.match(audit, /workflow_dispatch:\s*\n\s+inputs:\s*\n\s+sha:/);
    assert.match(audit, /AUDIT_SHA: \$\{\{ inputs\.sha \|\| github\.sha \}\}/);

    const promotion = readWorkflow('package-promotion.yml');
    assert.match(
        promotion,
        /echo "bot-merge-sha=\$merge_sha" >> "\$GITHUB_OUTPUT"[\s\S]*?gh workflow run push_create-package1\.yml[\s\S]*?if: always\(\) && steps\.wait-for-merge\.outputs\.bot-merge-sha != ''[\s\S]*?gh workflow run post-merge-review-audit\.yml --ref main --repo "\$GITHUB_REPOSITORY" -f sha="\$MERGE_SHA"/
    );
});

test('audit concurrency is keyed by the SHA being audited', () => {
    const audit = readWorkflow('post-merge-review-audit.yml');
    assert.match(audit, /group: post-merge-review-audit-\$\{\{ inputs\.sha \|\| github\.sha \}\}/);
});

test('sandbox installation inherits only its explicitly passed secrets', () => {
    const promotion = readWorkflow('package-promotion.yml');
    for (const [job, allowedSecret, forbiddenSecret] of [
        ['install-package-preprod', 'CRM_PREPROD_SFDX_URL', 'CRM_UAT_SFDX_URL'],
        ['install-package-uat', 'CRM_UAT_SFDX_URL', 'CRM_PREPROD_SFDX_URL']
    ]) {
        const section = promotion.match(new RegExp(`^    ${job}:\\n([\\s\\S]*?)(?=^    [\\w-]+:|$(?![\\s\\S]))`, 'm'));
        assert.ok(section, `Missing ${job}`);
        assert.match(section[1], new RegExp(`${allowedSecret}: \\$\\{\\{ secrets\\.${allowedSecret} \\}\\}`));
        assert.match(section[1], /CRM_PACKAGE_KEY: \$\{\{ secrets\.CRM_PACKAGE_KEY \}\}/);
        assert.doesNotMatch(section[1], new RegExp(`${forbiddenSecret}|CRM_PROD_SFDX_URL|secrets: inherit`));
    }

    const installer = readWorkflow('package-install.yml');
    assert.match(installer, /workflow_call:/);
    assert.match(installer, /CRM_PREPROD_SFDX_URL:\s*\n\s+required: false/);
    assert.match(installer, /CRM_UAT_SFDX_URL:\s*\n\s+required: false/);
    assert.match(installer, /CRM_PACKAGE_KEY:\s*\n\s+required: true/);
    assert.doesNotMatch(installer, /CRM_PROD_SFDX_URL|CRM_DEPLOYMENT_PAT/);
    assert.match(installer, /uses: navikt\/crm-workflows-base\/\.github\/workflows\/deployPackage\.yml@[a-f0-9]{40}/);
    assert.match(installer, /secrets: inherit/);
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
