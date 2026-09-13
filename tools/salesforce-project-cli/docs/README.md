# Salesforce Project CLI documentation

This handbook describes the current implementation of `@navikt/salesforce-project-cli`. The TypeScript source, tests, and package scripts remain authoritative when behavior changes.

## Choose a guide

| Audience            | Start here                                                                                        | Use it for                                                                                     |
| ------------------- | ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| CLI users           | [CLI reference](cli-reference.md)                                                                 | Exact commands, options, output contracts, exit codes, and confirmation rules                  |
| Project maintainers | [Configuration](configuration.md)                                                                 | `sfdx-project.json`, `sf-project.config.json`, environment variables, defaults, and validation |
| Operators           | [Workflows](workflows.md) and [operations and troubleshooting](operations-and-troubleshooting.md) | Ordering, side effects, dry runs, recovery, diagnostics, and failure handling                  |
| API consumers       | [Web API](web-api.md)                                                                             | Loopback security, endpoints, payloads, SSE, retention, and errors                             |
| Frontend developers | [Web frontend](web-frontend.md)                                                                   | Dashboard state, forms, policy behavior, Aksel, accessibility, and responsive layout           |
| Contributors        | [Development and testing](development-and-testing.md)                                             | Local setup, scripts, test doubles, validation, and extension patterns                         |
| Package owners      | [Packaging and extraction](packaging-and-extraction.md)                                           | npm contents, pack smoke, CI, repository extraction, and release gates                         |
| Architects          | [Architecture](architecture.md)                                                                   | Layers, dependency direction, event lifecycle, adapters, and tradeoffs                         |

## Governing and historical documents

- [ADR-0001: CLI-first tool with shared application core](adr/0001-cli-first-shared-application-core.md) records the accepted architecture decision.
- [Legacy behaviour matrix](legacy-behavior-matrix.md) records implemented, corrected, deferred, and intentionally omitted behavior from the former scripts.
- [Security policy](../SECURITY.md) defines the local trust boundary, implemented controls, residual risks, and reporting expectations.

## Validation boundary

Unit, contract, component, and browser tests use fake command responses or an in-memory service facade. They validate local contracts without contacting Salesforce. Real org creation, package installation, deployment, retrieval, or authenticated compatibility requires an explicitly selected org, human approval, and a separate Salesforce validation run.
