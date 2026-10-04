# P360 integration

P360 archive processing is integrated into `main` behind the `P360_Archive_Processing` feature flag. The deployed metadata default is false; merging or deploying the feature does not approve activation.

## Current documents

- [Technical overview](teknisk-oversikt.md): implemented behavior, remaining gaps, and target architecture.
- [Mock test guide](user-testing-guide.md): approved default scratch-org validation. It is not evidence of live SIF interoperability.
- [P360 completion roadmap](../../../.github/specs/p360-completion-roadmap.md): phases, acceptance criteria, and contract gates.
- [Jira update proposal](../../context/p360/jira-oppdateringsoversikt.md): proposed Jira changes; Jira itself remains the status authority.
- [Archive data model](../../architecture/p360-data-model-og-arkiveringsjob.md): object ownership, event jobs, and persistence contract.

## Activation boundary

Keep `P360_Archive_Processing` disabled except during approved non-production validation. `Use_Mock_Transport__c` selects mock versus real transport; it is not the processing switch. `P360_Archive_Release` authorizes a user to release a decision; it is not the processing switch. Production activation requires the separate readiness decision in GitHub issue #1093.
