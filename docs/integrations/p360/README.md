# P360 integration

P360 archive processing is integrated into `main` behind the `P360_Archive_Processing` feature flag. The deployed metadata default is false; merging or deploying the feature does not approve activation.

## Start here

Read [Code and test walkthrough](kodegjennomgang.md) first for a plain-language explanation of the current flow, what is and is not implemented, what Apex tests prove, and the order for the human-led review.

## Supporting documents

- [Code walkthrough](kodegjennomgang.md): explains the current trigger-to-worker implementation, metadata switches, tests, and remaining gaps.
- [Technical overview](teknisk-oversikt.md): implemented behavior, remaining gaps, and target architecture.
- [Mock test guide](user-testing-guide.md): approved default scratch-org validation. It is not evidence of live SIF interoperability.
- [P360 test log](test-log.md): recorded automated results, smoke outcome, and remaining cleanup from the latest test round.
- [Step-by-step regression and mock validation](../../operations/p360-og-crm-arbeidsforhold-testgjennomgang.md): manual scenarios, expected outcomes, and result matrices for scratch-org and integration sandbox.
- [P360 completion roadmap](../../../.github/specs/p360-completion-roadmap.md): phases, acceptance criteria, and contract gates.
- [Jira update proposal](../../context/p360/jira-oppdateringsoversikt.md): proposed Jira changes; Jira itself remains the status authority.
- [Archive data model](../../architecture/p360-data-model-og-arkiveringsjob.md): object ownership, event jobs, and persistence contract.

## Activation boundary

Keep `P360_Archive_Processing` disabled except during approved non-production validation. `Use_Mock_Transport__c` selects mock versus real transport; it is not the processing switch. `P360_Archive_Release` authorizes a user to release a decision; it is not the processing switch. Production activation requires the separate readiness decision in GitHub issue #1093.
