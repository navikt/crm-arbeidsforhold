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
$PSNativeCommandArgumentPassing = 'Standard'

function Get-SfCommandDisplay {
    param([string[]]$Arguments)

    $displayArguments = @($Arguments)
    $keyIndex = [array]::IndexOf($displayArguments, '--installation-key')
    if ($keyIndex -ge 0 -and $keyIndex + 1 -lt $displayArguments.Count) {
        $displayArguments[$keyIndex + 1] = '<redacted>'
    }

    return "sf $($displayArguments -join ' ')"
}

function Invoke-SfJson {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    Write-Host "-> $(Get-SfCommandDisplay $Arguments)" -ForegroundColor DarkGray
    $raw = & sf @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $message = try { ($raw | ConvertFrom-Json -ErrorAction Stop).message } catch { $null }
        $detail = if ($message) { ": $message" } else { '' }
        throw "Command failed with exit code ${exitCode}$detail ($(Get-SfCommandDisplay $Arguments))"
    }
    if (-not $raw) {
        throw "No output from sf command: $(Get-SfCommandDisplay $Arguments)"
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
        [string[]]$Arguments
    )

    Write-Host "-> $(Get-SfCommandDisplay $Arguments)" -ForegroundColor DarkGray
    & sf @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Command failed with exit code ${exitCode}: $(Get-SfCommandDisplay $Arguments)"
    }
}

function Invoke-ShellNoThrow {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    Write-Host "-> $(Get-SfCommandDisplay $Arguments)" -ForegroundColor DarkGray
    $output = & sf @Arguments
    $exitCode = $LASTEXITCODE
    return @{
        Output = $output
        ExitCode = $exitCode
    }
}

Write-Host "=== Post-package coverage check ===" -ForegroundColor Cyan
Write-Host "Target org: $TargetOrg"
Write-Host "Minimum coverage threshold: $MinCoverage%"

if (-not $SkipInstall -and $PackageId) {
    $installArgs = @('force:package:install', '--target-org', $TargetOrg, '--package', $PackageId, '-r', '--json')
    if ($InstallationKey) {
        $installArgs += @('--installation-key', $InstallationKey)
    }
    [void](Invoke-SfJson -Arguments $installArgs)
    Write-Host "Package install completed." -ForegroundColor Green
} elseif (-not $SkipInstall -and -not $PackageId) {
    Write-Host "Package install skipped (no PackageId provided)." -ForegroundColor Yellow
} else {
    Write-Host "Package install skipped by flag." -ForegroundColor Yellow
}

if (-not $SkipDeploy) {
    [void](Invoke-SfJson -Arguments @('project', 'deploy', 'start', '--target-org', $TargetOrg, '--source-dir', 'force-app', '--ignore-conflicts', '--json'))
    Write-Host "Deploy completed." -ForegroundColor Green
} else {
    Write-Host "Deploy skipped by flag." -ForegroundColor Yellow
}

if ($TestRunAll) {
    try {
        [void](Invoke-SfJson -Arguments @('apex', 'run', 'test', '--target-org', $TargetOrg, '--code-coverage', '--wait', '120', '--json'))
    } catch {
        Write-Host "All-tests with --wait failed, retrying with async fallback." -ForegroundColor Yellow
        $runAll = Invoke-SfJson -Arguments @('apex', 'run', 'test', '--target-org', $TargetOrg, '--code-coverage', '--json')
        $testRunId = $runAll.result.testRunId
        if ([string]::IsNullOrWhiteSpace($testRunId)) {
            throw "Could not parse testRunId from async test run output."
        }

        Write-Host "Async test run started: $testRunId" -ForegroundColor Yellow
        $getResult = Invoke-ShellNoThrow -Arguments @('apex', 'get', 'test', '--target-org', $TargetOrg, '--test-run-id', $testRunId, '--code-coverage', '--result-format', 'human')
        if ($getResult.ExitCode -ne 0) {
            Write-Host "Warning: sf apex get test returned exit code $($getResult.ExitCode). Continuing with coverage query." -ForegroundColor Yellow
        }
    }
} else {
    Invoke-ShellChecked -Arguments @('apex', 'run', 'test', '--target-org', $TargetOrg, '--tests', $TestClass, '--code-coverage', '--synchronous', '--result-format', 'human')
}

$query = "SELECT SUM(NumLinesCovered) covered, SUM(NumLinesUncovered) uncovered FROM ApexCodeCoverageAggregate WHERE ApexClassOrTrigger.Name LIKE 'AAREG_%'"
$aggregate = Invoke-SfJson -Arguments @('data', 'query', '--target-org', $TargetOrg, '--use-tooling-api', '--query', $query, '--result-format', 'json')

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
