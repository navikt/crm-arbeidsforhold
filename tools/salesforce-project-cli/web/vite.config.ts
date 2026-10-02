import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
    root: import.meta.dirname,
    plugins: [react()],
    build: {
        outDir: '../web-dist',
        emptyOutDir: true
    },
    test: {
        environment: 'jsdom',
        include: ['src/**/*.test.{ts,tsx}'],
        setupFiles: ['./test/setup.ts']
    }
});
