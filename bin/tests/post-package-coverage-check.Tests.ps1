param([switch]$RequireWindows)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -ne 7) { throw 'Run this harness with PowerShell 7.' }
if ($RequireWindows -and -not $IsWindows) { throw '-RequireWindows must run on Windows; skipping Windows coverage is not allowed.' }

$ScriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'post-package-coverage-check.ps1'
$FixturePath = Join-Path $PSScriptRoot 'fixtures/post-package-coverage-cli.ps1'
$HostPath = (Get-Process -Id $PID).Path
$WorkDirectory = Join-Path $PSScriptRoot ('.post-package-coverage-tests-' + [guid]::NewGuid().ToString('N'))
$FakeBin = Join-Path $WorkDirectory 'fake-bin'
$LogPath = Join-Path $WorkDirectory 'calls.jsonl'
$MarkerPath = Join-Path $WorkDirectory 'injection-marker'
$Passed = 0
$Failures = 0
$Skipped = 0
$Calls = @()
$CoverageJson = '{"status":0,"result":{"records":[{"covered":80,"uncovered":20}]}}'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:Passed++; Write-Host "PASS: $Message" }
    else { $script:Failures++; Write-Host "FAIL: $Message" }
}

function Assert-Exit {
    param($Result, [int]$Expected, [string]$Message)
    $detail = if ($Result.ExitCode -eq $Expected) { $Message } else { "$Message (exit $($Result.ExitCode)): $($Result.Output)" }
    Assert-True ($Result.ExitCode -eq $Expected) $detail
}

function Get-ArgumentValue {
    param($Call, [string]$Option)
    $arguments = @($Call.arguments)
    for ($index = 0; $index -lt $arguments.Count - 1; $index++) {
        if ($arguments[$index] -ceq $Option) { return $arguments[$index + 1] }
    }
    return $null
}

function Reset-Scenario {
    [IO.File]::WriteAllText($LogPath, '')
    if (Test-Path -LiteralPath $MarkerPath) { Remove-Item -LiteralPath $MarkerPath -Force }
}

function Invoke-Scenario {
    param(
        [string[]]$Options = @(),
        [hashtable]$Environment = @{}
    )
    Reset-Scenario
    $info = [Diagnostics.ProcessStartInfo]::new($HostPath)
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.WorkingDirectory = $WorkDirectory
    foreach ($argument in @('-NoLogo', '-NoProfile', '-File', $ScriptPath) + $Options) { $info.ArgumentList.Add($argument) }

    foreach ($name in @($info.Environment.Keys)) {
        if ($name -match '^(SF_|SFDX_|COVERAGE_)') { $info.Environment.Remove($name) | Out-Null }
    }
    $pathEntries = @($FakeBin)
    if ($IsWindows) { $pathEntries += Join-Path $env:SystemRoot 'System32' }
    $info.Environment['PATH'] = $pathEntries -join [IO.Path]::PathSeparator
    $info.Environment['HOME'] = $WorkDirectory
    $info.Environment['USERPROFILE'] = $WorkDirectory
    $info.Environment['SF_CONFIG_DIR'] = $WorkDirectory
    $info.Environment['SF_DISABLE_TELEMETRY'] = 'true'
    $info.Environment['COVERAGE_TEST_HOST'] = $HostPath
    $info.Environment['COVERAGE_TEST_FIXTURE'] = $FixturePath
    $info.Environment['COVERAGE_TEST_LOG'] = $LogPath
    $info.Environment['COVERAGE_TEST_QUERY_JSON'] = $CoverageJson
    $info.Environment['COVERAGE_TEST_RUN_ALL_FALLBACK'] = 'false'
    $info.Environment['COVERAGE_TEST_TEST_EXIT'] = '0'
    $info.Environment['COVERAGE_TEST_GET_TEST_EXIT'] = '0'
    foreach ($entry in $Environment.GetEnumerator()) { $info.Environment[$entry.Key] = [string]$entry.Value }

    $process = [Diagnostics.Process]::Start($info)
    try {
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(30000)) { $process.Kill($true); throw 'Offline coverage scenario timed out.' }
        $result = [pscustomobject]@{
            ExitCode = $process.ExitCode
            Output = $stdoutTask.GetAwaiter().GetResult() + $stderrTask.GetAwaiter().GetResult()
        }
    } finally { $process.Dispose() }

    $script:Calls = @(Get-Content -LiteralPath $LogPath | Where-Object { $_ } | ForEach-Object { $_ | ConvertFrom-Json })
    return $result
}

try {
    New-Item -ItemType Directory -Path $WorkDirectory, $FakeBin | Out-Null
    if ($IsWindows) {
        "@echo off`r`n`"%COVERAGE_TEST_HOST%`" -NoLogo -NoProfile -File `"%COVERAGE_TEST_FIXTURE%`" sf %*`r`nexit /b %errorlevel%`r`n" |
            Set-Content -LiteralPath (Join-Path $FakeBin 'sf.cmd') -Encoding ascii
    } else {
        $wrapper = Join-Path $FakeBin 'sf'
        $escapedHost = $HostPath.Replace("'", "'\''")
        $escapedFixture = $FixturePath.Replace("'", "'\''")
        "#!/bin/sh`nexec '$escapedHost' -NoLogo -NoProfile -File '$escapedFixture' sf `"`$@`"`n" |
            Set-Content -LiteralPath $wrapper -Encoding utf8NoBOM
        [IO.File]::SetUnixFileMode($wrapper, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute)
    }

    foreach ($file in @($ScriptPath, $PSCommandPath, $FixturePath)) {
        $parseErrors = $null; $tokens = $null
        [Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$parseErrors) | Out-Null
        Assert-True ($parseErrors.Count -eq 0) "parses: $file"
    }

    $result = Invoke-Scenario
    Assert-Exit $result 0 'default invocation passes at 80% coverage'
    Assert-True ($result.Output -match 'Target org: crm-arbeidsforhold' -and $result.Output -match 'Minimum coverage threshold: 75%') 'default org and threshold are preserved'
    Assert-True (@($Calls | Where-Object { $_.arguments -contains 'force:package:install' }).Count -eq 0) 'missing package ID skips install by default'
    $deployCall = @($Calls | Where-Object { $_.arguments -contains 'deploy' })[0]
    $testCall = @($Calls | Where-Object { $_.arguments -contains '--tests' })[0]
    Assert-True ((Get-ArgumentValue $deployCall '--target-org') -ceq 'crm-arbeidsforhold') 'default target org reaches deploy argv'
    Assert-True ((Get-ArgumentValue $testCall '--tests') -ceq 'AAREG_ApplicationDecisionControllerTest') 'default test class reaches sf argv'
    Assert-True ($result.Output -match 'Covered:\s+80' -and $result.Output -match 'Uncovered:\s+20' -and $result.Output -match 'Percent:\s+80%') 'coverage JSON is parsed and reported'

    $result = Invoke-Scenario -Options @('-PackageId', 'package-id')
    Assert-Exit $result 0 'package ID enables install when SkipInstall defaults false'
    $installCall = @($Calls | Where-Object { $_.arguments -contains 'force:package:install' })[0]
    Assert-True ($installCall -and $installCall.arguments -notcontains '--installation-key') 'installation key defaults to omitted'

    $secret = 'offline-key-should-not-be-printed'
    $result = Invoke-Scenario -Options @('-TargetOrg', 'org with spaces', '-PackageId', 'package-id', '-InstallationKey', $secret, '-MinCoverage', '80', '-TestClass', 'Custom Test Class')
    Assert-Exit $result 0 'all parameter overrides are accepted'
    $installCall = @($Calls | Where-Object { $_.arguments -contains 'force:package:install' })[0]
    Assert-True ((Get-ArgumentValue $installCall '--target-org') -ceq 'org with spaces') 'spaced target org remains one argv value'
    Assert-True ((Get-ArgumentValue $installCall '--installation-key') -ceq $secret) 'installation key is forwarded literally'
    Assert-True (-not $result.Output.Contains($secret)) 'installation key is never printed'
    Assert-True ((Get-ArgumentValue (@($Calls | Where-Object { $_.arguments -contains 'deploy' })[0]) '--target-org') -ceq 'org with spaces') 'target org override reaches deploy'
    Assert-True ((Get-ArgumentValue (@($Calls | Where-Object { $_.arguments -contains '--tests' })[0]) '--tests') -ceq 'Custom Test Class') 'test class override remains one argv value'

    $result = Invoke-Scenario -Options @('-PackageId', 'package-id', '-SkipInstall', '-SkipDeploy')
    Assert-Exit $result 0 'skip switches retain successful test and coverage flow'
    Assert-True (@($Calls | Where-Object { $_.arguments -contains 'force:package:install' -or $_.arguments -contains 'deploy' }).Count -eq 0) 'skip switches suppress install and deploy'

    $result = Invoke-Scenario -Options @('-TestRunAll') -Environment @{ COVERAGE_TEST_RUN_ALL_FALLBACK = 'true' }
    Assert-Exit $result 0 'run-all test retries asynchronously after wait failure'
    $testCalls = @($Calls | Where-Object { $_.arguments -contains 'test' -and $_.arguments -contains 'run' })
    Assert-True ($testCalls.Count -eq 2 -and $testCalls[0].arguments -contains '--wait' -and $testCalls[1].arguments -notcontains '--wait') 'run-all uses synchronous attempt then async fallback'
    Assert-True (@($Calls | Where-Object { $_.arguments -contains 'get' -and $_.arguments -contains 'test' }).Count -eq 1) 'async fallback retrieves test run result'

    $result = Invoke-Scenario -Environment @{ COVERAGE_TEST_QUERY_JSON = '{"status":0,"result":{"records":[{"covered":74,"uncovered":26}]}}' }
    Assert-Exit $result 2 'coverage below threshold exits with legacy code 2'
    Assert-True ($result.Output -match '74%' -and $result.Output -match 'below 75%') 'below-threshold result reports parsed percentage'

    foreach ($badJson in @('', 'not-json', '{"status":0,"result":')) {
        $result = Invoke-Scenario -Environment @{ COVERAGE_TEST_QUERY_JSON = $badJson }
        Assert-Exit $result 1 "malformed/empty query JSON fails: '$badJson'"
        Assert-True ($Calls.Count -ge 1) 'bad JSON scenario invokes the fake CLI'
    }

    $result = Invoke-Scenario -Options @('-SkipInstall', '-SkipDeploy') -Environment @{ COVERAGE_TEST_TEST_EXIT = '17' }
    Assert-Exit $result 1 'non-zero targeted sf exit fails the script'
    Assert-True ($result.Output -match 'exit code 17') 'targeted test failure preserves sf exit code in diagnostics'

    $result = Invoke-Scenario -Options @('-SkipInstall') -Environment @{ COVERAGE_TEST_DEPLOY_EXIT = '1' }
    Assert-Exit $result 1 'non-zero JSON sf exit fails the script'
    Assert-True ($result.Output -match 'exit code 1' -and $result.Output -match 'scripted deploy failure') 'JSON sf failure keeps the CLI message'
    Assert-True (@($Calls | Where-Object { $_.arguments -contains 'test' }).Count -eq 0) 'deploy failure stops before tests run'

    foreach ($payload in @(
        'org with spaces',
        "org; Set-Content -LiteralPath '$MarkerPath' -Value pwn; #",
        "org`$(Set-Content -LiteralPath '$MarkerPath' -Value pwn)",
        "org & Set-Content -LiteralPath '$MarkerPath' -Value pwn"
    )) {
        $result = Invoke-Scenario -Options @('-TargetOrg', $payload, '-SkipInstall', '-SkipDeploy')
        Assert-Exit $result 0 "literal TargetOrg accepted: $payload"
        $testCall = @($Calls | Where-Object { $_.arguments -contains '--tests' })[0]
        $passedOrg = Get-ArgumentValue $testCall '--target-org'
        Assert-True ($passedOrg -ceq $payload) "TargetOrg arrives as one literal sf argument: $payload"
        Assert-True (-not (Test-Path -LiteralPath $MarkerPath)) "TargetOrg cannot execute injected commands: $payload"
    }
} finally {
    Remove-Item -LiteralPath $WorkDirectory -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not $IsWindows) {
    $Skipped++
    Write-Host 'Windows .cmd argument forwarding was not verified on this macOS run.'
}
Write-Host "Passed: $Passed; failed: $Failures"
if ($RequireWindows -and $Skipped -gt 0) { throw 'Windows coverage was required but could not be run.' }
if ($Failures -gt 0) { exit 1 }
