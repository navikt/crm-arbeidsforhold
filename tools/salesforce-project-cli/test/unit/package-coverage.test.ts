import { afterEach, describe, expect, it, vi } from 'vitest';
import { runPackageCoverageCheck } from '../../src/application/package-coverage.js';
import type { CommandRequest, CommandResult } from '../../src/infrastructure/command-runner.js';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { runCli } from '../../src/cli-app.js';

const temporaryDirectories: string[] = [];

afterEach(async () => {
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { recursive: true, force: true }))
    );
});

function result(request: CommandRequest, stdout = '', exitCode = 0): CommandResult {
    return {
        executable: request.executable,
        arguments: [...(request.arguments ?? [])],
        exitCode,
        failed: exitCode !== 0,
        stdout,
        stderr: '',
        durationMs: 1,
        timedOut: false,
        canceled: false,
        attempts: 1,
        error: ''
    };
}

describe('post-package coverage check', () => {
    it('installs, deploys, runs the selected test, and reports aggregate coverage', async () => {
        const requests: CommandRequest[] = [];
        const runCommand = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            if (request.arguments?.includes('query')) {
                return result(
                    request,
                    JSON.stringify({
                        status: 0,
                        result: { records: [{ covered: 80, uncovered: 20 }] }
                    })
                );
            }
            return result(request, '{"status":0,"result":{}}');
        });

        const summary = await runPackageCoverageCheck({
            targetOrg: 'scratch-org',
            projectDirectory: '/project',
            packageId: '04t-package',
            installationKey: 'secret-key',
            minimumCoverage: 75,
            testClass: 'SampleTest',
            runAllTests: false,
            skipInstall: false,
            skipDeploy: false,
            classNamePattern: "App'%",
            runCommand
        });

        expect(summary).toEqual({ covered: 80, uncovered: 20, percentage: 80, minimumCoverage: 75, passed: true });
        expect(requests.map((request) => request.arguments?.slice(0, 3))).toEqual([
            ['package', 'install', '--target-org'],
            ['project', 'deploy', 'start'],
            ['apex', 'run', 'test'],
            ['data', 'query', '--target-org']
        ]);
        expect(requests[0]?.secretValues).toEqual(['secret-key']);
        expect(requests[2]?.arguments).toContain('SampleTest');
        expect(requests[3]?.arguments?.some((argument) => argument.includes("LIKE 'App\\'%'"))).toBe(true);
        expect(requests[3]?.arguments?.some((argument) => argument.includes('ApexCodeCoverageAggregate'))).toBe(true);
    });

    it('returns a failed threshold result without hiding the measured percentage', async () => {
        const runCommand = vi.fn(async (request: CommandRequest) =>
            request.arguments?.includes('query')
                ? result(request, '{"status":0,"result":{"records":[{"covered":60,"uncovered":40}]}}')
                : result(request, '{"status":0,"result":{}}')
        );

        await expect(
            runPackageCoverageCheck({
                targetOrg: 'scratch-org',
                projectDirectory: '/project',
                minimumCoverage: 75,
                testClass: 'SampleTest',
                runAllTests: false,
                skipInstall: true,
                skipDeploy: true,
                runCommand
            })
        ).resolves.toEqual({ covered: 60, uncovered: 40, percentage: 60, minimumCoverage: 75, passed: false });
    });

    it('dry-run emits the full command plan without running external commands', async () => {
        const runCommand = vi.fn();

        const summary = await runPackageCoverageCheck({
            targetOrg: 'scratch-org',
            projectDirectory: '/project',
            packageId: '04t-package',
            minimumCoverage: 75,
            testClass: 'SampleTest',
            runAllTests: true,
            skipInstall: false,
            skipDeploy: false,
            dryRun: true,
            runCommand
        });

        expect(summary).toBeUndefined();
        expect(runCommand).not.toHaveBeenCalled();
    });

    it('can skip install and deploy while running all tests with async fallback', async () => {
        let runAllCount = 0;
        const requests: CommandRequest[] = [];
        const runCommand = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            const args = request.arguments ?? [];
            if (args[0] === 'apex' && args.includes('run')) {
                if (args.includes('--wait')) {
                    runAllCount += 1;
                    return result(request, 'test wait timed out', 1);
                }
                return result(request, '{"status":0,"result":{"testRunId":"707000000000001"}}');
            }
            if (args[0] === 'apex' && args.includes('get')) return result(request, 'Tests completed');
            if (args.includes('query'))
                return result(request, '{"status":0,"result":{"records":[{"covered":77,"uncovered":23}]}}');
            return result(request, '{"status":0,"result":{}}');
        });

        await expect(
            runPackageCoverageCheck({
                targetOrg: 'scratch-org',
                projectDirectory: '/project',
                minimumCoverage: 75,
                testClass: 'SampleTest',
                runAllTests: true,
                skipInstall: true,
                skipDeploy: true,
                runCommand
            })
        ).resolves.toMatchObject({ passed: true, percentage: 77 });

        expect(runAllCount).toBe(1);
        expect(requests.map((request) => request.arguments?.[0])).toEqual(['apex', 'apex', 'apex', 'data']);
        expect(requests[2]?.arguments).toContain('707000000000001');
    });

    it('fails when an Apex test command fails', async () => {
        const runCommand = vi.fn(async (request: CommandRequest) =>
            request.arguments?.[0] === 'apex' ? result(request, 'tests failed', 1) : result(request)
        );

        await expect(
            runPackageCoverageCheck({
                targetOrg: 'scratch-org',
                projectDirectory: '/project',
                minimumCoverage: 75,
                testClass: 'SampleTest',
                runAllTests: false,
                skipInstall: true,
                skipDeploy: true,
                runCommand
            })
        ).rejects.toThrow('tests failed');
    });

    it('exposes a non-mutating coverage plan through the terminal CLI', async () => {
        const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-coverage-cli-'));
        temporaryDirectories.push(projectDirectory);
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({ packageDirectories: [{ path: 'force-app' }] })
        );
        await writeFile(
            path.join(projectDirectory, 'sf-project.config.json'),
            JSON.stringify({ defaultOrgAlias: 'scratch-org' })
        );
        const runCommand = vi.fn();
        const stdout: string[] = [];
        const stderr: string[] = [];

        await expect(
            runCli(
                [
                    'coverage',
                    'check',
                    '--project-dir',
                    projectDirectory,
                    '--dry-run',
                    '--skip-install',
                    '--skip-deploy',
                    '--run-all'
                ],
                { stdout: (line) => stdout.push(line), stderr: (line) => stderr.push(line) },
                { runCommand }
            )
        ).resolves.toBe(0);

        expect(runCommand).not.toHaveBeenCalled();
        expect(stdout.join('\n')).toContain('Would run all Apex tests');
        expect(stdout.join('\n')).toContain('Would query aggregate Apex coverage');
        expect(stderr).toEqual([]);
    });
});
