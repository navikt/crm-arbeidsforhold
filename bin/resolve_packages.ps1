param(
    [string]$ProjectFile = "sfdx-project.json"
)

$json = Get-Content $ProjectFile -Raw | ConvertFrom-Json
$deps = $json.packageDirectories | Where-Object { $_.dependencies } | ForEach-Object { $_.dependencies } | ForEach-Object { $_ }
$aliases = @{}
foreach ($prop in $json.packageAliases.PSObject.Properties) { $aliases[$prop.Name] = $prop.Value }

foreach ($dep in $deps) {
    $pkgName = $dep.package
    $packageId = $aliases[$pkgName]
    if (-not $packageId) {
        Write-Error "No alias found for $pkgName"
        continue
    }
    try {
        $versionJson = sf package version list --packages $packageId --released --order-by CreatedDate --json 2>$null | ConvertFrom-Json
        $latest = $versionJson.result | Select-Object -Last 1
        if ($latest.SubscriberPackageVersionId) {
            # Use IsPasswordProtected to determine if installation key is needed
            $hasKey = "KEY"
            if ($null -ne $latest.IsPasswordProtected -and $latest.IsPasswordProtected -eq $false) {
                $hasKey = "NOKEY"
            }
            Write-Output "$pkgName|$($latest.SubscriberPackageVersionId)|$hasKey"
        } else {
            Write-Error "No released version found for $pkgName ($packageId)"
        }
    } catch {
        Write-Error "Failed to resolve version for $pkgName : $_"
    }
}