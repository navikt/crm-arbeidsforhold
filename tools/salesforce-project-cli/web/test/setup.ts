import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { toHaveNoViolations } from 'jest-axe';
import { afterEach, expect } from 'vitest';

expect.extend(toHaveNoViolations);
(globalThis as typeof globalThis & { AKSEL_NO_EXIT_ANIMATIONS: boolean }).AKSEL_NO_EXIT_ANIMATIONS = true;
afterEach(cleanup);
