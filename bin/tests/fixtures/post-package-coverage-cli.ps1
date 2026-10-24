param(
    [Parameter(Mandatory = $true)]
    [string]$Tool,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$entry = [pscustomobject]@{
    tool = $Tool
    arguments = @($Arguments)
}
$logPath = $env:COVERAGE_TEST_LOG
$line = ConvertTo-Json -InputObject $entry -Compress -Depth 10
[IO.File]::AppendAllText($logPath, $line + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

$exitCode = 0
$output = ''
if ($Tool -ne 'sf') {
    $exitCode = 90
    $output = 'Unexpected executable'
} elseif ($Arguments -contains 'force:package:install') {
    $output = '{"status":0,"result":{}}'
} elseif ($Arguments -contains 'deploy') {
    if ($env:COVERAGE_TEST_DEPLOY_EXIT) {
        $exitCode = [int]$env:COVERAGE_TEST_DEPLOY_EXIT
        $output = '{"status":1,"message":"scripted deploy failure"}'
    } else {
        $output = '{"status":0,"result":{}}'
    }
} elseif ($Arguments -contains 'get' -and $Arguments -contains 'test') {
    $exitCode = [int]$env:COVERAGE_TEST_GET_TEST_EXIT
    $output = 'async test result'
} elseif ($Arguments -contains 'run' -and $Arguments -contains 'test') {
    if ($Arguments -contains '--tests') {
        $exitCode = [int]$env:COVERAGE_TEST_TEST_EXIT
        $output = 'targeted test result'
    } elseif ($Arguments -contains '--wait' -and $env:COVERAGE_TEST_RUN_ALL_FALLBACK -eq 'true') {
        $output = '{"status":1,"message":"scripted synchronous failure"}'
    } else {
        $output = '{"status":0,"result":{"testRunId":"offline-test-run"}}'
    }
} elseif ($Arguments -contains '--query') {
    $output = $env:COVERAGE_TEST_QUERY_JSON
} else {
    $exitCode = 91
    $output = 'Unexpected sf arguments'
}

if ($output) { [Console]::Out.WriteLine($output) }
exit $exitCode
