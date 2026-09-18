# Salesforce Project CLI documentation

This handbook describes the current implementation of `@navikt/salesforce-project-cli`. The TypeScript source, tests, and package scripts remain authoritative when behavior changes.

## Choose a guide

| Audience                    | Start here                                                                                        | Use it for                                                                                          |
| --------------------------- | ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| CLI users                   | [CLI reference](cli-reference.md)                                                                 | Exact commands, options, output contracts, exit codes, and confirmation rules                       |
| Project maintainers         | [Configuration](configuration.md)                                                                 | `sfdx-project.json`, `sf-project.config.json`, environment variables, defaults, and validation      |
| Adopters in another project | [Portability guide](portability-guide.md)                                                         | Minimal configuration, which defaults are required versus repository-specific, incremental adoption |
| Operators                   | [Workflows](workflows.md) and [operations and troubleshooting](operations-and-troubleshooting.md) | Ordering, side effects, dry runs, recovery, diagnostics, and failure handling                       |
| API consumers               | [Web API](web-api.md)                                                                             | Loopback security, endpoints, payloads, SSE, retention, and errors                                  |
| Frontend developers         | [Web frontend](web-frontend.md)                                                                   | Dashboard state, forms, policy behavior, Aksel, accessibility, and responsive layout                |
| Contributors                | [Development and testing](development-and-testing.md)                                             | Local setup, scripts, test doubles, validation, and extension patterns                              |
| Package owners              | [Packaging and extraction](packaging-and-extraction.md)                                           | npm contents, pack smoke, CI, repository extraction, and release gates                              |
| Architects                  | [Architecture](architecture.md)                                                                   | Layers, dependency direction, event lifecycle, adapters, and tradeoffs                              |

## Governing and historical documents

- [ADR-0001: CLI-first tool with shared application core](adr/0001-cli-first-shared-application-core.md) records the accepted architecture decision.
- [Legacy behaviour matrix](legacy-behavior-matrix.md) records implemented, corrected, deferred, and intentionally omitted behavior from the former scripts.
- [Documentation and engineering standards](documentation-standards.md) defines how this module documents source code, public contracts, architecture, operations, releases, and workflows.
- [Security policy](../SECURITY.md) defines the local trust boundary, implemented controls, residual risks, and reporting expectations.

## All documents

| Document                                                              | Contents                                                                                      |
| --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| [README](README.md)                                                   | This documentation map                                                                        |
| [Architecture](architecture.md)                                       | Layers, dependency direction, event lifecycle, adapters, and tradeoffs                        |
| [CLI reference](cli-reference.md)                                     | Exact commands, options, output contracts, exit codes, and confirmation rules                 |
| [Configuration](configuration.md)                                     | `sfdx-project.json`, `sf-project.config.json`, environment variables, defaults, validation    |
| [Development and testing](development-and-testing.md)                 | Local setup, scripts, test doubles, validation, and extension patterns                        |
| [Documentation and engineering standards](documentation-standards.md) | Source, API, and architecture documentation conventions for this module                       |
| [Legacy behaviour matrix](legacy-behavior-matrix.md)                  | Implemented, corrected, deferred, and intentionally omitted behavior from the former scripts  |
| [Operations and troubleshooting](operations-and-troubleshooting.md)   | Diagnostics, recovery, dry runs, and failure handling                                         |
| [Packaging and extraction](packaging-and-extraction.md)               | npm contents, pack smoke, CI, repository extraction, and release gates                        |
| [Portability guide](portability-guide.md)                             | Minimal configuration and adoption path for a project shaped differently than this repository |
| [Web API](web-api.md)                                                 | Loopback security, endpoints, payloads, SSE, retention, and errors                            |
| [Web frontend](web-frontend.md)                                       | Dashboard state, forms, policy behavior, Aksel, accessibility, and responsive layout          |
| [Workflows](workflows.md)                                             | Ordering, side effects, dry runs, and composed operation behavior                             |
| [ADR-0001](adr/0001-cli-first-shared-application-core.md)             | Accepted architecture decision: CLI-first tool with a shared application core                 |
| [Security policy](../SECURITY.md)                                     | Local trust boundary, implemented controls, residual risks, and reporting expectations        |

## Validation boundary

Unit, contract, component, and browser tests use fake command responses or an in-memory service facade. They validate local contracts without contacting Salesforce. Real org creation, package installation, deployment, retrieval, or authenticated compatibility requires an explicitly selected org, human approval, and a separate Salesforce validation run.
