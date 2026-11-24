import { defineConfig, devices } from '@playwright/test';
import path from 'node:path';

const AUTH_DIRECTORY = path.join(__dirname, '.auth');

export default defineConfig({
    testDir: __dirname,
    testMatch: '**/*.spec.ts',
    globalSetup: require.resolve('./global-setup.ts'),
    outputDir: path.join(__dirname, 'test-results'),
    fullyParallel: false,
    workers: 1,
    retries: 0,
    timeout: 180_000,
    expect: { timeout: 45_000 },
    reporter: [['list'], ['html', { open: 'never', outputFolder: path.join(__dirname, 'playwright-report') }]],
    use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1440, height: 900 },
        locale: 'nb-NO',
        storageState: path.join(AUTH_DIRECTORY, 'admin.json'),
        screenshot: 'on',
        trace: 'retain-on-failure',
        navigationTimeout: 90_000
    }
});
