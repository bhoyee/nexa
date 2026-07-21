$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $root 'scripts\dev\mariadb-version-policy.ps1')

foreach ($supported in @(
    'mariadb.exe Ver 15.1 Distrib 10.11.16-MariaDB, for Win64',
    '11.0.6-MariaDB',
    'mariadb from 11.4.7-MariaDB, client 15.2',
    '11.8.3-MariaDB-ubu2404'
)) {
    Assert-NexaMariaDbVersion $supported 'test version' | Out-Null
}

foreach ($unsupported in @(
    '10.4.32-MariaDB',
    '12.0.1-MariaDB',
    'mysql  Ver 8.0.42 for Win64'
)) {
    try {
        Assert-NexaMariaDbVersion $unsupported 'test version' | Out-Null
        throw "Expected an unsupported-version error for: $unsupported"
    } catch {
        if ($_.Exception.Message -like 'Expected an unsupported-version error*') { throw }
    }
}

Write-Host 'MariaDB version policy tests passed.'
