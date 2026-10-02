import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it } from 'vitest';
import { runCli } from '../../src/cli-app.js';
import { EXIT_CODES } from '../../src/domain/events.js';

const temporaryDirectories: string[] = [];
const output = { stdout: () => undefined, stderr: () => undefined };

afterEach(async () => {
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

describe('CLI exit codes', () => {
    it('returns invalid-input for an unknown command', async () => {
        await expect(runCli(['unknown-command'], output)).resolves.toBe(EXIT_CODES.INVALID_INPUT_OR_CONFIG);
    });

    it('returns invalid-input for malformed project configuration', async () => {
        const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-invalid-config-'));
        temporaryDirectories.push(projectDirectory);
        await writeFile(path.join(projectDirectory, 'sfdx-project.json'), '{ invalid json');

        await expect(runCli(['dependencies', 'clear', '--project-dir', projectDirectory], output)).resolves.toBe(
            EXIT_CODES.INVALID_INPUT_OR_CONFIG
        );
    });

    it('returns missing-prerequisite when the Salesforce project file is absent', async () => {
        const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-missing-project-'));
        temporaryDirectories.push(projectDirectory);

        await expect(runCli(['dependencies', 'clear', '--project-dir', projectDirectory], output)).resolves.toBe(
            EXIT_CODES.MISSING_PREREQUISITE
        );
    });
});
