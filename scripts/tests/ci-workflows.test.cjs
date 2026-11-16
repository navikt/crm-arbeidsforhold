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

test('promotion helper uses the local reusable workflow', () => {
    const caller = readWorkflow('helper_promotion1.yml');
    assert.match(caller, /uses: \.\/\.github\/workflows\/package-promotion\.yml/);
    assert.match(caller, /packageId: \$\{\{ inputs\.packageId \}\}/);
    assert.match(caller, /comment: \$\{\{ inputs\.comment \}\}/);
    assert.match(caller, /if: github\.ref == 'refs\/heads\/main'/);
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
    assert.match(promotion, /sf package version promote/);
    assert.match(promotion, /packageMinorVersionUpdater@/);
    assert.match(promotion, /create-pull-request@/);
    assert.match(promotion, /gh pr merge .*--auto .*--match-head-commit/);
    assert.match(promotion, /create-release:[\s\S]*?softprops\/action-gh-release@/);
    assert.doesNotMatch(promotion, /CRM_DEPLOYMENT_PAT|merge-pull-request-action|--admin/);
    assert.doesNotMatch(
        promotion,
        /navikt\/crm-workflows-base\/.*(?:@master|@main)|(?:actions|peter-evans|metcalfc|softprops)\/.*@(?![a-f0-9]{40}\b)[^\s]+/
    );
    assert.equal(fs.existsSync(path.join(directory, 'promotion-auto-merge.yml')), false);
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
