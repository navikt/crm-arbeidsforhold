const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const { developerName, parseArgs, recordXml, writeVerifications } = require('../metadata-cleanup-verify.cjs');

function tempMetadataDirectory(environments = ['SIT2', 'Production']) {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'cleanup-verify-'));
    for (const environment of environments) {
        fs.writeFileSync(path.join(directory, `AAREG_Cleanup_Environment.${environment}.md-meta.xml`), '<x/>');
    }
    return directory;
}

test('developer names are valid, unique per environment and component, and at most 40 characters', () => {
    const long = developerName('Production', 'CustomField', 'ApplicationBasisCode__c.LegalBasisStateMilitary__c');
    assert.ok(long.length <= 40, long);
    assert.match(long, /^Production_[A-Za-z0-9]+(_[A-Za-z0-9]+)*$/);
    assert.doesNotMatch(long, /__/);
    assert.notEqual(developerName('SIT2', 'ApexClass', 'A'), developerName('Production', 'ApexClass', 'A'));
    assert.notEqual(developerName('SIT2', 'ApexClass', 'A'), developerName('SIT2', 'ApexTrigger', 'A'));
    assert.equal(developerName('SIT2', 'ApexClass', 'A'), developerName('SIT2', 'ApexClass', 'A'));
});

test('the record links the environment and escapes XML', () => {
    const xml = recordXml({
        environment: 'SIT2',
        type: 'Layout',
        name: 'Account-Old & Layout',
        verifiedOn: '2026-11-25',
        verifiedBy: 'navikt/crm-arbeidsforhold',
        evidenceUrl: 'https://github.com/navikt/crm-arbeidsforhold/pull/1'
    });
    assert.match(xml, /<field>Environment__c<\/field>\s*<value xsi:type="xsd:string">SIT2<\/value>/);
    assert.match(xml, /Account-Old &amp; Layout/);
    assert.match(xml, /<value xsi:type="xsd:date">2026-11-25<\/value>/);
});

test('an export from the cleanup overview becomes one record per component; existing records are kept', () => {
    const directory = tempMetadataDirectory();
    const exported = {
        environment: 'SIT2',
        checkedOn: '2026-11-24',
        components: [
            { type: 'ApexClass', name: 'CRM_ApplicationDomain' },
            { type: 'Flow', name: 'AAREG_Old' }
        ]
    };
    const options = { verifiedBy: 'navikt/crm-arbeidsforhold', evidenceUrl: 'https://example.com/pr/1' };

    const first = writeVerifications(exported, options, directory);
    const second = writeVerifications(exported, options, directory);

    assert.equal(first.written.length, 2);
    assert.equal(second.written.length, 0);
    assert.equal(second.skipped.length, 2);
    const content = fs.readFileSync(path.join(directory, first.written[0]), 'utf8');
    assert.match(content, /2026-11-24/);
});

test('unknown environments, missing evidence and invalid dates are rejected', () => {
    const directory = tempMetadataDirectory();
    const options = { verifiedBy: 'x', evidenceUrl: 'https://example.com' };
    const component = [{ type: 'ApexClass', name: 'A' }];
    assert.throws(
        () => writeVerifications({ environment: 'Dev', components: component }, options, directory),
        /Ukjent miljø/
    );
    assert.throws(
        () => writeVerifications({ environment: 'SIT2', components: component }, { verifiedBy: 'x' }, directory),
        /--evidence/
    );
    assert.throws(
        () =>
            writeVerifications(
                { environment: 'SIT2', checkedOn: '24.11.2026', components: component },
                options,
                directory
            ),
        /dato/
    );
});

test('arguments accept an export file or a single component', () => {
    assert.deepEqual(parseArgs(['--from', 'x.json', '--by', 'me', '--evidence', 'https://e']), {
        from: 'x.json',
        by: 'me',
        evidence: 'https://e'
    });
    assert.equal(parseArgs(['--env', 'SIT2', '--type', 'ApexClass', '--name', 'A']).name, 'A');
});
