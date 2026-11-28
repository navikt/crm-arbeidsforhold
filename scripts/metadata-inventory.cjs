#!/usr/bin/env node
'use strict';

const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');
const OUTPUT_DIRECTORY = path.join(ROOT, 'force-app/internalAdmin/staticresources');
const RESOURCE_NAME = 'AAREG_Metadata_Inventory';
const OWNED_PREFIXES = ['AAREG', 'P360'];
const SCHEMA_VERSION = 1;

const SIMPLE_TYPES = {
    classes: { type: 'ApexClass', pattern: /^(?:.+\/)?([^/]+)\.cls(-meta\.xml)?$/ },
    triggers: { type: 'ApexTrigger', pattern: /^(?:.+\/)?([^/]+)\.trigger(-meta\.xml)?$/ },
    pages: { type: 'ApexPage', pattern: /^(?:.+\/)?([^/]+)\.page(-meta\.xml)?$/ },
    components: { type: 'ApexComponent', pattern: /^(?:.+\/)?([^/]+)\.component(-meta\.xml)?$/ },
    staticresources: { type: 'StaticResource', pattern: /^([^/.]+)(\.[^/]+)?(\/.*)?$/ },
    flows: { type: 'Flow', pattern: /^(?:.+\/)?([^/]+)\.flow-meta\.xml$/ },
    layouts: { type: 'Layout', pattern: /^(?:.+\/)?([^/]+)\.layout-meta\.xml$/ },
    flexipages: { type: 'FlexiPage', pattern: /^(?:.+\/)?([^/]+)\.flexipage-meta\.xml$/ },
    reportTypes: { type: 'ReportType', pattern: /^(?:.+\/)?([^/]+)\.reportType-meta\.xml$/ },
    quickActions: { type: 'QuickAction', pattern: /^(?:.+\/)?([^/]+)\.quickAction-meta\.xml$/ },
    permissionsets: { type: 'PermissionSet', pattern: /^(?:.+\/)?([^/]+)\.permissionset-meta\.xml$/ },
    permissionsetgroups: { type: 'PermissionSetGroup', pattern: /^(?:.+\/)?([^/]+)\.permissionsetgroup-meta\.xml$/ },
    customPermissions: { type: 'CustomPermission', pattern: /^(?:.+\/)?([^/]+)\.customPermission-meta\.xml$/ },
    applications: { type: 'CustomApplication', pattern: /^(?:.+\/)?([^/]+)\.app-meta\.xml$/ },
    workflows: { type: 'Workflow', pattern: /^(?:.+\/)?([^/]+)\.workflow-meta\.xml$/ },
    testSuites: { type: 'ApexTestSuite', pattern: /^(?:.+\/)?([^/]+)\.testSuite-meta\.xml$/ },
    tabs: { type: 'CustomTab', pattern: /^(?:.+\/)?([^/]+)\.tab-meta\.xml$/ },
    lwc: { type: 'LightningComponentBundle', pattern: /^([^/]+)\/.+$/ },
    aura: { type: 'AuraDefinitionBundle', pattern: /^([^/]+)\/.+$/ },
    customMetadata: { type: 'CustomMetadata', pattern: /^(?:.+\/)?([^/]+)\.md-meta\.xml$/ },
    remoteSiteSettings: { type: 'RemoteSiteSetting', pattern: /^(?:.+\/)?([^/]+)\.remoteSite-meta\.xml$/ },
    pathAssistants: { type: 'PathAssistant', pattern: /^(?:.+\/)?([^/]+)\.pathAssistant-meta\.xml$/ },
    reports: { type: 'Report', pattern: /^(?:.+\/)?([^/]+)\.report-meta\.xml$/ },
    dashboards: { type: 'Dashboard', pattern: /^(?:.+\/)?([^/]+)\.dashboard-meta\.xml$/ },
    email: { type: 'EmailTemplate', pattern: /^(?:.+\/)?([^/]+)\.email(-meta\.xml)?$/ }
};

const OBJECT_CHILDREN = {
    fields: { type: 'CustomField', suffix: '.field-meta.xml' },
    listViews: { type: 'ListView', suffix: '.listView-meta.xml' },
    recordTypes: { type: 'RecordType', suffix: '.recordType-meta.xml' },
    validationRules: { type: 'ValidationRule', suffix: '.validationRule-meta.xml' },
    webLinks: { type: 'WebLink', suffix: '.webLink-meta.xml' },
    compactLayouts: { type: 'CompactLayout', suffix: '.compactLayout-meta.xml' },
    fieldSets: { type: 'FieldSet', suffix: '.fieldSet-meta.xml' }
};

/**
 * Maps a source-format file path to the metadata component it belongs to.
 * Returns null for files that are not a whole component, such as translations or Experience Cloud fragments.
 */
function componentForPath(filePath) {
    const parts = filePath.split('/');
    for (let index = parts.length - 2; index >= 0; index--) {
        const folder = parts[index];
        const rest = parts.slice(index + 1).join('/');
        if (folder === 'objects') {
            return objectComponent(parts.slice(index + 1));
        }
        const simple = SIMPLE_TYPES[folder];
        if (simple) {
            const match = rest.match(simple.pattern);
            return match ? { type: simple.type, name: match[1] } : null;
        }
    }
    return null;
}

function objectComponent(parts) {
    const [objectName, child, fileName] = parts;
    if (parts.length === 2 && child === `${objectName}.object-meta.xml`) {
        return { type: 'CustomObject', name: objectName };
    }
    const childType = OBJECT_CHILDREN[child];
    if (parts.length === 3 && childType && fileName.endsWith(childType.suffix)) {
        return { type: childType.type, name: `${objectName}.${fileName.slice(0, -childType.suffix.length)}` };
    }
    return null;
}

function key(component) {
    return `${component.type}:${component.name}`;
}

/** Standard components such as standard__LightningSales are platform-owned and cannot be deleted. */
function isStandard(name) {
    return name.startsWith('standard__');
}

function isOwned(name) {
    const upper = name.toUpperCase();
    return OWNED_PREFIXES.some((prefix) => upper.startsWith(prefix));
}

function git(args) {
    const result = spawnSync('git', args, { cwd: ROOT, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
    if (result.status !== 0) {
        throw new Error(`git ${args.join(' ')} failed: ${result.stderr.trim()}`);
    }
    return result.stdout;
}

function packageDirectories() {
    const project = JSON.parse(fs.readFileSync(path.join(ROOT, 'sfdx-project.json'), 'utf8'));
    return project.packageDirectories.map((directory) => directory.path);
}

/** Components present in the given source paths, keyed by type and name. */
function currentComponents(filePaths) {
    const components = new Map();
    for (const filePath of filePaths) {
        const component = componentForPath(filePath);
        if (component) {
            components.set(key(component), component);
        }
    }
    return components;
}

/**
 * Parses `git log --name-only --format=@@%H|%cI|%s` output into the most recent deletion per component.
 * The log is newest first, so the first deletion seen for a component wins.
 */
function deletions(logOutput) {
    const removed = new Map();
    let commit = null;
    for (const line of logOutput.split('\n')) {
        if (line.startsWith('@@')) {
            const [hash, date, ...subject] = line.slice(2).split('|');
            commit = { hash, date, subject: subject.join('|') };
            continue;
        }
        const component = line.trim() ? componentForPath(line.trim()) : null;
        if (component && commit && !removed.has(key(component))) {
            removed.set(key(component), {
                ...component,
                path: line.trim(),
                commit: commit.hash.slice(0, 12),
                removedOn: commit.date.slice(0, 10),
                subject: commit.subject
            });
        }
    }
    return removed;
}

/** Builds the inventory from deletion history and the current source tree. */
function buildInventory({ logOutput, trackedFiles, commit, committedAt, repositoryUrl = null }) {
    const current = currentComponents(trackedFiles);
    const removed = [...deletions(logOutput).values()]
        .filter((component) => !current.has(key(component)) && !isStandard(component.name))
        .sort((left, right) => key(left).localeCompare(key(right)));
    const owned = {};
    for (const component of current.values()) {
        if (isOwned(component.name.split('.')[0])) {
            (owned[component.type] ??= []).push(component.name);
        }
    }
    for (const names of Object.values(owned)) {
        names.sort();
    }
    return {
        schemaVersion: SCHEMA_VERSION,
        commit: commit.slice(0, 12),
        committedAt,
        repositoryUrl,
        ownedPrefixes: OWNED_PREFIXES,
        removed,
        repository: Object.fromEntries(Object.entries(owned).sort(([left], [right]) => left.localeCompare(right)))
    };
}

/** Converts an SSH or HTTPS Git remote to a browsable GitHub URL. */
function repositoryUrlFromRemote(remote) {
    const match = remote.trim().match(/github\.com[:/](.+?)(\.git)?$/);
    return match ? `https://github.com/${match[1]}` : null;
}

function resourceMeta() {
    return [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<StaticResource xmlns="http://soap.sforce.com/2006/04/metadata">',
        '    <cacheControl>Private</cacheControl>',
        '    <contentType>application/json</contentType>',
        '    <description>Generated by scripts/metadata-inventory.cjs. Components removed from the repository and owned components still in source; read by the Arbeidsforhold Admin cleanup overview.</description>',
        '</StaticResource>',
        ''
    ].join('\n');
}

function main(argv = process.argv.slice(2)) {
    const reference = argv[0] ?? 'HEAD';
    const directories = packageDirectories();
    const logOutput = git(['log', reference, '--diff-filter=D', '--name-only', '--format=@@%H|%cI|%s', '--', ...directories]);
    const trackedFiles = git(['ls-files', '--', ...directories]).split('\n').filter(Boolean);
    const [commit, committedAt] = git(['log', '-1', '--format=%H|%cI', reference]).trim().split('|');
    const repositoryUrl = repositoryUrlFromRemote(git(['remote', 'get-url', 'origin']));
    const inventory = buildInventory({ logOutput, trackedFiles, commit, committedAt, repositoryUrl });
    fs.mkdirSync(OUTPUT_DIRECTORY, { recursive: true });
    fs.writeFileSync(path.join(OUTPUT_DIRECTORY, `${RESOURCE_NAME}.json`), `${JSON.stringify(inventory, null, 2)}\n`);
    fs.writeFileSync(path.join(OUTPUT_DIRECTORY, `${RESOURCE_NAME}.resource-meta.xml`), resourceMeta());
    console.log(
        `${RESOURCE_NAME}: ${inventory.removed.length} removed components, ` +
            `${Object.values(inventory.repository).flat().length} owned components in source (${inventory.commit}).`
    );
    return inventory;
}

if (require.main === module) {
    main();
}

module.exports = { buildInventory, componentForPath, deletions, main, repositoryUrlFromRemote };
