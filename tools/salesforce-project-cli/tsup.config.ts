import { defineConfig } from 'tsup';

export default defineConfig({
    entry: ['src/cli.ts', 'src/index.ts'],
    clean: true,
    dts: true,
    format: ['esm'],
    sourcemap: false,
    splitting: false,
    banner: {
        js: '#!/usr/bin/env node'
    }
});
