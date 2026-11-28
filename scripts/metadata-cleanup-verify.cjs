#!/usr/bin/env node
'use strict';

const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const METADATA_DIRECTORY = path.resolve(__dirname, '../force-app/internalAdmin/customMetadata');
const ENVIRONMENT_PREFIX = 'AAREG_Cleanup_Environment.';
const RECORD_PREFIX = 'AAREG_Cleanup_Verification.';
const SUFFIX = '.md-meta.xml';
const MAX_NAME = 40;
const USAGE = [
    'Bruk:',
    '  npm run metadata:verify -- --from <eksport.json> --by <github-brukar> --evidence <lenkje>',
    '  npm run metadata:verify -- --env SIT2 --type ApexClass --name <namn> --by <github-brukar> --evidence <lenkje> [--date YYYY-MM-DD]'
].join('\n');

function parseArgs(argv) {
    const options = {};
    for (let index = 0; index < argv.length; index += 2) {
        const key = argv[index];
        if (!key.startsWith('--') || argv[index + 1] === undefined) {
            throw new Error(`Ugyldig argument ${key}.\n${USAGE}`);
        }
        options[key.slice(2)] = argv[index + 1];
    }
    return options;
}

function developerName(environment, type, name) {
    const hash = crypto.createHash('sha1').update(`${environment}|${type}|${name}`).digest('hex').slice(0, 8);
    const room = MAX_NAME - environment.length - hash.length - 2;
    const readable = name
        .replace(/__c\b/g, '')
        .replace(/[^A-Za-z0-9]+/g, '_')
        .replace(/^_+|_+$/g, '')
        .slice(0, Math.max(room, 0))
        .replace(/_+$/g, '');
    return [environment, readable, hash].filter(Boolean).join('_');
}

function escapeXml(value) {
    return String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function value(field, content, type = 'xsd:string') {
    const body =
        content === undefined || content === null || content === ''
            ? '        <value xsi:nil="true"/>'
            : `        <value xsi:type="${type}">${escapeXml(content)}</value>`;
    return ['    <values>', `        <field>${field}</field>`, body, '    </values>'].join('\n');
}

function recordXml({ environment, type, name, verifiedOn, verifiedBy, evidenceUrl }) {
    return [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">',
        `    <label>${escapeXml(`${environment} ${name}`.slice(0, MAX_NAME))}</label>`,
        '    <protected>false</protected>',
        value('Environment__c', environment),
        value('Metadata_Type__c', type),
        value('Component_Name__c', name),
        value('Verified_On__c', verifiedOn, 'xsd:date'),
        value('Verified_By__c', verifiedBy),
        value('Evidence_Url__c', evidenceUrl),
        '</CustomMetadata>',
        ''
    ].join('\n');
}

function knownEnvironments(directory) {
    return fs
        .readdirSync(directory)
        .filter((file) => file.startsWith(ENVIRONMENT_PREFIX) && file.endsWith(SUFFIX))
        .map((file) => file.slice(ENVIRONMENT_PREFIX.length, -SUFFIX.length));
}

function today() {
    return new Date().toISOString().slice(0, 10);
}

function writeVerifications(exported, { verifiedBy, evidenceUrl }, directory = METADATA_DIRECTORY) {
    const environments = knownEnvironments(directory);
    if (!environments.includes(exported.environment)) {
        throw new Error(
            `Ukjent miljø «${exported.environment}». Kjende miljø: ${environments.join(', ')}. ` +
                'Legg miljøet inn i AAREG_Cleanup_Environment__mdt eller bruk --env.'
        );
    }
    if (!evidenceUrl || !/^https:\/\//.test(evidenceUrl)) {
        throw new Error('--evidence må vere ei https-lenkje til PR, issue eller køyring som dokumenterer sjekken.');
    }
    if (!verifiedBy) {
        throw new Error('--by må vere GitHub-brukaren eller teamet som sjekka miljøet.');
    }
    const verifiedOn = exported.checkedOn ?? today();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(verifiedOn)) {
        throw new Error(`Ugyldig dato «${verifiedOn}». Bruk YYYY-MM-DD.`);
    }
    const written = [];
    const skipped = [];
    for (const { type, name } of exported.components ?? []) {
        const file = `${RECORD_PREFIX}${developerName(exported.environment, type, name)}${SUFFIX}`;
        const target = path.join(directory, file);
        if (fs.existsSync(target)) {
            skipped.push(file);
            continue;
        }
        fs.writeFileSync(
            target,
            recordXml({ environment: exported.environment, type, name, verifiedOn, verifiedBy, evidenceUrl })
        );
        written.push(file);
    }
    return { written, skipped };
}

function main(argv = process.argv.slice(2)) {
    const options = parseArgs(argv);
    const exported = options.from
        ? JSON.parse(fs.readFileSync(options.from, 'utf8'))
        : {
              environment: options.env,
              checkedOn: options.date,
              components: options.type && options.name ? [{ type: options.type, name: options.name }] : []
          };
    if (options.env) {
        exported.environment = options.env;
    }
    if (options.date) {
        exported.checkedOn = options.date;
    }
    if (!exported.components?.length) {
        throw new Error(`Ingen komponentar å registrere.\n${USAGE}`);
    }
    const result = writeVerifications(exported, { verifiedBy: options.by, evidenceUrl: options.evidence });
    console.log(
        `${exported.environment}: ${result.written.length} nye verifikasjonar, ${result.skipped.length} fanst frå før.`
    );
    for (const file of result.written) {
        console.log(`  + force-app/internalAdmin/customMetadata/${file}`);
    }
    return result;
}

if (require.main === module) {
    try {
        main();
    } catch (error) {
        console.error(error.message);
        process.exitCode = 1;
    }
}

module.exports = { developerName, main, parseArgs, recordXml, writeVerifications };
