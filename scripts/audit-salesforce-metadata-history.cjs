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

function main() {
    const ref = process.argv[2] || 'origin/main';
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
    console.log('13 audit self-tests passed.');
} else {
    main();
}
