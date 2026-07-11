param(
    [string]$TargetOrg = "crm-arbeidsforhold",
    [string]$PackageId,
    [string]$InstallationKey,
    [double]$MinCoverage = 75,
    [switch]$SkipInstall,
    [switch]$SkipDeploy,
    [switch]$TestRunAll,
    [string]$TestClass = "AAREG_ApplicationDecisionControllerTest"
)

$ErrorActionPreference = "Stop"

function Invoke-SfJson {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    Write-Host "-> $Command" -ForegroundColor DarkGray
    $raw = Invoke-Expression $Command
    if (-not $raw) {
        throw "No output from command: $Command"
    }

    $json = $raw | ConvertFrom-Json
    if ($json.status -ne 0) {
        $message = if ($json.message) { $json.message } else { "Unknown SF CLI error" }
        throw "Command failed: $message"
    }

    return $json
}

function Invoke-ShellChecked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    Write-Host "-> $Command" -ForegroundColor DarkGray
    Invoke-Expression $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command"
    }
}

function Invoke-ShellNoThrow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    Write-Host "-> $Command" -ForegroundColor DarkGray
    $output = Invoke-Expression $Command
    return @{
        Output = $output
        ExitCode = $LASTEXITCODE
    }
}

Write-Host "=== Post-package coverage check ===" -ForegroundColor Cyan
Write-Host "Target org: $TargetOrg"
Write-Host "Minimum coverage threshold: $MinCoverage%"

if (-not $SkipInstall -and $PackageId) {
    $installCmd = "sf force:package:install --target-org $TargetOrg --package $PackageId -r --json"
    if ($InstallationKey) {
        $installCmd += " --installation-key $InstallationKey"
    }
    [void](Invoke-SfJson -Command $installCmd)
    Write-Host "Package install completed." -ForegroundColor Green
} elseif (-not $SkipInstall -and -not $PackageId) {
    Write-Host "Package install skipped (no PackageId provided)." -ForegroundColor Yellow
} else {
    Write-Host "Package install skipped by flag." -ForegroundColor Yellow
}

if (-not $SkipDeploy) {
    [void](Invoke-SfJson -Command "sf project deploy start --target-org $TargetOrg --source-dir force-app --ignore-conflicts --json")
    Write-Host "Deploy completed." -ForegroundColor Green
} else {
    Write-Host "Deploy skipped by flag." -ForegroundColor Yellow
}

if ($TestRunAll) {
    try {
        [void](Invoke-SfJson -Command "sf apex run test --target-org $TargetOrg --code-coverage --wait 120 --json")
    } catch {
        Write-Host "All-tests with --wait failed, retrying with async fallback." -ForegroundColor Yellow
        $runAll = Invoke-SfJson -Command "sf apex run test --target-org $TargetOrg --code-coverage --json"
        $testRunId = $runAll.result.testRunId
        if ([string]::IsNullOrWhiteSpace($testRunId)) {
            throw "Could not parse testRunId from async test run output."
        }

        Write-Host "Async test run started: $testRunId" -ForegroundColor Yellow
        $getResult = Invoke-ShellNoThrow -Command "sf apex get test --target-org $TargetOrg --test-run-id $testRunId --code-coverage --result-format human"
        if ($getResult.ExitCode -ne 0) {
            Write-Host "Warning: sf apex get test returned exit code $($getResult.ExitCode). Continuing with coverage query." -ForegroundColor Yellow
        }
    }
} else {
    $testCmd = "sf apex run test --target-org $TargetOrg --tests $TestClass --code-coverage --synchronous --result-format human"
    Invoke-ShellChecked -Command $testCmd
}

$queryCmd = "sf data query --target-org $TargetOrg --use-tooling-api --query `"SELECT SUM(NumLinesCovered) covered, SUM(NumLinesUncovered) uncovered FROM ApexCodeCoverageAggregate WHERE ApexClassOrTrigger.Name LIKE 'AAREG_%'`" --result-format json"
$aggregate = Invoke-SfJson -Command $queryCmd

$covered = [double]$aggregate.result.records[0].covered
$uncovered = [double]$aggregate.result.records[0].uncovered
$total = $covered + $uncovered
$percent = if ($total -gt 0) { [math]::Round(($covered / $total) * 100, 2) } else { 0 }

Write-Host "=== AAREG Aggregate Coverage ===" -ForegroundColor Cyan
Write-Host "Covered:   $covered"
Write-Host "Uncovered: $uncovered"
Write-Host "Percent:   $percent%"

if ($percent -lt $MinCoverage) {
    Write-Host "Coverage is below $MinCoverage%." -ForegroundColor Yellow
    exit 2
}

Write-Host "Coverage is at or above $MinCoverage%." -ForegroundColor Green
