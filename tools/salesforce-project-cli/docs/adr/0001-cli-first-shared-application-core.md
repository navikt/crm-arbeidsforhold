# ADR-0001: CLI-first tool with shared application core

## Status

Accepted

## Date

2026-09-13

## Context

Salesforce project setup was split across Bash, Batch, PowerShell and JavaScript. The implementations differed by platform and could not support a web interface without duplicating command and security logic.

The tool must run on macOS, Linux and Windows, remain useful without a browser, and be extractable from its original Salesforce repository.

## Decision

Build an independent Node.js 22 and TypeScript package with these boundaries:

- CLI is the authoritative product interface and behavioural contract.
- Domain and application modules contain configuration, planning, policy and workflow logic.
- Infrastructure adapters own filesystem and child-process integration.
- CLI and local HTTP adapters call the same application services and consume the same typed operation events.
- The React frontend is separately built and has no imports into the reusable core.
- Salesforce CLI remains the platform integration boundary and is invoked with argument arrays and `shell: false`.
- The local HTTP server binds only to `127.0.0.1`, authenticates API and SSE requests with an ephemeral token, and applies read-only policy to production and unknown orgs.

## Alternatives considered

### Python

Rejected because Salesforce CLI and the host repositories already require Node.js. Python would add a second runtime and more Windows installation variance.

### Shell scripts per platform

Rejected because behaviour, quoting, retries and validation had already diverged across Bash, Batch and PowerShell.

### Web-first service

Rejected because local automation, CI and recovery must remain available without a browser. The browser is an adapter, not the command engine.

### Web frontend spawning the CLI

Rejected because it would duplicate parsing, make cancellation and event streaming brittle, and weaken policy enforcement. Both adapters invoke the application layer directly.

## Consequences

- The package can be packed and installed independently.
- Behaviour is testable with fake Salesforce executables and no authenticated org.
- Human output and NDJSON events originate from one event model.
- Frontend dependencies increase development size but are isolated from core imports.
- Existing scripts remain available until parity is accepted; unsafe argument forwarding is not introduced prematurely.
- Authenticated org validation remains a separate, explicit gate.

## Follow-up

- Activate the module-local CI workflow after extraction to its own repository.
- Review legacy wrapper parity before removing Bash, Batch or PowerShell entry points.
- Reassess installation-key transport if Salesforce CLI adds a stdin or protected-file option.
