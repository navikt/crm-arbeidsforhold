# Security

## Trust boundary

The tool runs with the local developer's Salesforce CLI credentials and filesystem access. Treat command execution and the local web interface as privileged developer tooling.

## Controls

- Child processes receive executable and argument arrays with shell interpolation disabled.
- API and SSE endpoints require an ephemeral bearer token and exact loopback Host validation.
- Mutating HTTP requests also require a matching same-origin header.
- The browser token is injected only into the loopback-served page and is not written to URLs, storage or logs.
- Production, Dev Hub and unknown orgs are read-only by default.
- Payloads are allowlisted, size-limited and reject control characters.
- Operation history, events and SSE subscribers are bounded.
- Static assets and dependency paths use canonical containment checks and reject symlink escape.
- Dependency refresh uses a durable transaction marker and recoverable `.forceignore` backup.
- Configured secrets and Salesforce auth URL or access-token patterns are redacted from output and retained events.
- npm packages contain compiled code and web assets only; source maps, tests, environment files and auth artifacts are excluded.

## Residual risks

Salesforce package installation currently requires passing the installation key as a Salesforce CLI argument. The value is redacted from this tool's output, but it may be visible to same-user process inspection. Use trusted single-user development machines and avoid shared execution accounts.

The standard web-service facade does not yet declare cancellation support. Unsupported cancellation returns a conflict response rather than pretending an operation stopped.

Authenticated org validation is opt-in. Local tests use fake Salesforce command responses and must not be represented as proof that a real org operation succeeded.

## Reporting

Do not include Salesforce credentials, access tokens, installation keys, auth URLs, org user data or personal data in an issue. Report security concerns through the owning team's approved private channel.
