<#
.SYNOPSIS
Creates and configures a Salesforce scratch org without sf-project tooling.

.DESCRIPTION
Reads project settings from sf-project.config.json and invokes Salesforce CLI (sf) directly.
#>
[CmdletBinding()]
param(
    [Alias('Alias')][string]$OrgAlias,
    [int]$DurationDays,
    [string]$DefinitionFile,
    [string]$ProjectFile,
    [string]$ConfigFile,
    [switch]$NoConfig,
    [switch]$InitConfig,
    [switch]$Force,
    [switch]$DryRun,
    [string[]]$PostSteps,
    [string]$CommunityName,
    [string]$DummyDataPlan,
    [string[]]$PermissionSets,
    [switch]$Help,
    [switch]$InstallLatest,
    [switch]$UpdatePackages,
    [switch]$PackagePlan,
    [switch]$DeleteOrgOnly,
    [switch]$SelfCheck,
    [switch]$UsePool,
    [string]$PoolTag,
    [string]$PoolDevHub,
    [switch]$NoFallbackToCreate,
    [switch]$SkipOrg,
    [switch]$SkipPackages,
    [switch]$SkipVersionCheck,
    [switch]$PostStepsOnly,
    [switch]$RefreshDependencySources,
    [switch]$ClearDependencySourcesOnly
)

$ErrorActionPreference = 'Stop'
$script:BoundParameters = $PSBoundParameters

function Get-ObjectProperty {
    param($Object, [string]$Name, $Default = $null)
    if ($null -eq $Object) { return $Default }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $Default }
    return $property.Value
}

function Test-HasProperty {
    param($Object, [string]$Name)
    return ($null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name])
}

function Set-ObjectProperty {
    param($Object, [string]$Name, $Value)
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}

function Test-NonEmptyString {
    param($Value)
    return ($Value -is [string] -and -not [string]::IsNullOrWhiteSpace($Value))
}

function ConvertTo-StringArray {
    param($Value)
    if ($null -eq $Value) { return @() }
    return @($Value | ForEach-Object { [string]$_ })
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "File not found: $Path" }
    try {
        return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
    } catch {
        throw "Invalid JSON in $Path`: $($_.Exception.Message)"
    }
}

function Write-Utf8JsonFile {
    param([string]$Path, $Value)
    $json = $Value | ConvertTo-Json -Depth 100
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, $encoding)
}

function Test-Configuration {
    param($Config)
    if ($null -eq $Config -or $Config -isnot [pscustomobject]) { throw 'sf-project.config.json must contain a JSON object.' }
    $schemaVersion = Get-ObjectProperty $Config 'schemaVersion' 1
    if ($schemaVersion -ne 1) { throw "Unsupported schemaVersion '$schemaVersion'; expected 1." }
    foreach ($name in @('defaultOrgAlias', 'scratchDefinition', 'packageInstallKeyEnvironmentVariable')) {
        $value = Get-ObjectProperty $Config $name
        if ((Test-HasProperty $Config $name) -and -not (Test-NonEmptyString $value)) { throw "$name must be a non-empty string." }
    }
    $duration = Get-ObjectProperty $Config 'scratchDurationDays' 14
    if ($duration -isnot [int] -and $duration -isnot [long]) { throw 'scratchDurationDays must be an integer from 1 to 30.' }
    if ($duration -lt 1 -or $duration -gt 30) { throw 'scratchDurationDays must be an integer from 1 to 30.' }
    foreach ($name in @('permissionSets', 'postSteps', 'customPostSteps')) {
        if ((Test-HasProperty $Config $name) -and (Get-ObjectProperty $Config $name) -isnot [array]) { throw "$name must be an array." }
    }
    $steps = ConvertTo-StringArray (Get-ObjectProperty $Config 'postSteps' @('deploy'))
    $customSteps = @(Get-ObjectProperty $Config 'customPostSteps' @())
    $knownSteps = @('deploy', 'permsets', 'data', 'community') + @($customSteps | ForEach-Object { $_.name })
    foreach ($step in $steps) {
        if ($step -notin $knownSteps) { throw "Unknown post step '$step'." }
    }
    $arrays = @('permissionSets', 'postSteps')
    foreach ($name in $arrays) {
        $value = Get-ObjectProperty $Config $name
        if (@($value | Where-Object { -not (Test-NonEmptyString $_) }).Count -gt 0) { throw "$name must contain non-empty strings." }
    }
    foreach ($name in @('dummyDataPlan', 'communityName')) {
        $value = Get-ObjectProperty $Config $name
        if ((Test-HasProperty $Config $name) -and $null -ne $value -and -not (Test-NonEmptyString $value)) {
            throw "$name must be a non-empty string or null."
        }
    }
    $customNames = @($customSteps | ForEach-Object { $_.name })
    if (@($customNames | Select-Object -Unique).Count -ne $customNames.Count) { throw 'customPostSteps names must be unique.' }
    foreach ($name in $customNames) {
        if ($name -in @('deploy', 'permsets', 'data', 'community')) { throw "customPostSteps name '$name' conflicts with a built-in step." }
    }
    foreach ($custom in $customSteps) {
        if (-not (Test-NonEmptyString $custom.name) -or -not (Test-NonEmptyString $custom.executable)) { throw 'customPostSteps entries require non-empty name and executable values.' }
        if ((Test-HasProperty $custom 'arguments') -and ($custom.arguments -isnot [array] -or @($custom.arguments | Where-Object { $_ -isnot [string] }).Count -gt 0)) { throw 'customPostSteps.arguments must be a string array.' }
        if ((Test-HasProperty $custom 'label') -and -not (Test-NonEmptyString $custom.label)) { throw 'customPostSteps.label must be a non-empty string.' }
    }
    $pool = Get-ObjectProperty $Config 'pool'
    if ((Test-HasProperty $Config 'pool') -and $null -eq $pool) { throw 'pool must be an object.' }
    if ($null -ne $pool) {
        if ($pool -isnot [pscustomobject]) { throw 'pool must be an object.' }
        foreach ($name in @('use', 'fallbackToCreate')) {
            $value = Get-ObjectProperty $pool $name
            if ((Test-HasProperty $pool $name) -and $value -isnot [bool]) { throw "pool.$name must be a boolean." }
        }
        foreach ($name in @('tag', 'devHub')) {
            $value = Get-ObjectProperty $pool $name
            if ((Test-HasProperty $pool $name) -and -not (Test-NonEmptyString $value)) { throw "pool.$name must be a non-empty string." }
        }
    }
    $dependencyPolicy = Get-ObjectProperty $Config 'dependencySourcePolicy'
    if ((Test-HasProperty $Config 'dependencySourcePolicy') -and $null -eq $dependencyPolicy) { throw 'dependencySourcePolicy must be an object.' }
    if ($null -ne $dependencyPolicy) {
        if ($dependencyPolicy -isnot [pscustomobject]) { throw 'dependencySourcePolicy must be an object.' }
        $requireLocal = Get-ObjectProperty $dependencyPolicy 'requireLocalDirectories'
        if ((Test-HasProperty $dependencyPolicy 'requireLocalDirectories') -and $requireLocal -isnot [bool]) { throw 'dependencySourcePolicy.requireLocalDirectories must be a boolean.' }
        $preserved = Get-ObjectProperty $dependencyPolicy 'preserveRootFiles'
        if ((Test-HasProperty $dependencyPolicy 'preserveRootFiles') -and ($preserved -isnot [array] -or @($preserved | Where-Object { -not (Test-NonEmptyString $_) }).Count -gt 0)) { throw 'dependencySourcePolicy.preserveRootFiles must be an array of non-empty strings.' }
    }
    $timeouts = Get-ObjectProperty $Config 'commandTimeouts'
    if ((Test-HasProperty $Config 'commandTimeouts') -and $null -eq $timeouts) { throw 'commandTimeouts must be an object.' }
    if ($null -ne $timeouts) {
        if ($timeouts -isnot [pscustomobject]) { throw 'commandTimeouts must be an object.' }
        foreach ($name in @('readMs', 'mutationMs')) {
            $value = Get-ObjectProperty $timeouts $name
            if ((Test-HasProperty $timeouts $name) -and ($value -isnot [ValueType] -or $value -is [bool] -or [double]$value -le 0 -or [double]$value -ne [math]::Floor([double]$value))) {
                throw "commandTimeouts.$name must be a positive integer."
            }
        }
    }
    $dummyUsers = Get-ObjectProperty $Config 'dummyUsers'
    if ((Test-HasProperty $Config 'dummyUsers') -and $null -eq $dummyUsers) { throw 'dummyUsers must be an object.' }
    if ($null -ne $dummyUsers) {
        if ($dummyUsers -isnot [pscustomobject]) { throw 'dummyUsers must be an object.' }
        if (-not (Test-NonEmptyString (Get-ObjectProperty $dummyUsers 'file'))) { throw 'dummyUsers.file is required.' }
        $defaultProfileName = Get-ObjectProperty $dummyUsers 'profileName'
        if ((Test-HasProperty $dummyUsers 'profileName') -and -not (Test-NonEmptyString $defaultProfileName)) { throw 'dummyUsers.profileName must be a non-empty string.' }
        foreach ($name in @('profileAssignments', 'permissionSetAssignments')) {
            if ((Test-HasProperty $dummyUsers $name) -and (Get-ObjectProperty $dummyUsers $name) -isnot [array]) { throw "dummyUsers.$name must be an array." }
        }
        $profileUsernames = @()
        foreach ($assignment in @(Get-ObjectProperty $dummyUsers 'profileAssignments' @())) {
            if (-not (Test-NonEmptyString $assignment.profileName) -or $assignment.usernames -isnot [array] -or @($assignment.usernames).Count -eq 0) {
                throw 'Each dummyUsers.profileAssignments entry requires profileName and at least one username.'
            }
            if (@($assignment.usernames | Where-Object { -not (Test-NonEmptyString $_) }).Count -gt 0) {
                throw 'dummyUsers.profileAssignments usernames must be non-empty strings.'
            }
            $profileUsernames += @($assignment.usernames)
        }
        if (@($profileUsernames | Select-Object -Unique).Count -ne $profileUsernames.Count) {
            throw 'Each dummy user can have only one profile assignment.'
        }
        foreach ($assignment in @(Get-ObjectProperty $dummyUsers 'permissionSetAssignments' @())) {
            if ($assignment.permissionSets -isnot [array] -or $assignment.usernames -isnot [array] -or
                @($assignment.permissionSets).Count -eq 0 -or @($assignment.usernames).Count -eq 0) {
                throw 'Each dummyUsers.permissionSetAssignments entry requires permissionSets and usernames.'
            }
            if (@($assignment.permissionSets | Where-Object { -not (Test-NonEmptyString $_) }).Count -gt 0 -or
                @($assignment.usernames | Where-Object { -not (Test-NonEmptyString $_) }).Count -gt 0) {
                throw 'dummyUsers.permissionSetAssignments values must be non-empty strings.'
            }
        }
    }
}

function Invoke-External {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [string[]]$Arguments = @(),
        [switch]$PlanOnly
    )
    if ($PlanOnly) {
        Write-Host "[dry-run] $Executable $($Arguments -join ' ')" -ForegroundColor Yellow
        return [pscustomobject]@{ ExitCode = 0; Output = @() }
    }
    $output = @(& $Executable @Arguments 2>&1 | ForEach-Object { $_.ToString() })
    $exitCode = $LASTEXITCODE
    return [pscustomobject]@{ ExitCode = $exitCode; Output = $output }
}

function Invoke-SfJson {
    param([string[]]$Arguments, [switch]$PlanOnly, [switch]$AllowFailure)
    $result = Invoke-External -Executable 'sf' -Arguments ($Arguments + @('--json')) -PlanOnly:$PlanOnly
    if ($PlanOnly) { return $null }
    if ($result.ExitCode -ne 0 -and -not $AllowFailure) { throw "sf $($Arguments -join ' ') failed (exit $($result.ExitCode)): $($result.Output -join "`n")" }
    $jsonStart = -1
    for ($index = 0; $index -lt $result.Output.Count; $index++) {
        if ($result.Output[$index].TrimStart().StartsWith('{')) { $jsonStart = $index; break }
    }
    if ($jsonStart -lt 0) {
        if ($AllowFailure) { return [pscustomobject]@{ status = $result.ExitCode; message = ($result.Output -join "`n"); result = $null } }
        throw "sf $($Arguments -join ' ') returned no JSON."
    }
    try { $parsed = ($result.Output[$jsonStart..($result.Output.Count - 1)] -join "`n") | ConvertFrom-Json }
    catch { throw "Could not parse JSON from sf $($Arguments -join ' '): $($_.Exception.Message)" }
    if ((Get-ObjectProperty $parsed 'status' 0) -ne 0 -and -not $AllowFailure) {
        throw "sf $($Arguments -join ' ') returned a failed JSON response: $($parsed.message)"
    }
    return $parsed
}

function Invoke-Sf {
    param([string[]]$Arguments, [switch]$PlanOnly, [switch]$AllowFailure)
    $result = Invoke-External -Executable 'sf' -Arguments $Arguments -PlanOnly:$PlanOnly
    if (-not $PlanOnly -and $result.ExitCode -ne 0 -and -not $AllowFailure) {
        throw "sf $($Arguments -join ' ') failed (exit $($result.ExitCode)): $($result.Output -join "`n")"
    }
    return $result
}

function ConvertTo-SoqlLiteral {
    param([string]$Value)
    $escaped = $Value.Replace('\', '\\').Replace("'", "\'")
    return "'$escaped'"
}

function Get-PackageDependencies {
    $dependencies = @()
    foreach ($directory in @($script:SfdxProject.packageDirectories)) {
        foreach ($dependency in @(Get-ObjectProperty $directory 'dependencies' @())) { $dependencies += $dependency }
    }
    return $dependencies
}

function Get-PackageVersionData {
    param([string]$PackageName)
    $response = Invoke-SfJson @('package', 'version', 'list', '--packages', $PackageName, '--released', '--order-by', 'CreatedDate')
    return @($response.result | Where-Object { $_.SubscriberPackageVersionId } | Sort-Object -Property @(
        @{ Expression = { [int]$_.MajorVersion } },
        @{ Expression = { [int]$_.MinorVersion } },
        @{ Expression = { [int]$_.PatchVersion } },
        @{ Expression = { [int]$_.BuildNumber } }
    ))
}

function Select-PackageVersion {
    param([string]$PackageName, [string]$RequestedVersion)
    $versions = @(Get-PackageVersionData $PackageName)
    if ($versions.Count -eq 0) { throw "No released version found for package '$PackageName'." }
    if ($script:InstallLatest -or [string]::IsNullOrWhiteSpace($RequestedVersion)) { return $versions[-1] }
    $parts = $RequestedVersion -split '\.'
    if ($parts.Count -lt 3) { throw "Invalid version '$RequestedVersion' for package '$PackageName'." }
    $matchingVersions = @($versions | Where-Object {
        [int]$_.MajorVersion -eq [int]$parts[0] -and
        [int]$_.MinorVersion -eq [int]$parts[1] -and
        [int]$_.PatchVersion -eq [int]$parts[2]
    })
    if ($parts.Count -ge 4 -and $parts[3] -match '^\d+$') {
        $matchingVersions = @($matchingVersions | Where-Object { [int]$_.BuildNumber -eq [int]$parts[3] })
    }
    if ($matchingVersions.Count -eq 0) { throw "Could not resolve requested version '$RequestedVersion' for '$PackageName'." }
    return $matchingVersions[-1]
}

function Get-InstalledPackages {
    $response = Invoke-SfJson @('package', 'installed', 'list', '--target-org', $script:TargetOrg)
    return @($response.result)
}

function Get-PackageNameFromInstall {
    param($Installed)
    foreach ($name in @('SubscriberPackageName', 'PackageName', 'Name', 'Package')) {
        $value = Get-ObjectProperty $Installed $name
        if ($value) { return [string]$value }
    }
    return ''
}

function Invoke-PackageInstall {
    param([string]$PackageName, [string]$VersionId)
    $arguments = @('package', 'install', '--package', $VersionId, '--target-org', $script:TargetOrg, '--wait', [string]$script:PackageWaitMinutes, '--publish-wait', [string]$script:PackageWaitMinutes, '--no-prompt')
    $requiresKey = $PackageName -notin @($script:NoKeyPackages)
    if ($requiresKey) { $requiresKey = (Get-ObjectProperty $script:SfdxProject.packageKeyConfig $PackageName $true) -ne $false }
    if ($requiresKey) {
        if ([string]::IsNullOrEmpty($script:InstallationKey)) { throw "An install key is required for '$PackageName'. Set $($script:KeyEnvironmentVariable)." }
        $arguments += @('--installation-key', $script:InstallationKey)
    }
    for ($attempt = 1; $attempt -le $script:InstallMaxAttempts; $attempt++) {
        if ($script:DryRun) {
            $displayArguments = @($arguments)
            $keyIndex = [Array]::IndexOf($displayArguments, '--installation-key')
            if ($keyIndex -ge 0) { $displayArguments[$keyIndex + 1] = '***' }
            Invoke-External -Executable 'sf' -Arguments $displayArguments -PlanOnly | Out-Null
            return
        }
        $result = Invoke-External -Executable 'sf' -Arguments $arguments
        if ($result.ExitCode -eq 0) { return }
        $text = $result.Output -join "`n"
        $transient = $text -match 'ECONNRESET|ETIMEDOUT|ENOTFOUND|socket hang up|TypeError: terminated|UND_ERR_'
        if (-not $transient -or $attempt -eq $script:InstallMaxAttempts) { throw "Installing '$PackageName' failed (exit $($result.ExitCode)): $text" }
        Write-Warning "Transient install failure for $PackageName; retry $attempt/$($script:InstallMaxAttempts) after $($script:RetryDelaySeconds)s."
        Start-Sleep -Seconds $script:RetryDelaySeconds
    }
}

function Resolve-TargetOrg {
    param([switch]$ForPartialRun)
    if ($ForPartialRun -and -not $script:TargetOrgIsExplicit) {
        $response = Invoke-SfJson @('config', 'get', 'target-org')
        $entry = @($response.result | Where-Object { $_.name -eq 'target-org' }) | Select-Object -First 1
        $script:TargetOrg = [string]$entry.value
        if (-not $script:TargetOrg) { throw 'No Salesforce default target org is configured. Pass -OrgAlias or set defaultOrgAlias.' }
    }
    if (-not $script:TargetOrg) { throw 'No target org is configured. Pass -OrgAlias or set defaultOrgAlias.' }
}

function Invoke-PostStep {
    param([string]$Step)
    switch ($Step) {
        'deploy' {
            Invoke-Sf @('project', 'reset', 'tracking', '--target-org', $script:TargetOrg, '--no-prompt') -PlanOnly:$script:DryRun | Out-Null
            Invoke-Sf @('project', 'deploy', 'start', '--target-org', $script:TargetOrg, '--ignore-conflicts') -PlanOnly:$script:DryRun | Out-Null
            Invoke-Sf @('project', 'reset', 'tracking', '--target-org', $script:TargetOrg, '--no-prompt') -PlanOnly:$script:DryRun | Out-Null
        }
        'permsets' {
            if (@($script:Config.permissionSets).Count -eq 0) { Write-Warning 'No permission sets configured; skipping.'; return }
            $arguments = @('org', 'assign', 'permset', '--target-org', $script:TargetOrg)
            foreach ($name in @($script:Config.permissionSets)) { $arguments += @('--name', [string]$name) }
            Invoke-Sf $arguments -PlanOnly:$script:DryRun | Out-Null
        }
        'data' {
            if (-not $script:Config.dummyDataPlan) { Write-Warning 'No dummy data plan configured; skipping.'; return }
            Invoke-Sf @('data', 'import', 'tree', '--target-org', $script:TargetOrg, '--plan', $script:Config.dummyDataPlan) -PlanOnly:$script:DryRun | Out-Null
            Invoke-DummyUsers
        }
        'community' {
            if (-not $script:Config.communityName) { Write-Warning 'No community configured; skipping.'; return }
            Invoke-Sf @('community', 'publish', '--target-org', $script:TargetOrg, '--name', $script:Config.communityName) -PlanOnly:$script:DryRun | Out-Null
        }
        default {
            $custom = @($script:Config.customPostSteps | Where-Object { $_.name -eq $Step }) | Select-Object -First 1
            if ($null -eq $custom) { throw "Unknown post-step '$Step'." }
            if ($script:DryRun) { Write-Host "[dry-run] $($custom.executable) $($custom.arguments -join ' ')" -ForegroundColor Yellow }
            else {
                Push-Location $script:ProjectRoot
                try {
                    $customArguments = @($custom.arguments)
                    & $custom.executable @customArguments
                    if ($LASTEXITCODE -ne 0) { throw "Custom step '$Step' failed ($LASTEXITCODE)." }
                }
                finally { Pop-Location }
            }
        }
    }
}

function Invoke-DummyUsers {
    $dummy = $script:Config.dummyUsers
    if ($null -eq $dummy) { return }
    $file = [IO.Path]::GetFullPath((Join-Path $script:ProjectRoot $dummy.file))
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Write-Warning "Dummy user file not found: $file"; return }
    $tree = Read-JsonFile $file
    $profileByUsername = @{}
    foreach ($assignment in @($dummy.profileAssignments)) {
        foreach ($username in @($assignment.usernames)) { $profileByUsername[[string]$username] = [string]$assignment.profileName }
    }
    $profileNames = @($dummy.profileName) + @($dummy.profileAssignments | ForEach-Object { $_.profileName }) | Select-Object -Unique
    $profileIds = @{}
    foreach ($name in $profileNames) {
        if ($script:DryRun) { Write-Host "[dry-run] Resolve profile '$name'" -ForegroundColor Yellow; continue }
        $response = Invoke-SfJson @('data', 'query', '--target-org', $script:TargetOrg, '--query', "SELECT Id FROM Profile WHERE Name = $(ConvertTo-SoqlLiteral $name) LIMIT 1")
        $profileId = [string](@($response.result.records) | Select-Object -First 1 | ForEach-Object { $_.Id })
        if ($profileId) { $profileIds[$name] = $profileId } else { Write-Warning "Profile '$name' is missing in $script:TargetOrg; users mapped to it will be skipped." }
    }
    if ($script:DryRun) {
        Write-Host "[dry-run] Import missing dummy users from $file; profiles: $($profileNames -join ', ')" -ForegroundColor Yellow
        foreach ($assignment in @($dummy.permissionSetAssignments)) {
            $arguments = @('org', 'assign', 'permset', '--target-org', $script:TargetOrg)
            foreach ($permissionSet in @($assignment.permissionSets)) { $arguments += @('--name', [string]$permissionSet) }
            foreach ($username in @($assignment.usernames)) { $arguments += @('--on-behalf-of', [string]$username) }
            Invoke-Sf $arguments -PlanOnly | Out-Null
        }
        return
    }
    $usernames = @($tree.records | ForEach-Object { $_.Username } | Where-Object { $_ })
    $existing = @()
    if ($usernames.Count -gt 0) {
        $inClause = ($usernames | ForEach-Object { ConvertTo-SoqlLiteral ([string]$_) }) -join ','
        $response = Invoke-SfJson @('data', 'query', '--target-org', $script:TargetOrg, '--query', "SELECT Username FROM User WHERE Username IN ($inClause)")
        $existing = @($response.result.records | ForEach-Object { $_.Username })
    }
    $newRecords = @()
    foreach ($record in @($tree.records)) {
        $username = [string]$record.Username
        if ($existing -contains $username) { continue }
        $profileName = if ($profileByUsername.ContainsKey($username)) { $profileByUsername[$username] } else { [string]$dummy.profileName }
        if (-not $profileIds.ContainsKey($profileName)) { continue }
        $record.ProfileId = $profileIds[$profileName]
        $newRecords += $record
    }
    if ($newRecords.Count -gt 0) {
        $tempFile = Join-Path ([IO.Path]::GetTempPath()) ("sf-dummy-users-{0}.json" -f [guid]::NewGuid())
        try {
            Write-Utf8JsonFile -Path $tempFile -Value @{ records = $newRecords }
            Invoke-Sf @('data', 'import', 'tree', '--target-org', $script:TargetOrg, '--files', $tempFile) | Out-Null
        } finally { Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue }
    }
    $permissionAssignments = @($dummy.permissionSetAssignments)
    if ($env:DUMMY_USER_PERMSET_ASSIGNMENTS) {
        $permissionAssignments = @()
        foreach ($group in ($env:DUMMY_USER_PERMSET_ASSIGNMENTS -split ';')) {
            if ([string]::IsNullOrWhiteSpace($group)) { continue }
            $separator = $group.IndexOf(':')
            if ($separator -lt 1) { throw 'DUMMY_USER_PERMSET_ASSIGNMENTS entries must use PermissionSet1,PermissionSet2:user1,user2 format.' }
            $names = @($group.Substring(0, $separator) -split '[,\s]+' | Where-Object { $_ })
            $users = @($group.Substring($separator + 1) -split '[,\s]+' | Where-Object { $_ })
            if ($names.Count -eq 0 -or $users.Count -eq 0) { throw 'DUMMY_USER_PERMSET_ASSIGNMENTS groups require permission-set names and usernames.' }
            $permissionAssignments += [pscustomobject]@{ permissionSets = $names; usernames = $users }
        }
    }
    foreach ($assignment in $permissionAssignments) {
        $arguments = @('org', 'assign', 'permset', '--target-org', $script:TargetOrg)
        foreach ($permissionSet in @($assignment.permissionSets)) { $arguments += @('--name', [string]$permissionSet) }
        foreach ($username in @($assignment.usernames)) { $arguments += @('--on-behalf-of', [string]$username) }
        $result = Invoke-SfJson $arguments -AllowFailure
        if ($result.status -ne 0) {
            $failures = @($result.result.failures)
            if ($failures.Count -eq 0 -or @($failures | Where-Object { $_.message -notmatch 'Duplicate PermissionSetAssignment' }).Count -gt 0) {
                throw "Could not assign dummy user permission sets: $($result.message)"
            }
        }
    }
}

function Get-SelectedPostSteps {
    if ($script:BoundParameters.ContainsKey('PostSteps')) { $requested = @($PostSteps | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
    else { $requested = @($script:Config.postSteps) }
    $canonicalSteps = @('deploy', 'permsets', 'data', 'community') + @($script:Config.customPostSteps | ForEach-Object { $_.name })
    if ($requested.Count -eq 1 -and $requested[0] -eq 'all') { return $canonicalSteps }
    if ($requested.Count -eq 1 -and $requested[0] -eq 'none') { return @() }
    foreach ($step in $requested) { if ($step -notin $canonicalSteps) { throw "Unknown post-step '$step'." } }
    return @($canonicalSteps | Where-Object { $_ -in $requested })
}

function Invoke-Packages {
    param([switch]$PlanOnly, [switch]$Update)
    $dependencies = @(Get-PackageDependencies)
    if ($dependencies.Count -eq 0) { Write-Host 'No package dependencies are declared.'; return }
    $installed = @()
    if (-not $script:DryRun) { $installed = @(Get-InstalledPackages) }
    foreach ($dependency in $dependencies) {
        $name = [string]$dependency.package
        $target = Select-PackageVersion $name ([string]$dependency.versionNumber)
        $latest = @(Get-PackageVersionData $name)[-1]
        if (-not $script:SkipVersionCheck -and $target -and $latest -and
            ([int]$target.MajorVersion -ne [int]$latest.MajorVersion -or
             [int]$target.MinorVersion -ne [int]$latest.MinorVersion -or
             [int]$target.PatchVersion -ne [int]$latest.PatchVersion)) {
            Write-Warning "$name is configured at $($target.VersionNumber); latest released is $($latest.VersionNumber)."
        }
        $current = @($installed | Where-Object { (Get-PackageNameFromInstall $_) -eq $name }) | Select-Object -First 1
        $currentVersion = [string](Get-ObjectProperty $current 'SubscriberPackageVersionNumber' (Get-ObjectProperty $current 'VersionNumber' ''))
        $state = if ($null -eq $current) { 'missing' } elseif ($currentVersion -eq $target.VersionNumber) { 'current' } else { 'different' }
        $installedLabel = if ($currentVersion) { $currentVersion } else { 'missing' }
        Write-Host "${name}: configured=$($dependency.versionNumber), selected=$($target.VersionNumber), installed=$installedLabel"
        if ($PlanOnly) { continue }
        if ($Update -and $state -eq 'current') { continue }
        if ($Update -and $state -eq 'different' -and (Compare-Version $currentVersion $target.VersionNumber) -ge 0) { Write-Warning "Not downgrading $name ($currentVersion > $($target.VersionNumber))."; continue }
        if ($state -eq 'current') { continue }
        Invoke-PackageInstall $name ([string]$target.SubscriberPackageVersionId)
    }
}

function Compare-Version {
    param([string]$Left, [string]$Right)
    try {
        $leftVersion = [version]($Left -replace '\.LATEST$|\.NEXT$', '')
        $rightVersion = [version]($Right -replace '\.LATEST$|\.NEXT$', '')
        return $leftVersion.CompareTo($rightVersion)
    }
    catch { return 0 }
}

function Invoke-PoolAcquire {
    $devHub = $script:PoolDevHub
    if (-not $devHub) {
        $hub = Invoke-SfJson @('config', 'get', 'target-dev-hub')
        $devHub = [string](@($hub.result | Where-Object { $_.name -eq 'target-dev-hub' } | Select-Object -First 1).value)
    }
    if (-not $devHub) { throw 'Pool use requires -PoolDevHub or sf target-dev-hub configuration.' }
    $result = Invoke-External -Executable 'sfp' -Arguments @('pool', 'list', '--tag', $script:PoolTag, '-a', '--targetdevhubusername', $devHub)
    if ($result.ExitCode -ne 0) { throw "Could not list pool: $($result.Output -join "`n")" }
    $text = $result.Output -join "`n"
    $match = [regex]::Match($text, 'Unused Scratch Orgs in the Pool\s*:\s*(\d+)', 'IgnoreCase')
    if ($match.Success -and [int]$match.Groups[1].Value -gt 0) {
        Invoke-Sf @('org', 'delete', 'scratch', '--target-org', $script:TargetOrg, '--no-prompt') -AllowFailure | Out-Null
        Invoke-Sf @('pool', 'fetch', '--tag', $script:PoolTag, '--targetdevhubusername', $devHub, '--alias', $script:TargetOrg, '--setdefaultusername') -PlanOnly:$script:DryRun | Out-Null
        return $true
    }
    if (-not $script:FallbackToCreate) { throw 'No unused scratch org is available in the pool.' }
    Write-Warning 'No unused scratch orgs found; falling back to direct creation.'
    return $false
}

function Resolve-DependencyFolders {
    $names = @((Get-PackageDependencies | ForEach-Object { $_.package }) | Select-Object -Unique)
    foreach ($name in $names) {
        $directory = @($script:SfdxProject.packageDirectories | Where-Object { $_.package -eq $name -or [IO.Path]::GetFileName($_.path.TrimEnd('/')) -eq $name }) | Select-Object -First 1
        if ($null -eq $directory) {
            if ($script:RequireLocalDirectories) { throw "Dependency package directory is not declared: $name" }
            Write-Warning "No local directory for dependency '$name'; skipping."
            continue
        }
        $path = [IO.Path]::GetFullPath((Join-Path $script:ProjectRoot $directory.path))
        if (-not $path.StartsWith($script:ProjectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to modify path outside project root: $path" }
        if (Test-Path -LiteralPath $path -PathType Container) {
            $rootItem = Get-Item -LiteralPath $path -Force
            if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Refusing to use linked dependency directory: $path" }
        }
        [pscustomobject]@{ Name = $name; Path = $path }
    }
}

function Clear-DependencyFolders {
    $preserved = @(Get-ObjectProperty $script:Config.dependencySourcePolicy 'preserveRootFiles' @('README.md'))
    foreach ($dependency in @(Resolve-DependencyFolders)) {
        if (-not (Test-Path $dependency.Path -PathType Container)) { continue }
        $rootItem = Get-Item -LiteralPath $dependency.Path -Force
        if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Refusing to clear linked dependency directory: $($dependency.Path)" }
        foreach ($item in Get-ChildItem -LiteralPath $dependency.Path -Force) {
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Refusing to clear linked dependency child: $($item.FullName)" }
            if ($preserved -contains $item.Name) { continue }
            if ($script:DryRun) { Write-Host "[dry-run] Remove $($item.FullName)" -ForegroundColor Yellow }
            else { Remove-Item -LiteralPath $item.FullName -Recurse -Force }
        }
    }
}

function Refresh-DependencyFolders {
    $forceignore = Join-Path $script:ProjectRoot '.forceignore'
    $backup = "$forceignore.disabled"
    $moved = $false
    try {
        if (Test-Path -LiteralPath $forceignore) {
            if ($script:DryRun) { Write-Host '[dry-run] Temporarily disable .forceignore' -ForegroundColor Yellow }
            else { Move-Item -LiteralPath $forceignore -Destination $backup -Force; $moved = $true }
        }
        foreach ($dependency in @(Resolve-DependencyFolders)) {
            Invoke-Sf @('project', 'retrieve', 'start', '--target-org', $script:TargetOrg, '-n', $dependency.Name) -PlanOnly:$script:DryRun | Out-Null
        }
    } finally {
        if ($moved -and (Test-Path -LiteralPath $backup)) { Move-Item -LiteralPath $backup -Destination $forceignore -Force }
    }
}

function Invoke-SelfCheck {
    if (-not (Test-Path -LiteralPath $script:ProjectFilePath -PathType Leaf)) { throw "Salesforce project file not found: $script:ProjectFilePath" }
    if (-not (Test-Path -LiteralPath $script:DefinitionFile -PathType Leaf)) { throw "Scratch definition not found: $script:DefinitionFile" }
    $null = Invoke-SfJson @('--version')
    $null = Invoke-SfJson @('org', 'list')
    if ($script:TargetOrgIsExplicit) {
        Resolve-TargetOrg -ForPartialRun
        $null = Invoke-SfJson @('org', 'display', '--target-org', $script:TargetOrg)
    }
    if ($script:UsePool) {
        $poolVersion = Invoke-External -Executable 'sfp' -Arguments @('--version')
        if ($poolVersion.ExitCode -ne 0) { throw 'sfp is required by the configured scratch-org pool.' }
    }
    Write-Host 'Self-check passed.' -ForegroundColor Green
}

function Invoke-Main {
    if ($Help) {
        @'
Usage: create-scratch-org.bat [-OrgAlias <alias>] [-DurationDays <1..30>] [-DryRun]
       [-PostStepsOnly] [-PostSteps <steps>] [-SkipPackages] [-UpdatePackages]
       [-PackagePlan] [-DeleteOrgOnly] [-UsePool] [-RefreshDependencySources]
       [-ClearDependencySourcesOnly] [-SelfCheck] [-InitConfig] [-Force]

Reads sf-project.config.json beside sfdx-project.json. Requires only PowerShell,
jq for dependency cleanup, and Salesforce CLI (sf). It does not require sf-project.
'@ | Write-Host
        return
    }
    if (-not $ProjectFile) { $ProjectFile = if ($env:PROJECT_FILE) { $env:PROJECT_FILE } else { 'sfdx-project.json' } }
    $projectFilePath = [IO.Path]::GetFullPath($ProjectFile)
    $script:ProjectFilePath = $projectFilePath
    $script:ProjectRoot = Split-Path -Parent $projectFilePath
    if (-not $script:ProjectRoot) { $script:ProjectRoot = (Get-Location).Path }
    $script:SfdxProject = Read-JsonFile $projectFilePath
    if (-not $ConfigFile -and $env:SF_PROJECT_CONFIG) { $ConfigFile = $env:SF_PROJECT_CONFIG }
    $configPath = if ($ConfigFile) {
        if ([IO.Path]::IsPathRooted($ConfigFile)) { [IO.Path]::GetFullPath($ConfigFile) } else { [IO.Path]::GetFullPath((Join-Path $script:ProjectRoot $ConfigFile)) }
    } else { Join-Path $script:ProjectRoot 'sf-project.config.json' }
    $script:Config = [pscustomobject]@{
        schemaVersion = 1; scratchDefinition = 'config/project-scratch-def.json'; scratchDurationDays = 14
        permissionSets = @(); dummyDataPlan = $null; communityName = $null; postSteps = @('deploy')
        customPostSteps = @(); pool = [pscustomobject]@{ use = $false; tag = 'dev'; fallbackToCreate = $true }
        packageInstallKeyEnvironmentVariable = 'PACKAGE_INSTALL_KEY'
        dependencySourcePolicy = [pscustomobject]@{ preserveRootFiles = @('README.md'); requireLocalDirectories = $true }
    }
    if (-not $NoConfig -and (Test-Path -LiteralPath $configPath)) {
        $loaded = Read-JsonFile $configPath
        foreach ($property in $loaded.PSObject.Properties) { $script:Config | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value -Force }
        Test-Configuration $script:Config
    } elseif (-not $NoConfig -and $ConfigFile) { throw "Configuration file not found: $configPath" }

    if ($null -eq $script:Config.pool) { $script:Config.pool = [pscustomobject]@{ use = $false; tag = 'dev'; fallbackToCreate = $true } }
    if ($null -eq $script:Config.customPostSteps) { $script:Config.customPostSteps = @() }
    if ($null -eq $script:Config.postSteps) { $script:Config.postSteps = @('deploy') }
    if ($null -eq $script:Config.permissionSets) { $script:Config.permissionSets = @() }
    if ($null -ne $script:Config.dummyUsers) {
        if (-not $script:Config.dummyUsers.profileName) { $script:Config.dummyUsers | Add-Member -NotePropertyName profileName -NotePropertyValue 'Standard User' -Force }
        if ($null -eq $script:Config.dummyUsers.profileAssignments) { $script:Config.dummyUsers | Add-Member -NotePropertyName profileAssignments -NotePropertyValue @() -Force }
        if ($null -eq $script:Config.dummyUsers.permissionSetAssignments) { $script:Config.dummyUsers | Add-Member -NotePropertyName permissionSetAssignments -NotePropertyValue @() -Force }
        if ($env:DUMMY_USER_FILE) { $script:Config.dummyUsers.file = $env:DUMMY_USER_FILE }
        if ($env:DUMMY_USER_PROFILE_NAME) { $script:Config.dummyUsers.profileName = $env:DUMMY_USER_PROFILE_NAME }
    }

    $envAlias = [Environment]::GetEnvironmentVariable('ORG_ALIAS')
    $script:TargetOrgIsExplicit = $script:BoundParameters.ContainsKey('OrgAlias') -or [bool]$envAlias -or [bool]$script:Config.defaultOrgAlias
    $script:TargetOrg = if ($script:BoundParameters.ContainsKey('OrgAlias')) { $OrgAlias } elseif ($envAlias) { $envAlias } elseif ($script:Config.defaultOrgAlias) { [string]$script:Config.defaultOrgAlias } else { Split-Path -Leaf $script:ProjectRoot }
    $duration = if ($DurationDays -gt 0) { $DurationDays } elseif ($env:DURATION_DAYS) { [int]$env:DURATION_DAYS } else { [int]$script:Config.scratchDurationDays }
    if ($duration -lt 1 -or $duration -gt 30) { throw 'DurationDays must be from 1 to 30.' }
    $script:DefinitionFile = if ($DefinitionFile) { $DefinitionFile } elseif ($env:SCRATCH_DEF_FILE) { $env:SCRATCH_DEF_FILE } else { [string]$script:Config.scratchDefinition }
    if (-not [IO.Path]::IsPathRooted($script:DefinitionFile)) { $script:DefinitionFile = Join-Path $script:ProjectRoot $script:DefinitionFile }
    $script:DefinitionFile = [IO.Path]::GetFullPath($script:DefinitionFile)
    if ($script:BoundParameters.ContainsKey('CommunityName')) { $script:Config.communityName = $CommunityName }
    elseif ($env:COMMUNITY_NAME) { $script:Config.communityName = $env:COMMUNITY_NAME }
    if ($script:BoundParameters.ContainsKey('DummyDataPlan')) { $script:Config.dummyDataPlan = $DummyDataPlan }
    elseif ($env:DUMMY_DATA_PLAN) { $script:Config.dummyDataPlan = $env:DUMMY_DATA_PLAN }
    if ($script:BoundParameters.ContainsKey('PermissionSets')) { $script:Config.permissionSets = @($PermissionSets | ForEach-Object { $_ -split '[,\s]+' } | Where-Object { $_ }) }
    elseif ($env:PERMISSION_SETS) { $script:Config.permissionSets = @($env:PERMISSION_SETS -split '[,\s]+' | Where-Object { $_ }) }
    if (-not $script:BoundParameters.ContainsKey('PostSteps') -and $env:POST_STEPS) { $script:Config.postSteps = @($env:POST_STEPS -split ',' | Where-Object { $_ }) }
    $script:PackageWaitMinutes = if ($env:PACKAGE_WAIT_MINUTES) { [int]$env:PACKAGE_WAIT_MINUTES } else { 10 }
    $script:InstallMaxAttempts = if ($env:PACKAGE_INSTALL_MAX_ATTEMPTS) { [int]$env:PACKAGE_INSTALL_MAX_ATTEMPTS } else { 3 }
    $script:RetryDelaySeconds = if ($env:PACKAGE_INSTALL_RETRY_DELAY_SECONDS) { [int]$env:PACKAGE_INSTALL_RETRY_DELAY_SECONDS } else { 5 }
    $script:InstallLatest = $InstallLatest.IsPresent -or $env:INSTALL_LATEST_PACKAGES -eq 'true'
    $script:SkipVersionCheck = $SkipVersionCheck.IsPresent -or $env:VERIFY_PACKAGE_VERSIONS -eq 'false'
    $script:DryRun = $DryRun.IsPresent
    $script:PoolTag = if ($PoolTag) { $PoolTag } elseif ($env:POOL_TAG) { $env:POOL_TAG } else { [string]$script:Config.pool.tag }
    $script:PoolDevHub = if ($PoolDevHub) { $PoolDevHub } elseif ($env:POOL_DEVHUB_USERNAME) { $env:POOL_DEVHUB_USERNAME } else { [string]$script:Config.pool.devHub }
    $script:FallbackToCreate = -not $NoFallbackToCreate -and [bool]$script:Config.pool.fallbackToCreate
    $script:UsePool = if ($UsePool.IsPresent) { $true } elseif ($env:USE_POOL -eq 'false') { $false } elseif ($env:USE_POOL -eq 'true') { $true } else { [bool]$script:Config.pool.use }
    $script:RequireLocalDirectories = [bool](Get-ObjectProperty $script:Config.dependencySourcePolicy 'requireLocalDirectories' $true)
    $script:KeyEnvironmentVariable = [string]$script:Config.packageInstallKeyEnvironmentVariable
    if ($env:PACKAGE_INSTALL_KEY_ENV_VAR) { $script:KeyEnvironmentVariable = $env:PACKAGE_INSTALL_KEY_ENV_VAR }
    $script:InstallationKey = [Environment]::GetEnvironmentVariable($script:KeyEnvironmentVariable)
    if (-not $script:InstallationKey) { $script:InstallationKey = $env:PACKAGE_INSTALL_KEY }
    if ($env:PACKAGE_INSTALL_MAX_ATTEMPTS) { $script:InstallMaxAttempts = [int]$env:PACKAGE_INSTALL_MAX_ATTEMPTS }
    if ($env:PACKAGE_INSTALL_RETRY_DELAY_SECONDS) { $script:RetryDelaySeconds = [int]$env:PACKAGE_INSTALL_RETRY_DELAY_SECONDS }
    if ($script:InstallMaxAttempts -lt 1) { throw 'PACKAGE_INSTALL_MAX_ATTEMPTS must be at least 1.' }
    if ($script:RetryDelaySeconds -lt 0) { throw 'PACKAGE_INSTALL_RETRY_DELAY_SECONDS cannot be negative.' }
    if ($script:PackageWaitMinutes -lt 0) { throw 'PACKAGE_WAIT_MINUTES cannot be negative.' }
    $script:PackageWaitMinutes = [Math]::Max(1, $script:PackageWaitMinutes)
    $script:NoKeyPackages = @()
    if ($env:PACKAGES_NOT_REQUIRING_INSTALL_KEY) { $script:NoKeyPackages = @($env:PACKAGES_NOT_REQUIRING_INSTALL_KEY -split '[,\s]+' | Where-Object { $_ }) }
    if ($env:FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY -eq 'false') { $script:FallbackToCreate = $false }
    elseif ($env:FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY -eq 'true' -and -not $NoFallbackToCreate) { $script:FallbackToCreate = $true }
    $script:ProjectRoot = [IO.Path]::GetFullPath($script:ProjectRoot)

    if ($InitConfig) {
        if ($NoConfig) { throw '-InitConfig cannot be combined with -NoConfig.' }
        if ((Test-Path -LiteralPath $configPath) -and -not $Force -and -not $DryRun) { throw "Config exists; pass -Force to update: $configPath" }
        Set-ObjectProperty $script:Config 'defaultOrgAlias' $script:TargetOrg
        Set-ObjectProperty $script:Config 'scratchDurationDays' $duration
        if ($script:BoundParameters.ContainsKey('PermissionSets')) { $script:Config.permissionSets = @($PermissionSets | ForEach-Object { $_ -split '[,\s]+' } | Where-Object { $_ }) }
        if ($script:BoundParameters.ContainsKey('DummyDataPlan')) { $script:Config.dummyDataPlan = $DummyDataPlan }
        if ($script:BoundParameters.ContainsKey('CommunityName')) { $script:Config.communityName = $CommunityName }
        if ($script:BoundParameters.ContainsKey('PostSteps')) { $script:Config.postSteps = @($PostSteps | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
        if ($DryRun) { $script:Config | ConvertTo-Json -Depth 100; return }
        Write-Utf8JsonFile -Path $configPath -Value $script:Config
        Write-Host "Wrote $configPath"
        return
    }

    Push-Location $script:ProjectRoot
    try {
        if ($ClearDependencySourcesOnly) { Clear-DependencyFolders; return }
        if ($SelfCheck) { Invoke-SelfCheck; return }
        if ($DeleteOrgOnly) {
            Resolve-TargetOrg -ForPartialRun
            Invoke-Sf @('org', 'delete', 'scratch', '--target-org', $script:TargetOrg, '--no-prompt') -PlanOnly:$script:DryRun -AllowFailure | Out-Null
            return
        }
        if ($PackagePlan) {
            Resolve-TargetOrg -ForPartialRun
            Invoke-Packages -PlanOnly
            return
        }
        $steps = if ($UpdatePackages) { @() } else { @(Get-SelectedPostSteps) }
        $setupOrg = -not ($SkipOrg -or $PostStepsOnly -or $UpdatePackages)
        $installPackages = -not $SkipPackages -and -not $PostStepsOnly
        if (-not $setupOrg -and ($installPackages -or $UpdatePackages -or $steps.Count -gt 0)) { Resolve-TargetOrg -ForPartialRun }
        if ($RefreshDependencySources -and $setupOrg) { Clear-DependencyFolders }
        if ($setupOrg) {
            if ($UsePool) { $acquired = Invoke-PoolAcquire } else { $acquired = $false }
            if (-not $acquired) {
                if (-not $DryRun -and -not (Test-Path -LiteralPath $script:DefinitionFile -PathType Leaf)) { throw "Scratch definition not found: $script:DefinitionFile" }
                Invoke-Sf @('org', 'delete', 'scratch', '--target-org', $script:TargetOrg, '--no-prompt') -PlanOnly:$script:DryRun -AllowFailure | Out-Null
                Invoke-Sf @('org', 'create', 'scratch', '--set-default', '--definition-file', $script:DefinitionFile, '--duration-days', [string]$duration, '--alias', $script:TargetOrg) -PlanOnly:$script:DryRun | Out-Null
            }
        }
        if ($UpdatePackages) { Invoke-Packages -Update }
        elseif ($installPackages) { Invoke-Packages }
        foreach ($step in $steps) { Invoke-PostStep $step }
        if ($RefreshDependencySources) { Refresh-DependencyFolders }
        Write-Host 'Scratch-org setup completed.' -ForegroundColor Green
    } finally { Pop-Location }
}

try {
    Invoke-Main
    exit 0
} catch {
    [Console]::Error.WriteLine("ERROR: $($_.Exception.Message)")
    exit 1
}
