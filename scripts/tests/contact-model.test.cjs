const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const { FLAGS, flagRecord, main } = require('../contact-model.cjs');

const FLAG_DIRECTORY = path.join(__dirname, '../../force-app/contactModel/customMetadata');

function source(flag) {
    return fs.readFileSync(path.join(FLAG_DIRECTORY, `Feature_Flag.${flag}.md-meta.xml`), 'utf8');
}

test('every flag ships disabled in the repository', () => {
    for (const flag of FLAGS) {
        assert.match(source(flag), /<field>Is_Enabled__c<\/field>\s*<value xsi:type="xsd:boolean">false<\/value>/);
    }
});

test('pilot scope enables the flag only for the pilot custom permission', () => {
    const record = flagRecord(source(FLAGS[0]), 'pilot');
    assert.match(record, /<value xsi:type="xsd:boolean">true<\/value>/);
    assert.match(record, /<value xsi:type="xsd:string">AAREG_ContactModelPilot<\/value>/);
});

test('all scope enables the flag without a required permission', () => {
    const record = flagRecord(source(FLAGS[0]), 'all');
    assert.match(record, /<value xsi:type="xsd:boolean">true<\/value>/);
    assert.doesNotMatch(record, /AAREG_ContactModelPilot/);
});

test('off scope turns a pilot flag back off', () => {
    const record = flagRecord(flagRecord(source(FLAGS[0]), 'pilot'), 'off');
    assert.match(record, /<value xsi:type="xsd:boolean">false<\/value>/);
    assert.doesNotMatch(record, /AAREG_ContactModelPilot/);
});

test('unknown mode or flag scope exits with 2 before calling Salesforce', () => {
    const runSf = () => assert.fail('Salesforce must not be called');
    const errors = [];
    const logError = (message) => errors.push(message);
    assert.equal(main({ mode: 'deploy', runSf, logError }), 2);
    assert.equal(main({ mode: 'flags', argument: 'everyone', runSf, logError }), 2);
    assert.equal(errors.length, 2);
});
