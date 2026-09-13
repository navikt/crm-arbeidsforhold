# Web API

The local server is a privileged developer-tool adapter over the shared application services. It is not a network service and cannot bind beyond IPv4 loopback.

## Lifecycle

Start the production dashboard with:

```bash
sf-project web start --project-dir /path/to/project
sf-project web start --project-dir /path/to/project --port 4310
```

The CLI loads project configuration, creates the production facade, starts the server on `127.0.0.1`, and prints only the URL. The default port is `1717`; port `0` selects an available port. Built assets default to `web-dist`. The listening server keeps the process alive. The normal CLI path does not install explicit shutdown handlers; embedded callers receive a handle whose `close()` ends SSE responses and the HTTP server.

History is bounded process memory and disappears when the process exits.

## Bootstrap and authentication

Each server process generates 32 random bytes and encodes them as a 64-character hexadecimal bearer token. `GET /` injects it into the built HTML:

```html
<meta name="sf-project-session-token" content="..." />
```

The browser reads the token from the meta element. It is not placed in the URL, local storage, normal CLI output, or retained API fields. Embedded callers receive it in memory on the returned server handle and must not log or persist it.

Every request requires an exact `Host` value of `127.0.0.1:<bound-port>` or receives `421`. `GET /api/v1/health` is the only unauthenticated API route. All other `/api/v1` and SSE requests require:

```text
Authorization: Bearer <session-token>
```

Bearer comparison is length-checked and timing-safe. Every POST additionally requires an HTTP `Origin` whose host exactly matches the request `Host` and whose hostname is `127.0.0.1`; missing or mismatched origin receives `403`.

Use placeholders in diagnostics and examples. Never paste a real token into documentation, issues, or logs:

```bash
BASE_URL='http://127.0.0.1:1717'
SESSION_TOKEN='<ephemeral-token-from-the-served-page>'

curl --fail-with-body "$BASE_URL/api/v1/health"
curl --fail-with-body \
  -H "Authorization: Bearer $SESSION_TOKEN" \
  "$BASE_URL/api/v1/orgs"
```

## Limits and retention

| Limit                         |                                            Default |
| ----------------------------- | -------------------------------------------------: |
| Request body                  |                                             64 KiB |
| String value                  | 1,024 characters, non-empty, no control characters |
| Retained operations           |                                                100 |
| Retained events per operation |                                                500 |
| Total SSE subscribers         |                                                 32 |
| SSE subscribers per operation |                                                  4 |

When operation capacity is exceeded, the oldest operation is removed and its subscribers are closed. When event capacity is exceeded, oldest events are dropped. Limit overrides are available only to embedded callers of `startWebServer`, must be positive integers, and are not CLI flags.

## Response models

Org summaries include nullable alias, username, org ID, expiration and lifetime data; normalized org, connection, authentication, and instance classifications; default flags; source tracking; refresh timestamp; and `{sourceTracking, mutationPolicy}` capabilities. Org detail adds nullable API version, edition, creation date, and Dev Hub username. Instance URLs are classified but not returned.

Package status returns:

```json
{
    "targetOrg": "feature-org",
    "packages": [
        {
            "packageName": "shared-package",
            "configuredVersion": "2.4.0.LATEST",
            "installedVersion": "2.3.0.7",
            "selectedVersion": "2.4.0.3",
            "status": "update-available"
        }
    ],
    "summary": {
        "total": 1,
        "current": 0,
        "updateAvailable": 1,
        "higher": 0,
        "missing": 0,
        "unknown": 0
    }
}
```

Operation records contain `id`, `command`, `status`, `createdAt`, optional `completedAt`, optional `exitCode`, and retained `events`. Lists are newest first. Status is `running`, `completed`, or `failed`; only exit code `0` becomes `completed`.

## Endpoints

| Method and path                      | Success                                 | Behavior and failures                                              |
| ------------------------------------ | --------------------------------------- | ------------------------------------------------------------------ |
| `GET /`                              | `200` HTML                              | Injects bootstrap token; `404` when the web app is not built       |
| `GET /api/v1/health`                 | `200 {"status":"ok","apiVersion":"v1"}` | No bearer token required                                           |
| `GET /api/v1/orgs`                   | `200` org-list result                   | Facade failure is redacted `500`                                   |
| `GET /api/v1/orgs/:alias`            | `200` org result                        | Alias is URI-decoded; facade failure is redacted `404`             |
| `GET /api/v1/orgs/:alias/packages`   | `200` package status                    | Facade failure is redacted `500`                                   |
| `GET /api/v1/operations`             | `200` operation array                   | Newest first                                                       |
| `GET /api/v1/operations/:id`         | `200` operation                         | Unknown ID is `404`                                                |
| `GET /api/v1/operations/:id/events`  | `200` SSE                               | Unknown ID is `404`; capacity is `429`                             |
| `POST /api/v1/operations`            | `202 {"id":"..."}`                      | Invalid payload `400`; oversized body `413`; denied mutation `403` |
| `POST /api/v1/operations/:id/cancel` | `202 {"cancelled":true}`                | Unsupported or refused cancellation is `409`                       |

Unknown routes and disallowed static assets return `404`. Request `Content-Type` is not enforced, but the body must parse as JSON for operation creation.

## Operation requests

The top-level body must contain exactly `command` and `payload`; unknown fields are rejected. Payloads also use exact allowlists.

| Command                | Allowed payload                                                                                                                                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dependencies.clear`   | `{dryRun?: boolean}`                                                                                                                                                                                                                                  |
| `dependencies.refresh` | `{targetOrg?: string, dryRun?: boolean}`                                                                                                                                                                                                              |
| `packages.plan`        | `{targetOrg?: string, installLatest?: boolean, dryRun?: boolean}`                                                                                                                                                                                     |
| `packages.install`     | `{targetOrg?: string, installLatest?: boolean, dryRun?: boolean}`                                                                                                                                                                                     |
| `packages.update`      | `{targetOrg?: string, installLatest?: boolean, dryRun?: boolean}`                                                                                                                                                                                     |
| `org.create`           | `{alias: string, durationDays?: integer 1..30, postSteps?: PostStep[], usePool?: boolean, poolTag?: string, poolDevHub?: string, fallbackToCreate?: boolean, clearDependencySources?: boolean, refreshDependencySources?: boolean, dryRun?: boolean}` |
| `org.delete`           | `{alias: string, confirmed?: boolean, dryRun?: boolean}`; real execution requires `confirmed: true`                                                                                                                                                   |
| `project.configure`    | `{alias?: string, postSteps?: PostStep[], refreshDependencySources?: boolean, dryRun?: boolean}`                                                                                                                                                      |

`PostStep` is one of `deploy`, `permsets`, `data`, or `community`. Strings must be non-empty, at most 1,024 characters, and contain no control characters.

Example dry-run request:

```bash
curl --fail-with-body \
  -X POST \
  -H "Authorization: Bearer $SESSION_TOKEN" \
  -H "Origin: $BASE_URL" \
  -H 'Content-Type: application/json' \
  --data '{"command":"packages.install","payload":{"targetOrg":"feature-org","dryRun":true}}' \
  "$BASE_URL/api/v1/operations"
```

Example confirmed scratch-org deletion:

```bash
curl --fail-with-body \
  -X POST \
  -H "Authorization: Bearer $SESSION_TOKEN" \
  -H "Origin: $BASE_URL" \
  -H 'Content-Type: application/json' \
  --data '{"command":"org.delete","payload":{"alias":"feature-org","confirmed":true}}' \
  "$BASE_URL/api/v1/operations"
```

## Mutation authorization

Dry runs, package plan, dependency clear, and org creation do not trigger target preauthorization in the HTTP adapter. Real package install/update and dependency refresh resolve `targetOrg` or the configured default; project configure resolves its payload alias or configured default; org delete resolves its required alias. The server calls `getOrgStatus` and allows dispatch only when mutation policy is `allowed`.

Production, Dev Hub, development, sandbox, and unknown orgs are read-only by default. The standard policy allows mutations only for scratch orgs; an HTTP caller must use the exact command-and-org confirmation contract exposed by the application service for an override. Server preauthorization is a defense in depth layer, not a substitute for service policy.

When no target is in a web package/configure payload, preauthorization resolves `sf-project.config.json` `defaultOrgAlias`. This can differ from Salesforce CLI `target-org`; operators should configure targets explicitly to avoid checking one default and mutating another.

## SSE

The events route responds as `text/event-stream`, replays retained events in order, then subscribes the connection to live events:

```text
event: operation
data: {"kind":"progress","operationId":"...","timestamp":"..."}
```

Every accepted operation receives server-owned `operation-started` and exactly one replayable `operation-completed`. A rejected facade promise also produces a redacted `step-failed` followed by terminal failure. The standard facade has no cancellation implementation.

The stream has no heartbeat, SSE `id`, `Last-Event-ID` support, resume cursor, or automatic reconnect contract. Clients should treat disconnect as loss of the live stream and refetch operation history when appropriate.

Example stream:

```bash
OPERATION_ID='<id-returned-by-operation-create>'
curl --no-buffer \
  -H "Authorization: Bearer $SESSION_TOKEN" \
  "$BASE_URL/api/v1/operations/$OPERATION_ID/events"
```

## Errors, redaction, and static assets

JSON errors use `{ "error": "message" }`. Errors, API values, stored history, and SSE events remove recursively named sensitive fields and redact the session token, configured install key, Salesforce access-token patterns, and auth URLs. Raw command environments are never exposed.

Responses set no-store for HTML/API/SSE and include CSP, same-origin opener policy, no-referrer, MIME-sniff prevention, and frame denial. Static assets are limited to CSS, JavaScript, source-map, SVG, WOFF, and WOFF2 extensions and must pass lexical and realpath containment checks. Although `.map` is an allowed server extension, the pack smoke rejects source maps from the npm artifact.

See [Security](../SECURITY.md) for the trust boundary and residual risks.
