# Adopting `sf-project` in another Salesforce DX project

This guide is for a team that wants to use `sf-project` for a Salesforce DX project shaped
differently than `crm-arbeidsforhold` — typically with no private dependency packages, no
Experience Cloud community, and no project-specific post-setup steps. It complements
[Configuration](configuration.md), which is the exact schema reference; this guide is the
shortest path to a working minimal setup and explains which defaults are genuinely portable
versus which ones happen to match this repository's conventions.

## Minimal configuration

A project with a single package directory, no declared dependencies, no community, and no
custom post-steps needs only `sfdx-project.json` (already required by Salesforce CLI) and,
optionally, a minimal `sf-project.config.json`:

`sfdx-project.json`:

```json
{
    "packageDirectories": [{ "path": "force-app", "default": true }]
}
```

`sf-project.config.json` (every field is optional; this file itself is optional):

```json
{
    "schemaVersion": 1,
    "defaultOrgAlias": "my-scratch-org"
}
```

Run `npm run sf-project:setup` (or `node scripts/setup-project.mjs --non-interactive` for a
non-interactive bootstrap) to generate this file interactively with portable defaults; see
[Configuration](configuration.md#sf-projectconfigjson).

With only this configuration:

- `sf-project doctor`, `sf-project org create`, `sf-project org delete`, `sf-project org
list/status/info`, and `sf-project packages plan/install/update` all work. `packages
plan/install/update` have nothing to do when `sfdx-project.json` declares no dependencies —
  they report an empty plan rather than failing.
- `sf-project project configure` runs the default post-step (`deploy`), since `postSteps`
  defaults to `["deploy"]`.
- `sf-project dependencies clear/refresh` have nothing to do and complete immediately, since
  there are no declared dependency source directories.

## What each default assumes, and what is genuinely required

| Behavior                                                      | Default                                                       | Required, or a convenience default?                                                                                                                                                                                                                                                                                             |
| ------------------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sfdx-project.json` with a non-empty `packageDirectories`     | N/A                                                           | **Required.** This is Salesforce CLI's own project marker; `sf-project` cannot run without it.                                                                                                                                                                                                                                  |
| `sf-project.config.json` itself                               | Absent is fine                                                | **Convenience.** Every field has a portable default (see [Configuration](configuration.md#sf-projectconfigjson)); the file only needs to exist to override one.                                                                                                                                                                 |
| `scratchDefinition: "config/project-scratch-def.json"`        | Convenience                                                   | Only resolved (and required to exist) when a command actually creates a scratch org (`org create` without a pool). Not needed for `packages plan`, `doctor`, etc.                                                                                                                                                               |
| `postSteps: ["deploy"]`                                       | Convenience                                                   | `deploy` is the only post-step with a command in every project (it does not depend on optional configuration like `permissionSets`). `permsets`, `data`, and `community` are safe to select even when unconfigured — they emit a warning and are skipped, they do not fail.                                                     |
| `pool.use: false`                                             | Convenience                                                   | Scratch-org pool support requires `sfp` and Dev Hub access; leave it `false` unless the project actually operates a pool.                                                                                                                                                                                                       |
| Dependency declarations (`packageDirectories[].dependencies`) | Absent is fine                                                | Only needed for a project that installs other Salesforce packages as dependencies. A project with a single package needs none.                                                                                                                                                                                                  |
| `dependencySourcePolicy.requireLocalDirectories: true`        | **Repository-specific choice**, not a portability requirement | `crm-arbeidsforhold` vendors a local source folder for every dependency package and wants a missing one to fail loudly. A project that manages dependencies purely through installed package IDs (no local source folders) should set this to `false` — see [Configuration](configuration.md#sfdx-projectjson) and issue #1042. |
| `customPostSteps: []`                                         | Absent is fine                                                | Only needed for a project-specific setup step beyond `deploy`/`permsets`/`data`/`community` (see [Configuration](configuration.md#sf-projectconfigjson) and issue #1043). Not part of the interactive setup script; add it to `sf-project.config.json` by hand.                                                                 |
| `packageInstallKeyEnvironmentVariable: "PACKAGE_INSTALL_KEY"` | Convenience                                                   | Only read when a package that requires an installation key is actually installed. Rename it if the project already uses a different environment variable convention.                                                                                                                                                            |

## Incremental adoption path

1. Start with the minimal configuration above and confirm `sf-project doctor` passes.
2. Add `postSteps`/`permissionSets`/`dummyDataPlan`/`communityName` only for the post-steps the
   project actually uses.
3. Add `packageDirectories[].dependencies` (and matching package directories, or
   `dependencySourcePolicy.requireLocalDirectories: false` if the project does not vendor
   dependency source locally) only once the project actually depends on other packages.
4. Add `customPostSteps` only once a built-in step is not enough.
5. Use `sf-project project configure --skip-packages --post-steps <steps>` (see
   [CLI reference](cli-reference.md#project-configure)) to iterate on post-step configuration
   against an already-created org, without recreating it or reinstalling packages each time.

## Known repository-specific conventions that are not required elsewhere

These are conveniences that happen to match `crm-arbeidsforhold`'s own setup and are safe to
ignore or override in another project:

- The example values throughout `docs/configuration.md` (`crm-arbeidsforhold`, `Aa-registret`,
  package names like `shared-package`) are illustrative only; nothing in the schema or code
  requires them.
- `dependencySourcePolicy.requireLocalDirectories` defaults to `true` because that is
  `crm-arbeidsforhold`'s own preference (see above); it is not a tool-wide requirement.
- The interactive setup script's post-steps prompt only lists the four built-in step names; it
  does not currently prompt for `customPostSteps`. A project that needs a custom step adds it to
  `sf-project.config.json` directly (see [Configuration](configuration.md#sf-projectconfigjson)).

No other hardcoded, non-overridable repository-specific assumption was found during this audit
(2026-09, alongside #1041–#1043). If you find one while adopting the tool elsewhere, file it as
its own issue rather than working around it silently, so the fix benefits every adopter.
