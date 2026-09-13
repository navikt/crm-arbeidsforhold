# Packaging and extraction

The module is structured as an independently packable npm package, but it is currently private and has no publication workflow. Extraction must preserve the CLI, library, dashboard, documentation, security boundary, and platform matrix as one owned product.

## Package entry points

| Surface                 | Packed path       |
| ----------------------- | ----------------- |
| `sf-project` executable | `dist/cli.js`     |
| ESM library import      | `dist/index.js`   |
| Type declarations       | `dist/index.d.ts` |
| Web dashboard           | `web-dist/`       |

tsup builds ESM without splitting or source maps, emits declarations, cleans the output, and adds the Node shebang to generated JavaScript. Vite builds the frontend separately before the core build.

## npm contents

The package `files` allowlist contains only:

- `dist`
- `web-dist`
- `docs`
- `README.md`
- `SECURITY.md`

The npm pack manifest also includes npm-required package metadata. Tests, TypeScript source, source maps, dependencies, result artifacts, screenshots, environment files, and auth-like paths are not intended package contents.

## Runtime and development dependencies

Runtime dependencies are:

- `commander` for CLI parsing
- `execa` for shell-free process execution
- `zod` for runtime validation

React, React DOM, Aksel packages, Vite, TypeScript, tsup, Vitest, Testing Library, axe, jsdom, Playwright, `tsx`, and type packages are development dependencies. The built frontend bundles its browser dependencies; a production installation must not gain React or Aksel runtime dependency entries.

Node.js `>=22` is the declared runtime requirement. The package uses npm lockfile version 3.

## Pack smoke

Run:

```bash
npm run test:pack
```

The script first builds the web and core artifacts, then:

1. Creates a temporary independent directory under the operating-system temp directory.
2. Runs `npm pack --json` into that directory.
3. Rejects packed paths matching source maps, `node_modules`, test results, screenshots, environment files, or auth-like names.
4. Creates a minimal private fixture package.
5. Installs the tarball with production dependencies only, scripts disabled, and audit/funding output disabled.
6. Verifies package version `0.1.0`.
7. Runs the installed CLI help and requires the `doctor` command.
8. Reads the installed web root and requires its React mount element.
9. Confirms frontend packages are not runtime dependencies.
10. Removes the temporary fixture in `finally`.

The fixture is generated dynamically and is not a checked-in directory. Pack smoke does not contact Salesforce.

## Module-local CI matrix

The nested workflow at `.github/workflows/ci.yml` runs on pull requests and pushes to `main` with read-only contents permission. Its matrix is Node.js 22 on:

- Ubuntu latest
- macOS latest
- Windows latest

Each job runs `npm ci`, `npm run check`, and `npm run test:pack`. It does not run Playwright E2E or authenticated Salesforce validation. Because the workflow is nested inside the module, it is intended for activation after extraction; it is not a root repository workflow.

## Extraction checklist

1. Move the module directory contents to the new repository root without copying generated `dist`, `web-dist`, `test-results`, or `node_modules`.
2. Preserve package history or record the source commit and extraction decision.
3. Move `.github/workflows/ci.yml` to the new repository’s active workflow location and review pinned action SHAs.
4. Recreate branch protection, CODEOWNERS, dependency update policy, security reporting, secret scanning, and release permissions under the new owner.
5. Run `npm ci`, `npm run check`, `npm run test:e2e`, `npm audit`, and `npm run test:pack` on the extracted repository.
6. Confirm Linux, macOS, and Windows CI behavior before removing the in-repository copy.
7. Decide publication identity, registry, access, provenance, signing, changelog, and support policy before changing `private: true`.
8. Update parent-repository invocation links and migration guidance only after the extracted package is consumable.
9. Keep legacy scripts until parity and ownership are formally accepted.

## Ownership and version decisions

Extraction requires explicit decisions that the current package does not encode:

- owning team and CODEOWNERS
- npm scope, registry, and package visibility
- semantic-versioning and backward-compatibility policy for CLI syntax, exit codes, events, API payloads, and library exports
- release approval and rollback process
- supported Node, Salesforce CLI, and `sfp` versions
- vulnerability response and dependency update cadence
- artifact provenance, signing, and retention
- whether the local web API is a supported external contract or an internal dashboard boundary

Version `0.1.0` and `private: true` describe the current package only. There is no implemented publish, tag, changelog, provenance, or release command to document.

## Release validation gates

The local release candidate should pass:

```bash
npm ci
npm run check
npm run test:e2e
npm audit
npm run test:pack
```

These checks validate code, browser behavior, dependency findings, builds, and package shape. They do not validate Salesforce compatibility.

Before a release that claims Salesforce support, run an approved authenticated gate against an explicitly selected non-production org. At minimum, exercise the supported read paths and the release-relevant mutation paths, verify stable exit/output contracts, and record sanitized evidence. Org creation, package installation, deployment, retrieval, deletion, and pool use require human approval and suitable disposable targets. Never embed credentials or installation keys in CI configuration, fixtures, logs, or artifacts.

## Legacy handover

Use the [legacy behaviour matrix](legacy-behavior-matrix.md) as the extraction acceptance ledger. Deferred shell behavior must either receive an explicit tested contract or remain with the legacy entry point. Do not replace existing scripts with a forwarding wrapper until argument, environment, summary, and exit-code parity has been accepted.

The architecture rationale remains in [ADR-0001](adr/0001-cli-first-shared-application-core.md), and the extracted repository must retain [Security](../SECURITY.md) with its local trust boundary and reporting route.
