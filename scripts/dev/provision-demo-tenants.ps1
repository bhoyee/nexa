[CmdletBinding()]
param(
    [ValidateSet('Docker', 'Local')]
    [string] $Mode = 'Docker',
    [string] $PhpPath = 'php',
    [string] $UserName = 'demo-admin'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$previousUserName = $env:NEXA_DEMO_ADMIN_USERNAME
$previousPassword = $env:NEXA_DEMO_ADMIN_PASSWORD

try {
    if ($Mode -eq 'Docker') {
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            throw 'Docker is unavailable.'
        }

        & docker compose --project-directory $root exec -T `
            -e "NEXA_DEMO_ADMIN_USERNAME=$UserName" `
            espocrm php bin/provision-demo-tenants.php

        if ($LASTEXITCODE -ne 0) {
            throw 'Demo tenant administrator provisioning failed.'
        }

        return
    }

    if (-not (Get-Command $PhpPath -ErrorAction SilentlyContinue)) {
        throw "PHP executable not found: $PhpPath"
    }

    $securePassword = Read-Host 'Demo tenant administrator password' -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)

    try {
        $env:NEXA_DEMO_ADMIN_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }

    $env:NEXA_DEMO_ADMIN_USERNAME = $UserName
    & $PhpPath (Join-Path $root 'espocrm\bin\provision-demo-tenants.php')

    if ($LASTEXITCODE -ne 0) {
        throw 'Demo tenant administrator provisioning failed.'
    }
}
finally {
    $env:NEXA_DEMO_ADMIN_USERNAME = $previousUserName
    $env:NEXA_DEMO_ADMIN_PASSWORD = $previousPassword
}