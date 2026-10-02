# Documentation and engineering standards

This document defines how `@navikt/salesforce-project-cli` documents source code, public contracts, architecture, operations, releases, and user workflows. It is normative for this module. When the module is extracted, move this document with it.

## Standards hierarchy

Apply standards in this order:

1. Repository and NAV requirements that govern security, source boundaries, human approval, and Salesforce operations.
2. This module's documented public contracts and accepted architecture decisions.
3. Official language, runtime, framework, and platform documentation.
4. Existing module patterns where higher-level guidance does not decide the question.

A lower-level convention must not weaken a higher-level safety or compatibility requirement. Record intentional deviations in an ADR or the relevant reference document.

## Standards by level

| Level                  | Standard used here                                                                                                                                                                                                                                                                                                                     | Purpose                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Repository governance  | Root `AGENTS.md`, module security policy, NAV Copilot principles                                                                                                                                                                                                                                                                       | Source boundaries, human approval, validation language, secrets, and personal data |
| Salesforce platform    | [Salesforce CLI documentation](https://developer.salesforce.com/tools/salesforcecli), [Salesforce DX project configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm), [Salesforce Well-Architected](https://architect.salesforce.com/docs/architect/well-architected/overview) | CLI integration, project metadata, trust, reliability, and operational behavior    |
| TypeScript language    | [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html), [declaration-file guidance](https://www.typescriptlang.org/docs/handbook/declaration-files/do-s-and-don-ts.html), [TSConfig reference](https://www.typescriptlang.org/tsconfig/)                                                                       | Type design, strict compiler behavior, public declarations, and module semantics   |
| Source documentation   | [TSDoc](https://tsdoc.org/), [TSDoc tags](https://tsdoc.org/pages/tags/), [TypeDoc doc comments](https://typedoc.org/documents/Doc_Comments.html)                                                                                                                                                                                      | Parseable API comments and generated reference documentation                       |
| API documentation tool | [TypeDoc](https://typedoc.org/), [TypeDoc options](https://typedoc.org/documents/Options.html)                                                                                                                                                                                                                                         | Validate and generate API documentation from `src/index.ts`                        |
| Web UI                 | [Aksel](https://aksel.nav.no/), [Aksel code packages](https://aksel.nav.no/grunnleggende/introduksjon/kom-i-gang-med-kodepakkene), [WCAG 2.2](https://www.w3.org/TR/WCAG22/)                                                                                                                                                           | Components, tokens, language, accessibility, and responsive behavior               |
| HTTP security          | [OWASP API Security Top 10](https://owasp.org/API-Security/), [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)                                                                                                                                                                                                          | Input validation, access control, secrets, browser boundaries, and safe errors     |
| Technical writing      | [Diátaxis](https://diataxis.fr/), [Write the Docs guide](https://www.writethedocs.org/guide/writing/beginners-guide-to-docs/), [GitHub Flavored Markdown](https://github.github.com/gfm/)                                                                                                                                              | Documentation structure, audience, Markdown, and maintainability                   |
| Diagrams               | [Mermaid](https://mermaid.js.org/intro/)                                                                                                                                                                                                                                                                                               | Version-controlled architecture and sequence diagrams                              |
| Architecture decisions | [Architecture Decision Records](https://adr.github.io/) and the module ADR template established in `docs/adr/`                                                                                                                                                                                                                         | Context, decision, alternatives, consequences, and follow-up                       |
| Versioning             | [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)                                                                                                                                                                                                                                                                       | Compatibility and release numbering after publication                              |
| Change communication   | [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/)                                                                                                                                                                                                                                                                         | Human-readable notable changes after publication                                   |
| Commit messages        | [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)                                                                                                                                                                                                                                                           | Structured change intent and future release automation                             |

## Documentation architecture

The module follows the audience-oriented principle from Diátaxis without forcing every page into a rigid template:

- **Tutorial or onboarding:** the module `README.md` provides the shortest path to install, configure, and run the tool.
- **How-to guidance:** `operations-and-troubleshooting.md`, `development-and-testing.md`, and `packaging-and-extraction.md` guide concrete work.
- **Reference:** `cli-reference.md`, `configuration.md`, `web-api.md`, and generated TypeDoc output describe exact contracts.
- **Explanation:** `architecture.md`, ADRs, the legacy behavior matrix, and `SECURITY.md` explain decisions and tradeoffs.

`docs/README.md` is the documentation map. New documents must be linked there and from the nearest relevant guide.

## Language and terminology

- Source identifiers, TSDoc, API reference, technical Markdown, configuration keys, and command names use English.
- User-facing frontend text may use Norwegian Nynorsk according to the current product surface.
- Use the stable terms from the specification and domain types. Do not alternate casually between `org`, `organization`, `environment`, and `target` when they mean different things.
- Prefer short sentences, active voice, concrete nouns, and explicit prerequisites.
- State what is locally verified, org-dependent, assumed, or intentionally unsupported.
- Never include real credentials, installation keys, access tokens, auth URLs, usernames classified as sensitive, or personal data.

## TypeScript source documentation

### Comment syntax

Use TSDoc-compatible `/** ... */` comments for documentation attached to TypeScript declarations. TSDoc standardizes the grammar used by TypeScript documentation tools; TypeDoc consumes these comments to produce API reference output.

Use ordinary `//` comments only for a local invariant, ordering constraint, security boundary, compatibility reason, or recovery rule that cannot be expressed clearly through names and types.

Do not:

- narrate the next line of code;
- preserve disabled code in comments;
- duplicate a type signature in prose;
- use comments to compensate for unclear names or avoid a needed abstraction;
- place credentials, org details, personal data, or command output containing secrets in examples.

### Package and file-level documentation

`src/index.ts`, the public package entrypoint, must begin with a TSDoc block containing `@packageDocumentation`. It defines the package purpose, supported public boundary, and important safety expectations.

A file-level TSDoc block is required for modules that own a significant boundary or non-obvious lifecycle, including:

- process execution and redaction;
- operation events and output rendering;
- configuration normalization;
- filesystem mutation and recovery;
- package and org orchestration;
- HTTP authentication, event streaming, and retained history;
- browser API transport and the operational application root.

A small leaf module does not need a file-level block when its name and declaration-level documentation fully explain its responsibility. Do not add boilerplate such as "This file contains utilities."

File-level blocks describe responsibility and invariants, not author, copyright, change history, or version.

### Public declarations

Every declaration exported from `src/index.ts` must have TSDoc at its declaration site:

- functions and classes;
- interfaces and type aliases;
- constants and enums;
- public interface properties and methods;
- callback, options, result, event, and lifecycle contracts.

The first paragraph is a concise summary. Add `@remarks` only when consumers need details that do not belong in the summary.

Use tags when they add contract information:

```ts
/**
 * Executes a command without shell interpolation.
 *
 * @remarks
 * Returned and streamed text is redacted before it crosses the adapter boundary.
 *
 * @param request - Executable, literal arguments, observation hooks, and retry policy.
 * @returns The normalized result of the final attempt.
 * @throws {@link RangeError} When the retry attempt count is invalid.
 */
```

Rules:

- `@param`: document meaning, units, constraints, defaults, or security classification; do not repeat only the parameter name.
- `@returns`: document observable result semantics, not merely the TypeScript type.
- `@throws`: document meaningful error categories a caller can handle. It is informational and not an exhaustive runtime type guarantee.
- `@remarks`: reserve for lifecycle, ordering, security, compatibility, or examples too detailed for the summary.
- `{@link ...}`: link related public declarations when the relationship helps navigation.
- `@deprecated`: include the replacement and planned removal boundary. Deprecation requires release notes and a compatible migration period.
- `@example`: use for a public API whose correct use is not apparent from its signature. Examples must be executable in principle and use synthetic data.

### Internal declarations

Document an internal declaration when it defines one of these contracts:

- data shared across multiple functions or modules;
- normalization of external Salesforce or filesystem data;
- security checks and trust boundaries;
- retry, cancellation, timeout, or partial-completion behavior;
- durable recovery or transaction state;
- protocol framing, stream decoding, or event ordering;
- compatibility behavior that a future refactor could accidentally remove.

Private helpers that are local, obvious, pure, and well named normally need no docblock.

### `@author`, `@version`, and `@since`

Do not use `@author` in source files. Git history and repository ownership are the source of truth; personal headers become stale and obscure collective ownership.

Do not use file-level `@version`. The package version in `package.json`, Git tags, release notes, and the changelog define the released version.

`@since` is not a TSDoc core tag and is not currently configured as a custom project tag. Do not use it before the first stable public release. If the project later needs per-symbol introduction metadata, define `@since` in `tsdoc.json`, document its exact SemVer syntax here, and require it only for public API additions made after the baseline release. Historical values must come from release history, never guesses.

## TypeDoc

TypeDoc is the API documentation generator for the package. It uses `src/index.ts` as the only entrypoint and follows its re-exports. This keeps generated documentation aligned with the supported package surface instead of exposing internal implementation accidentally.

Generated TypeDoc HTML is build output:

- write it to `api-docs/`;
- do not edit or commit it;
- do not include it in the npm package unless publication design explicitly changes;
- run TypeDoc validation in the local quality gate and CI;
- treat broken declaration links and undocumented exported API warnings as failures.

TypeDoc complements, but does not replace, the authored handbook. Generated API pages answer exact symbol questions; the handbook explains workflows, architecture, operations, and decisions.

## Markdown documentation

Each document must have one clear audience and purpose. Start with the outcome or subject, then prerequisites and exact behavior. Use:

- tables for stable option or contract matrices;
- numbered lists for ordered procedures;
- bullets for unordered criteria;
- fenced code blocks with language identifiers;
- Mermaid for diagrams that benefit from version-controlled source;
- relative links for module-local documents;
- direct HTTPS links for authoritative external standards.

Do not duplicate large sections across files. Link to the source of truth. Update all affected reference and how-to documents in the same change as a public behavior change.

### Document ownership by subject

| Change                                            | Documentation to update                                            |
| ------------------------------------------------- | ------------------------------------------------------------------ |
| CLI command, option, output, or exit code         | `cli-reference.md`, relevant workflow/troubleshooting guide, TSDoc |
| Configuration key or precedence                   | `configuration.md`, example config, TSDoc                          |
| Operation ordering or side effect                 | `workflows.md`, architecture when cross-cutting, TSDoc             |
| HTTP route, payload, auth, limit, or SSE behavior | `web-api.md`, frontend guide when user-visible, TSDoc              |
| Frontend workflow or accessibility behavior       | `web-frontend.md`, component tests, E2E tests                      |
| Security boundary or residual risk                | `SECURITY.md`, architecture/ADR when structural                    |
| Architecture decision                             | New or superseding ADR; do not rewrite accepted history silently   |
| Release-visible change                            | `CHANGELOG.md` after release management is activated               |
| Packaging or ownership                            | `packaging-and-extraction.md`, README, package metadata            |

## ADR standard

Write an ADR when a decision affects multiple components, changes a trust boundary, establishes a reusable convention, or would be costly to reverse. Every ADR includes:

- status;
- date;
- context;
- decision;
- alternatives considered;
- consequences;
- follow-up.

Accepted ADRs are historical records. Supersede them with a new ADR instead of rewriting the original decision.

## API and protocol documentation

CLI, NDJSON, HTTP, SSE, configuration, and exit codes are public contracts even before npm publication. Their documentation must specify:

- inputs, defaults, precedence, and validation;
- output shape and output channel;
- ordering and terminal states;
- errors and stable exit/status codes;
- authentication and authorization;
- redaction and sensitive values;
- side effects and dry-run guarantees;
- retention, retry, cancellation, timeout, and recovery behavior;
- unsupported behavior and environmental prerequisites.

Examples use synthetic aliases and placeholders such as `<session-token>`. Never publish a real Salesforce org URL or credential.

## Version and change documentation

The package is currently in initial development under major version zero. When publication begins:

- follow Semantic Versioning for the declared public API;
- maintain `CHANGELOG.md` using Keep a Changelog sections: Added, Changed, Deprecated, Removed, Fixed, and Security;
- keep an Unreleased section;
- use ISO `YYYY-MM-DD` release dates;
- do not generate the human changelog by dumping Git history;
- use Conventional Commits for merge/squash commit messages when release automation is enabled;
- identify breaking changes explicitly in code migration docs, changelog, and release notes.

Until release ownership and publication are approved, `package.json` remains the only version source and no per-symbol `@since` values are asserted.

## Validation

Documentation changes are complete when applicable checks pass:

```bash
npm run docs:check
npm run typecheck
npm test
npm run test:pack
```

Also verify:

- Prettier formatting for authored TypeScript, TSX, Markdown, JSON, and configuration files;
- all relative Markdown links resolve;
- generated API output is reproducible and ignored by Git;
- npm pack includes the authored handbook and `SECURITY.md`, but not generated API HTML;
- examples contain no secrets or personal data;
- no claim of Salesforce validation is made without a completed authenticated command.

## Review checklist

- Does the documentation explain why and observable behavior rather than restating implementation?
- Is the public API documented at its declaration site?
- Does a complex module explain its responsibility and critical invariants at file level?
- Are side effects, dry-run, failure, recovery, and security semantics explicit?
- Are ownership and version facts sourced from Git, CODEOWNERS, package metadata, and releases rather than duplicated headers?
- Are external standards linked and local deviations recorded?
- Were affected handbook pages and generated API validation updated with the code?
