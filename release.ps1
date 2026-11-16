param(
    [ValidateSet('check','publish','status','full')][string]$Mode = 'publish',
    [switch]$Native,
    [ValidateRange(1,21600)][int]$Budget = 900
)
$ErrorActionPreference = 'Stop'
$env:PYTHONUTF8 = '1'
$bfhArguments = @((Join-Path $PSScriptRoot 'tools/release.py'), $Mode, '--budget', "$Budget")
if ($Native) { $bfhArguments += '--native' }
& python @bfhArguments
exit $LASTEXITCODE
