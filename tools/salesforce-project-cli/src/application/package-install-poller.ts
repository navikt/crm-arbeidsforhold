import { setTimeout as wait } from 'node:timers/promises';
import type { EventSink } from '../domain/events.js';
import type { CommandResult } from '../infrastructure/command-runner.js';
import type { CommandRunner } from './refresh-dependencies.js';

const POLL_INTERVAL_MS = 15_000;
export const PACKAGE_INSTALL_STATUS_PROBE_TIMEOUT_MS = 10_000;

export interface PackageInstallPollerOptions {
    runCommand: CommandRunner;
    requestId: string;
    targetOrg?: string;
    projectDirectory: string;
    installationKey?: string;
    packageName: string;
    stepId: string;
    operationId: string;
    emit: EventSink;
    deadline: number;
    signal?: AbortSignal;
    isInstalled: () => Promise<boolean>;
}

export async function pollPackageInstall(options: PackageInstallPollerOptions): Promise<CommandResult> {
    let reportResult: CommandResult | undefined;
    while (Date.now() < options.deadline) {
        if (await options.isInstalled()) {
            options.emit({
                kind: 'progress',
                operationId: options.operationId,
                timestamp: new Date().toISOString(),
                stepId: options.stepId,
                step: 'Install package',
                message: `${options.packageName} is installed; finishing package step`
            });
            return reportResult ?? successfulProbeResult(options.requestId);
        }

        reportResult = await options.runCommand({
            executable: 'sf',
            arguments: [
                'package',
                'install',
                'report',
                '--request-id',
                options.requestId,
                ...(options.targetOrg === undefined ? [] : ['--target-org', options.targetOrg]),
                '--json'
            ],
            cwd: options.projectDirectory,
            timeoutMs: Math.min(PACKAGE_INSTALL_STATUS_PROBE_TIMEOUT_MS, Math.max(1, options.deadline - Date.now())),
            ...(options.installationKey === undefined ? {} : { secretValues: [options.installationKey] }),
            ...(options.signal === undefined ? {} : { signal: options.signal })
        });
        if (reportResult.failed || reportResult.canceled || reportResult.timedOut) return reportResult;

        const status = packageInstallStatus(reportResult);
        if (status === 'SUCCESS' || status === 'SUCCEEDED' || status === 'INSTALLED' || status === 'COMPLETED') return reportResult;
        if (status === 'ERROR' || status === 'FAILED' || status === 'CANCELED' || status === 'UNSUCCESSFUL') {
            return { ...reportResult, failed: true, exitCode: 1, error: `Salesforce package install reported ${status}` };
        }

        await wait(
            Math.min(POLL_INTERVAL_MS, Math.max(1, options.deadline - Date.now())),
            undefined,
            options.signal === undefined ? {} : { signal: options.signal }
        );
    }

    return {
        ...(reportResult ?? successfulProbeResult(options.requestId)),
        failed: true,
        timedOut: true,
        error: 'Package install report did not reach a terminal state before the deadline'
    };
}

function packageInstallStatus(result: CommandResult): string | undefined {
    try {
        const payload = JSON.parse(result.stdout) as { result?: Record<string, unknown> };
        const status = payload.result?.Status ?? payload.result?.status;
        return typeof status === 'string' ? status.toUpperCase() : undefined;
    } catch {
        return undefined;
    }
}

function successfulProbeResult(requestId: string): CommandResult {
    return {
        executable: 'sf',
        arguments: ['package', 'install', 'report', '--request-id', requestId, '--json'],
        exitCode: 0,
        stdout: JSON.stringify({ status: 0, result: { Status: 'SUCCESS' } }),
        stderr: '',
        durationMs: 0,
        failed: false,
        timedOut: false,
        canceled: false,
        attempts: 1
    };
}