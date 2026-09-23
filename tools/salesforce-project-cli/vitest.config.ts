import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        coverage: {
            provider: 'v8',
            include: ['src/**/*.ts'],
            exclude: ['src/cli.ts']
        },
        include: ['test/**/*.test.ts']
    }
});
