import type { ProjectConfiguration } from '../domain/config.js';
import { normalizeConfiguredVersion } from '../domain/packages.js';
import type { CommandRequest, CommandResult } from './command-runner.js';

/** Deterministic failure modes available to local mock-backed operation tests. */
export type MockScenario = 'success' | 'failure' | 'timeout' | 'retry' | 'partial';

/** Creates deterministic Salesforce command responses without starting external processes. */
export function createMockCommandRunner(
    configuration: ProjectConfiguration,
    scenario: MockScenario = 'success'
): (request: CommandRequest) => Promise<CommandResult> {
    const dependenciesByAlias = new Map(
        configuration.packageDependencies
            .filter((dependency) => dependency.packageAlias !== undefined && dependency.configuredVersion !== undefined)
            .map((dependency) => [dependency.packageAlias as string, dependency] as const)
    );

    let installCount = 0;
    return async (request) => {
        const isInstallRequest =
            request.arguments?.[0] === 'package' &&
            request.arguments?.[1] === 'install' &&
            request.arguments?.[2] !== 'report';
        if (isInstallRequest) installCount += 1;
        const result = mockResult(request, mockPayload(request, dependenciesByAlias, scenario, installCount));
        if (scenario === 'retry' && isInstallRequest && installCount === 1) {
            const transientFailure = { ...result, exitCode: 1, failed: true, stderr: 'ECONNRESET', error: 'Mock transient failure' };
            request.retry?.onRetry?.(transientFailure, 2, request.retry.delayMs ?? 0);
            return { ...result, attempts: 2 };
        }
        if (scenario === 'timeout' && request.arguments?.[1] === 'install' && request.arguments?.[2] === 'report') {
            return { ...result, failed: true, timedOut: true, error: 'Mock timeout' };
        }
        return Promise.resolve(result);
    };
}

function mockPayload(
    request: CommandRequest,
    dependenciesByAlias: ReadonlyMap<string, ProjectConfiguration['packageDependencies'][number]>,
    scenario: MockScenario,
    installCount: number
): unknown {
    const [resource, action, subcommand] = request.arguments ?? [];
    if (resource === 'package' && action === 'installed' && subcommand === 'list') return [];
    if (resource === 'package' && action === 'version' && subcommand === 'list') {
        const alias = valueAfter(request.arguments, '--packages');
        const dependency = alias === undefined ? undefined : dependenciesByAlias.get(alias);
        const version = dependency?.configuredVersion === undefined ? '1.0.0.1' : mockVersion(dependency.configuredVersion);
        return [
            {
                MajorVersion: version[0],
                MinorVersion: version[1],
                PatchVersion: version[2],
                BuildNumber: version[3],
                SubscriberPackageVersionId: `04tMOCK${String(alias ?? 'package').replace(/[^a-zA-Z0-9]/g, '').slice(0, 12)}`
            }
        ];
    }
    if (resource === 'package' && action === 'install' && subcommand === 'report') {
        if (scenario === 'failure' || (scenario === 'partial' && installCount > 1)) return { Status: 'ERROR' };
        return { Status: 'SUCCESS' };
    }
    if (resource === 'package' && action === 'install') return { Id: '0HfMOCKREQUEST', Status: 'IN_PROGRESS' };
    if (resource === 'org' && action === 'display') {
        return { alias: 'mock-org', orgType: 'scratch', connectedStatus: 'Connected' };
    }
    if (resource === 'org' && action === 'list') {
        const expirationDate = new Date();
        expirationDate.setUTCDate(expirationDate.getUTCDate() + 30);
        return {
            scratchOrgs: [
                {
                    alias: 'mock-org',
                    username: 'mock@example.test',
                    orgId: '00DMOCK00000001',
                    status: 'Active',
                    connectedStatus: 'Connected',
                    instanceUrl: 'https://mock.example.test',
                    expirationDate: expirationDate.toISOString().slice(0, 10),
                    isDefaultUsername: true,
                    tracksSource: true
                }
            ],
            nonScratchOrgs: []
        };
    }
    return {};
}

function mockVersion(configuredVersion: string): [number, number, number, number] {
    const normalized = normalizeConfiguredVersion(configuredVersion).split('.').map(Number);
    return [normalized[0] ?? 1, normalized[1] ?? 0, normalized[2] ?? 0, normalized[3] ?? 1];
}

function valueAfter(arguments_: readonly string[] | undefined, flag: string): string | undefined {
    const index = arguments_?.indexOf(flag) ?? -1;
    return index < 0 ? undefined : arguments_?.[index + 1];
}

function mockResult(request: CommandRequest, payload: unknown): CommandResult {
    return {
        executable: request.executable,
        arguments: [...(request.arguments ?? [])],
        exitCode: 0,
        stdout: JSON.stringify({ status: 0, result: payload }),
        stderr: '',
        durationMs: 0,
        failed: false,
        timedOut: false,
        canceled: false,
        attempts: 1
    };
}