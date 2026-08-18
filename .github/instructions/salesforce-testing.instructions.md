---
applyTo: "force-app/**/*Test.cls,force-app/**/__tests__/**/*.js"
---

# Salesforce testing standards

For new or materially changed Apex and LWC tests:

- Follow `.github/skills/tdd-salesforce/SKILL.md` and identify the public behavioural seam before writing the test.
- Write one focused test for one observable behaviour, then run it red before implementing the smallest change.
- Name Apex test methods after the business scenario and expected behaviour, using a readable `given_When_Then` or `should_When` shape without a `test` prefix. Use descriptive Jest test names as well.
- Prefer assertions against public outcomes: returned values, persisted records, emitted events, rendered DOM, user-visible errors, callout requests, or permission outcomes.
- Avoid private-state assertions, implementation-coupled mocks, tautological expectations, shared mutable state, and tests that only prove that code did not throw.
- Keep tests deterministic and isolated. Use `Test.startTest()`/`Test.stopTest()` around the operation under test and existing test-data factories where applicable.
- Do not use real personal data, hardcoded Salesforce IDs, package keys, credentials, or org-specific URLs in fixtures.
- Test both success and relevant error paths, including access denial and empty or missing data where the contract exposes them.
- For callouts, use `HttpCalloutMock` and assert the integration contract without making real network calls.
- For LWC, test user-visible DOM and interaction, wire/Apex outcomes, loading/empty/error states, and relevant accessibility behaviour.
- If an Apex test requires an authenticated Salesforce org, report the exact blocked command and do not claim the test is green.
- Use ApexDoc for new or materially changed test classes and test methods, following the same standard as production Apex (see `.github/instructions/salesforce-apex.instructions.md`).
  - Give the test class a class-level ApexDoc block with a one-sentence summary, `@author` (original file author first, then top contributors ordered by each person's first commit on the file, from `git log --follow`), `@since`, and `@group`.
  - Give each test method a one-sentence ApexDoc summary of the scenario under test, plus `@since` showing when that specific test method was added (from `git log -S"methodName"` on the file), so the history of test coverage growth stays visible. Always include `@since` on test methods, even when it matches the class-level `@since`. Never invent a date; if history cannot be determined reliably, state that explicitly instead of guessing.
  - Do not add `@param`/`@return` to test methods (they take no meaningful parameters and return void).

