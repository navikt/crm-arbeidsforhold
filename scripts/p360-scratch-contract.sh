#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORG="crm-arbeidsforhold"
MODE="${1:-verify}"
case "$MODE" in verify|test|regression|smoke|inspect|e2e) ;; *) echo "Use verify, test, regression, smoke, inspect or e2e." >&2; exit 2 ;; esac

WORK="$(mktemp -d)"
cleanup() {
    rm -f "$WORK/orgs.json" "$WORK/check.json" "$WORK/result.json" "$WORK/e2e.json"
    if [[ -d "$WORK/metadata" ]]; then
        rm -f "$WORK/metadata/package.xml"
        rm -f "$WORK/metadata/classes/P360_ScratchRpcClient.cls" "$WORK/metadata/classes/P360_ScratchRpcClient.cls-meta.xml"
        rm -f "$WORK/metadata/classes/P360_ScratchRpcClientTest.cls" "$WORK/metadata/classes/P360_ScratchRpcClientTest.cls-meta.xml"
        rm -f "$WORK/metadata/objects/P360ScratchCapture__c.object" "$WORK/metadata/objects/P360ScratchSetting__c.object"
        rm -f "$WORK/metadata/permissionsets/P360_Scratch_Capture_Access.permissionset"
        rm -f "$WORK/metadata/tabs/P360ScratchCapture__c.tab" "$WORK/metadata/layouts/P360ScratchCapture__c-P360 Scratch Capture.layout"
        rmdir "$WORK/metadata/classes" "$WORK/metadata/objects" "$WORK/metadata/permissionsets" "$WORK/metadata/tabs" "$WORK/metadata/layouts" "$WORK/metadata"
    fi
    if [[ -d "$WORK/flag" ]]; then
        rm -f "$WORK/flag/package.xml" "$WORK/flag/customMetadata/Feature_Flag.P360_Archive_Processing.md"
        rmdir "$WORK/flag/customMetadata" "$WORK/flag"
    fi
    rmdir "$WORK"
}
trap cleanup EXIT

sf org list --skip-connection-status --json > "$WORK/orgs.json"
jq -e --arg alias "$ORG" '
    [.result.scratchOrgs[] | select(.alias == $alias and .isScratch == true)
      | select(.instanceUrl | test("^https://[a-zA-Z0-9.-]+\\.scratch\\.my\\.salesforce\\.com$"))]
    | length == 1
' "$WORK/orgs.json" > /dev/null || {
    echo "STOP: The explicit target is not a locally identified scratch org." >&2
    exit 1
}
TARGET="$(jq -er --arg alias "$ORG" '.result.scratchOrgs[] | select(.alias == $alias) | .username | select(type == "string" and length > 0)' "$WORK/orgs.json")"
sf data query --target-org "$TARGET" --query "SELECT IsSandbox FROM Organization" --json > "$WORK/check.json"
jq -e '.status == 0 and .result.records[0].IsSandbox == true' "$WORK/check.json" > /dev/null
echo "Target verified: crm-arbeidsforhold, scratch domain and IsSandbox=true."

print_result() {
    jq '{
        status,
        deployment: (.result | {status, success, numberComponentErrors, numberTestErrors}),
        componentFailures: .result.details.componentFailures,
        summary: (.result.summary | {outcome, testsRan, passing, failing, skipped, testTotalTime}),
        tests: [.result.tests[]? | {FullName, Outcome, Message}],
        error: .message
    }' "$WORK/result.json"
}

deploy_metadata() {
    if ! sf project deploy start --metadata-dir "$WORK/metadata" --target-org "$TARGET" --test-level NoTestRun --wait 10 --json "$@" > "$WORK/result.json"; then
        print_result
        exit 1
    fi
    print_result
    jq -e '.status == 0 and .result.success == true' "$WORK/result.json" > /dev/null
}

if [[ "$MODE" == "verify" ]]; then
    mkdir -p "$WORK/metadata/classes" "$WORK/metadata/objects" "$WORK/metadata/permissionsets" "$WORK/metadata/tabs" "$WORK/metadata/layouts"
    cp "$ROOT/scripts/scratch/p360/package.xml" "$WORK/metadata/package.xml"
    cp "$ROOT/scripts/scratch/p360/classes/P360_ScratchRpcClient.cls" "$ROOT/scripts/scratch/p360/classes/P360_ScratchRpcClient.cls-meta.xml" "$WORK/metadata/classes/"
    cp "$ROOT/force-app/tests/classes/integration/p360/scratch/P360_ScratchRpcClientTest.cls" "$ROOT/force-app/tests/classes/integration/p360/scratch/P360_ScratchRpcClientTest.cls-meta.xml" "$WORK/metadata/classes/"
    cp "$ROOT/scripts/scratch/p360/objects/P360ScratchCapture__c.object" "$ROOT/scripts/scratch/p360/objects/P360ScratchSetting__c.object" "$WORK/metadata/objects/"
    cp "$ROOT/scripts/scratch/p360/permissionsets/P360_Scratch_Capture_Access.permissionset" "$WORK/metadata/permissionsets/"
    cp "$ROOT/scripts/scratch/p360/tabs/P360ScratchCapture__c.tab" "$WORK/metadata/tabs/"
    cp "$ROOT/scripts/scratch/p360/layouts/P360ScratchCapture__c-P360 Scratch Capture.layout" "$WORK/metadata/layouts/"
    deploy_metadata --dry-run
    deploy_metadata
fi

if [[ "$MODE" == "verify" || "$MODE" == "test" ]]; then
    if ! sf apex run test --target-org "$TARGET" --tests P360_ScratchRpcClientTest --synchronous --wait 10 --json > "$WORK/result.json"; then
        print_result
        exit 1
    fi
    print_result
    jq -e '.status == 0 and .result.summary.outcome == "Passed"' "$WORK/result.json" > /dev/null
fi

if [[ "$MODE" == "regression" ]]; then
    if ! sf apex run test --target-org "$TARGET" \
        --tests P360_ScratchRpcClientTest --tests P360_AdapterFactoryTest \
        --tests AAREG_FileMapperTest --tests AAREG_CreateDocumentMapperTest \
        --result-format json --wait 10 --json > "$WORK/result.json"; then
        print_result
        exit 1
    fi
    print_result
    jq -e '.status == 0 and .result.summary.outcome == "Passed"' "$WORK/result.json" > /dev/null
fi

if [[ "$MODE" == "verify" || "$MODE" == "smoke" ]]; then
    permission_status=0
    sf org assign permset --target-org "$TARGET" --name P360_Scratch_Capture_Access --json > "$WORK/result.json" || permission_status=$?
    if ! jq -e '
        ((.result.successes | length) + (.result.failures | length) > 0) and
        all(.result.failures[]?; .message | contains("Duplicate PermissionSetAssignment"))
    ' "$WORK/result.json" > /dev/null; then
        echo "FAIL: The current scratch user could not receive the capture permission set (CLI status $permission_status)." >&2
        exit 1
    fi
    echo "Scratch-only capture permission set is assigned to the current CLI user."
    if ! sf apex run --target-org "$TARGET" --file "$ROOT/scripts/apex/p360ScratchCapture.apex" --json > "$WORK/result.json"; then
        jq '{status, name, message, compileProblem: .result.compileProblem, exceptionMessage: .result.exceptionMessage}' "$WORK/result.json"
        exit 1
    fi
    jq -e '.status == 0 and .result.compiled == true and .result.success == true' "$WORK/result.json" > /dev/null
    jq -r '.result.logs | split("\n")[] | select(contains("|USER_DEBUG|") and contains("P360_SCRATCH_RESULT=")) | split("P360_SCRATCH_RESULT=")[1]' "$WORK/result.json" \
        | jq -e 'select(.simulationOnly == true and .filesVerified == 2 and .callouts == 0 and .productJobCountUnchanged == true and (.receipts | length) == 2)'
fi

if [[ "$MODE" == "verify" || "$MODE" == "smoke" || "$MODE" == "inspect" ]]; then
    case_key="$(printf 'CaseService/CreateCase\nScratch P360\nscratch-p360-smoke-case-v1' | shasum -a 256 | cut -d ' ' -f 1)"
    document_key="$(printf 'DocumentService/CreateDocument\nScratch P360\nscratch-p360-smoke-document-v1' | shasum -a 256 | cut -d ' ' -f 1)"
    sf data query --target-org "$TARGET" --query \
        "SELECT Name, Operation__c, Outcome__c, Attempts__c, RequestBody__c FROM P360ScratchCapture__c WHERE RequestKey__c IN ('$case_key', '$document_key')" \
        --json > "$WORK/result.json"
    jq -e '
        .status == 0 and .result.totalSize == 2 and
        all(.result.records[]; .Outcome__c == "Accepted") and
        ([.result.records[].RequestBody__c | fromjson | .parameter | select(has("Files")) | .Files[] | .Base64Data | @base64d] ==
         ["{\"kind\":\"synthetic-application\",\"submission\":1}", "Synthetic attachment without personal data."])
    ' "$WORK/result.json" > /dev/null
    jq '{
        persistentReceipts: .result.totalSize,
        filesVerifiedAfterCommit: 2,
        receipts: [.result.records[] | {Name, Operation__c, Outcome__c, Attempts__c}]
    }' "$WORK/result.json"
fi

if [[ "$MODE" == "e2e" ]]; then
    FLAG_SOURCE="$ROOT/force-app/integration/p360/customMetadata/Feature_Flag.P360_Archive_Processing.md-meta.xml"
    restore_flag() {
        if sf project deploy start --source-dir "$FLAG_SOURCE" --target-org "$TARGET" --test-level NoTestRun --wait 10 --json > "$WORK/flag.json"; then
            echo "Archive-processing flag restored from source (Is_Enabled__c=false)."
        else
            echo "WARNING: restore the archive-processing flag manually from $FLAG_SOURCE." >&2
        fi
        rm -f "$WORK/flag.json"
        cleanup
    }
    trap restore_flag EXIT
    for permset in P360_Scratch_Capture_Access P360_Code_Table_Access; do
        sf org assign permset --target-org "$TARGET" --name "$permset" --json > "$WORK/result.json" || true
        jq -e '((.result.successes | length) + (.result.failures | length) > 0) and
            all(.result.failures[]?; .message | contains("Duplicate PermissionSetAssignment"))' "$WORK/result.json" > /dev/null || {
            echo "FAIL: $permset could not be assigned to the scratch CLI user." >&2
            exit 1
        }
    done
    mkdir -p "$WORK/flag/customMetadata"
    cat > "$WORK/flag/package.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types><members>Feature_Flag.P360_Archive_Processing</members><name>CustomMetadata</name></types>
    <version>67.0</version>
</Package>
XML
    sed 's#<value xsi:type="xsd:boolean">false</value>#<value xsi:type="xsd:boolean">true</value>#' "$FLAG_SOURCE" \
        > "$WORK/flag/customMetadata/Feature_Flag.P360_Archive_Processing.md"
    sf project deploy start --metadata-dir "$WORK/flag" --target-org "$TARGET" --test-level NoTestRun --wait 10 --json > "$WORK/result.json"
    jq -e '.status == 0 and .result.success == true' "$WORK/result.json" > /dev/null
    echo "Archive-processing flag temporarily enabled in the scratch org."
    if ! sf apex run --target-org "$TARGET" --file "$ROOT/scripts/apex/p360ScratchSubmissionE2E.apex" --json > "$WORK/result.json"; then
        jq '{status, message, compileProblem: .result.compileProblem, exceptionMessage: .result.exceptionMessage}' "$WORK/result.json"
        exit 1
    fi
    jq -e '.status == 0 and .result.compiled == true and .result.success == true' "$WORK/result.json" > /dev/null || {
        jq '{status, compileProblem: .result.compileProblem, exceptionMessage: .result.exceptionMessage}' "$WORK/result.json"
        exit 1
    }
    jq -r '.result.logs | split("\n")[] | select(contains("|USER_DEBUG|") and contains("P360_E2E_RESULT=")) | split("P360_E2E_RESULT=")[1]' "$WORK/result.json" \
        > "$WORK/e2e.json"
    jq . "$WORK/e2e.json"
    jq -e 'select(.simulationOnly == true and .claimedJobs == 1 and .jobStatus == "Succeeded" and .filesVerified == 2
            and .callouts == 0 and (.receipts | length) == 2 and all(.receipts[]; .outcome == "Accepted"))' "$WORK/e2e.json" > /dev/null
fi
