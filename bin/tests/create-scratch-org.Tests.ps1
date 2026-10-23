$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -ne 7) { throw 'Run this harness with PowerShell 7 LTS (pwsh).' }

$BinDirectory = Split-Path -Parent $PSScriptRoot
$ScriptPath = Join-Path $BinDirectory 'create-scratch-org.ps1'
$LauncherPath = Join-Path $BinDirectory 'create-scratch-org.bat'
$HostPath = (Get-Process -Id $PID).Path
$NodePath = if ($IsWindows) { (Get-Command node -ErrorAction Stop).Source } else { $null }
$NpmPath = if ($IsWindows) { (Get-Command npm.cmd -ErrorAction Stop).Source } else { $null }
$TempRoot = if ($env:TMPDIR) { $env:TMPDIR } else { [IO.Path]::GetTempPath() }
$WorkDirectory = Join-Path $TempRoot ('scratch-tests-' + [guid]::NewGuid().ToString('N'))
$ProjectDirectory = Join-Path $WorkDirectory 'project with spaces ø'
$FakeBin = Join-Path $WorkDirectory 'fake-bin'
$RulePath = Join-Path $WorkDirectory 'rules.json'
$LogPath = Join-Path $WorkDirectory 'calls.jsonl'
$Failures = 0
$Passed = 0
$Skipped = 0
$Calls = @()
$Config = $null
$Rules = @()
$Overrides = @{}
$VersionJson = '{"status":0,"result":[{"MajorVersion":1,"MinorVersion":0,"PatchVersion":0,"BuildNumber":3,"VersionNumber":"1.0.0.3","SubscriberPackageVersionId":"offline-version"}]}'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:Passed++; Write-Host "PASS: $Message" }
    else { $script:Failures++; Write-Host "FAIL: $Message" }
}

function Write-Json {
    param([string]$Path, $Value)
    ConvertTo-Json -InputObject $Value -Depth 50 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Reset-Scenario {
    $script:Config = @{
        defaultOrgAlias = 'offline-org'
        postSteps = @('deploy')
        pool = @{ use = $false; tag = 'dev'; fallbackToCreate = $false }
    }
    $script:Rules = @()
    $script:Overrides = @{}
    Write-Json (Join-Path $ProjectDirectory 'sfdx-project.json') @{
        packageDirectories = @(@{ path = 'force-app' })
        packageAliases = @{}
    }
}

function Add-Rule {
    param([string]$Tool, [string[]]$Prefix, [string]$Output = '{"status":0,"result":{}}', [int]$ExitCode = 0, [string]$ErrorOutput = '')
    $script:Rules += @{ tool = $Tool; prefix = $Prefix; output = $Output; exitCode = $ExitCode; stderr = $ErrorOutput }
}

function Set-PackageProject {
    Write-Json (Join-Path $ProjectDirectory 'sfdx-project.json') @{
        packageDirectories = @(@{ path = 'force-app'; dependencies = @(@{ package = 'offline-package'; versionNumber = '1.0.0.LATEST' }) })
        packageAliases = @{ 'offline-package' = 'offline-package-id' }
        packageKeyConfig = @{ 'offline-package' = $false }
    }
    Add-Rule sf @('package', 'version', 'list') $VersionJson
    Add-Rule sf @('package', 'installed', 'list') '{"status":0,"result":[]}'
}

function Invoke-Scenario {
    param(
        [string[]]$Options = @(),
        [string]$Executable = $HostPath,
        [string[]]$LeadingArguments = @('-NoLogo', '-NoProfile', '-File', $ScriptPath),
        [switch]$AllowUnexpected,
        [switch]$WithoutRuntime
    )
    Write-Json (Join-Path $ProjectDirectory 'sf-project.config.json') $Config
    Write-Json $RulePath @($Rules)
    [IO.File]::WriteAllText($LogPath, '')
    $info = [Diagnostics.ProcessStartInfo]::new($Executable)
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.WorkingDirectory = $ProjectDirectory
    foreach ($argument in @($LeadingArguments) + @($Options)) { $info.ArgumentList.Add($argument) }
    foreach ($name in @($info.Environment.Keys)) {
        if ($name -match '^(ORG_ALIAS|DURATION_DAYS|PROJECT_FILE|SF_|SFDX_|SCRATCH_|DUMMY_|COMMUNITY_|PERMISSION_|POST_STEPS|PACKAGE_|PACKAGES_|POOL_|USE_POOL|COVERAGE_|FALLBACK_|RUN_|INSTALL_|VERIFY_|DRY_RUN|FULL_DEPLOY)') {
            $info.Environment.Remove($name) | Out-Null
        }
    }
    $paths = @($FakeBin)
    if ($IsWindows) {
        $paths += Join-Path $env:SystemRoot 'System32'
        $paths += Split-Path -Parent $NodePath
        if (-not $WithoutRuntime) { $paths += $PSHOME }
    }
    $info.Environment['PATH'] = $paths -join [IO.Path]::PathSeparator
    $info.Environment['HOME'] = $WorkDirectory
    $info.Environment['USERPROFILE'] = $WorkDirectory
    $info.Environment['SF_CONFIG_DIR'] = $WorkDirectory
    $info.Environment['SF_DISABLE_TELEMETRY'] = 'true'
    $info.Environment['SCRATCH_TEST_RULES'] = $RulePath
    $info.Environment['SCRATCH_TEST_LOG'] = $LogPath
    $info.Environment['SCRATCH_TEST_HOST'] = $HostPath
    $info.Environment['SCRATCH_TEST_FIXTURE'] = Join-Path $PSScriptRoot 'fixtures/scratch-cli.ps1'
    $info.Environment['PACKAGE_INSTALL_MAX_ATTEMPTS'] = '1'
    foreach ($entry in $Overrides.GetEnumerator()) { $info.Environment[$entry.Key] = $entry.Value }
    $process = [Diagnostics.Process]::Start($info)
    try {
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(60000)) { $process.Kill($true); throw 'Offline scenario timed out.' }
        $result = [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult() }
    } finally { $process.Dispose() }
    $script:Calls = @(Get-Content -LiteralPath $LogPath | ForEach-Object { $_ | ConvertFrom-Json })
    if (-not $AllowUnexpected) {
        $unexpected = @($Calls | Where-Object unexpected).Count -gt 0
        $message = if ($unexpected) { "Unexpected CLI calls: $($result.Output)" } else { 'no unexpected CLI calls' }
        Assert-True (-not $unexpected) $message
    }
    return $result
}

function Assert-Exit {
    param($Result, [int]$Expected, [string]$Message)
    $detail = if ($Result.ExitCode -eq $Expected) { $Message } else { "$Message (exit $($Result.ExitCode)): $($Result.Output)" }
    Assert-True ($Result.ExitCode -eq $Expected) $detail
}

try {
    New-Item -ItemType Directory -Path $ProjectDirectory, $FakeBin | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ProjectDirectory 'config') | Out-Null
    Write-Json (Join-Path $ProjectDirectory 'config/project-scratch-def.json') @{ edition = 'Developer' }
    $fixture = Join-Path $PSScriptRoot 'fixtures/scratch-cli.ps1'
    foreach ($tool in @('sf', 'sfp')) {
        if ($IsWindows) {
            "@echo off`r`n`"%SCRATCH_TEST_HOST%`" -NoLogo -NoProfile -File `"%SCRATCH_TEST_FIXTURE%`" $tool %*`r`nexit /b %errorlevel%`r`n" |
                Set-Content -LiteralPath (Join-Path $FakeBin "$tool.cmd") -Encoding ascii
        } else {
            $wrapper = Join-Path $FakeBin $tool
            "#!/bin/sh`nexec '$($HostPath.Replace("'", "'\''"))' -NoLogo -NoProfile -File '$($fixture.Replace("'", "'\''"))' $tool `"`$@`"`n" |
                Set-Content -LiteralPath $wrapper -Encoding utf8NoBOM
            [IO.File]::SetUnixFileMode($wrapper, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute)
        }
    }
    Write-Host "Runtime: $($PSVersionTable.PSVersion); OS: $([Runtime.InteropServices.RuntimeInformation]::OSDescription)"
    foreach ($file in @($ScriptPath, $PSCommandPath, $fixture)) {
        $parseErrors = $null; $tokens = $null
        [Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$parseErrors) | Out-Null
        Assert-True ($parseErrors.Count -eq 0) "parses: $file"
    }

    Reset-Scenario
    $result = Invoke-Scenario -Options @('-Help')
    Assert-Exit $result 0 'help succeeds without CLI calls'
    Assert-True ($Calls.Count -eq 0) 'help is offline'
    $guardCommand = "`$PSVersionTable.PSVersion = [version]'5.1'; & '$($ScriptPath.Replace("'", "''"))' -Help"
    $result = Invoke-Scenario -LeadingArguments @('-NoLogo', '-NoProfile', '-Command', $guardCommand)
    Assert-Exit $result 1 'runtime guard rejects simulated 5.1 before help or side effects'
    Assert-True ($result.Output -match 'PowerShell 7 LTS is required' -and $Calls.Count -eq 0) 'runtime guard gives migration guidance (not a real 5.1 test)'

    Reset-Scenario
    $result = Invoke-Scenario -Options @('-InitConfig', '-DryRun')
    Assert-Exit $result 0 'config preview succeeds with one post-step'
    Assert-True ($result.Output -match '"postSteps":\s*\[\s*"deploy"') 'single-item arrays remain arrays'
    Assert-True ($Calls.Count -eq 0) 'init-config preview is offline'
    $result = Invoke-Scenario -Options @('-InitConfig', '-Force', '-OrgAlias', 'written-org')
    Assert-Exit $result 0 'explicit config write succeeds in temporary project'
    $written = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sf-project.config.json') -Raw | ConvertFrom-Json
    Assert-True ($written.defaultOrgAlias -eq 'written-org') 'config write persists CLI override'

    Reset-Scenario
    $Overrides['ORG_ALIAS'] = 'environment-org'
    $result = Invoke-Scenario -Options @('-InitConfig', '-DryRun', '-OrgAlias', 'cli-org')
    Assert-Exit $result 0 'CLI overrides environment and config'
    Assert-True ($result.Output -match '"defaultOrgAlias":\s*"cli-org"') 'CLI alias is used'
    $result = Invoke-Scenario -Options @('-InitConfig', '-DryRun')
    Assert-True ($result.Output -match '"defaultOrgAlias":\s*"environment-org"') 'environment overrides config'

    Reset-Scenario
    $Config['scratchDurationDays'] = 31
    $result = Invoke-Scenario -Options @('-InitConfig', '-DryRun')
    Assert-Exit $result 1 'invalid config fails'
    Assert-True ($result.Output -match 'scratchDurationDays') 'invalid config has actionable error'
    Assert-True ($Calls.Count -eq 0) 'invalid config fails before CLI'

    Reset-Scenario
    New-Item -ItemType Directory -Path (Join-Path $ProjectDirectory 'data') | Out-Null
    Write-Json (Join-Path $ProjectDirectory 'data/Plan.json') @()
    Write-Json (Join-Path $ProjectDirectory 'data/User.json') @{ records = @(@{ Username = 'handler@example.test' }) }
    $Config['dummyDataPlan'] = 'data/Plan.json'
    $Config.postSteps = @('data')
    $Config['dummyUsers'] = @{
        file = 'data/User.json'
        profileName = 'Standard User'
        profileAssignments = @(
            @{ profileName = 'Case Handler'; usernames = @('handler@example.test') },
            @{ profileName = 'Support User'; usernames = @('support@example.test') }
        )
    }
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-DryRun')
    Assert-Exit $result 0 'dummy-user profile preview succeeds'
    Assert-True ($result.Output -match '(?s)(?=.*Case Handler)(?=.*Standard User)(?=.*Support User)') 'profile preview includes configured and fallback profiles'
    $Config.dummyUsers.profileAssignments[1].usernames = @('handler@example.test')
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-DryRun')
    Assert-Exit $result 1 'duplicate profile mappings fail'
    Assert-True ($result.Output -match 'only one profile assignment') 'duplicate mappings have actionable error'

    Reset-Scenario
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-PostSteps', 'deploy', '-DryRun')
    Assert-Exit $result 0 'deploy preview succeeds without CLI'
    Assert-True ($Calls.Count -eq 0) 'deploy preview makes no calls'

    Reset-Scenario
    Add-Rule sf @('project', 'deploy', 'start')
    Add-Rule sf @('project', 'reset', 'tracking')
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-PostSteps', 'deploy')
    Assert-Exit $result 0 'deploy succeeds'
    Assert-True ($Calls.Count -eq 2 -and $Calls[0].arguments[1] -eq 'deploy') 'deploy precedes tracking reset'

    Reset-Scenario
    Add-Rule sf @('project', 'deploy', 'start') '' 9 'offline deployment failed'
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-PostSteps', 'deploy')
    Assert-Exit $result 1 'deploy failure propagates'
    Assert-True ($Calls.Count -eq 1 -and $result.Output -match 'offline deployment failed') 'no tracking reset after failure'

    Reset-Scenario
    $Config.pool.use = $true
    $Config.pool.devHub = 'offline-hub'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 1'
    Add-Rule sfp @('pool', 'fetch')
    Add-Rule sf @('org', 'delete', 'scratch')
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 0 'configured pool uses sfp fetch'
    Assert-True (@($Calls | Where-Object { $_.tool -eq 'sfp' -and $_.arguments[1] -eq 'fetch' }).Count -eq 1) 'pool fetch uses sfp, not sf'

    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none', '-DryRun')
    Assert-Exit $result 0 'pool dry-run succeeds'
    Assert-True ($Calls.Count -eq 1 -and $Calls[0].arguments[1] -eq 'list') 'pool dry-run only reads pool status, never deletes org'

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.devHub = 'offline-hub'
    Add-Rule sfp @('pool', 'list') '' 6 'offline pool listing failed'
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 1 'pool list failure propagates without create fallback'
    Assert-True ($Calls.Count -eq 1 -and $result.Output -match 'offline pool listing failed') 'pool list error is visible without mutations'

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.devHub = 'offline-hub'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 0'
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 1 'empty pool without fallback fails'
    Assert-True ($Calls.Count -eq 1) 'empty pool does not create or delete an org'

    Reset-Scenario
    $Config.pool.use = $true; $Config.pool.devHub = 'offline-hub'
    Add-Rule sfp @('pool', 'list') 'Unused Scratch Orgs in the Pool: 1'
    Add-Rule sf @('org', 'delete', 'scratch')
    Add-Rule sfp @('pool', 'fetch') '' 8 'offline fetch failed'
    $result = Invoke-Scenario -Options @('-SkipPackages', '-PostSteps', 'none')
    Assert-Exit $result 1 'pool fetch failure propagates'
    Assert-True ($result.Output -match 'offline fetch failed') 'pool fetch error is visible'

    Reset-Scenario
    Set-PackageProject
    Add-Rule sf @('package', 'install')
    $result = Invoke-Scenario -Options @('-SkipOrg', '-PostSteps', 'none')
    Assert-Exit $result 0 'missing package installs'
    Assert-True (@($Calls | Where-Object { $_.arguments[1] -eq 'install' }).Count -eq 1) 'package install was executed'
    $result = Invoke-Scenario -Options @('-PackagePlan')
    Assert-Exit $result 0 'package plan succeeds'
    Assert-True (@($Calls | Where-Object { $_.arguments[1] -eq 'install' }).Count -eq 0) 'package plan never installs'
    $result = Invoke-Scenario -Options @('-UpdatePackages')
    Assert-Exit $result 0 'package update installs missing package'

    Reset-Scenario
    Set-PackageProject
    $script:Rules = @($Rules | Where-Object { $_.prefix[1] -ne 'installed' })
    Add-Rule sf @('package', 'installed', 'list') '{"status":0,"result":[{"SubscriberPackageName":"offline-package","SubscriberPackageVersionNumber":"1.0.0.3"}]}'
    $result = Invoke-Scenario -Options @('-UpdatePackages')
    Assert-Exit $result 0 'current package is not reinstalled'
    Assert-True (@($Calls | Where-Object { $_.arguments[1] -eq 'install' }).Count -eq 0) 'current package skipped'

    foreach ($output in @("CLI warning`n$VersionJson", 'not JSON', '', '{"broken":', '{"status":1,"message":"offline JSON failure"}')) {
        Reset-Scenario
        Set-PackageProject
        $script:Rules = @($Rules | Where-Object { $_.prefix[1] -ne 'version' })
        Add-Rule sf @('package', 'version', 'list') $output
        $result = Invoke-Scenario -Options @('-CheckVersions')
        $expected = if ($output.StartsWith('CLI warning')) { 0 } else { 1 }
        Assert-Exit $result $expected "JSON output handling: $output"
        Assert-True ($Calls.Count -eq 1) 'JSON scenario reached the fake CLI'
        if ($output -eq 'not JSON' -or $output -eq '') {
            Assert-True ($result.Output -match 'returned no JSON') 'empty/invalid output has actionable JSON error'
        } elseif ($output -eq '{"broken":') {
            Assert-True ($result.Output -match 'Could not parse JSON') 'malformed JSON has actionable error'
        } elseif ($output.StartsWith('{"status":1')) {
            Assert-True ($result.Output -match 'offline JSON failure') 'failed JSON status is surfaced'
        }
    }

    Reset-Scenario
    Set-PackageProject
    $project = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw | ConvertFrom-Json
    $project.packageDirectories[0].dependencies[0].versionNumber = '0.9.0.LATEST'
    $project.packageDirectories += [pscustomobject]@{
        path = 'second-package'
        dependencies = @([pscustomobject]@{ package = 'offline-package'; versionNumber = '0.9.0.NEXT' })
    }
    Write-Json (Join-Path $ProjectDirectory 'sfdx-project.json') $project
    $originalProject = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw
    $result = Invoke-Scenario -Options @('-CheckVersions')
    Assert-Exit $result 0 'version preview succeeds'
    Assert-True ($result.Output -match '0\.9\.0\.LATEST -> 1\.0\.0\.LATEST') 'preview reports version change'
    Assert-True ((Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw) -ceq $originalProject) 'version preview preserves project file exactly'
    $result = Invoke-Scenario -Options @('-ApplyProjectVersions')
    Assert-Exit $result 0 'explicit version apply succeeds'
    Assert-True ((Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json.backup') -Raw) -ceq $originalProject) 'version apply preserves exact backup'
    $updatedProject = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw | ConvertFrom-Json
    Assert-True ($updatedProject.packageDirectories[1].dependencies[0].versionNumber -eq '1.0.0.LATEST') 'version apply updates duplicate dependency declarations'

    Reset-Scenario
    $Config.postSteps = @('capture')
    $expectedArguments = @('capture', 'two words', '', 'say "hello"', 'norsk ø')
    $Config['customPostSteps'] = @(@{ name = 'capture'; executable = 'sf'; arguments = $expectedArguments })
    Add-Rule sf @('capture')
    $result = Invoke-Scenario -Options @('-PostStepsOnly')
    Assert-Exit $result 0 'custom post-step succeeds'
    Assert-True (($Calls[0].arguments | ConvertTo-Json -Compress) -ceq ($expectedArguments | ConvertTo-Json -Compress)) 'native argument boundaries preserved'

    Reset-Scenario
    Set-PackageProject
    $project = Get-Content -LiteralPath (Join-Path $ProjectDirectory 'sfdx-project.json') -Raw | ConvertFrom-Json
    $project.packageKeyConfig.'offline-package' = $true
    Write-Json (Join-Path $ProjectDirectory 'sfdx-project.json') $project
    $Overrides['PACKAGE_INSTALL_KEY'] = 'offline-secret-marker'
    Add-Rule sf @('package', 'install') 'failure echoed offline-secret-marker' 5
    $result = Invoke-Scenario -Options @('-SkipOrg', '-PostSteps', 'none')
    Assert-Exit $result 1 'install failure propagates'
    Assert-True ($result.Output -notmatch 'offline-secret-marker') 'install key never appears in output'
    Assert-True ((Get-Content -LiteralPath $LogPath -Raw) -notmatch 'offline-secret-marker') 'fake CLI journal redacts key arguments'

    Reset-Scenario
    Add-Rule sf @('--version')
    Add-Rule sf @('org', 'list')
    Add-Rule sf @('org', 'display') '' 4 'offline sf failure'
    $result = Invoke-Scenario -Options @('-SelfCheck')
    Assert-Exit $result 1 'self-check propagates CLI failures'
    Assert-True ($result.Output -match 'offline sf failure') 'self-check surfaces stderr'

    Reset-Scenario
    $result = Invoke-Scenario -Options @('-CoverageCheck', '-DryRun', '-CoveragePackageId', 'offline-version')
    Assert-Exit $result 0 'coverage preview succeeds offline'
    Assert-True ($result.Output -match 'Query % aggregate coverage' -and $Calls.Count -eq 0) 'coverage preview never invokes CLI'

    Reset-Scenario
    $result = Invoke-Scenario -Options @('-PostStepsOnly', '-PostSteps', 'deploy') -AllowUnexpected
    Assert-Exit $result 1 'unexpected fake CLI command fails closed'
    Assert-True (@($Calls | Where-Object unexpected).Count -eq 1) 'unexpected call is recorded, not sent to real CLI'

    if ($IsWindows) {
        Reset-Scenario
        Write-Json (Join-Path $ProjectDirectory 'package.json') @{
            private = $true
            scripts = @{ 'scratch-org' = "node `"$(Join-Path $BinDirectory 'create-scratch-org.js')`"" }
        }
        $result = Invoke-Scenario -Executable $env:ComSpec -LeadingArguments @('/d', '/c', "`"$LauncherPath`" -Help")
        Assert-Exit $result 0 'CMD launcher actually starts PowerShell help'
        $result = Invoke-Scenario -Executable $env:ComSpec -LeadingArguments @('/d', '/c', "`"$NpmPath`" run scratch-org -- --help")
        Assert-Exit $result 0 'npm run actually starts PowerShell help'
        foreach ($launcher in @('cmd', 'npm')) {
            $Config.postSteps = @('deploy')
            $script:Rules = @()
            Add-Rule sf @('project', 'deploy', 'start') '' 9 'offline Windows deployment failed'
            $command = if ($launcher -eq 'cmd') {
                "`"$LauncherPath`" -PostStepsOnly -OrgAlias `"alias with spaces`""
            } else { "`"$NpmPath`" run scratch-org -- -PostStepsOnly -OrgAlias `"alias with spaces`"" }
            $result = Invoke-Scenario -Executable $env:ComSpec -LeadingArguments @('/d', '/c', $command)
            Assert-Exit $result 1 "$launcher propagates script failure"
            Assert-True ($Calls.Count -eq 1 -and $Calls[0].arguments[4] -eq 'alias with spaces') "$launcher preserves spaced argument"
            Assert-True ($result.Output -match 'offline Windows deployment failed') "$launcher surfaces script failure details"
            if ($launcher -eq 'cmd') {
                $result = Invoke-Scenario -Executable $env:ComSpec -LeadingArguments @('/d', '/c', "`"$LauncherPath`" -Help") -WithoutRuntime
            } else {
                $result = Invoke-Scenario -Executable $env:ComSpec -LeadingArguments @('/d', '/c', "`"$NpmPath`" run scratch-org -- --help") -WithoutRuntime
            }
            Assert-Exit $result 1 "$launcher rejects missing pwsh"
            Assert-True ($result.Output -match 'Install.*PowerShell 7 LTS') "$launcher gives installation guidance"
            Assert-True ($Calls.Count -eq 0) "$launcher never contacts CLI without runtime"
        }
    } else {
        $Skipped += 1
        Write-Host 'SKIP: Windows CMD/npm execution and missing-runtime scenarios require Windows; not verified on Mac.'
    }
} finally {
    Remove-Item -LiteralPath $WorkDirectory -Recurse -Force
}
Write-Host "Passed: $Passed; failed: $Failures; skipped groups: $Skipped"
if ($Failures -gt 0) { exit 1 }
