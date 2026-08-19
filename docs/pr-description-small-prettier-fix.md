# fix: resolve Prettier parser errors in LWC templates

## Summary

Fix malformed HTML that caused the PR formatting check to fail:

- Remove an extra `</p>` in `aareg_application`.
- Replace invalid `</br>` tags in `aareg_applicationBasis`.
- Exclude Anonymous Apex utility scripts from Prettier, since the Apex parser cannot parse them.

## Scope

- [ ] Main package only (`force-app/`)
- [ ] Package-owned or reference-only content changed with explicit approval
- [ ] Metadata/API/public contract changed
- [ ] CI, authentication, deployment, package, or environment configuration changed

## TDD and validation

- [ ] Behavioural seam identified
- [ ] Focused test added or updated before implementation where an executable seam exists
- [ ] Red result observed before implementation, or the environment blocker is explained below
- [x] Focused check rerun after implementation
- [ ] Relevant broader validation run

Checks run:

```text
npm run prettier:check
Result: Parser errors are resolved. The command still fails because 145 pre-existing files do not match Prettier formatting.
```

Blocked checks or org prerequisites:

```text
No Salesforce org validation required. Full Prettier validation remains blocked by existing repository-wide formatting drift.
```

## Review

### Standards

- [x] Nav Platforce naming and Salesforce source conventions followed
- [ ] ApexDoc added or updated for new or materially changed public Apex contracts
- [ ] Sharing, access control, FLS, Experience Cloud visibility, and data handling reviewed where relevant
- [x] No hardcoded IDs, credentials, URLs, package keys, or personal data
- [ ] Bulk safety, callout handling, error handling, and logging reviewed
- [x] Salesforce Well-Architected considered: Trusted, Easy, Adaptable
- [x] Clean code: focused responsibilities, readable names, shallow control flow, no speculative abstractions

### Specification

- [x] Requested behaviour is covered
- [x] Success and relevant error paths are covered
- [x] No unrelated behaviour or refactoring included
- [x] Residual risk and follow-up work are recorded

Residual risk: PR validation remains red until existing formatting drift is handled or the formatting validation scope is changed.

## Human approval

- [ ] Required human approval obtained
- [ ] Not applicable

Human approval is required before merging because the `.prettierignore` change affects the validation scope in CI.
