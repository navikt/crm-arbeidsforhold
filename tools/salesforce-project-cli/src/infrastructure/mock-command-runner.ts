import type { ProjectConfiguration } from '../domain/config.js';
import { normalizeConfiguredVersion } from '../domain/packages.js';
import type { CommandRequest, CommandResult } from './command-runner.js';

/** Creates deterministic Salesforce command responses without starting external processes. */
export function createMockCommandRunner(configuration: ProjectConfiguration): (request: CommandRequest) => Promise<CommandResult> {
    const dependenciesByAlias = new Map(
        configuration.packageDependencies
            .filter((dependency) => dependency.packageAlias !== undefined && dependency.configuredVersion !== undefined)
            .map((dependency) => [dependency.packageAlias as string, dependency] as const)
    );

    return async (request) => {
        const result = mockResult(request, mockPayload(request, dependenciesByAlias));
        return Promise.resolve(result);
    };
}

function mockPayload(
    request: CommandRequest,
    dependenciesByAlias: ReadonlyMap<string, ProjectConfiguration['packageDependencies'][number]>
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
    if (resource === 'package' && action === 'install' && subcommand === 'report') return { Status: 'SUCCESS' };
    if (resource === 'package' && action === 'install') return { Id: '0HfMOCKREQUEST', Status: 'IN_PROGRESS' };
    if (resource === 'org' && action === 'display') {
        return { alias: 'mock-org', orgType: 'scratch', connectedStatus: 'Connected' };
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