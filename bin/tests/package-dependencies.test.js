const assert = require('node:assert/strict');
const { test } = require('node:test');
const { checkDependencies, createProvider } = require('../package-dependencies');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');

function cliFixture(context, project, source) {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'dependency-output-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const file = path.join(directory, 'project.json');
    fs.writeFileSync(file, JSON.stringify(project));
    const fixture = path.join(directory, 'fake-cli.cjs');
    fs.writeFileSync(fixture, source);
    fs.writeFileSync(
        path.join(directory, process.platform === 'win32' ? 'sf.cmd' : 'sf'),
        process.platform === 'win32'
            ? `@echo off\r\n"${process.execPath}" "${fixture}" %*\r\n`
            : `#!/bin/sh\nexec '${process.execPath.replaceAll("'", "'\\''")}' '${fixture.replaceAll("'", "'\\''")}' "$@"\n`,
        { mode: 0o755 }
    );
    return {
        file,
        args: [path.resolve(__dirname, '../package-dependencies.js'), '--project-file', file],
        env: { ...process.env, NO_COLOR: '', FORCE_COLOR: '', PATH: directory + path.delimiter + process.env.PATH }
    };
}

function runSetupFixture(fixture, planFile, answer) {
    return spawnSync(
        process.execPath,
        [
            '-e',
            `const answers = ${JSON.stringify(Array.isArray(answer) ? answer : [answer])};
            require(process.argv[1]).runCli(process.argv.slice(2), {
            interactive: true,
            ask: async (prompt) => { console.log(prompt); return answers.shift() ?? 's'; }
        }).then(code => { process.exitCode = code; });`,
            ...fixture.args,
            '--plan-file',
            planFile
        ],
        { env: fixture.env, encoding: 'utf8' }
    );
}

test('shows the active metadata read and a timed heartbeat before a slow CLI completes', async (context) => {
    const fixture = cliFixture(
        context,
        {
            packageDirectories: [{ path: 'force-app', dependencies: [{ package: 'parent', versionNumber: '1.0.0.1' }] }]
        },
        `
        setTimeout(() => {
            console.log(JSON.stringify({status: 1, message: 'offline delayed failure'}));
            process.exitCode = 1;
        }, 5600);
    `
    );
    const child = spawn(process.execPath, fixture.args, { env: fixture.env });
    context.after(() => {
        if (child.exitCode === null) child.kill();
    });
    let output = '';
    let errors = '';
    let activeBeforeExit = false;
    let heartbeatBeforeExit = false;
    child.stdout.on('data', (chunk) => {
        output += chunk;
        if (output.includes('Reading released versions: parent')) activeBeforeExit = child.exitCode === null;
        if (/Still running: Reading released versions: parent \(\d+s\)/.test(output)) {
            heartbeatBeforeExit = child.exitCode === null;
        }
    });
    child.stderr.on('data', (chunk) => {
        errors += chunk;
    });
    const code = await new Promise((resolve, reject) => {
        child.on('error', reject);
        child.on('close', resolve);
    });
    assert.equal(code, 1);
    assert.equal(activeBeforeExit, true, output);
    assert.equal(heartbeatBeforeExit, true, output);
    assert.match(output, /\[1\/1\] parent/);
    assert.match(errors, /offline delayed failure/);
    assert.doesNotMatch(output + errors, /\x1b|\r(?!\n)/);
    assert.equal(fs.existsSync(`${fixture.file}.dependencies.backup`), false);
});

test('groups repeated version conflicts by dependency with readable versions and actionable summary', (context) => {
    const project = {
        packageDirectories: [
            {
                path: 'force-app',
                dependencies: [
                    { package: 'child', versionNumber: '1.0.0.1' },
                    { package: 'first', versionNumber: '1.0.0.1' },
                    { package: 'second', versionNumber: '1.0.0.1' }
                ]
            }
        ]
    };
    const fixture = cliFixture(
        context,
        project,
        `
        const args = process.argv.slice(2);
        const record = (id, packageId, major, dependencies = []) => ({
            SubscriberPackageVersionId: id, Package2Id: packageId,
            MajorVersion: major, MinorVersion: 0, PatchVersion: 0, BuildNumber: 1,
            SubscriberPackageVersion: { Dependencies: {ids: dependencies.map(subscriberPackageVersionId => ({subscriberPackageVersionId}))} }
        });
        const records = {
            child: record('selected-child', 'child-package', 1),
            first: record('first', 'first-package', 1, ['required-child']),
            second: record('second', 'second-package', 1, ['required-child']),
            'required-child': record('required-child', 'child-package', 2)
        };
        const result = args[2] === 'list' ? [records[args[args.indexOf('--packages') + 1]]]
            : records[args[args.indexOf('--package') + 1]] ?? records.child;
        console.log(JSON.stringify({status: 0, result}));
    `
    );
    const result = spawnSync(process.execPath, fixture.args, { env: fixture.env, encoding: 'utf8' });
    assert.equal(result.status, 1);
    const output = result.stdout + result.stderr;
    assert.match(output, /Version conflicts \(1 package, 2 requirements\)/);
    assert.equal((output.split('\nDependency graph')[0].match(/Package: child/g) ?? []).length, 1, output);
    assert.match(output, /Selected: 1\.0\.0\.1/);
    assert.match(output, /Required: 2\.0\.0\.1/);
    assert.match(output, /first 1\.0\.0\.1/);
    assert.match(output, /second 1\.0\.0\.1/);
    assert.match(output, /Next steps/);
    assert.match(output, /No files changed/);
    assert.match(output, /upgrade low versions/i);
    assert.match(output, /Missing packages: 0/);
    assert.match(output, /No missing package declarations were found/);
    assert.match(output, /Version differences: 1/);
    assert.match(output, /Dependency graph/);
    const report = fs.readFileSync(path.join(path.dirname(fixture.file), 'package-dependencies-report.md'), 'utf8');
    assert.match(report, /# Package dependency report/);
    assert.match(report, /```mermaid\nflowchart LR/);
    assert.match(report, /VERSION DIFF/);
    assert.match(report, /selected-child/);
    assert.match(report, /required-child/);
    assert.match(report, /not expanded/);
    const [fullGraph, packageGraphs] = report.split('## Dependency graphs per package');
    assert.equal((fullGraph.match(/ --> /g) ?? []).length, 2);
    assert.match(packageGraphs, /### force-app: first/);
    assert.match(packageGraphs, /### force-app: second/);
    assert.equal((packageGraphs.match(/ --> /g) ?? []).length, 2);
    assert.match(report, /\[Interactive HTML graph\]\(package-dependencies-report\.html\)/);
    const html = fs.readFileSync(path.join(path.dirname(fixture.file), 'package-dependencies-report.html'), 'utf8');
    assert.match(html, /<!doctype html>/i);
    assert.match(html, /Content-Security-Policy/);
    assert.doesNotMatch(html, /<script[^>]+src=|<link[^>]+href=|https?:\/\//);
    assert.equal((html.match(/class="edge" /g) ?? []).length, 2);
    assert.equal((html.match(/class="node /g) ?? []).length, 4);
    assert.match(html, /Requires \(outgoing/);
    assert.match(html, /Required by \(incoming/);
    assert.match(html, /selected 1.0.0.1/);
    assert.match(output, /\+-- child \[FAIL: VERSION TOO LOW\]/);
    assert.match(output, /Required: >= 2\.0\.0\.1; selected: 1\.0\.0\.1/);
    assert.doesNotMatch(output, /Manual version reconciliation required/);
    assert.ok(
        output.split(/\r?\n/).every((line) => line.length <= 100),
        output
    );
    for (const answer of ['s', 'c']) {
        const planFile = path.join(path.dirname(fixture.file), `conflict-${answer}.json`);
        const decision = runSetupFixture(fixture, planFile, answer);
        assert.equal(decision.status, answer === 'c' ? 0 : 1, decision.stdout + decision.stderr);
        const summary = decision.stdout.slice(decision.stdout.indexOf('Dependency issues requiring attention'));
        assert.match(summary, /ISSUE: Selected version is too low/);
        assert.match(summary, /Package: child \(force-app\)/);
        assert.match(summary, /Required minimum: 2\.0\.0\.1; selected: 1\.0\.0\.1/);
        assert.match(summary, /Required by: first 1\.0\.0\.1/);
        assert.match(summary, /Fix: upgrade the selected version to meet all required minimums/);
        assert.match(summary, /Continue unchanged: accept these issues; installation may fail/);
        assert.match(summary, /Stop: make no manifest changes and do not start setup/);
        assert.match(decision.stdout, /Continue unchanged.*Stop/);
        assert.match(decision.stdout, /\[f\] Apply/);
        assert.equal(fs.existsSync(planFile), answer === 'c');
        assert.equal(fs.existsSync(`${fixture.file}.dependencies.backup`), false);
        assert.deepEqual(JSON.parse(fs.readFileSync(fixture.file, 'utf8')), project);
        if (answer === 'c') assert.match(decision.stdout, /explicitly accepted.*Installation may still fail/);
    }
    for (const [index, input] of ['s\n', '\n', ''].entries()) {
        const planFile = path.join(path.dirname(fixture.file), `cancel-${index}.json`);
        const cancelled = spawnSync(
            process.execPath,
            [
                '-e',
                `process.stdin.isTTY = true;
            require(process.argv[1]).runCli(process.argv.slice(2)).then(code => { process.exitCode = code; });`,
                ...fixture.args,
                '--plan-file',
                planFile
            ],
            { env: fixture.env, encoding: 'utf8', input }
        );
        assert.equal(cancelled.status, 1, cancelled.stdout + cancelled.stderr);
        assert.match(cancelled.stdout, /Continue unchanged.*Stop/);
        assert.equal(fs.existsSync(planFile), false);
    }
    const upgradedPlan = path.join(path.dirname(fixture.file), 'upgraded.json');
    const upgraded = runSetupFixture(fixture, upgradedPlan, ['f', 's']);
    assert.equal(upgraded.status, 0, upgraded.stdout + upgraded.stderr);
    assert.match(upgraded.stdout, /Upgrade: child 1\.0\.0\.1 -> 2\.0\.0\.1/);
    assert.match(upgraded.stdout, /Autofix validation PASSED/);
    assert.deepEqual(JSON.parse(fs.readFileSync(`${fixture.file}.dependencies.backup`, 'utf8')), project);
    const updated = JSON.parse(fs.readFileSync(fixture.file, 'utf8'));
    assert.equal(
        updated.packageDirectories[0].dependencies.find((entry) => entry.package === 'child').versionNumber,
        '2.0.0.1'
    );
    assert.equal(JSON.parse(fs.readFileSync(upgradedPlan, 'utf8')).child.SubscriberPackageVersionId, 'required-child');
});

test('supports semantic colors, plain redirected logs and explicit color precedence', (context) => {
    const fixture = cliFixture(context, { packageDirectories: [] }, '');
    for (const { args, env, color } of [
        { args: [], env: {}, color: false },
        { args: ['--color'], env: { NO_COLOR: '1' }, color: true },
        { args: ['--no-color'], env: { FORCE_COLOR: '1' }, color: false },
        { args: [], env: { FORCE_COLOR: '1' }, color: true },
        { args: [], env: { FORCE_COLOR: '1', NO_COLOR: '1' }, color: false },
        { args: [], env: { FORCE_COLOR: '0' }, color: false }
    ]) {
        const result = spawnSync(process.execPath, [...fixture.args, ...args], {
            env: { ...fixture.env, ...env },
            encoding: 'utf8'
        });
        assert.equal(result.status, 0, result.stderr);
        assert.equal(/\x1b\[/.test(result.stdout), color, JSON.stringify({ args, env, output: result.stdout }));
        if (color) {
            assert.match(result.stdout, /\x1b\[1;36m/);
            assert.match(result.stdout, /\x1b\[32m/);
        }
        assert.match(result.stdout, /Missing packages: 0/);
    }
    const invalid = spawnSync(process.execPath, [...fixture.args, '--color', '--no-color'], {
        env: fixture.env,
        encoding: 'utf8'
    });
    assert.equal(invalid.status, 1);
    assert.match(invalid.stderr, /cannot be combined/);
});

test('highlights missing packages first and draws recursive and shared dependencies without dropping edges', (context) => {
    const project = {
        packageDirectories: [{ path: 'force-app', dependencies: [{ package: 'parent', versionNumber: '1.0.0.1' }] }],
        packageAliases: { child: 'child-package', leaf: 'leaf-package' }
    };
    const fixture = cliFixture(
        context,
        project,
        `
        const args = process.argv.slice(2);
        const record = (id, dependencies = []) => ({
            SubscriberPackageVersionId: id, Package2Id: id + '-package',
            MajorVersion: 1, MinorVersion: 0, PatchVersion: 0, BuildNumber: 1,
            SubscriberPackageVersion: { Dependencies: {ids: dependencies.map(subscriberPackageVersionId => ({subscriberPackageVersionId}))} }
        });
        const records = { parent: record('parent', ['child', 'leaf']), child: record('child', ['leaf']), leaf: record('leaf') };
        const result = args[2] === 'list' ? [records[args[args.indexOf('--packages') + 1]]]
            : records[args[args.indexOf('--package') + 1]];
        console.log(JSON.stringify({status: 0, result}));
    `
    );
    const result = spawnSync(process.execPath, [...fixture.args, '--color'], { env: fixture.env, encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.match(result.stdout, /\x1b\[31m[^\n]*MISSING/);
    const output = result.stdout.replace(/\x1b\[[0-9;]*m/g, '');
    assert.match(output, /Missing packages: 2/);
    assert.match(output, /Version differences: 0/);
    assert.ok(output.indexOf('Missing dependencies') < output.indexOf('Dependency graph'), output);
    assert.match(output, /parent 1\.0\.0\.1 \[PASS\]/);
    assert.match(output, /  \+-- child \[FAIL: MISSING\]/);
    assert.match(output, /  \|   \+-- child \[FAIL: MISSING\]/);
    assert.match(output, /  \|   \|   \+-- leaf \[FAIL: MISSING\]/);
    assert.match(output, /Required: >= 1\.0\.0\.1; selected: NOT DECLARED/);
    assert.doesNotMatch(output, /\(see above\)/);
    assert.match(output, /Required by:\n\s+- child 1\.0\.0\.1\n\s+- parent 1\.0\.0\.1/);
    assert.equal(fs.existsSync(`${fixture.file}.dependencies.backup`), false);
    assert.deepEqual(JSON.parse(fs.readFileSync(fixture.file, 'utf8')), project);
    const defaultReport = path.join(path.dirname(fixture.file), 'package-dependencies-report.md');
    const report = fs.readFileSync(defaultReport, 'utf8');
    assert.match(report, /Missing packages: 2/);
    assert.match(report, /## Missing dependencies/);
    assert.equal((report.split('## Dependency graphs per package')[0].match(/ --> /g) ?? []).length, 3);
    assert.equal((report.split('## Dependency graphs per package')[0].match(/:::missing/g) ?? []).length, 2);
    assert.doesNotMatch(report, /\x1b/);
    fs.writeFileSync(defaultReport, 'previous report');
    const customReport = path.join(path.dirname(fixture.file), 'custom report.md');
    const custom = spawnSync(process.execPath, [...fixture.args, '--report', customReport], {
        env: fixture.env,
        encoding: 'utf8'
    });
    assert.equal(custom.status, 1);
    assert.equal(fs.readFileSync(defaultReport, 'utf8'), 'previous report');
    assert.match(fs.readFileSync(customReport, 'utf8'), /```mermaid/);
    assert.match(fs.readFileSync(customReport, 'utf8'), /\[Interactive HTML graph\]\(custom%20report\.html\)/);
    assert.match(fs.readFileSync(customReport.replace(/\.md$/, '.html'), 'utf8'), /Dependency graph explorer/);
    const rerun = spawnSync(process.execPath, fixture.args, { env: fixture.env, encoding: 'utf8' });
    assert.equal(rerun.status, 1);
    assert.match(fs.readFileSync(defaultReport, 'utf8'), /# Package dependency report/);
    const failedWrite = spawnSync(
        process.execPath,
        [...fixture.args, '--report', path.join(path.dirname(fixture.file), 'absent/report.md')],
        { env: fixture.env, encoding: 'utf8' }
    );
    assert.equal(failedWrite.status, 1);
    assert.match(failedWrite.stderr, /ENOENT/);
    assert.equal(fs.existsSync(`${fixture.file}.dependencies.backup`), false);
    const protectedFile = spawnSync(process.execPath, [...fixture.args, '--report', fixture.file], {
        env: fixture.env,
        encoding: 'utf8'
    });
    assert.equal(protectedFile.status, 1);
    assert.match(protectedFile.stderr, /report.*\.md/i);
    assert.deepEqual(JSON.parse(fs.readFileSync(fixture.file, 'utf8')), project);
    const stoppedPlan = path.join(path.dirname(fixture.file), 'stopped.json');
    const stopped = runSetupFixture(fixture, stoppedPlan, 's');
    assert.equal(stopped.status, 1, stopped.stdout + stopped.stderr);
    assert.match(stopped.stdout, /ISSUE: Missing dependency declaration/);
    assert.match(stopped.stdout, /Package: child \(force-app\)/);
    assert.match(stopped.stdout, /Required minimum: 1\.0\.0\.1; selected: NOT DECLARED/);
    assert.match(stopped.stdout, /Fix: add the missing dependency to the manifest/);
    assert.match(stopped.stdout, /Apply safe fixes: upgrade low versions, add missing declarations and reorder/);
    assert.equal(fs.existsSync(stoppedPlan), false);
    assert.deepEqual(JSON.parse(fs.readFileSync(fixture.file, 'utf8')), project);
    const fixedPlan = path.join(path.dirname(fixture.file), 'fixed.json');
    const fixed = runSetupFixture(fixture, fixedPlan, 'f');
    assert.equal(fixed.status, 0, fixed.stdout + fixed.stderr);
    assert.match(fixed.stdout, /Apply safe fixes and continue/);
    assert.match(fixed.stdout, /Safe manifest fixes applied by request/);
    assert.deepEqual(JSON.parse(fs.readFileSync(`${fixture.file}.dependencies.backup`, 'utf8')), project);
    assert.deepEqual(
        JSON.parse(fs.readFileSync(fixture.file, 'utf8')).packageDirectories[0].dependencies.map(
            (entry) => entry.package
        ),
        ['leaf', 'child', 'parent']
    );
    const plan = JSON.parse(fs.readFileSync(fixedPlan, 'utf8'));
    assert.equal(plan.child.SubscriberPackageVersionId, 'child');
    assert.equal(plan.leaf.SubscriberPackageVersionId, 'leaf');
    const recheck = spawnSync(process.execPath, fixture.args, { env: fixture.env, encoding: 'utf8' });
    assert.equal(recheck.status, 0, recheck.stdout + recheck.stderr);
});

test('escapes untrusted package labels in Markdown and Mermaid reports', (context) => {
    const name = 'pkg["<script>|`unsafe';
    const fixture = cliFixture(
        context,
        {
            packageDirectories: [
                { path: 'force-app', dependencies: [{ package: 'parent', versionNumber: '1.0.0.1' }] }
            ],
            packageAliases: { [name]: 'child-package' }
        },
        `
        if (process.argv.slice(2).some(argument => argument.includes('unsafe'))) {
            console.error('Report labels must come from metadata, not shell arguments.');
            process.exit(1);
        }
        const child = { SubscriberPackageVersionId: 'child', Package2Id: 'child-package',
            MajorVersion: 1, MinorVersion: 0, PatchVersion: 0, BuildNumber: 1,
            SubscriberPackageVersion: { Dependencies: null } };
        const parent = { ...child, SubscriberPackageVersionId: 'root', Package2Id: 'parent-package',
            SubscriberPackageVersion: { Dependencies: { ids: [{ subscriberPackageVersionId: 'child' }] } } };
        const args = process.argv.slice(2);
        const result = args[2] === 'list' ? [parent] : args[args.indexOf('--package') + 1] === 'root' ? parent : child;
        console.log(JSON.stringify({status: 0, result}));
    `
    );
    const result = spawnSync(process.execPath, fixture.args, { env: fixture.env, encoding: 'utf8' });
    assert.equal(result.status, 1, result.stderr);
    assert.match(result.stdout, /Missing packages: 1/);
    assert.doesNotMatch(result.stderr, /Report labels must come from metadata/);
    const report = fs.readFileSync(path.join(path.dirname(fixture.file), 'package-dependencies-report.md'), 'utf8');
    assert.doesNotMatch(report, /<script>/);
    assert.match(report, /#34;/);
    assert.match(report, /&#124;/);
    const html = fs.readFileSync(path.join(path.dirname(fixture.file), 'package-dependencies-report.html'), 'utf8');
    assert.equal((html.match(/<script>/g) ?? []).length, 1);
    assert.match(html, /&lt;script&gt;/);
    assert.match(html, /&quot;/);
});

const version = (id, packageId, dependencies = []) => ({
    SubscriberPackageVersionId: id,
    Package2Id: packageId,
    MajorVersion: 1,
    MinorVersion: 0,
    PatchVersion: 0,
    BuildNumber: 1,
    SubscriberPackageVersion: {
        Dependencies: { ids: dependencies.map((subscriberPackageVersionId) => ({ subscriberPackageVersionId })) }
    }
});

function scenario(dependencies = [{ package: 'parent', versionNumber: '1.0.0.LATEST' }]) {
    const project = {
        packageDirectories: [{ path: 'force-app', dependencies }],
        packageAliases: { parent: 'parent-package', child: 'child-package' }
    };
    const reports = {
        parent: version('parent', 'parent-package', ['child']),
        child: version('child', 'child-package')
    };
    const provider = {
        resolve: (dependency) => (dependency.package === 'parent' ? 'parent' : 'child'),
        report: (id) => {
            if (!reports[id]) throw new Error(`Unknown version ${id}`);
            return reports[id];
        },
        name: (id) => (id === 'parent-package' ? 'parent' : 'child')
    };
    return { project, reports, provider };
}

test('reports a missing indirect dependency with its requiring package and exact version', async () => {
    const { project, provider } = scenario();
    const result = await checkDependencies(project, provider);
    assert.equal(result.valid, false);
    assert.match(result.errors.join('\n'), /parent.*child.*1\.0\.0\.1/);
    assert.deepEqual(
        result.project.packageDirectories[0].dependencies.map((entry) => entry.package),
        ['child', 'parent']
    );
    assert.equal(project.packageDirectories[0].dependencies.length, 1);
    assert.equal(result.fixable, true);
});

test('accepts a complete dependency-first manifest', async () => {
    const { project, provider } = scenario([{ package: 'child' }, { package: 'parent' }]);
    assert.equal((await checkDependencies(project, provider)).valid, true);
});

test('CLI passes higher selected versions and preserves the selected installation plan', (context) => {
    const { project, reports } = scenario([
        { package: 'child', versionNumber: '1.0.0.10' },
        { package: 'parent', versionNumber: '1.0.0.1' }
    ]);
    reports['selected-child'] = version('selected-child', 'child-package');
    reports['selected-child'].BuildNumber = 10;
    reports.child.BuildNumber = 2;
    const fixture = cliFixture(
        context,
        project,
        `
        const records = ${JSON.stringify(reports)};
        const args = process.argv.slice(2);
        const name = args[args.indexOf('--packages') + 1];
        const result = args[2] === 'list' ? [records[name === 'child' ? 'selected-child' : name]]
            : records[args[args.indexOf('--package') + 1]];
        console.log(JSON.stringify({status: 0, result}));
    `
    );
    const planFile = path.join(path.dirname(fixture.file), 'plan.json');
    const result = spawnSync(process.execPath, [...fixture.args, '--plan-file', planFile], {
        env: fixture.env,
        encoding: 'utf8'
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(result.stdout, /Dependency preflight PASSED/);
    assert.match(result.stdout, /Version differences: 0/);
    assert.match(result.stdout, /Higher selected versions: 1 \(PASS; review recommended\)/);
    assert.match(result.stdout, /Required: 1\.0\.0\.2 -> Selected: 1\.0\.0\.10 -> PASS; review recommended/);
    assert.match(
        result.stdout,
        /\+-- child \[PASS: HIGHER VERSION\]\n\s*\|\s+\|\s+Required: >= 1\.0\.0\.2; selected: 1\.0\.0\.10/
    );
    assert.match(result.stdout, /parent 1\.0\.0\.1 \[PASS\]/);
    assert.doesNotMatch(result.stdout, /\x1b/);
    const colored = spawnSync(process.execPath, [...fixture.args, '--color'], {
        env: fixture.env,
        encoding: 'utf8'
    });
    assert.equal(colored.status, 0, colored.stderr);
    assert.match(colored.stdout, /\x1b\[1;35m[^\n]*\[PASS: HIGHER VERSION\]/);
    assert.match(colored.stdout, /\x1b\[32m[^\n]*parent 1\.0\.0\.1 \[PASS\]/);
    assert.doesNotMatch(colored.stdout, /\x1b\[(?:1;)?33m/);
    assert.equal(JSON.parse(fs.readFileSync(planFile, 'utf8')).child.SubscriberPackageVersionId, 'selected-child');
    assert.deepEqual(JSON.parse(fs.readFileSync(fixture.file, 'utf8')), project);
    const report = fs.readFileSync(path.join(path.dirname(fixture.file), 'package-dependencies-report.md'), 'utf8');
    assert.match(report, /Higher selected versions \(PASS; review recommended\)/);
    assert.match(report, /1\.0\.0\.2.*1\.0\.0\.10.*PASS; review recommended/);
    const html = fs.readFileSync(path.join(path.dirname(fixture.file), 'package-dependencies-report.html'), 'utf8');
    assert.match(html, /PASS; review recommended/);
    for (const answer of ['c', 's', '']) {
        const interactivePlan = path.join(path.dirname(fixture.file), `interactive-${answer || 'default'}.json`);
        const interactive = runSetupFixture(fixture, interactivePlan, answer);
        assert.equal(interactive.status, 0, interactive.stdout + interactive.stderr);
        assert.doesNotMatch(interactive.stdout, /Continue unchanged.*Stop|Setup decision required/);
        assert.match(interactive.stdout, /Higher selected versions are informational only; no decision is required/);
        assert.equal(fs.existsSync(interactivePlan), true);
        assert.deepEqual(JSON.parse(fs.readFileSync(fixture.file, 'utf8')), project);
    }
    for (const [index, input] of ['s\n', '\n', ''].entries()) {
        const pipedPlan = path.join(path.dirname(fixture.file), `piped-output-${index}.json`);
        const piped = spawnSync(
            process.execPath,
            [
                '-e',
                `process.stdin.isTTY = true;
            require(process.argv[1]).runCli(process.argv.slice(2)).then(code => { process.exitCode = code; });`,
                ...fixture.args,
                '--plan-file',
                pipedPlan
            ],
            { env: fixture.env, encoding: 'utf8', input }
        );
        assert.equal(piped.status, 0, piped.stdout + piped.stderr);
        assert.doesNotMatch(piped.stdout, /Continue unchanged.*Stop/);
        assert.equal(fs.existsSync(pipedPlan), true);
    }
});

test('autofix resolves highest minimums recursively without downgrades or partial writes', (context) => {
    for (const brokenMetadata of [false, true]) {
        const project = {
            packageDirectories: [
                {
                    path: 'force-app',
                    dependencies: [
                        { package: 'leaf', versionNumber: '1.0.0.2' },
                        { package: 'child', versionNumber: '1.0.0.1' },
                        { package: 'higher', versionNumber: '1.0.0.10' },
                        { package: 'parent', versionNumber: '1.0.0.1' },
                        { package: 'second', versionNumber: '1.0.0.1' }
                    ]
                }
            ],
            packageAliases: { obsolete: 'obsolete-package', added: 'added-package' }
        };
        const records = {
            'old-leaf': { ...version('old-leaf', 'leaf-package'), BuildNumber: 2 },
            'new-leaf': { ...version('new-leaf', 'leaf-package'), BuildNumber: 10 },
            'old-child': version('old-child', 'child-package', ['obsolete']),
            'child-two': { ...version('child-two', 'child-package'), MajorVersion: 2 },
            'child-three': { ...version('child-three', 'child-package', ['new-leaf', 'added']), MajorVersion: 3 },
            higher: { ...version('higher', 'higher-package'), BuildNumber: 10 },
            'required-higher': { ...version('required-higher', 'higher-package'), BuildNumber: 2 },
            parent: version('parent', 'parent-package', ['child-two', 'required-higher']),
            second: version('second', 'second-package', ['child-three']),
            obsolete: version('obsolete', 'obsolete-package'),
            added: version('added', 'added-package')
        };
        if (brokenMetadata) delete records['child-three'].SubscriberPackageVersion;
        const fixture = cliFixture(
            context,
            project,
            `
            const records = ${JSON.stringify(records)};
            const selected = { leaf: 'old-leaf', child: 'old-child', higher: 'higher', parent: 'parent', second: 'second' };
            const args = process.argv.slice(2);
            const result = args[2] === 'list' ? [records[selected[args[args.indexOf('--packages') + 1]]]]
                : records[args[args.indexOf('--package') + 1]];
            console.log(JSON.stringify({status: 0, result}));
        `
        );
        const planFile = path.join(path.dirname(fixture.file), 'autofix.json');
        const result = spawnSync(process.execPath, [...fixture.args, '--apply', '--plan-file', planFile], {
            env: fixture.env,
            encoding: 'utf8'
        });
        const output = result.stdout + result.stderr;
        assert.equal(result.status, brokenMetadata ? 1 : 0, output);
        if (brokenMetadata) {
            assert.deepEqual(JSON.parse(fs.readFileSync(fixture.file, 'utf8')), project);
            assert.equal(fs.existsSync(`${fixture.file}.dependencies.backup`), false);
            assert.equal(fs.existsSync(planFile), false);
            continue;
        }
        const updated = JSON.parse(fs.readFileSync(fixture.file, 'utf8'));
        const dependencies = updated.packageDirectories[0].dependencies;
        const plan = JSON.parse(fs.readFileSync(planFile, 'utf8'));
        assert.equal(dependencies.find((entry) => entry.package === 'child').versionNumber, '3.0.0.1');
        assert.equal(dependencies.find((entry) => entry.package === 'leaf').versionNumber, '1.0.0.10');
        assert.equal(dependencies.find((entry) => entry.package === 'higher').versionNumber, '1.0.0.10');
        assert.equal(
            dependencies.some((entry) => entry.package === 'obsolete'),
            false
        );
        assert.equal(
            dependencies.some((entry) => entry.package === 'added'),
            true
        );
        const order = dependencies.map((entry) => entry.package);
        assert.ok(order.indexOf('leaf') < order.indexOf('child'));
        assert.ok(order.indexOf('added') < order.indexOf('child'));
        assert.ok(order.indexOf('child') < order.indexOf('parent'));
        assert.equal(plan.child.SubscriberPackageVersionId, 'child-three');
        assert.equal(plan.leaf.SubscriberPackageVersionId, 'new-leaf');
        assert.equal(plan.added.SubscriberPackageVersionId, 'added');
        assert.equal(plan.higher.SubscriberPackageVersionId, 'higher');
        assert.deepEqual(JSON.parse(fs.readFileSync(`${fixture.file}.dependencies.backup`, 'utf8')), project);
        assert.equal((output.match(/Reading dependency metadata: child-three/g) ?? []).length, 1);
    }
});

test('accepts selected versions at or above requirements using all four numeric components', async () => {
    for (const [selected, required] of [
        [
            [1, 0, 0, 1],
            [1, 0, 0, 1]
        ],
        [
            [2, 0, 0, 1],
            [1, 9, 9, 9]
        ],
        [
            [1, 10, 0, 1],
            [1, 2, 9, 9]
        ],
        [
            [1, 0, 10, 1],
            [1, 0, 2, 9]
        ],
        [
            [1, 0, 0, 10],
            [1, 0, 0, 2]
        ]
    ]) {
        const { project, reports, provider } = scenario([{ package: 'child' }, { package: 'parent' }]);
        reports['selected-child'] = version('selected-child', 'child-package');
        for (const [index, key] of ['MajorVersion', 'MinorVersion', 'PatchVersion', 'BuildNumber'].entries()) {
            reports['selected-child'][key] = selected[index];
            reports.child[key] = required[index];
        }
        provider.resolve = (entry) => (entry.package === 'child' ? 'selected-child' : 'parent');
        const result = await checkDependencies(project, provider);
        assert.equal(result.valid, true, `${selected.join('.')} must satisfy ${required.join('.')}`);
        assert.deepEqual(result.issues, []);
        assert.equal(result.reviews.length, selected.join('.') === required.join('.') ? 0 : 1);
        assert.equal(result.graphs[0].nodes.get('child').status, 'OK');
        assert.equal(result.versions.child.SubscriberPackageVersionId, 'selected-child');
        assert.equal(result.project.packageDirectories[0].dependencies.length, 2);
    }
});

test('checks the selected higher version dependencies rather than obsolete requirements', async () => {
    const { project, reports, provider } = scenario([{ package: 'child' }, { package: 'parent' }]);
    reports['selected-child'] = version('selected-child', 'child-package', ['leaf']);
    reports['selected-child'].MinorVersion = 1;
    reports.child.SubscriberPackageVersion.Dependencies.ids.push({ subscriberPackageVersionId: 'obsolete' });
    reports.leaf = version('leaf', 'leaf-package');
    provider.resolve = (entry) => (entry.package === 'child' ? 'selected-child' : 'parent');
    provider.name = () => 'leaf';
    const result = await checkDependencies(project, provider);
    assert.equal(result.valid, false);
    assert.deepEqual(
        result.issues.map((issue) => [issue.type, issue.package]),
        [['missing', 'leaf']]
    );
    assert.deepEqual(
        result.project.packageDirectories[0].dependencies.map((entry) => entry.package),
        ['leaf', 'child', 'parent']
    );
});

test('detects incorrect order and proposes dependency-first order', async () => {
    const { project, provider } = scenario([{ package: 'parent' }, { package: 'child' }]);
    const result = await checkDependencies(project, provider);
    assert.match(result.errors.join('\n'), /order/i);
    assert.deepEqual(
        result.project.packageDirectories[0].dependencies.map((entry) => entry.package),
        ['child', 'parent']
    );
});

test('recurses beyond a single dependency level and detects cycles', async () => {
    const { project, reports, provider } = scenario();
    reports.child.SubscriberPackageVersion.Dependencies.ids.push({ subscriberPackageVersionId: 'parent' });
    await assert.rejects(() => checkDependencies(project, provider), /cycle/i);
});

test('fails closed if dependency metadata is missing or a report fails', async () => {
    const { project, reports, provider } = scenario();
    delete reports.parent.SubscriberPackageVersion;
    await assert.rejects(() => checkDependencies(project, provider), /dependency metadata/i);
    provider.report = () => {
        throw new Error('offline permission failure');
    };
    await assert.rejects(() => checkDependencies(project, provider), /offline permission failure/);
});

test('rejects selected versions below requirements without silently replacing them', async () => {
    for (const [selected, required] of [
        [
            [1, 9, 9, 9],
            [2, 0, 0, 1]
        ],
        [
            [1, 2, 9, 9],
            [1, 10, 0, 1]
        ],
        [
            [1, 0, 2, 9],
            [1, 0, 10, 1]
        ],
        [
            [1, 0, 0, 2],
            [1, 0, 0, 10]
        ]
    ]) {
        const { project, reports, provider } = scenario([{ package: 'child' }, { package: 'parent' }]);
        provider.resolve = (entry) => (entry.package === 'child' ? 'other-child' : 'parent');
        reports['other-child'] = version('other-child', 'child-package');
        for (const [index, key] of ['MajorVersion', 'MinorVersion', 'PatchVersion', 'BuildNumber'].entries()) {
            reports['other-child'][key] = selected[index];
            reports.child[key] = required[index];
        }
        const result = await checkDependencies(project, provider);
        assert.equal(result.valid, false, `${selected.join('.')} must not satisfy ${required.join('.')}`);
        assert.equal(result.fixable, true);
        assert.match(result.errors.join('\n'), /version mismatch/i);
        assert.equal(result.versions.child.SubscriberPackageVersionId, 'other-child');
    }
});

test('checks every package directory separately and keeps unrelated project fields', async () => {
    const { project, provider } = scenario([{ package: 'child' }, { package: 'parent' }]);
    project.sourceApiVersion = '67.0';
    project.packageDirectories.push({ path: 'second', dependencies: [{ package: 'parent' }] });
    const result = await checkDependencies(project, provider);
    assert.equal(result.valid, false);
    assert.equal(result.project.sourceApiVersion, '67.0');
    assert.equal(result.project.packageDirectories[1].dependencies[0].package, 'child');
});

test('visits three levels, deduplicates shared dependencies and pins checked versions', async () => {
    const { project, reports, provider } = scenario();
    reports.child.SubscriberPackageVersion.Dependencies.ids.push({ subscriberPackageVersionId: 'leaf' });
    reports.leaf = version('leaf', 'leaf-package');
    provider.name = (id) => (id === 'leaf-package' ? 'leaf' : 'child');
    const result = await checkDependencies(project, provider);
    assert.deepEqual(
        result.project.packageDirectories[0].dependencies.map((entry) => entry.package),
        ['leaf', 'child', 'parent']
    );
    assert.equal(result.versions.parent.SubscriberPackageVersionId, 'parent');
    assert.equal(result.versions.parent.VersionNumber, '1.0.0.1');
});

test('rejects conflicting declarations across directories and malformed dependency IDs', async () => {
    const { project, reports, provider } = scenario();
    project.packageDirectories.push({
        path: 'second',
        dependencies: [{ package: 'parent', versionNumber: '2.0.0.1' }]
    });
    reports.new = version('new', 'parent-package');
    provider.resolve = (entry) => (entry.versionNumber === '2.0.0.1' ? 'new' : 'parent');
    await assert.rejects(() => checkDependencies(project, provider), /conflicting versions/i);
    project.packageDirectories.pop();
    reports.parent.SubscriberPackageVersion.Dependencies.ids = [{}];
    await assert.rejects(() => checkDependencies(project, provider), /invalid dependency metadata/i);
});

test('resolves numeric builds and LATEST numerically, not lexicographically', async () => {
    const records = [version('ten', 'pkg'), version('two', 'pkg')];
    records[0].BuildNumber = 10;
    records[1].BuildNumber = 2;
    const calls = [];
    const provider = createProvider(
        {},
        (args) => {
            if (args[2] === 'report') return records[1];
            calls.push(args);
            return records;
        },
        false
    );
    assert.equal(await provider.resolve({ package: 'parent', versionNumber: '1.0.0.LATEST' }), 'ten');
    assert.equal(await provider.resolve({ package: 'parent', versionNumber: '1.0.0.2' }), 'two');
    await assert.rejects(
        () => provider.resolve({ package: 'parent', versionNumber: '2.0.0.LATEST' }),
        /Cannot resolve/
    );
    assert.ok(calls.every((args) => args.includes('--released')));
    const selected = await provider.report('two');
    assert.equal(selected.SubscriberPackageVersionId, 'two');
    assert.equal(selected.LatestVersion.SubscriberPackageVersionId, 'ten');
    assert.equal(selected.LatestVersion.VersionNumber, '1.0.0.10');
});

test('does not guess an unavailable package name or dependency graph', async () => {
    const provider = createProvider({}, () => [], false);
    await assert.rejects(() => provider.name('unavailable'), /Dev Hub access/);
    await assert.rejects(() => provider.resolve({ package: 'parent' }), /missing versionNumber/);
});

test('actual CLI surfaces JSON failures instead of misleading plugin warnings', (context) => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'dependency-cli-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const project = path.join(directory, 'project with spaces ø.json');
    const report = path.join(directory, 'package-dependencies-report.md');
    fs.writeFileSync(report, 'previous completed report');
    const htmlReport = path.join(directory, 'package-dependencies-report.html');
    fs.writeFileSync(htmlReport, 'previous completed HTML report');
    fs.writeFileSync(project, JSON.stringify(scenario().project));
    const fixture = path.join(directory, 'fake-cli.cjs');
    fs.writeFileSync(
        fixture,
        `
        console.error('synthetic plugin warning');
        console.log(JSON.stringify({status: 1, message: 'offline metadata permission denied'}));
        process.exit(1);
    `
    );
    const wrapper = process.platform === 'win32' ? 'sf.cmd' : 'sf';
    fs.writeFileSync(
        path.join(directory, wrapper),
        process.platform === 'win32'
            ? `@echo off\r\n"${process.execPath}" "${fixture}" %*\r\n`
            : `#!/bin/sh\nexec '${process.execPath.replaceAll("'", "'\\''")}' '${fixture.replaceAll("'", "'\\''")}' "$@"\n`,
        { mode: 0o755 }
    );
    const result = spawnSync(
        process.execPath,
        [path.resolve(__dirname, '../package-dependencies.js'), '--project-file', project],
        {
            encoding: 'utf8',
            env: { ...process.env, PATH: directory + path.delimiter + process.env.PATH }
        }
    );
    assert.equal(result.status, 1);
    assert.match(result.stderr, /offline metadata permission denied/);
    assert.doesNotMatch(result.stderr, /synthetic plugin warning/);
    assert.equal(fs.existsSync(`${project}.dependencies.backup`), false);
    assert.equal(fs.readFileSync(report, 'utf8'), 'previous completed report');
    assert.equal(fs.readFileSync(htmlReport, 'utf8'), 'previous completed HTML report');
});
