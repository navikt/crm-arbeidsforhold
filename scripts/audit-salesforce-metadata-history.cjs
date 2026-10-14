const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const directoryTypes = {
    classes: 'ApexClass',
    triggers: 'ApexTrigger',
    pages: 'ApexPage',
    components: 'ApexComponent',
    flows: 'Flow',
    flowDefinitions: 'FlowDefinition',
    permissionsets: 'PermissionSet',
    permissionsetgroups: 'PermissionSetGroup',
    profiles: 'Profile',
    layouts: 'Layout',
    flexipages: 'FlexiPage',
    customMetadata: 'CustomMetadata',
    labels: 'CustomLabels',
    translations: 'Translations',
    staticresources: 'StaticResource',
    networks: 'Network',
    sites: 'CustomSite',
    experiences: 'ExperienceBundle',
    digitalExperiences: 'DigitalExperienceBundle',
    reports: 'Report',
    dashboards: 'Dashboard',
    applications: 'CustomApplication',
    tabs: 'CustomTab',
    remoteSiteSettings: 'RemoteSiteSetting',
    namedCredentials: 'NamedCredential',
    externalCredentials: 'ExternalCredential',
    authproviders: 'AuthProvider',
    customPermissions: 'CustomPermission',
    queues: 'Queue',
    groups: 'Group',
    sharingRules: 'SharingRules',
    workflows: 'Workflow',
    email: 'EmailTemplate',
    quickActions: 'QuickAction',
    duplicateRules: 'DuplicateRule',
    matchingRules: 'MatchingRules',
    globalValueSets: 'GlobalValueSet',
    standardValueSets: 'StandardValueSet',
    contentassets: 'ContentAsset',
    navigationMenus: 'NavigationMenu',
    pathAssistants: 'PathAssistant',
    reportTypes: 'ReportType',
    testSuites: 'ApexTestSuite'
};
const objectChildren = {
    fields: 'CustomField',
    recordTypes: 'RecordType',
    validationRules: 'ValidationRule',
    listViews: 'ListView',
    fieldSets: 'FieldSet',
    businessProcesses: 'BusinessProcess',
    compactLayouts: 'CompactLayout',
    webLinks: 'WebLink',
    sharingReasons: 'SharingReason',
    indexes: 'Index'
};

function metadata(filePath) {
    if (/^(docs|bin|scripts|tools|config|manifest|logs|dummy-data|\.github)\//.test(filePath)) return null;
    const segments = filePath.split('/');
    if (segments.includes('__tests__') || segments.includes('node_modules') || segments.includes('README.md'))
        return null;
    const filename = segments.at(-1);
    const scope = filePath.startsWith('force-app/') ? 'force-app' : 'Referanse/annan kjelderot';
    const name = filename.replace(/\.[^.]+-meta\.xml$/, '').replace(/\.(cls|trigger|page|component)$/, '');
    for (const bundleDirectory of ['lwc', 'aura', 'experiences', 'digitalExperiences', 'staticresources']) {
        const index = segments.indexOf(bundleDirectory);
        if (index < 0 || !segments[index + 1]) continue;
        const type =
            { lwc: 'LightningComponentBundle', aura: 'AuraDefinitionBundle' }[bundleDirectory] ||
            directoryTypes[bundleDirectory];
        const fullName = segments[index + 1].replace(/\.resource(?:-meta\.xml)?$/, '');
        return { type, fullName, scope };
    }
    const objectIndex = segments.indexOf('objects');
    if (objectIndex >= 0) {
        const objectName = segments[objectIndex + 1];
        if (!objectName) return null;
        if (filename.endsWith('.object-meta.xml') || filename.endsWith('.object'))
            return { type: 'CustomObject', fullName: objectName.replace(/\.object$/, ''), scope };
        const childType = objectChildren[segments[objectIndex + 2]];
        if (childType && filename.endsWith('-meta.xml'))
            return { type: childType, fullName: `${objectName}.${name}`, scope };
    }
    if (segments.includes('objectTranslations') && filename.endsWith('-meta.xml')) {
        const index = segments.indexOf('objectTranslations');
        return { type: 'CustomObjectTranslation', fullName: segments[index + 1], scope };
    }
    if (!filename.endsWith('-meta.xml') && !/\.(cls|trigger|page|component|report|dashboard|email)$/.test(filename))
        return null;
    const directory = segments.find((segment) => directoryTypes[segment]);
    if (directory) {
        const index = segments.indexOf(directory);
        const relativeName = segments.slice(index + 1).join('/');
        const componentPath = ['reports', 'dashboards', 'email'].includes(directory) ? relativeName : filename;
        const fullName = componentPath
            .replace(/\.[^.]+-meta\.xml$/, '')
            .replace(/\.(cls|trigger|page|component|report|dashboard|email)$/, '');
        const type = /Folder-meta\.xml$/.test(filename)
            ? { reports: 'ReportFolder', dashboards: 'DashboardFolder', email: 'EmailFolder' }[directory] ||
              directoryTypes[directory]
            : directoryTypes[directory];
        return { type, fullName, scope };
    }
    if (filename.endsWith('-meta.xml')) {
        const suffix = filename.match(/\.([^.]+)-meta\.xml$/)?.[1];
        const suffixType = {
            flow: 'Flow',
            settings: `${name}Settings`,
            pathAssistant: 'PathAssistant',
            reportType: 'ReportType',
            testSuite: 'ApexTestSuite'
        }[suffix];
        if (suffixType) return { type: suffixType, fullName: name, scope };
        return { type: `Uavklart:${suffix}`, fullName: name, scope };
    }
    return null;
}

function parseHistory(output) {
    const tokens = output.split('\0');
    const events = [];
    let commit;
    for (let index = 0; index < tokens.length; index++) {
        const token = tokens[index].trim();
        if (!token) continue;
        if (token === 'COMMIT') {
            commit = { sha: tokens[++index], date: tokens[++index], subject: tokens[++index] };
        } else if (token === 'D' || /^R\d+$/.test(token)) {
            const oldPath = tokens[++index];
            const newPath = token === 'D' ? '' : tokens[++index];
            const oldMetadata = metadata(oldPath);
            const newMetadata = newPath ? metadata(newPath) : null;
            if (!oldMetadata) continue;
            const action =
                token === 'D'
                    ? 'Sletta'
                    : path.posix.basename(oldPath) === path.posix.basename(newPath)
                      ? 'Flytta (same filnamn)'
                      : 'Endra filnamn (Git-heuristikk)';
            events.push({
                ...commit,
                action,
                similarity: token === 'D' ? '' : token.slice(1),
                oldPath,
                newPath,
                ...oldMetadata,
                newType: newMetadata?.type || '',
                newName: newMetadata?.fullName || ''
            });
        }
    }
    return events;
}

function key(component) {
    return `${component.type}:${component.fullName}`;
}

function csv(rows, columns) {
    const escape = (value) => `"${String(value ?? '').replaceAll('"', '""')}"`;
    return (
        [columns.join(','), ...rows.map((row) => columns.map((column) => escape(row[column])).join(','))].join('\n') +
        '\n'
    );
}

function git(args) {
    return execFileSync('git', args, { encoding: 'utf8', maxBuffer: 128 * 1024 * 1024 });
}

function verifyTrees(events) {
    const checks = events.flatMap((event) => [
        { revision: `${event.sha}^:${event.oldPath}`, exists: true },
        { revision: `${event.sha}:${event.oldPath}`, exists: false },
        ...(event.newPath ? [{ revision: `${event.sha}:${event.newPath}`, exists: true }] : [])
    ]);
    const output = execFileSync('git', ['cat-file', '--batch-check=%(objecttype)'], {
        input: checks.map((check) => check.revision).join('\n') + '\n',
        encoding: 'utf8',
        maxBuffer: 128 * 1024 * 1024
    })
        .trim()
        .split('\n');
    assert.equal(output.length, checks.length, 'Every Git tree check must have a result.');
    checks.forEach((check, index) => {
        assert.ok(check.exists ? output[index] === 'blob' : output[index].endsWith(' missing'), check.revision);
    });
    return checks.length;
}

function apexLiteral(value) {
    return (
        "'" +
        value
            .replaceAll('\\', '\\\\')
            .replaceAll("'", "\\'")
            .replaceAll('\r', '\\r')
            .replaceAll('\n', '\\n')
            .replaceAll('\t', '\\t') +
        "'"
    );
}

function createAnonymousBatches(candidates) {
    for (const candidate of candidates) {
        if (!/^[A-Za-z][A-Za-z0-9]*$/.test(candidate.type)) {
            throw new Error(`Invalid metadata type: ${candidate.type}`);
        }
        if (typeof candidate.fullName !== 'string' || !candidate.fullName.trim() || candidate.fullName.length > 255) {
            throw new Error('Each candidate requires a fullName of at most 255 characters.');
        }
    }
    const batches = [];
    for (let offset = 0; offset < candidates.length; offset += 10) {
        const batch = candidates.slice(offset, offset + 10);
        const number = String(batches.length + 1).padStart(2, '0');
        const entries = batch
            .map(
                (candidate) =>
                    `    new AAREG_MetadataCleanupAudit.Candidate(${apexLiteral(candidate.type)}, ${apexLiteral(candidate.fullName)})`
            )
            .join(',\n');
        batches.push({
            filename: `batch-${number}.apex`,
            count: batch.length,
            source:
                'List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>{\n' +
                entries +
                '\n};\n' +
                'List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(candidates);\n' +
                `System.debug(LoggingLevel.INFO, 'METADATA_AUDIT_BATCH_${number}\\n' + JSON.serializePretty(results));\n`
        });
    }
    return batches;
}

function writeAnonymousBatches(candidates, ref, sha) {
    const batches = createAnonymousBatches(candidates);
    const directory = path.resolve('scripts/apex/metadata-cleanup-audit');
    fs.mkdirSync(directory, { recursive: true });
    for (const batch of batches) {
        fs.writeFileSync(path.join(directory, batch.filename), batch.source);
    }
    const index =
        '# Metadata audit: Execute Anonymous batches\n\n' +
        `Source: ${ref}, commit ${sha}.\n\n` +
        `${candidates.length} candidates in ${batches.length} batches. No org was contacted during generation.\n\n` +
        'Run each listed file separately in an explicitly approved org. Do not concatenate batches into one transaction.\n' +
        'The Apex class must already be deployed and its same-org API access configured.\n' +
        'Production execution requires separate approval. UNKNOWN does not mean absent, and no result authorizes deletion.\n\n' +
        '| Script | Candidates |\n| --- | --- |\n' +
        batches.map((batch) => `| [${batch.filename}](${batch.filename}) | ${batch.count} |`).join('\n') +
        '\n\n' +
        'Open each file and run its contents in Developer Console Execute Anonymous, or use Salesforce CLI for the approved scratch org:\n\n' +
        (batches.length
            ? '```bash\nsf apex run --file scripts/apex/metadata-cleanup-audit/' +
              batches[0].filename +
              ' --target-org crm-arbeidsforhold\n```\n\n'
            : '') +
        'Logs contain METADATA_AUDIT_BATCH_nn followed by indented JSON results. Record the approved target environment separately.\n' +
        'Export audit results without unrelated trace data using `npm run metadata:audit:export -- <debug-log-path>`.\n' +
        'Run only files listed in this index; older generated files may remain after the candidate list shrinks.\n\n' +
        '[Prerequisites and status meanings](../../../docs/operations/salesforce-metadata-cleanup-runbook.md#lesebasert-apex-kontroll).\n';
    fs.writeFileSync(path.join(directory, 'README.md'), index);
    console.log(
        `Generated ${batches.length} Execute Anonymous scripts for ${candidates.length} candidates in scripts/apex/metadata-cleanup-audit.`
    );
}

function readAuditArray(text, start) {
    if (text[start] !== '[') throw new Error('Invalid audit JSON: expected an array.');
    let depth = 0;
    let inString = false;
    let escaped = false;
    for (let index = start; index < text.length; index++) {
        const character = text[index];
        if (inString) {
            if (escaped) escaped = false;
            else if (character === '\\') escaped = true;
            else if (character === '"') inString = false;
        } else if (character === '"') {
            inString = true;
        } else if (character === '[' || character === '{') {
            depth++;
        } else if (character === ']' || character === '}') {
            depth--;
            if (depth === 0) {
                try {
                    return JSON.parse(text.slice(start, index + 1));
                } catch {
                    throw new Error('Invalid audit JSON.');
                }
            }
        }
    }
    throw new Error('Incomplete audit JSON; the log may be truncated.');
}

function sanitizeAuditResult(result) {
    if (
        !result ||
        !['FOUND', 'NOT_FOUND', 'UNKNOWN'].includes(result.status) ||
        typeof result.metadataType !== 'string' ||
        !/^[A-Za-z][A-Za-z0-9]*$/.test(result.metadataType) ||
        typeof result.fullName !== 'string' ||
        !result.fullName.trim() ||
        result.fullName.length > 255 ||
        (result.errorCode != null &&
            (typeof result.errorCode !== 'string' || !/^[A-Z0-9_]{1,80}$/.test(result.errorCode)))
    ) {
        throw new Error('Invalid audit result; refusing to export unexpected data.');
    }
    return {
        status: result.status,
        metadataType: result.metadataType,
        fullName: result.fullName,
        errorCode: result.errorCode ?? null
    };
}

function extractAuditResults(text) {
    const marker = /(?:^|\n)(?:[^\r\n]*\|USER_DEBUG\|\[\d+\]\|[A-Z]+\|)?METADATA_AUDIT_BATCH_(\d+)\s*/g;
    const batches = [];
    for (const match of text.matchAll(marker)) {
        const records = readAuditArray(text, match.index + match[0].length);
        batches.push({ batch: match[1], results: records.map(sanitizeAuditResult) });
    }
    if (!batches.length) throw new Error('No audit results found in this log.');
    return batches;
}

function proposeDestructiveChanges(batches, candidates, currentKeys, references = new Map()) {
    const candidateMap = new Map(candidates.map((candidate) => [key(candidate), candidate]));
    const currentNames = new Set([...currentKeys].map((name) => name.toLowerCase()));
    const findings = new Map();
    for (const batch of batches) {
        for (const value of batch.results) {
            const result = sanitizeAuditResult(value);
            const componentKey = `${result.metadataType}:${result.fullName}`;
            findings.set(componentKey, [...(findings.get(componentKey) || []), result]);
        }
    }
    const included = [];
    const excluded = [];
    const supportedTypes = new Set([
        ...Object.values(directoryTypes),
        ...Object.values(objectChildren),
        'CustomObject',
        'LightningComponentBundle',
        'AuraDefinitionBundle',
        'ReportFolder',
        'DashboardFolder',
        'EmailFolder'
    ]);
    for (const [componentKey, results] of findings) {
        const candidate = candidateMap.get(componentKey);
        const result = results[0];
        let reason;
        if (results.some((finding) => finding.status !== result.status)) reason = 'CONFLICTING_FINDINGS';
        else if (result.status !== 'FOUND' || results.some((finding) => finding.errorCode != null))
            reason = 'NOT_CONFIRMED_FOUND';
        else if (currentNames.has(componentKey.toLowerCase())) reason = 'STILL_IN_MAIN';
        else if (!candidate) reason = 'NOT_A_HISTORICAL_CANDIDATE';
        else if (candidate.scope !== 'force-app') reason = 'REFERENCE_OR_PACKAGE_OWNER_REVIEW';
        else if (!supportedTypes.has(result.metadataType) || result.metadataType.endsWith('Settings'))
            reason = 'UNSUPPORTED_OR_SETTINGS';
        else if ((references.get(componentKey) || []).length) reason = 'REFERENCED_IN_MAIN';
        if (reason) excluded.push({ ...result, reason, references: references.get(componentKey) || [] });
        else
            included.push({
                ...result,
                lastMainDate: candidate.latestMainDate,
                lastMainCommit: candidate.latestMainCommit
            });
    }
    const sortResults = (left, right) =>
        `${left.metadataType}:${left.fullName}`.localeCompare(`${right.metadataType}:${right.fullName}`);
    return { included: included.sort(sortResults), excluded: excluded.sort(sortResults) };
}

function exportAuditLog() {
    const input = process.argv[3];
    if (!input) throw new Error('Usage: --export-log <debug-log-path> [output-json-path]');
    const output = path.resolve(process.argv[4] || 'logs/metadata-audit-results.json');
    const results = extractAuditResults(fs.readFileSync(input, 'utf8'));
    fs.mkdirSync(path.dirname(output), { recursive: true });
    fs.writeFileSync(output, JSON.stringify(results, null, 2) + '\n', { flag: 'wx' });
    console.log(`Exported ${results.length} audit batch(es) to ${path.relative(process.cwd(), output)}.`);
}

function getAuditInventory(ref) {
    const sha = git(['rev-parse', ref]).trim();
    const currentPaths = git(['ls-tree', '-r', '--name-only', '-z', sha]).split('\0').filter(Boolean);
    const currentComponents = new Map();
    for (const filePath of currentPaths) {
        const component = metadata(filePath);
        if (!component) continue;
        const componentKey = key(component);
        currentComponents.set(componentKey, [...(currentComponents.get(componentKey) || []), filePath]);
    }
    const events = parseHistory(
        git([
            'log',
            sha,
            '--first-parent',
            '--diff-merges=first-parent',
            '-M50%',
            '--diff-filter=DR',
            '--name-status',
            '-z',
            '--format=COMMIT%x00%H%x00%cI%x00%s%x00'
        ])
    );
    const treeChecks = verifyTrees(events);
    for (const event of events) {
        event.currentPaths = (currentComponents.get(key(event)) || []).join(' | ');
        event.state = event.currentPaths
            ? 'Komponenten finst i main (flytta/gjenoppretta/delvis sletta)'
            : 'Ikkje i main; sjekk org';
        event.production = 'Ikkje undersøkt';
        event.renameEvidence = event.newPath ? 'Git-heuristikk; ikkje API-verifisert' : '';
        if (event.newPath && ['ApexClass', 'ApexTrigger'].includes(event.type) && event.oldPath.endsWith('-meta.xml')) {
            const sourceRename = events.some(
                (source) =>
                    source.sha === event.sha &&
                    source.newPath &&
                    source.oldPath === event.oldPath.replace('-meta.xml', '') &&
                    source.newPath === event.newPath.replace('-meta.xml', '')
            );
            event.renameEvidence = sourceRename
                ? 'Source og metadata-sidefil samsvarer'
                : 'Berre metadata-sidefil; mogleg feilkopling';
        }
    }
    const candidates = new Map();
    for (const event of events) {
        if (event.currentPaths) continue;
        const componentKey = key(event);
        const candidate = candidates.get(componentKey) || {
            type: event.type,
            fullName: event.fullName,
            scope: event.scope,
            latestMainDate: event.date,
            latestMainCommit: event.sha,
            dates: new Set(),
            oldPaths: new Set(),
            gitRenameTargets: new Set(),
            renameEvidence: new Set(),
            production: 'Ikkje undersøkt'
        };
        candidate.dates.add(event.date);
        candidate.oldPaths.add(event.oldPath);
        if (event.newName && `${event.newType}:${event.newName}` !== componentKey)
            candidate.gitRenameTargets.add(`${event.newType}:${event.newName}`);
        if (event.renameEvidence) candidate.renameEvidence.add(event.renameEvidence);
        candidates.set(componentKey, candidate);
    }
    const candidateRows = [...candidates.values()]
        .map((candidate) => ({
            ...candidate,
            dates: [...candidate.dates].sort().join(' | '),
            oldPaths: [...candidate.oldPaths].sort().join(' | '),
            gitRenameTargets: [...candidate.gitRenameTargets].sort().join(' | '),
            renameEvidence: [...candidate.renameEvidence].sort().join(' | ')
        }))
        .sort((left, right) =>
            `${left.scope}:${left.type}:${left.fullName}`.localeCompare(
                `${right.scope}:${right.type}:${right.fullName}`
            )
        );
    return { sha, currentComponents, candidateRows, events, treeChecks };
}

function buildDestructiveXml(results, apiVersion) {
    if (!/^\d+\.\d+$/.test(apiVersion)) throw new Error('Invalid Salesforce API version.');
    const { JSDOM } = require('jsdom');
    const window = new JSDOM().window;
    try {
        const namespace = 'http://soap.sforce.com/2006/04/metadata';
        const document = window.document.implementation.createDocument(namespace, 'Package', null);
        const root = document.documentElement;
        const groups = new Map();
        for (const result of results) {
            if (result.fullName.includes('*')) throw new Error('Wildcard members are forbidden.');
            groups.set(result.metadataType, new Set([...(groups.get(result.metadataType) || []), result.fullName]));
        }
        const appendText = (parent, name, value) => {
            const element = document.createElementNS(namespace, name);
            element.textContent = value;
            parent.appendChild(element);
        };
        for (const [type, members] of [...groups].sort(([left], [right]) => left.localeCompare(right))) {
            const element = document.createElementNS(namespace, 'types');
            for (const member of [...members].sort()) appendText(element, 'members', member);
            appendText(element, 'name', type);
            root.appendChild(element);
        }
        appendText(root, 'version', apiVersion);
        return (
            '<?xml version="1.0" encoding="UTF-8"?>\n' + new window.XMLSerializer().serializeToString(document) + '\n'
        );
    } finally {
        window.close();
    }
}

function loadAuditFindings(input) {
    const text = fs.readFileSync(input, 'utf8');
    if (!text.trimStart().startsWith('[')) return extractAuditResults(text);
    const batches = JSON.parse(text);
    if (
        !Array.isArray(batches) ||
        !batches.length ||
        batches.some(
            (batch) =>
                !batch || typeof batch.batch !== 'string' || !/^\d+$/.test(batch.batch) || !Array.isArray(batch.results)
        )
    ) {
        throw new Error('Expected exported audit batches with batch numbers and results.');
    }
    return batches.map((batch) => ({ batch: batch.batch, results: batch.results.map(sanitizeAuditResult) }));
}

function findMainReferences(sha, results) {
    const references = new Map();
    const childTypes = new Set(Object.values(objectChildren));
    for (const result of results) {
        const terms = [result.fullName];
        if (childTypes.has(result.metadataType)) terms.push(result.fullName.split('.').at(-1));
        const args = ['grep', '-l', '-I', '-i', '-F', ...terms.flatMap((term) => ['-e', term]), sha, '--', 'force-app'];
        try {
            const files = git(args)
                .trim()
                .split('\n')
                .filter(Boolean)
                .map((file) => file.slice(sha.length + 1));
            references.set(`${result.metadataType}:${result.fullName}`, files);
        } catch (error) {
            if (error.status !== 1) throw new Error('Unable to complete main-source reference checks.');
        }
    }
    return references;
}

function writeDestructiveProposal() {
    const args = process.argv.slice(3);
    const input = args.shift();
    let environment;
    let outputDirectory;
    let ref = 'origin/main';
    for (let index = 0; index < args.length; index += 2) {
        const value = args[index + 1];
        if (!value) throw new Error('Each option requires a value.');
        if (args[index] === '--environment') environment = value;
        else if (args[index] === '--output-dir') outputDirectory = value;
        else if (args[index] === '--ref') ref = value;
        else throw new Error('Unknown draft-generation option.');
    }
    if (!input || !environment || !/^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$/.test(environment)) {
        throw new Error(
            'Usage: --destructive <debug-log-or-json> --environment <label> [--output-dir <new-directory>] [--ref <main-ref>]'
        );
    }
    const batches = loadAuditFindings(input);
    const inventory = getAuditInventory(ref);
    const currentKeys = new Set(inventory.currentComponents.keys());
    const preliminary = proposeDestructiveChanges(batches, inventory.candidateRows, currentKeys);
    const references = findMainReferences(inventory.sha, preliminary.included);
    const proposal = proposeDestructiveChanges(batches, inventory.candidateRows, currentKeys, references);
    const project = JSON.parse(git(['show', `${inventory.sha}:sfdx-project.json`]));
    const xml = buildDestructiveXml(proposal.included, project.sourceApiVersion);
    const directory = path.resolve(outputDirectory || `logs/metadata-audit-draft/${environment}`);
    fs.mkdirSync(path.dirname(directory), { recursive: true });
    fs.mkdirSync(directory);
    fs.writeFileSync(path.join(directory, 'destructiveChangesPost.xml'), xml, { flag: 'wx' });
    fs.writeFileSync(
        path.join(directory, 'review.json'),
        JSON.stringify(
            {
                draftOnly: true,
                deployAuthorized: false,
                environmentLabel: environment,
                environmentVerified: false,
                sourceRef: ref,
                sourceCommit: inventory.sha,
                inputFile: path.relative(process.cwd(), path.resolve(input)),
                generatedAt: new Date().toISOString(),
                includedCount: proposal.included.length,
                excludedCount: proposal.excluded.length,
                ...proposal
            },
            null,
            2
        ) + '\n',
        { flag: 'wx' }
    );
    const readme =
        '# Draft destructive metadata proposal\n\n' +
        `Environment label (operator supplied, not verified): ${environment}.\n\n` +
        `Main reference: ${ref}, commit ${inventory.sha}.\n\n` +
        `${proposal.included.length} proposed deletion entries; ${proposal.excluded.length} excluded components.\n\n` +
        'This is a local draft, not permission to deploy. No Salesforce org was contacted.\n' +
        'Only unambiguous FOUND historical candidates absent from main are considered. UNKNOWN, NOT_FOUND,\n' +
        'conflicting results, settings, reference-owned components and main-source text matches are excluded.\n\n' +
        'The reference scan is conservative text matching, including comments and tests; it is not a complete\n' +
        'Salesforce dependency check. Managed/unlocked-package ownership, org-only references, data loss,\n' +
        'permissions, rollback, log freshness and the actual target environment require human verification.\n' +
        'Do not mix logs from different environments. An operator label does not prove log provenance.\n\n' +
        '[Review all included and excluded findings](review.json).\n\n' +
        '[Draft XML](destructiveChangesPost.xml). An empty manifest means there are no justified entries.\n' +
        'Existing files and directories are never overwritten. No package/deploy command is generated or executed.\n';
    fs.writeFileSync(path.join(directory, 'README.md'), readme, { flag: 'wx' });
    console.log(
        `Draft generated in ${path.relative(process.cwd(), directory)}: ${proposal.included.length} included, ${proposal.excluded.length} excluded. No deployment performed.`
    );
}

function main() {
    const args = process.argv.slice(2);
    const ref = args.filter((argument) => argument !== '--anonymous')[0] || 'origin/main';
    const { sha, candidateRows, events, treeChecks } = getAuditInventory(ref);
    if (args.includes('--anonymous')) {
        writeAnonymousBatches(candidateRows, ref, sha);
        return;
    }
    const outputDirectory = path.resolve('docs/operations');
    fs.mkdirSync(outputDirectory, { recursive: true });
    fs.writeFileSync(
        path.join(outputDirectory, 'salesforce-metadata-history-events.csv'),
        csv(events, [
            'date',
            'sha',
            'action',
            'similarity',
            'scope',
            'type',
            'fullName',
            'oldPath',
            'newPath',
            'newType',
            'newName',
            'renameEvidence',
            'state',
            'currentPaths',
            'production'
        ])
    );
    fs.writeFileSync(
        path.join(outputDirectory, 'salesforce-metadata-cleanup-candidates.csv'),
        csv(candidateRows, [
            'scope',
            'type',
            'fullName',
            'latestMainDate',
            'latestMainCommit',
            'dates',
            'oldPaths',
            'gitRenameTargets',
            'renameEvidence',
            'production'
        ])
    );
    const counts = new Map();
    for (const candidate of candidateRows) {
        const countKey = `${candidate.scope} | ${candidate.type}`;
        counts.set(countKey, (counts.get(countKey) || 0) + 1);
    }
    const earliest = git(['log', sha, '--first-parent', '--reverse', '--format=%cI']).trim().split('\n')[0];
    const summary = {
        ref,
        sha,
        earliest,
        events: events.length,
        deletions: events.filter((event) => event.action === 'Sletta').length,
        renames: events.filter((event) => event.action.startsWith('Endra')).length,
        moves: events.filter((event) => event.action.startsWith('Flytta')).length,
        candidates: candidateRows.length,
        forceAppCandidates: candidateRows.filter((candidate) => candidate.scope === 'force-app').length,
        unknownTypes: candidateRows.filter((candidate) => candidate.type.startsWith('Uavklart:')).length,
        treeChecks
    };
    const report =
        `# Historikk for sletta og omnamna Salesforce-metadata\n\n` +
        `Generert frå ${ref} ved commit ${sha}. Historikken startar ${earliest}.\n\n` +
        `## Resultat\n\n` +
        `- ${summary.events} filhendingar: ${summary.deletions} slettingar, ${summary.renames} endra filnamn og ${summary.moves} flyttingar med same filnamn.\n` +
        `- ${summary.candidates} unike gamle metadatakomponentar finst ikkje i dagens main: ${summary.forceAppCandidates} under force-app og ${summary.candidates - summary.forceAppCandidates} i referansemapper/andre kjelderoter.\n` +
        `- ${summary.unknownTypes} kandidatar har uavklart metadatatype.\n` +
        `- Talet som framleis finst i produksjon er **ukjent**. Ingen produksjonsorg er kontakta.\n\n` +
        `Alle ${summary.events} filhendingar er verifiserte mot Git-trea med ${treeChecks} kontrollar: gammal fil fanst i førre main-commit, gammal sti er borte etter hendinga, og eventuelt nytt filnamn finst i den nye commiten.\n\n` +
        `## Fullstendige lister\n\n` +
        `- [Alle filhendingar med dato, gammal/ny sti og commit](salesforce-metadata-history-events.csv).\n` +
        `- [Dedupliserte kandidatar for kontroll mot org](salesforce-metadata-cleanup-candidates.csv).\n\n` +
        `## Kandidatar per type\n\n| Kjelderot | Type | Kandidatar |\n| --- | --- | --- |\n` +
        [...counts]
            .sort()
            .map(([countKey, count]) => `| ${countKey} | ${count} |`)
            .join('\n') +
        '\n\n' +
        `## Alle Git-gjenkjende filnamnendringar\n\n` +
        '| Dato i main | Gammal filsti | Ny filsti | Likskap | Merknad |\n| --- | --- | --- | --- | --- |\n' +
        events
            .filter((event) => event.action.startsWith('Endra'))
            .map(
                (event) =>
                    `| ${event.date.slice(0, 10)} | ${event.oldPath} | ${event.newPath} | ${event.similarity} % | ${event.renameEvidence} |`
            )
            .join('\n') +
        '\n\n' +
        `## Gamle komponentar som ikkje finst i main\n\n` +
        `Datoen under er siste filhending på main for det gamle komponentnamnet. CSV-en viser alle hendingar og datoar. Git-kopla nye namn er ikkje automatisk stadfesta erstatningar.\n\n` +
        '| Kjelderot | Type | Gammalt namn | Siste dato i main | Commit |\n| --- | --- | --- | --- | --- |\n' +
        candidateRows
            .map(
                (candidate) =>
                    `| ${candidate.scope} | ${candidate.type} | ${candidate.fullName} | ${candidate.latestMainDate.slice(0, 10)} | ${candidate.latestMainCommit.slice(0, 8)} |`
            )
            .join('\n') +
        '\n\n' +
        `## Metode og avgrensingar\n\n` +
        `Dato er commit-tidspunktet (med tidssone) då endringa kom inn på første-parent-hovudlinja til main, ikkje nødvendigvis den opphavlege arbeidsbranch-datoen eller produksjonsdeploy-datoen.\n\n` +
        `Git-gjenkjenning av rename brukar 50 % likskap. Ei rename-linje er ikkje bevis for ei Salesforce API-namnendring. XML-sidefiler kan feilaktig bli kopla til ein heilt annan komponent; sjekk type, gammalt/nytt komponentnamn og commit. Sletting pluss oppretting med mykje endra innhald kan vere registrert som sletting, ikkje rename.\n\n` +
        `Alle slettingar og Git-gjenkjende renames på hovudlinja er med, og reine filflyttingar er skilde ut. Metadata frå feature-branches som vart sletta før innfletting på main er ikkje med.\n\n` +
        `Kandidatlista grupperer etter metadatatype og fullName, ikkje fil. Apex source/sidefil og LWC/Aura-bundles blir difor ikkje talde fleire gonger. Ei sletta bundle-fil tyder ikkje at heile bundlen er sletta. Komponentar som framleis finst ein annan stad i main, eller som er gjenoppretta, er ikkje oppryddingskandidatar. Objektfelt blir kvalifiserte med objektnamn.\n\n` +
        `Filnamn og Salesforce fullName kan avvike, særleg for mapper, rapportar, dashboards, statiske ressursar og historiske source-format. XML-innhald er ikkje brukt til å bekrefte alle fullName-verdiar. Kandidatane er ein kontrolliste, ikkje eit ferdig destructiveChanges-manifest.\n\n` +
        `Berre filnamn/filsti blir undersøkte, ikkje API-namn endra inne i uendra XML-filer eller enkeltmetadata fjerna frå samansette filer. Settings (til dømes SecuritySettings) skal vurderast som konfigurasjon, ikkje som ein vanleg slettbar komponent. Bundle-namn med berre endra bokstavstorleik krev særskild kontroll i org.\n\n` +
        `Referanse-/pakke-eigde mapper er med i eiga gruppe; desse komponentane kan vere eigde av avhengigheitspakker og skal ikkje slettast som Aa-registeret-opprydding utan eigaravklaring. Felt og objekt kan ha data, og metadata kan ha avhengigheiter som må kontrollerast før sletting.\n\n` +
        `force-app er ei kjelderot, ikkje bevis for at fila var inkludert i ein pakke eller produksjonsdeploy. Historiske forceignore-reglar, unpackagable-mapper og deploy-manifest kan ha halde metadata utanfor deploy. Komponentar frå avhengigheitspakker kan finnast i org sjølv om referansekjelda ikkje finst lokalt.\n\n` +
        `## Kontroll mot produksjon\n\n` +
        `Hent eit type/fullName-inventar frå produksjon gjennom ein godkjend read-only Metadata API-prosess etter eksplisitt org-godkjenning. Match inventaret mot kandidatlista; berre treff er bekrefta som framleis til stades. Bruk historiske deploy-resultat for å avklare om komponenten nokon gong vart deploya. Vanleg source deploy slettar ikkje automatisk gamle komponentar.\n\n` +
        `Følg [runbooken](salesforce-metadata-cleanup-runbook.md) for eigarskap, avhengigheiter, godkjenning og eventuell seinare destructive deployment. Denne rapporten autoriserer ingen org-endringar.\n\n` +
        `## Reprodusering\n\n` +
        '```bash\nnode scripts/audit-salesforce-metadata-history.cjs --self-test\n' +
        `node scripts/audit-salesforce-metadata-history.cjs ${sha}\n` +
        '```\n';
    fs.writeFileSync(path.join(outputDirectory, 'salesforce-metadata-history.md'), report);
    console.log(JSON.stringify(summary, null, 2));
}

if (process.argv[2] === '--self-test') {
    assert.equal(
        metadata('force-app/main/default/objects/Account/fields/Legacy__c.field-meta.xml').fullName,
        'Account.Legacy__c'
    );
    assert.equal(metadata('force-app/utility/classes/Legacy.cls').type, 'ApexClass');
    assert.equal(metadata('force-app/integration/p360/classes/job/Worker.cls').fullName, 'Worker');
    assert.equal(metadata('force-app/utility/classes/Legacy.cls-meta.xml').fullName, 'Legacy');
    assert.equal(metadata('force-app/main/default/lwc/oldPanel/oldPanel.js').fullName, 'oldPanel');
    assert.equal(metadata('force-app/main/default/lwc/oldPanel/__tests__/oldPanel.test.js'), null);
    assert.equal(metadata('config/project-scratch-def.json'), null);
    assert.equal(metadata('AAREG_updateDecisionText.flow-meta.xml').type, 'Flow');
    assert.equal(metadata('force-app/main/default/settings/Security.settings-meta.xml').type, 'SecuritySettings');
    assert.equal(metadata('force-app/main/default/reports/Folder/Old.report-meta.xml').fullName, 'Folder/Old');
    const events = parseHistory(
        [
            'COMMIT',
            'abc',
            '2026-10-09T10:00:00+02:00',
            'Example',
            '\nD',
            'force-app/utility/classes/Legacy.cls',
            'R100',
            'force-app/main/default/lwc/oldPanel/oldPanel.js',
            'force-app/main/default/lwc/newPanel/newPanel.js',
            ''
        ].join('\0')
    );
    assert.equal(events.length, 2);
    assert.equal(events[0].action, 'Sletta');
    assert.equal(events[1].newName, 'newPanel');
    const batchCandidates = Array.from({ length: 21 }, (_, index) => ({
        type: 'ApexClass',
        fullName: `LegacyClass${index}`
    }));
    const batches = createAnonymousBatches(batchCandidates);
    assert.equal(batches.length, 3);
    assert.deepEqual(
        batches.map((batch) => batch.count),
        [10, 10, 1]
    );
    assert.equal(createAnonymousBatches([]).length, 0);
    const escapedBatch = createAnonymousBatches([{ type: 'Layout', fullName: "Account-Owner's \\ Layout" }])[0];
    assert.ok(escapedBatch.source.includes("Account-Owner\\'s \\\\ Layout"));
    assert.ok(batches[0].source.includes('AAREG_MetadataCleanupAudit.checkCandidates(candidates)'));
    assert.ok(batches[0].source.includes('JSON.serializePretty(results)'));
    assert.equal((batches[0].source.match(/new AAREG_MetadataCleanupAudit.Candidate\(/g) || []).length, 10);
    assert.throws(() => createAnonymousBatches([{ type: 'Uavklart:flow', fullName: 'Legacy' }]), /metadata type/);
    const auditResult = {
        status: 'UNKNOWN',
        metadataType: 'ApexClass',
        fullName: 'LegacyClass',
        errorCode: 'HTTP_500'
    };
    const compactLog =
        'trace not for export\n10:00:00.000 (1)|USER_DEBUG|[14]|INFO|METADATA_AUDIT_BATCH_01 ' +
        JSON.stringify([auditResult]) +
        '\nmore trace not for export';
    assert.deepEqual(extractAuditResults(compactLog), [{ batch: '01', results: [auditResult] }]);
    const prettyLog =
        '10:00:00.000 (1)|USER_DEBUG|[14]|INFO|METADATA_AUDIT_BATCH_02\n' +
        JSON.stringify([{ ...auditResult, extraTrace: 'not for export' }], null, 2) +
        '\nEXECUTION_FINISHED';
    assert.deepEqual(extractAuditResults(prettyLog), [{ batch: '02', results: [auditResult] }]);
    assert.equal(extractAuditResults(compactLog + '\n' + prettyLog).length, 2);
    assert.throws(() => extractAuditResults('no audit output'), /No audit/);
    assert.throws(() => extractAuditResults('METADATA_AUDIT_BATCH_01 [{'), /Incomplete/);
    assert.throws(() => extractAuditResults('METADATA_AUDIT_BATCH_01 [{}]'), /Invalid audit/);
    const removedCandidate = { type: 'ApexClass', fullName: 'LegacyClass', scope: 'force-app' };
    const findings = [
        {
            batch: '01',
            results: [
                { ...auditResult, status: 'FOUND', errorCode: null },
                { ...auditResult, status: 'NOT_FOUND', fullName: 'MissingClass', errorCode: null },
                { ...auditResult, fullName: 'UnknownClass' }
            ]
        }
    ];
    const proposal = proposeDestructiveChanges(findings, [removedCandidate], new Set());
    assert.deepEqual(
        proposal.included.map((result) => result.fullName),
        ['LegacyClass']
    );
    assert.equal(proposal.excluded.length, 2);
    assert.equal(
        proposeDestructiveChanges(findings, [removedCandidate], new Set(['ApexClass:LegacyClass'])).included.length,
        0
    );
    assert.equal(proposeDestructiveChanges(findings, [], new Set()).included.length, 0);
    const conflicting = [{ batch: '01', results: [{ ...auditResult, status: 'FOUND', errorCode: null }, auditResult] }];
    assert.equal(proposeDestructiveChanges(conflicting, [removedCandidate], new Set()).included.length, 0);
    const duplicate = [{ batch: '01', results: [findings[0].results[0], findings[0].results[0]] }];
    assert.equal(proposeDestructiveChanges(duplicate, [removedCandidate], new Set()).included.length, 1);
    const settingsFinding = [
        {
            batch: '01',
            results: [{ ...auditResult, metadataType: 'SecuritySettings', status: 'FOUND', errorCode: null }]
        }
    ];
    assert.equal(
        proposeDestructiveChanges(settingsFinding, [{ ...removedCandidate, type: 'SecuritySettings' }], new Set())
            .included.length,
        0
    );
    assert.equal(
        proposeDestructiveChanges(findings, [{ ...removedCandidate, scope: 'Referanse/annan kjelderot' }], new Set())
            .included.length,
        0
    );
    assert.equal(
        proposeDestructiveChanges(
            findings,
            [removedCandidate],
            new Set(),
            new Map([['ApexClass:LegacyClass', ['force-app/example.cls']]])
        ).included.length,
        0
    );
    assert.equal(
        proposeDestructiveChanges(findings, [removedCandidate], new Set(['apexclass:legacyclass'])).included.length,
        0
    );
    const xml = buildDestructiveXml(proposal.included, '67.0');
    const { JSDOM } = require('jsdom');
    const parsed = new JSDOM(xml, { contentType: 'text/xml' });
    assert.equal(parsed.window.document.documentElement.namespaceURI, 'http://soap.sforce.com/2006/04/metadata');
    assert.equal(parsed.window.document.querySelector('members').textContent, 'LegacyClass');
    assert.equal(parsed.window.document.querySelector('name').textContent, 'ApexClass');
    parsed.window.close();
    assert.ok(
        buildDestructiveXml([{ metadataType: 'Layout', fullName: 'Account-Old & <Special>' }], '67.0').includes(
            'Account-Old &amp; &lt;Special&gt;'
        )
    );
    assert.ok(!buildDestructiveXml([], '67.0').includes('<types>'));
    assert.throws(() => buildDestructiveXml([], 'not-a-version'), /API version/);
    assert.throws(() => buildDestructiveXml([{ metadataType: 'ApexClass', fullName: '*' }], '67.0'), /Wildcard/);
    console.log('44 audit self-tests passed.');
} else if (process.argv[2] === '--export-log') {
    exportAuditLog();
} else if (process.argv[2] === '--destructive') {
    writeDestructiveProposal();
} else {
    main();
}
