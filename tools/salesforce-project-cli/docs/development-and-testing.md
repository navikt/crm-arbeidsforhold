# Development and testing

The module is an independent npm package inside the current repository. Development requires Node.js 22 or newer and npm. Core unit and contract tests do not require Salesforce authentication. Browser tests require an installed Chrome channel. Only authenticated validation requires Salesforce CLI credentials.

## Setup

From `tools/salesforce-project-cli`:

```bash
npm ci
npm run typecheck
npm test
```

Use `npm ci` to reproduce `package-lock.json`. The lockfile uses npm lockfile version 3.

## Project structure

```text
src/
  application/       workflow orchestration and injected ports
  domain/            configuration, events, package logic, org policy
  infrastructure/    process runner, output, redaction, failure classification
  web/               loopback HTTP/SSE server
  cli-app.ts          command definitions and adapter wiring
  cli.ts              executable entry point
  index.ts            library exports
test/
  unit/               focused behavior tests
  contract/           CLI/server behavior with fake runners and facades
web/
  src/                React dashboard and browser API adapter
  test/               browser-test setup
  e2e/                deterministic fake server and Playwright scenarios
scripts/
  pack-smoke.mjs      independent tarball installation smoke test
docs/                 handbook, ADR, and migration matrix
```

`dist/`, `web-dist/`, `test-results/`, and `node_modules/` are generated outputs and must not be edited.

## Package scripts

| Script                  | Exact behavior                                                                             |
| ----------------------- | ------------------------------------------------------------------------------------------ |
| `npm run dev -- <args>` | Run `tsx src/cli.ts` with CLI arguments                                                    |
| `npm run typecheck`     | Type-check core and web TypeScript without emission                                        |
| `npm run test:core`     | Run core Vitest tests under `test/**/*.test.ts`                                            |
| `npm run test:web`      | Run web Vitest component/API tests using the Vite config                                   |
| `npm test`              | Run core tests, then web tests                                                             |
| `npm run test:watch`    | Start Vitest watch mode                                                                    |
| `npm run build:web`     | Build the Vite frontend into `web-dist/`                                                   |
| `npm run build:core`    | Build the CLI/library with tsup into `dist/`                                               |
| `npm run build`         | Build web, then core                                                                       |
| `npm run check`         | Type-check, run both Vitest suites, then build                                             |
| `npm run test:e2e`      | Run Playwright against the deterministic fake server                                       |
| `npm run test:pack`     | Build, pack, install production-only into a temporary project, and smoke-test the artifact |

Dependency audit is an npm command rather than a package script:

```bash
npm audit
```

Review audit findings in context. Do not change versions or lockfile entries without testing the module and its packed artifact.

## Test layers

### Unit tests

Unit tests isolate configuration, version selection, events, output, policy, command execution, error classification, workflows, and the web facade. Inject clocks, environments, command runners, delays, and event sinks rather than changing process globals where an existing seam is available.

### Contract tests

Contract tests call the CLI or HTTP server through public boundaries with fake command results or facades. They assert stable commands, arguments, payloads, status codes, output forms, security rules, and exit codes without contacting Salesforce.

### Component tests

Web tests use Vitest, jsdom, Testing Library, user-event, and `jest-axe`. Inject a `DashboardApi` fake and assert observable loading, policy, form, confirmation, event, and accessibility behavior.

### Browser tests

Playwright builds the frontend and starts `web/e2e/fake-server.ts` on `127.0.0.1:4178`. The fake server uses deterministic in-memory data and never invokes Salesforce. Projects cover desktop Chrome at `1440 × 1000` and iPhone 13 emulation using the installed Chrome channel. Reduced motion is enabled; traces are retained on failure.

Tests should assert behavior and invariants, not a fixed total test count. Adding a test must not require updating documentation solely because the suite count changed.

## Fake runner and facade patterns

Application and CLI tests provide a `CommandRunner` that records requests and returns normalized `CommandResult` values. Keep fake results representative of the specific Salesforce response shape being tested, including malformed and failure variants. Never use real credentials, auth URLs, installation keys, org data, or personal data in fixtures.

Server and UI tests provide a `WebServiceFacade` or `DashboardApi`. The facade must emit intermediate events only; the server owns `operation-started` and `operation-completed`. Use deterministic operation outcomes and explicit policy classifications.

## Focused validation

Run the narrowest check first, then broaden:

```bash
npm run test:core -- test/unit/config.test.ts
npm run test:web -- web/src/api.test.ts
npm run typecheck
npm run build
npm run test:e2e
npm run test:pack
```

Vitest accepts the trailing file filter shown above. `test:e2e` and `test:pack` do not contact Salesforce. `npm run check` is the module-wide local gate.

For documentation changes, run Prettier against the touched Markdown files and audit relative links. There is no module-local Prettier package script.

## Adding a command safely

1. Define observable behavior and stable exit semantics in a focused test.
2. Add or extend domain types and policy only when behavior belongs there.
3. Implement orchestration as an application service with injected command runner and event sink.
4. Register CLI syntax in `cli-app.ts`, including defaults, validation, output mode, and redaction.
5. If exposed on the web, add the command union member, exact payload allowlist, target policy resolution, facade dispatch, browser type, and UI control.
6. Add unit and contract tests, then component/E2E coverage for user-visible behavior.
7. Update the CLI, workflow, API, frontend, configuration, and troubleshooting docs that describe the changed contract.

Do not forward arbitrary user strings to a shell. Continue to pass literal executable argument arrays through the injected runner.

## Adding or changing events

`OperationEvent` is a public discriminated union used by terminal rendering, NDJSON, server history, SSE, tests, and the dashboard. Preserve existing `kind` values and stable exit codes. New events need:

- a typed domain variant with operation ID and ISO timestamp
- deterministic emission order and stable step identifiers
- redaction before output, storage, or transport
- human renderer behavior and NDJSON coverage
- replay/SSE and browser tolerance tests
- documentation when externally observable

Application services must not emit terminal `operation-completed` for web execution; the owning adapter adds exactly one terminal event.

## Documentation and TSDoc

Use clear technical English and describe current behavior, not intended future behavior. Link rather than duplicate the ADR, legacy matrix, and security policy. Public exported classes, interfaces, types, functions, options, and lifecycle contracts use concise TSDoc. Include `@param`, `@returns`, and `@throws` when they add contract information. Avoid comments that merely narrate code.

## Authenticated validation

Local fake-backed tests prove local behavior only. Real org creation, deletion, package installation, deployment, retrieval, or authenticated compatibility requires an explicitly selected non-production org and human approval. Record the exact target and completed command without recording credentials or org user data. Never describe a fake-backed test as Salesforce validation.
