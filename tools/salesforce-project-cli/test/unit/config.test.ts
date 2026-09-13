import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it } from 'vitest';
import { loadProjectConfiguration } from '../../src/domain/config.js';

const temporaryDirectories: string[] = [];

afterEach(async () => {
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

describe('project configuration', () => {
    it('resolves scratch setup and pool defaults into the effective configuration', async () => {
        const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-config-'));
        temporaryDirectories.push(projectDirectory);
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({
                packageDirectories: [{ path: 'force-app' }]
            })
        );
        await writeFile(
            path.join(projectDirectory, 'sf-project.config.json'),
            JSON.stringify({
                schemaVersion: 1,
                defaultOrgAlias: 'scratch-org',
                scratchDefinition: 'config/custom-scratch.json',
                scratchDurationDays: 21,
                permissionSets: ['Permission_One'],
                dummyDataPlan: 'dummy-data/Plan.json',
                communityName: 'Aa-registeret',
                postSteps: ['permsets', 'data'],
                pool: { use: true, tag: 'team', devHub: 'dev-hub', fallbackToCreate: false }
            })
        );

        const configuration = await loadProjectConfiguration(projectDirectory);

        expect(configuration).toMatchObject({
            defaultOrgAlias: 'scratch-org',
            scratchDefinition: path.join(projectDirectory, 'config/custom-scratch.json'),
            scratchDurationDays: 21,
            permissionSets: ['Permission_One'],
            dummyDataPlan: path.join(projectDirectory, 'dummy-data/Plan.json'),
            communityName: 'Aa-registeret',
            postSteps: ['permsets', 'data'],
            pool: { use: true, tag: 'team', devHub: 'dev-hub', fallbackToCreate: false }
        });
    });

    it('uses portable scratch and pool defaults when host configuration is absent', async () => {
        const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-config-'));
        temporaryDirectories.push(projectDirectory);
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({
                packageDirectories: [{ path: 'force-app' }]
            })
        );

        const configuration = await loadProjectConfiguration(projectDirectory);

        expect(configuration).toMatchObject({
            scratchDefinition: path.join(projectDirectory, 'config/project-scratch-def.json'),
            scratchDurationDays: 14,
            permissionSets: [],
            dummyDataPlan: null,
            communityName: null,
            postSteps: ['deploy'],
            pool: { use: false, tag: 'dev', fallbackToCreate: true }
        });
    });

    it('rejects invalid scratch durations before a workflow can mutate resources', async () => {
        const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-config-'));
        temporaryDirectories.push(projectDirectory);
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({
                packageDirectories: [{ path: 'force-app' }]
            })
        );
        await writeFile(
            path.join(projectDirectory, 'sf-project.config.json'),
            JSON.stringify({
                schemaVersion: 1,
                scratchDurationDays: 31
            })
        );

        await expect(loadProjectConfiguration(projectDirectory)).rejects.toThrow();
    });
});
