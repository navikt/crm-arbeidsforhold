const { spawnSync } = require('node:child_process');

const REPOSITORY = 'navikt/crm-arbeidsforhold';
const ISSUE_TITLE = '[CI] Reusable scratch org needs attention';
const GUIDE_URL =
    'https://github.com/navikt/crm-arbeidsforhold/blob/main/docs/operations/reusable-scratch-org-validation.md';

function runGh(args) {
    const result = spawnSync('gh', args, { encoding: 'utf8', maxBuffer: 1024 * 1024 });
    if (result.error) throw new Error(`Could not run gh ${args[0]}: ${result.error.message}`);
    if (result.status !== 0) throw new Error(`gh ${args[0]} failed with exit code ${result.status}.`);
    return result.stdout.trim();
}

function findOpenIssue(run) {
    const response = run([
        'issue',
        'list',
        '--repo',
        REPOSITORY,
        '--state',
        'open',
        '--limit',
        '1000',
        '--json',
        'number,title'
    ]);
    let issues;
    try {
        issues = JSON.parse(response);
    } catch (error) {
        if (!(error instanceof SyntaxError)) throw error;
        throw new Error('Could not parse open CI scratch-org maintenance issues.');
    }
    if (!Array.isArray(issues)) throw new Error('Could not read open CI scratch-org maintenance issues.');
    const matches = issues.filter((issue) => issue.title === ISSUE_TITLE);
    if (matches.length > 1) throw new Error('More than one open CI scratch-org maintenance issue exists.');
    return matches[0] ?? null;
}

function createIssueBody(reason, runUrl) {
    if (typeof reason !== 'string' || !reason.trim() || /[\r\n]/.test(reason)) {
        throw new Error('A single-line replacement reason is required.');
    }
    if (
        runUrl !== undefined &&
        !/^https:\/\/github\.com\/navikt\/crm-arbeidsforhold\/actions\/runs\/\d+$/.test(runUrl)
    ) {
        throw new Error('Invalid maintenance Actions run URL.');
    }
    return [
        'The scheduled CI scratch-org check found that the registered org needs attention. Depending on the reason, the org may need to be replaced.',
        '',
        `**Reason:** ${reason}`,
        '',
        ...(runUrl ? [`**Maintenance run:** [View in GitHub Actions](${runUrl})`, ''] : []),
        'Review the maintenance run before replacing the org when the reason is a failed deploy or Apex smoke test; the failure may need a source fix instead.',
        '',
        `A repository admin from @navikt/crm-arbeidsforhold-admin should follow the [replacement guide](${GUIDE_URL}).`,
        '',
        'The workflow does not create scratch orgs or change GitHub Environment secrets or variables. PR validation continues to use its fresh-org fallback until the replacement is registered.'
    ].join('\n');
}

function syncMaintenanceIssue(action, reason, run = runGh, runUrl) {
    if (typeof run !== 'function') throw new Error('A GitHub CLI runner is required.');
    const issue = findOpenIssue(run);
    if (action === 'ensure') {
        const body = createIssueBody(reason, runUrl);
        if (issue) {
            run(['issue', 'edit', String(issue.number), '--repo', REPOSITORY, '--body', body]);
            return { action: 'updated', number: issue.number };
        }
        run(['issue', 'create', '--repo', REPOSITORY, '--title', ISSUE_TITLE, '--body', body]);
        return { action: 'created' };
    }
    if (action === 'resolve') {
        if (!issue) return { action: 'none' };
        run([
            'issue',
            'close',
            String(issue.number),
            '--repo',
            REPOSITORY,
            '--comment',
            'The scheduled CI scratch-org check is healthy again. Closing this maintenance notice.'
        ]);
        return { action: 'closed', number: issue.number };
    }
    throw new Error('Usage: ci-scratch-org-maintenance.cjs ensure <reason> | resolve');
}

function main(args) {
    if (args[0] === 'ensure' && (args.length === 2 || args.length === 3)) {
        const result = syncMaintenanceIssue('ensure', args[1], runGh, args[2]);
        process.stdout.write(
            `${result.action === 'created' ? 'Created' : 'Updated'} CI scratch-org maintenance issue.\n`
        );
        return;
    }
    if (args[0] === 'resolve' && args.length === 1) {
        const result = syncMaintenanceIssue('resolve');
        process.stdout.write(
            result.action === 'closed'
                ? 'Closed the resolved CI scratch-org maintenance issue.\n'
                : 'No open CI scratch-org maintenance issue exists.\n'
        );
        return;
    }
    throw new Error('Usage: ci-scratch-org-maintenance.cjs ensure <reason> | resolve');
}

if (require.main === module) {
    try {
        main(process.argv.slice(2));
    } catch (error) {
        console.error(error.message);
        process.exitCode = 1;
    }
}

module.exports = { createIssueBody, syncMaintenanceIssue };
