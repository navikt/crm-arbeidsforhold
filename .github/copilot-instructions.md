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
- Work in the existing `crm-arbeidsforhold` scratch org without renewed user approval, including reads, previews, tests/scripts, retrievals, package installation, deployments, publishing, and data or metadata changes/deletions. Verify the explicit target is the intended scratch org before acting; an alias alone is not proof. Respect native tool approvals.
- Before each command accessing any other non-production org, obtain fresh confirmation of the exact target and action and explain the technical reason. Authentication, aliases, scripts and previous approvals do not authorize those operations.
- Agents must never access production, including a production-backed Dev Hub, even on request or with approval. Arrange human execution; Team Platforce approval is required for human production metadata changes, and Team Platforce performs production verification and deletion.
- Org creation/replacement, package creation/promotion, CI/auth changes, live external integrations, and operations outside the authorized scratch org still require explicit approval. Production remains prohibited. Follow the full org-safety rules in `AGENTS.md`.
- Team Arbeidsforhold owns the product/repository; `@navikt/crm-arbeidsforhold` is the GitHub contributor/reviewer team. Require a runbook and SIT2 verification for metadata deletion or renaming; never claim verification without evidence.
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
