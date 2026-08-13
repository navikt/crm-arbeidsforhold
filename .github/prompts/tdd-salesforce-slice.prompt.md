---
description: Start one Salesforce behavioural change using the repository's Nav-first red-green-refactor workflow.
---

Use the repository's `.github/skills/tdd-salesforce/SKILL.md`, `.github/instructions/agentic-development.instructions.md`, and `CONTEXT.md`.

Before editing:

1. Identify the requested user-visible behaviour and the smallest public test seam.
2. Locate the nearest implementation, test, test-data factory, and applicable package boundary.
3. Classify the change as green zone or red zone. Stop for human clarification if it touches access control, personal data, authentication, callouts, metadata visibility, architecture, or package-owned source.
4. State the exact focused check that should go red.

Implementation loop:

1. Write one focused behavioural test with a domain-readable name.
2. Run it and show the red result. For Apex, report the exact org/authentication prerequisite if it cannot run.
3. Implement the smallest change that can make that test green.
4. Run the same focused check and show the result.
5. Refactor only after green, then rerun the focused check.
6. Run the relevant broader local validation and report any org-dependent blocker.

Completion report:

- Behaviour and seam:
- Red check:
- Green check:
- Broader validation:
- Files changed:
- Architecture choice and tradeoff:
- Red-zone code the developer should understand:
- Blockers or residual risk:
