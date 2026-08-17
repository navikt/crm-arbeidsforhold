---
description: Review a Salesforce change against Nav, Platforce, Salesforce Well-Architected, and the originating specification.
---

Use `.github/skills/code-review-two-axis/SKILL.md`, `AGENTS.md`, `CONTEXT.md`, and the applicable files in `.github/instructions/`.

Before reviewing:

1. Identify the fixed point: `main`, a commit, branch, or other explicit reference.
2. Confirm the reference exists and inspect the merge-base diff and changed files.
3. Identify the originating issue, request, or specification. If none exists, state that the Specification axis is limited.
4. Classify changed paths as main package, package-owned/reference-only, generated, workflow, or configuration.

Review the two axes independently:

### Standards

Check Nav Platforce conventions, Salesforce source patterns, ApexDoc, clean code, package boundaries, sharing and access control, bulk safety, callouts, error handling, logging, PII/secrets, metadata visibility, workflow permissions, and Well-Architected Trusted/Easy/Adaptable tradeoffs.

### Specification

Check requested behaviour, missing success/error paths, scope creep, edge cases, and whether tests demonstrate the public behavioural contract.

### TDD and validation

Check for a focused behavioural test at the correct seam, red-green-refactor evidence where the environment supports it, and honest reporting of org/authentication blockers. Distinguish missing process evidence from a genuine Salesforce-org limitation.

Report findings first, ordered by severity. Keep Standards and Specification separate. Include file paths and concise evidence. Mark judgement calls as such. End with:

- checks run and results;
- checks blocked and exact prerequisites;
- residual risk;
- whether human review is required for red-zone work.

Never claim deployment, package installation, Salesforce tests, or external readiness checks passed unless the command completed successfully.
