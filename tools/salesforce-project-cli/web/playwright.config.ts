import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
    testDir: './e2e',
    outputDir: '../test-results/playwright',
    reporter: 'line',
    use: {
        baseURL: 'http://127.0.0.1:4178',
        reducedMotion: 'reduce',
        trace: 'retain-on-failure'
    },
    webServer: {
        command: 'npm run build:web && tsx web/e2e/fake-server.ts',
        cwd: '..',
        url: 'http://127.0.0.1:4178/api/v1/health',
        reuseExistingServer: false
    },
    projects: [
        {
            name: 'desktop',
            use: { ...devices['Desktop Chrome'], channel: 'chrome', viewport: { width: 1440, height: 1000 } }
        },
        {
            name: 'mobile',
            use: { ...devices['iPhone 13'], browserName: 'chromium', channel: 'chrome' }
        }
    ]
});
