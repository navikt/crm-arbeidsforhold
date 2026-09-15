#!/usr/bin/env bash

set -euo pipefail

ORG_ALIAS="crm-arbeidsforhold"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APEX_SCRIPT="$PROJECT_ROOT/scripts/apex/p360MockArchiveFlow.apex"
APEX_RESULT="$(mktemp)"
JOBS_RESULT="$(mktemp)"
DUPLICATES_RESULT="$(mktemp)"
WORKER_RESULT="$(mktemp)"
RUN_STARTED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

cleanup() {
    rm -f "$APEX_RESULT" "$JOBS_RESULT" "$DUPLICATES_RESULT" "$WORKER_RESULT"
}
trap cleanup EXIT

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "FAIL: Required command not found: $1" >&2
        exit 1
    fi
}

print_check() {
    local result="$1"
    local message="$2"
    printf "  %-4s %s\n" "$result" "$message"
}

run_query() {
    local query="$1"
    local output_file="$2"
    local label="$3"

    if ! sf data query --target-org "$ORG_ALIAS" --query "$query" --json > "$output_file"; then
        printf "FAIL: Could not query %s.\n" "$label"
        jq -r '.message // .data.message // "Unknown Salesforce query error"' "$output_file"
        exit 1
    fi
}

require_command sf
require_command jq

printf "P360 mock smoke test\n"
printf "Target org: %s\n\n" "$ORG_ALIAS"

if ! sf apex run --target-org "$ORG_ALIAS" --file "$APEX_SCRIPT" --json > "$APEX_RESULT"; then
    echo "FAIL: Anonymous Apex command failed."
    jq -r '.result.compileProblem // .result.exceptionMessage // .message // "Unknown Salesforce CLI error"' "$APEX_RESULT"
    exit 1
fi

if [[ "$(jq -r '.status == 0 and .result.compiled and .result.success' "$APEX_RESULT")" != "true" ]]; then
    echo "FAIL: Mock setup did not execute successfully."
    jq -r '.result.compileProblem // .result.exceptionMessage // .message // "Unknown Apex error"' "$APEX_RESULT"
    exit 1
fi

smoke_payload="$({
    jq -r '
        .result.logs
        | split("\n")
        | map(select(test("\\|USER_DEBUG\\|.*\\|DEBUG\\|P360_SMOKE_RESULT=")))
        | first
        | capture("P360_SMOKE_RESULT=(?<payload>\\{.*\\})").payload
    ' "$APEX_RESULT"
} 2>/dev/null || true)"

if [[ -z "$smoke_payload" || "$smoke_payload" == "null" ]]; then
    echo "FAIL: Apex completed, but P360_SMOKE_RESULT was not found in the debug log."
    exit 1
fi

application_id="$(jq -r '.applicationId' <<< "$smoke_payload")"
attachment_id="$(jq -r '.attachmentId' <<< "$smoke_payload")"
document_job_id="$(jq -r '.documentJobId' <<< "$smoke_payload")"

for worker_check in 1 2 3 4 5; do
    run_query \
        "SELECT Id, Status, NumberOfErrors, CompletedDate FROM AsyncApexJob WHERE ApexClass.Name = 'P360_ArchiveJobWorker' AND CreatedDate >= $RUN_STARTED_AT ORDER BY CreatedDate DESC LIMIT 1" \
        "$WORKER_RESULT" \
        "queueable worker status"

    worker_status="$(jq -r '.result.records[0].Status // "Not found"' "$WORKER_RESULT")"
    if [[ "$worker_status" == "Completed" || "$worker_status" == "Failed" || "$worker_status" == "Aborted" ]]; then
        break
    fi
done

run_query \
    "SELECT Id, Archive_Event_Type__c, Status__c, Attempt_Count__c, Idempotency_Key__c, Started_Date__c, Last_Error_Code__c, Last_Error_Message__c FROM P360_Archive_Job__c WHERE Application__c = '$application_id' ORDER BY CreatedDate ASC" \
    "$JOBS_RESULT" \
    "archive jobs"

run_query \
    "SELECT Idempotency_Key__c, COUNT(Id) jobCount FROM P360_Archive_Job__c WHERE Application__c = '$application_id' GROUP BY Idempotency_Key__c HAVING COUNT(Id) > 1" \
    "$DUPLICATES_RESULT" \
    "duplicate idempotency keys"

job_count="$(jq -r '.result.totalSize' "$JOBS_RESULT")"
expected_types="$(jq -r '[.result.records[].Archive_Event_Type__c] | sort == ["ApplicationAttachment", "ApplicationDocument"]' "$JOBS_RESULT")"
all_succeeded="$(jq -r '[.result.records[].Status__c] | length == 2 and all(. == "Succeeded")' "$JOBS_RESULT")"
all_attempted_once="$(jq -r '[.result.records[].Attempt_Count__c] | length == 2 and all(. == 1)' "$JOBS_RESULT")"
duplicate_count="$(jq -r '.result.totalSize' "$DUPLICATES_RESULT")"
worker_completed="$(jq -r '.result.totalSize == 1 and .result.records[0].Status == "Completed" and .result.records[0].NumberOfErrors == 0' "$WORKER_RESULT")"
worker_id="$(jq -r '.result.records[0].Id // "Not found"' "$WORKER_RESULT")"
worker_errors="$(jq -r '.result.records[0].NumberOfErrors // "Unknown"' "$WORKER_RESULT")"

printf "Created records\n"
printf "  Application:     %s\n" "$application_id"
printf "  ContentVersion:  %s\n" "$attachment_id"
printf "  Document job:    %s\n\n" "$document_job_id"

printf "Queueable worker\n"
printf "  ID:      %s\n" "$worker_id"
printf "  Status:  %s\n" "$worker_status"
printf "  Errors:  %s\n\n" "$worker_errors"

printf "Archive jobs\n"
printf "  %-22s %-12s %-8s %s\n" "TYPE" "STATUS" "ATTEMPTS" "ID"
jq -r '.result.records[] | [.Archive_Event_Type__c, .Status__c, (.Attempt_Count__c | tostring), .Id] | @tsv' "$JOBS_RESULT" \
    | while IFS=$'\t' read -r event_type job_status attempts job_id; do
        printf "  %-22s %-12s %-8s %s\n" "$event_type" "$job_status" "$attempts" "$job_id"
    done
printf "\n"

printf "Checks\n"
print_check "PASS" "Anonymous Apex compiled and executed"
[[ "$job_count" == "2" ]] && print_check "PASS" "Exactly two archive jobs were created" || print_check "FAIL" "Expected two archive jobs, found $job_count"
[[ "$expected_types" == "true" ]] && print_check "PASS" "ApplicationDocument and ApplicationAttachment are present" || print_check "FAIL" "Expected archive event types were not found"
[[ "$all_succeeded" == "true" ]] && print_check "PASS" "Both archive jobs succeeded" || print_check "FAIL" "One or more archive jobs did not succeed"
[[ "$all_attempted_once" == "true" ]] && print_check "PASS" "Each archive job was attempted once" || print_check "FAIL" "Unexpected attempt count"
[[ "$duplicate_count" == "0" ]] && print_check "PASS" "No duplicate idempotency keys" || print_check "FAIL" "Found $duplicate_count duplicate idempotency keys"
[[ "$worker_completed" == "true" ]] && print_check "PASS" "Queueable worker completed with zero errors" || print_check "FAIL" "Queueable worker did not complete cleanly"
print_check "PASS" "Mock transport was used; no live P360 callout was made"

if [[ "$job_count" != "2" || "$expected_types" != "true" || "$all_succeeded" != "true" || "$all_attempted_once" != "true" || "$duplicate_count" != "0" || "$worker_completed" != "true" ]]; then
    printf "\nResult: FAIL\n"
    printf "Mock mode remains enabled in %s.\n" "$ORG_ALIAS"
    exit 1
fi

printf "\nResult: PASS\n"
printf "Mock mode remains enabled in %s.\n" "$ORG_ALIAS"
