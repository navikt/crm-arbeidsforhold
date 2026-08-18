# GitHub Copilot Instructions

Use the repository root `AGENTS.md` as the general source of truth. Apply the more specific rules in `force-app/main/default/AGENTS.md` when working in the main Salesforce package.
For agent workflow, use `.github/instructions/agentic-development.instructions.md`.
For test-first changes, use `.github/skills/tdd-salesforce/SKILL.md`; for pre-PR review,
use `.github/skills/code-review-two-axis/SKILL.md`.

## Before changing code

- Identify whether the requested file belongs to the main package or a package-owned dependency.
- Read nearby metadata, Apex/LWC tests, and the relevant workflow before proposing a new pattern.
- Keep changes scoped to the user's request and preserve existing uncommitted work.

## Salesforce safety

- Do not invent Salesforce IDs, org URLs, package versions, permission-set assignments, or dependency APIs.
- Do not expose credentials, package installation keys, personal data, or authentication details in code, logs, prompts, or test fixtures.
- Treat org creation, package installation, deployment, package creation, and package promotion as explicit user actions. Ask before running them against a shared or production org.
- Do not modify package-owned directories without explicit approval. The repository already contains `.copilot/reference-only.instructions.md` for this boundary.

## Implementation and verification

- Prefer existing Apex utilities and metadata patterns.
- Keep Apex bulk-safe and security-conscious; follow the detailed local Apex instructions.
- Update focused tests when behavior changes.
- Run the narrowest relevant check first, normally a focused Jest test or `npm run prettier:check`. Report checks that require Salesforce CLI authentication or an org.
- Never claim an org deployment, package installation, or Salesforce test passed unless the command actually completed successfully.
- Use a red-green-refactor loop for each behavioural slice where the environment permits it; report authenticated-org blockers for Apex tests explicitly.

## Response style

Describe the assumption, the files changed, and the validation result briefly. Call out any blocked check and the exact prerequisite needed to run it.
