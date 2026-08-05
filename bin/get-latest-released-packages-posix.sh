#!/bin/sh
set -eu

PROJECT_FILE="${1:-sfdx-project.json}"

if ! command -v jq >/dev/null 2>&1; then
  echo "Feil: jq er ikkje installert." >&2
  exit 1
fi

if ! command -v sf >/dev/null 2>&1; then
  echo "Feil: Salesforce CLI (sf) er ikkje installert." >&2
  exit 1
fi

if [ ! -f "$PROJECT_FILE" ]; then
  echo "Feil: Fann ikkje fil: $PROJECT_FILE" >&2
  exit 1
fi

PACKAGES=$(
  jq -r '
    [
      .packageDirectories[]?.dependencies[]?
      | select(.versionNumber | endswith(".LATEST"))
      | .package
    ]
    | unique[]
  ' "$PROJECT_FILE"
)

if [ -z "$PACKAGES" ]; then
  echo "Ingen dependencies med .LATEST vart funne i $PROJECT_FILE"
  exit 0
fi

printf '%s\n' "$PACKAGES" | while IFS= read -r package; do
  [ -n "$package" ] || continue

  echo "=== $package ==="

  result=$(
    sf package version list \
      --released \
      --json \
      --packages "$package"
  )

  printf '%s\n' "$result" | jq '
    .result
    | sort_by(
        .MajorVersion,
        .MinorVersion,
        .PatchVersion,
        .BuildNumber
      )
    | last
    | {
        package: .Package2Name,
        version: .Version,
        subscriberPackageVersionId: .SubscriberPackageVersionId,
        packageVersionId: .Id,
        createdDate: .CreatedDate,
        installUrl: .InstallUrl
      }
  '

  echo
done
